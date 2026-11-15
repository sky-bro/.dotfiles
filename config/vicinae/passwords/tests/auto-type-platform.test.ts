import assert from "node:assert/strict";
import { test } from "node:test";
import { MacSecretTyper } from "../src/platform/auto-type.ts";
import { AccessibilityRequiredError } from "../src/domain/errors.ts";
import { typeEntry } from "../src/services/auto-type.ts";
import type { execute } from "../src/services/command.ts";
const target = { windowId: "7", pid: 123, launched: 10 };
function platform(options: { permission?: boolean; missingWindow?: boolean; abortOnHide?: AbortController } = {}) {
  const trace: string[] = []; const payloads: unknown[] = [];
  const command: typeof execute = async (_binary, args, _env, input, commandOptions) => {
    assert.ok(args.every(arg => !arg.includes("synthetic-password")));
    const value = JSON.parse(input!); trace.push(value.operation); payloads.push(value);
    if (value.operation === "permissions") return JSON.stringify(options.permission === false ? { error: "permission" } : { ready: true });
    if (value.operation === "prepare") return JSON.stringify({ target });
    assert.equal(commandOptions?.signal, undefined); // View cancellation must not kill delivery.
    return JSON.stringify({ sent: true });
  };
  const typer = new MacSecretTyper("/fixture-assets", {}, async () => {
    trace.push("window"); if (options.missingWindow) throw Error("SDK could not getActiveWindow");
    return { id: "7", focus: async () => { trace.push("focus"); return true; } };
  }, async () => { trace.push("hide"); options.abortOnHide?.abort(); }, command);
  const store = { read: async () => { trace.push("decrypt"); return { name: "fixture", version: "v1", content: "synthetic-password\nusername: alice", password: "synthetic-password", details: "username: alice" }; } };
  const recent = { record: async () => { } };
  return { typer, store, recent, trace, payloads };
}
test("denied helper permission is reported before window lookup or decryption", async () => {
  const f = platform({ permission: false });
  await assert.rejects(typeEntry(f.store, f.typer, f.recent, { name: "fixture", version: "v1" }, "password"), error => error instanceof AccessibilityRequiredError && /enable Vicinae/.test(error.message));
  assert.deepEqual(f.trace, ["permissions"]);
});
test("granted permission with unavailable SDK window does not decrypt or guess a target", async () => {
  const f = platform({ missingWindow: true });
  await assert.rejects(typeEntry(f.store, f.typer, f.recent, { name: "fixture", version: "v1" }, "password"), error => error instanceof Error && /previous window/.test(error.message) && !error.message.includes("SDK"));
  assert.deepEqual(f.trace, ["permissions", "window"]);
});
test("permission and window checks precede GPG, then focus is restored before delivery", async () => {
  const abort = new AbortController(); const f = platform({ abortOnHide: abort });
  await typeEntry(f.store, f.typer, f.recent, { name: "fixture", version: "v1" }, "login", undefined, abort.signal);
  assert.deepEqual(f.trace, ["permissions", "window", "prepare", "decrypt", "hide", "focus", "type"]);
  assert.equal(abort.signal.aborted, true);
  assert.deepEqual(f.payloads.at(-1), { operation: "type", target, steps: [{ text: "alice" }, { key: "tab" }, { text: "synthetic-password" }] });
});
