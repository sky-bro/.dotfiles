import assert from "node:assert/strict";
import { test } from "node:test";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import vm from "node:vm";
import { validateInputSteps } from "../src/domain/auto-type.ts";
import type { InputStep } from "../src/domain/auto-type.ts";
import { typeEntry } from "../src/services/auto-type.ts";
import { execute } from "../src/services/command.ts";
const entry = { name: "fixture", version: "fixture-version" };
function fixture(content = "fixture-password\nusername: alice") {
  const trace: string[] = []; const sent: InputStep[][] = [];
  const newline = content.indexOf("\n");
  const store = { read: async () => { trace.push("decrypt"); return { ...entry, content, password: newline < 0 ? content : content.slice(0, newline), details: newline < 0 ? "" : content.slice(newline + 1) }; } };
  const typer = { prepare: async () => { trace.push("prepare"); return { send: async (steps: InputStep[]) => { trace.push("send"); sent.push(steps); } }; } };
  const recent = { record: async () => { trace.push("recent"); } };
  return { trace, sent, store, typer, recent };
}
test("automatic login captures target before decryption and sends username, Tab, password without Enter", async () => {
  const f = fixture(); await typeEntry(f.store, f.typer, f.recent, entry, "login");
  assert.deepEqual(f.trace, ["prepare", "decrypt", "send", "recent"]);
  assert.deepEqual(f.sent, [[{ text: "alice" }, { key: "tab" }, { text: "fixture-password" }]]);
});
test("single password and username input omit navigation keys", async () => {
  for (const [mode, text] of [["password", "fixture-password"], ["username", "alice"]] as const) {
    const f = fixture(); await typeEntry(f.store, f.typer, f.recent, entry, mode); assert.deepEqual(f.sent, [[{ text }]]);
  }
});
test("missing permission prevents any decryption", async () => {
  const f = fixture(); f.typer.prepare = async () => { throw new Error("permission"); };
  await assert.rejects(typeEntry(f.store, f.typer, f.recent, entry, "password")); assert.deepEqual(f.trace, []);
});
test("missing username or actual password rejects the whole login sequence", async () => {
  for (const text of ["fixture-password", "otpauth://totp/a?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ\nusername: alice"]) {
    const f = fixture(text); await assert.rejects(typeEntry(f.store, f.typer, f.recent, entry, "login")); assert.equal(f.sent.length, 0);
  }
});
test("schema-defined credentials and standard aliases work for login", async () => {
  const f = fixture("alice\nfixture-password");
  await typeEntry(f.store, f.typer, f.recent, entry, "login", [{ key: "Login", type: "field" }, { key: "Password", type: "password" }]);
  assert.deepEqual(f.sent, [[{ text: "alice" }, { key: "tab" }, { text: "fixture-password" }]]);
  const alias = fixture("fixture-password\nUser: bob"); await typeEntry(alias.store, alias.typer, alias.recent, entry, "username"); assert.deepEqual(alias.sent, [[{ text: "bob" }]]);
});
test("OTP input delivers a current code and never the setup URI", async () => {
  const f = fixture("otpauth://totp/a?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ");
  await typeEntry(f.store, f.typer, f.recent, entry, "password");
  assert.match((f.sent[0][0] as { text: string }).text, /^\d{6}$/);
});
test("control characters or multiline values cannot become navigation or submit keys", async () => {
  for (const text of ["a\nb", "a\tb", "a\rb", "a\x00b", "a\x1bb", "a\u0085b", "a\u2028b", "", "x".repeat(1025)]) assert.throws(() => validateInputSteps([{ text }]));
  const f = fixture("fixture-password\nusername: alice\tother");
  await assert.rejects(typeEntry(f.store, f.typer, f.recent, entry, "login")); assert.equal(f.sent.length, 0);
});
test("cancellation after decryption prevents input", async () => {
  const f = fixture(); const abort = new AbortController(); const read = f.store.read;
  f.store.read = async () => { const record = await read(); abort.abort(); return record; };
  await assert.rejects(typeEntry(f.store, f.typer, f.recent, entry, "password", undefined, abort.signal)); assert.equal(f.sent.length, 0);
});
test("recent-cache failures do not turn a completed input into a retryable error", async () => {
  const f = fixture(); f.recent.record = async () => { throw Error("cache"); };
  await typeEntry(f.store, f.typer, f.recent, entry, "password"); assert.equal(f.sent.length, 1);
});

