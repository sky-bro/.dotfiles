import assert from "node:assert/strict";
import { after, before, beforeEach, test } from "node:test";
import { chmod, mkdir, mkdtemp, readFile, rm, symlink, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { PasswordStore as PassClient } from "../src/services/password-store.ts";
import { PassError, SavedWithoutCommit } from "../src/domain/errors.ts";
import { execute } from "../src/services/command.ts";
import { splitRecord, validateName } from "../src/domain/entry.ts";
import { parseFields, selectField } from "../src/domain/fields.ts";
import { MacClipboard } from "../src/platform/macos.ts";
import type { Entry } from "../src/domain/entry.ts";

let sandbox: string;
let gnupg: string;
let env: NodeJS.ProcessEnv;
let firstKey: string;
let secondKey: string;
let client: PassClient;
let store: string;
let sequence = 0;
const fixture = "synthetic-password-&-$()-空格";
const details = "username: fixture\nurl: https://example.invalid/\ncustom: keep this\nnotes with trailing blank lines\n\n";
const command = (args: string[]) => execute("gpg", ["--homedir", gnupg, "--batch", ...args], env);
const git = (args: string[]) => execute("git", ["-C", store, ...args], env);
const entry = async (name: string): Promise<Entry> => ({ name, version: (await client.version(name))! });

before(async () => {
  sandbox = await mkdtemp(join(tmpdir(), "pass-client-test-"));
  gnupg = join(sandbox, "gnupg");
  await mkdir(gnupg, { mode: 0o700 });
  const globalConfig = join(sandbox, "gitconfig");
  await writeFile(globalConfig, "[user]\nname = Fixture\nemail = fixture@example.invalid\n[commit]\ngpgsign = false\n");
  env = { ...process.env, GNUPGHOME: gnupg, GIT_CONFIG_GLOBAL: globalConfig, GIT_CONFIG_NOSYSTEM: "1", PASSWORD_STORE_DIR: undefined, PASSWORD_STORE_KEY: undefined, PASSWORD_STORE_SIGNING_KEY: undefined };
  for (const identity of ["one", "two"]) {
    await command(["--pinentry-mode", "loopback", "--passphrase", "", "--quick-generate-key", `${identity}@fixture.invalid`, "rsa2048", "encr", "1d"]);
  }
  const fingerprint = async (identity: string) => (await command(["--with-colons", "--list-keys", identity])).split("\n").find((line) => line.startsWith("fpr:"))!.split(":")[9];
  firstKey = await fingerprint("one@fixture.invalid");
  secondKey = await fingerprint("two@fixture.invalid");
});

after(async () => {
  if (!sandbox) return;
  // Dispose fixture keys through GnuPG, without reading or editing key files.
  for (const fingerprint of [firstKey, secondKey].filter(Boolean)) {
    await command(["--yes", "--delete-secret-and-public-key", fingerprint]);
  }
  await execute("gpgconf", ["--homedir", gnupg, "--kill", "all"], env);
  await rm(sandbox, { recursive: true, force: true });
});

beforeEach(async () => {
  store = join(sandbox, `store-${sequence++}`);
  await mkdir(store, { mode: 0o700 });
  await writeFile(join(store, ".gpg-id"), `${firstKey}\n`);
  client = new PassClient(store, "pass", env);
});

test("new entry encrypts stdin and round-trips all metadata", async () => {
  await client.save("web/account", `${fixture}\n${details}`);
  const ciphertext = await readFile(join(store, "web/account.gpg"));
  assert.equal(ciphertext.includes(Buffer.from(fixture)), false);
  const record = await client.read(await entry("web/account"));
  assert.equal(record.password, fixture);
  assert.equal(record.details, details);
  assert.equal(selectField(parseFields(record.content), "username")?.value, "fixture");
  assert.equal(selectField(parseFields(record.content), "url")?.value, "https://example.invalid/");
});

test("browsing does not decrypt and ignores symlinks and metadata directories", async () => {
  await writeFile(join(store, "not-decryptable.gpg"), "ciphertext-only-fixture");
  await mkdir(join(store, ".git"));
  await writeFile(join(store, ".git/hidden.gpg"), "fixture");
  await symlink(join(store, "not-decryptable.gpg"), join(store, "link.gpg"));
  assert.deepEqual((await client.list()).map((item) => item.name), ["not-decryptable"]);
});

test("special names are literal arguments, not shell commands", async () => {
  const name = '-web/a space $(touch INJECTED)';
  await client.save(name, fixture);
  assert.equal((await client.read(await entry(name))).password, fixture);
  assert.equal(await client.version("INJECTED"), undefined);
});

test("edits preserve supplied details and reject stale versions", async () => {
  await client.save("one", `${fixture}\n${details}`);
  const old = await entry("one");
  await client.save("one", `replacement\n${details}`, old.version);
  await assert.rejects(client.save("one", "lost update", old.version), /changed or already exists/);
  assert.equal((await client.read(await entry("one"))).details, details);
});

test("create and generate never overwrite existing entries", async () => {
  await client.save("one", fixture);
  await assert.rejects(client.save("one", "overwrite"), PassError);
  await assert.rejects(client.generate("one", 24, true), PassError);
  assert.equal((await client.read(await entry("one"))).password, fixture);
});

test("generate uses requested length and no-symbol option", async () => {
  await client.generate("generated", 32, false);
  assert.match((await client.read(await entry("generated"))).password, /^[A-Za-z0-9]{32}$/);
});

test("regenerate replaces only the first line", async () => {
  await client.save("one", `${fixture}\n${details}`);
  await client.generate("one", 31, true, (await entry("one")).version);
  const record = await client.read(await entry("one"));
  assert.equal(record.password.length, 31);
  assert.equal(record.details, details);
});

test("failed staging encryption leaves existing ciphertext untouched", async () => {
  await client.save("one", fixture);
  const old = await entry("one");
  const broken = new PassClient(store, "/usr/bin/false", env);
  await assert.rejects(broken.save("one", "replacement", old.version), PassError);
  assert.equal(await client.version("one"), old.version);
});

test("move reencrypts for destination recipients and preserves exact content", async () => {
  await client.save("one", `${fixture}\n${details}`);
  await mkdir(join(store, "team"));
  await writeFile(join(store, "team/.gpg-id"), `${secondKey}\n`);
  await client.transfer(await entry("one"), "team/two", true);
  assert.equal(await client.version("one"), undefined);
  assert.equal((await client.read(await entry("team/two"))).content, `${fixture}\n${details}`);
  const recipients = await command(["--list-only", "--status-fd", "1", "--decrypt", join(store, "team/two.gpg")]);
  assert.ok(recipients.includes(secondKey.slice(-16)));
});

test("duplicate does not remove source or overwrite destination", async () => {
  await client.save("one", fixture);
  const original = await entry("one");
  await client.transfer(original, "two", false);
  assert.equal(await client.version("one"), original.version);
  assert.equal((await client.read(await entry("two"))).content, fixture);
  await assert.rejects(client.transfer(original, "two", true), PassError);
});

test("delete supports encrypted undo without clobbering a recreated entry", async () => {
  await client.save("one", fixture);
  const undo = await client.remove(await entry("one"));
  assert.equal(undo.encrypted.includes(Buffer.from(fixture)), false);
  assert.equal(await client.version("one"), undefined);
  await client.restore(undo);
  assert.equal((await client.read(await entry("one"))).password, fixture);
  await assert.rejects(client.restore(undo), PassError);
});

test("Git commits include only the affected entries, preserving unrelated staging", async () => {
  await git(["init", "-q"]);
  await writeFile(join(store, "unrelated.txt"), "fixture unrelated staged change");
  await git(["add", "unrelated.txt"]);
  await client.save("one", fixture);
  assert.equal((await git(["diff", "--cached", "--name-only"])).trim(), "unrelated.txt");
  assert.equal((await git(["show", "--name-only", "--format=", "HEAD"])).trim(), "one.gpg");
  assert.ok((await client.history(await entry("one"))).includes("Add password for one"));
});

test("Git hook failure reports saved ciphertext, and deletion still has undo", async () => {
  await git(["init", "-q"]);
  const hook = join(store, ".git/hooks/pre-commit");
  await writeFile(hook, "#!/bin/sh\nexit 1\n"); await chmod(hook, 0o700);
  await assert.rejects(client.save("one", fixture), SavedWithoutCommit);
  assert.equal((await client.read(await entry("one"))).password, fixture);
  const undo = await client.remove(await entry("one"));
  assert.ok(undo.warning);
  assert.ok(undo.encrypted.length);
});

test("path traversal, metadata paths, and symlink destinations are rejected", async () => {
  for (const name of ["../outside", "/absolute", "a//b", "a/../b", ".git/config", ".extensions/run", "a\nb", "a\\b", ""]) {
    assert.throws(() => validateName(name), PassError);
  }
  const outside = join(sandbox, "outside");
  await mkdir(outside, { recursive: true });
  await symlink(outside, join(store, "escape"));
  await assert.rejects(client.save("escape/one", fixture), PassError);
});

test("invalid generation and missing fields fail without mutations", async () => {
  for (const length of [0, -1, 1.5, 1025, NaN]) await assert.rejects(client.generate("one", length, true), PassError);
  assert.equal(await client.version("one"), undefined);
  assert.equal(selectField(parseFields("password\nnote: data"), "username"), undefined);
  assert.deepEqual(splitRecord("password-only"), { password: "password-only", details: "" });
});

test("child error output and partial plaintext are never included in errors", async () => {
  const program = join(sandbox, "failed-child.cjs");
  await writeFile(program, `process.stdout.write(${JSON.stringify(fixture)}); process.stderr.write(${JSON.stringify(fixture)}); process.exit(1);`);
  await assert.rejects(execute(process.execPath, [program], env), (error: Error) => {
    assert.equal(String(error).includes(fixture), false);
    assert.equal("stdout" in error, false);
    assert.equal("stderr" in error, false);
    return true;
  });
});

test("writes are serialized while encryption is pending", async () => {
  const first = client.save("one", fixture);
  await assert.rejects(client.save("two", fixture), /still running/);
  await first;
  assert.equal(await client.version("two"), undefined);
});

test("entry history follows a nested password Git repository", async () => {
  const nested = join(store, "nested");
  await mkdir(nested);
  await execute("git", ["-C", nested, "init", "-q"], env);
  await client.save("nested/one", fixture);
  assert.ok((await client.history(await entry("nested/one"))).includes("Add password for nested/one"));
});

test("native clipboard bridge marks data and clears after its timeout", { skip: process.env.PASS_TEST_CLIPBOARD !== "1" }, async () => {
  const gui = new PassClient(store, "pass", { ...env, PASSWORD_STORE_CLIP_TIME: "2" });
  const inspect = `ObjC.import('AppKit'); function run(a) { var p=$.NSPasteboard.generalPasteboard; var t=ObjC.deepUnwrap(p.types)||[]; return JSON.stringify({matches:ObjC.unwrap(p.stringForType('public.utf8-plain-text'))===a[0], concealed:t.indexOf('org.nspasteboard.ConcealedType')>=0, transient:t.indexOf('org.nspasteboard.TransientType')>=0, empty:t.length===0}); }`;
  await new MacClipboard(join(import.meta.dirname, "../assets"), gui.env()).copy(fixture);
  const copied = JSON.parse(await execute("/usr/bin/osascript", ["-l", "JavaScript", "-e", inspect, fixture], env));
  assert.equal(copied.matches && copied.concealed && copied.transient, true);
  await new Promise((done) => setTimeout(done, 2300));
  const cleared = JSON.parse(await execute("/usr/bin/osascript", ["-l", "JavaScript", "-e", inspect, fixture], env));
  assert.equal(cleared.empty, true);
});

test("separate store instances observe the same write lock", async () => {
  const { acquireStoreLock } = await import("../src/services/store-lock.ts");
  const release = await acquireStoreLock(store);
  try {
    await assert.rejects(new PassClient(store, "pass", env).save("blocked", fixture), /store is locked/);
    assert.equal(await client.version("blocked"), undefined);
  } finally { await release(); }
  await client.save("unblocked", fixture);
});

test("an aborted mutation releases its lock without modifying the entry", async () => {
  const controller = new AbortController(); controller.abort();
  await assert.rejects(client.save("cancelled", fixture, undefined, controller.signal), /cancelled/);
  assert.equal(await client.version("cancelled"), undefined);
  await client.save("subsequent", fixture);
});

test("recipient changes during encryption prevent installation", async () => {
  const script = join(sandbox, "change-recipients.cjs");
  await writeFile(script, `#!/usr/bin/env node\nconst {spawnSync}=require('node:child_process'); const fs=require('node:fs'); const result=spawnSync('pass',process.argv.slice(2),{stdio:'inherit'}); if(result.status===0) fs.writeFileSync(process.env.TEST_RECIPIENT_PATH,process.env.TEST_NEW_RECIPIENT); process.exit(result.status ?? 1);\n`);
  await chmod(script, 0o700);
  const changing = new PassClient(store, script, { ...env, TEST_RECIPIENT_PATH: join(store, ".gpg-id"), TEST_NEW_RECIPIENT: `${secondKey}\n` });
  await assert.rejects(changing.save("one", fixture), /recipient configuration changed/);
  assert.equal(await client.version("one"), undefined);
});

test("a failed source removal rolls back the newly created destination", { skip: process.getuid?.() === 0 }, async () => {
  await client.save("readonly/one", fixture);
  const source = await entry("readonly/one");
  await chmod(join(store, "readonly"), 0o500);
  try {
    await assert.rejects(client.transfer(source, "two", true), /destination was rolled back/);
    assert.equal(await client.version("two"), undefined);
    assert.equal(await client.version(source.name), source.version);
  } finally { await chmod(join(store, "readonly"), 0o700); }
});

test("the bundled CLI uses the same standalone store backend", async () => {
  await client.save("cli/example", fixture);
  const binary = join(import.meta.dirname, "../assets/pass-cli.cjs");
  const result = await execute(process.execPath, [binary, "--list"], { ...env, PASSWORD_STORE_DIR: store });
  assert.equal(result.trim(), "cli/example");
});
