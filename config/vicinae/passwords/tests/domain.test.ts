import assert from "node:assert/strict";
import { test } from "node:test";
import { parseFields, parseSchema } from "../src/domain/fields.ts";
import { decodeBase32, otpCode, totp } from "../src/domain/otp.ts";
import { RecentEntries } from "../src/services/recent.ts";
import { execute, CommandError } from "../src/services/command.ts";
import { CancelledError, PassError } from "../src/domain/errors.ts";

test("field parsing preserves password whitespace, first-colon values and freeform notes", () => {
  const fields = parseFields(" p:a:ss \r\nurl: https://example.invalid:8443/a:b\r\ncustom: value:with:colons\r\nfreeform note\r\notpauth://totp/fixture?secret=MY======\r\n");
  assert.equal(fields[0].value, " p:a:ss ");
  assert.equal(fields[1].value, "https://example.invalid:8443/a:b");
  assert.equal(fields[2].value, "value:with:colons");
  assert.equal(fields[3].type, "note");
  assert.equal(fields[4].type, "otp");
});
test("schema layout is explicit and malformed schemas fail safely", () => {
  const schema = parseSchema('[{"key":"Login","type":"field"},{"key":"Password","type":"password"}]');
  const fields = parseFields("fixture-user\nfixture-password", schema);
  assert.equal(fields[0].title, "Login"); assert.equal(fields[1].type, "password");
  for (const schema of ['{}', '[{"key":"x","type":"unknown"}]', '[null]', 'not JSON']) assert.throws(() => parseSchema(schema), PassError);
});
test("Base32 decoding and URI handling reject unsupported OTP forms", () => {
  assert.equal(decodeBase32("GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ").toString(), "12345678901234567890");
  assert.equal(otpCode("otpauth://totp/fixture?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&digits=8", 59).code, "94287082");
  for (const uri of ["otpauth://hotp/f?secret=MY", "otpauth://totp/f?secret=INVALID!", "otpauth://totp/f?secret=MY&algorithm=MD5", "otpauth://totp/f?secret=MY&digits=9"]) assert.throws(() => otpCode(uri), PassError);
});
const vectors = [
  [59, "94287082", "46119246", "90693936"],
  [1111111109, "07081804", "68084774", "25091201"],
  [1111111111, "14050471", "67062674", "99943326"],
  [1234567890, "89005924", "91819424", "93441116"],
  [2000000000, "69279037", "90698825", "38618901"],
  [20000000000, "65353130", "77737706", "47863826"],
] as const;
for (const [time, sha1, sha256, sha512] of vectors) test(`RFC 6238 vectors at ${time}`, () => {
  for (const [algorithm, length, expected] of [["sha1", 20, sha1], ["sha256", 32, sha256], ["sha512", 64, sha512]] as const) {
    const key = Buffer.from("1234567890".repeat(7).slice(0, length));
    assert.equal(totp(key, algorithm, 8, 30, time).code, expected);
  }
});
test("recent cache stores navigation metadata only and respects TTL/store/disable", async () => {
  const values = new Map<string, string>();
  const storage = { get: async (key: string) => values.get(key), set: async (key: string, value: string) => { values.set(key, value); } };
  const recent = new RecentEntries("fixture-store", storage, 120);
  await recent.record("fixture-entry", "line:0", "password", 1000);
  assert.equal((await recent.get(1001))?.name, "fixture-entry");
  assert.equal(await recent.get(121000), undefined);
  assert.equal(await recent.get(0), undefined);
  assert.equal(await new RecentEntries("other-store", storage).get(1001), undefined);
  const before = values.size;
  await new RecentEntries("disabled", storage, 0).record("entry", "line:0", "password");
  assert.equal(values.size, before);
  assert.deepEqual(Object.keys(JSON.parse([...values.values()][0])).sort(), ["fieldId", "name", "timestamp", "type"]);
});
test("cancellation terminates a running child and hides its output", async () => {
  const controller = new AbortController();
  const pending = execute(process.execPath, ["-e", "setInterval(()=>{},1000)"], process.env, undefined, { signal: controller.signal });
  setTimeout(() => controller.abort(), 30);
  await assert.rejects(pending, CancelledError);
});
test("timeouts and missing commands have distinct sanitized error codes", async () => {
  await assert.rejects(execute("/fixture-command-that-does-not-exist", [], process.env), (error: CommandError) => error.kind === "missing");
  await assert.rejects(execute(process.execPath, ["-e", "setInterval(()=>{},1000)"], process.env, undefined, { timeoutMs: 30 }), (error: CommandError) => error.kind === "timeout");
});

test("field-copy service sends OTP codes, not seeds, to clipboard or recent metadata", async () => {
  const { copyEntryField } = await import("../src/services/credentials.ts");
  const content = "otpauth://totp/fixture?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ";
  let copied = ""; let lifetime = 0; let navigation: unknown[] = [];
  const store = { read: async () => ({ name: "fixture", version: "v1", password: content, details: "", content }) };
  await copyEntryField(store, { copy: async (text: string, seconds?: number) => { copied = text; lifetime = seconds || 0; } }, { record: async (...args: unknown[]) => { navigation = args; } }, { name: "fixture", version: "v1" });
  assert.match(copied, /^\d{6}$/); assert.ok(lifetime >= 1 && lifetime <= 30);
  assert.deepEqual(navigation, ["fixture", "line:0", "otp"]);
  assert.equal(JSON.stringify(navigation).includes("secret="), false);
});

test("field-copy service preserves arbitrary values and honours cancellation before copying", async () => {
  const { copyEntryField } = await import("../src/services/credentials.ts");
  const content = "fixture-password\nurl: https://example.invalid:8443/a:b";
  let copied = "";
  const store = { read: async () => ({ name: "fixture", version: "v1", password: "fixture-password", details: content.split("\n")[1], content }) };
  const clipboard = { copy: async (text: string) => { copied = text; } };
  const recent = { record: async () => { } };
  await copyEntryField(store, clipboard, recent, { name: "fixture", version: "v1" }, "line:1");
  assert.equal(copied, "https://example.invalid:8443/a:b");
  copied = "";
  const controller = new AbortController(); controller.abort();
  await assert.rejects(copyEntryField(store, clipboard, recent, { name: "fixture", version: "v1" }, "password", undefined, controller.signal), CancelledError);
  assert.equal(copied, "");
});

test("copying and typing resolve the same username in a custom schema", async () => {
  const { copyEntryField } = await import("../src/services/credentials.ts");
  const { typeEntry } = await import("../src/services/auto-type.ts");
  const content = "alice@example.invalid\nfixture-password\nhttps://example.invalid";
  const schema = parseSchema('[{"key":" Login ","type":"field"},{"key":"Password","type":"password"},{"key":"Website","type":"field"}]');
  const entry = { name: "fixture", version: "v1" };
  const store = { read: async () => ({ ...entry, content, password: "alice@example.invalid", details: "fixture-password\nhttps://example.invalid" }) };
  const recent = { record: async () => { } };
  const copied: string[] = []; const typed: unknown[] = [];
  for (const id of ["username", "url"]) await copyEntryField(store, { copy: async text => { copied.push(text); } }, recent, entry, id, schema);
  await typeEntry(store, { prepare: async () => ({ send: async steps => { typed.push(steps); } }) }, recent, entry, "login", schema);
  assert.deepEqual(copied, ["alice@example.invalid", "https://example.invalid"]);
  assert.deepEqual(typed, [[{ text: copied[0] }, { key: "tab" }, { text: "fixture-password" }]]);
});