const helper = await readFile(new URL("../assets/auto-type.js", import.meta.url), "utf8");
function nativeFixture(options: { permission?: boolean; switchAfterEvents?: number; launched?: number; bundle?: string; frontPid?: number } = {}) {
  const posted: { pid: number; code: number; down: boolean; text?: string }[] = [];
  let frontPid = options.frontPid || 123;
  const dollar = Object.assign((value: unknown) => value, {
    NSFileHandle: { fileHandleWithStandardInput: { readDataToEndOfFile: { length: 1 } } },
    NSString: { alloc: { initWithDataEncoding: () => request } }, NSUTF8StringEncoding: 4,
    AXIsProcessTrusted: () => options.permission !== false,
    CGWindowListCopyWindowInfo: () => [{ kCGWindowNumber: 7, kCGWindowOwnerPID: 123, kCGWindowLayer: 0 }],
    NSRunningApplication: { runningApplicationWithProcessIdentifier: () => ({ launchDate: { timeIntervalSince1970: options.launched || 10 }, bundleIdentifier: options.bundle || "org.fixture" }) },
    NSWorkspace: { sharedWorkspace: { get frontmostApplication() { return { processIdentifier: frontPid }; } } },
    CGEventSourceFlagsState: () => 0, CGEventSourceCreate: () => ({}),
    CGEventCreateKeyboardEvent: (_source: unknown, code: number, down: boolean) => ({ code, down }),
    CGEventSetFlags: () => { }, calloc: (length: number) => new Uint16Array(length), free: () => { },
    CGEventKeyboardSetUnicodeString: (event: { text?: string }, length: number, units: Uint16Array) => { event.text = String.fromCharCode(...units.slice(0, length)); },
    CGEventPostToPid: (pid: number, event: { code: number; down: boolean; text?: string }) => { posted.push({ pid, ...event }); if (posted.length === options.switchAfterEvents) frontPid = 999; },
    NSThread: { sleepForTimeInterval: () => { } },
  });
  let request = "";
  const context = vm.createContext({ $: dollar, ObjC: { import: () => { }, bindFunction: () => { }, unwrap: (v: unknown) => v, deepUnwrap: (v: unknown) => v, castRefToObject: (v: unknown) => v } });
  vm.runInContext(helper, context);
  return { posted, run: (value: unknown) => { request = JSON.stringify(value); return JSON.parse(vm.runInContext("run([])", context)); } };
}
const target = { windowId: "7", pid: 123, launched: 10 };
test("native permission preflight needs no window and sends no keys", () => {
  for (const permission of [true, false]) {
    const f = nativeFixture({ permission });
    assert.deepEqual(f.run({ operation: "permissions" }), permission ? { ready: true } : { error: "permission", partial: false });
    assert.equal(f.posted.length, 0);
  }
});
test("native helper posts only to the captured PID, preserves Unicode and only navigates with explicit Tab", () => {
  const f = nativeFixture(); const result = f.run({ operation: "type", target, steps: [{ text: "测试🔐" }, { key: "tab" }, { text: "fixture-password" }] });
  assert.equal(result.sent, true); assert.ok(f.posted.every(event => event.pid === 123));
  assert.equal(f.posted.filter(event => event.down && event.code === 0).map(event => event.text).join(""), "测试🔐fixture-password");
  assert.equal(f.posted.filter(event => event.down && event.code === 48).length, 1);
  assert.ok(f.posted.every(event => event.code !== 36 && event.code !== 76));
});
test("native helper stops before sending password when focus changes during input", () => {
  const f = nativeFixture({ switchAfterEvents: 2 });
  const result = f.run({ operation: "type", target, steps: [{ text: "alice" }, { key: "tab" }, { text: "fixture-password" }] });
  assert.equal(result.error, "focus"); assert.equal(result.partial, true); assert.equal(f.posted.length, 2);
});
test("native helper refuses wrong PID lifetime, wrong focus, missing permission and launcher/pinentry targets", () => {
  for (const options of [{ launched: 20 }, { frontPid: 999 }, { permission: false }, { bundle: "org.vicinae" }, { bundle: "org.pinentry" }]) {
    const f = nativeFixture(options); assert.ok(f.run({ operation: "type", target, steps: [{ text: "fixture" }] }).error); assert.equal(f.posted.length, 0);
  }
});
test("native helper validates every step before entering any credentials", () => {
  const f = nativeFixture(); assert.equal(f.run({ operation: "type", target, steps: [{ text: "alice" }, { key: "tab" }, { text: "bad\npassword" }] }).error, "input"); assert.equal(f.posted.length, 0);
});
test("real macOS input helper creates Unicode events without sending them", { skip: process.platform !== "darwin" || process.env.PASS_TEST_INPUT !== "1" }, async () => {
  const path = fileURLToPath(new URL("../assets/auto-type.js", import.meta.url));
  const result = JSON.parse(await execute("/usr/bin/osascript", ["-l", "JavaScript", path, "self-test"], process.env));
  assert.equal(result.unicodeRoundTrip, true); assert.equal(typeof result.trusted, "boolean");
});
