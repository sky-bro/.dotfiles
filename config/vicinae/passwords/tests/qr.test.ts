import assert from "node:assert/strict";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import { join } from "node:path";
import { test } from "node:test";
import { MacTotpQrReader } from "../src/platform/qr.ts";
import { execute } from "../src/services/command.ts";
const assets = fileURLToPath(new URL("../assets/", import.meta.url));
const generator = fileURLToPath(new URL("./qr-fixture.js", import.meta.url));
for (const source of ["file", "clipboard"] as const) {
  test(`macOS Vision decodes a synthetic TOTP QR from ${source}`, { skip: process.platform !== "darwin" || process.env.PASS_TEST_QR !== "1" || (source === "clipboard" && process.env.PASS_TEST_QR_CLIPBOARD !== "1") }, async () => {
    const temp = await mkdtemp(join(tmpdir(), "pass-qr-test-"));
    try {
      const path = join(temp, "fixture.png");
      await execute("/usr/bin/osascript", ["-l", "JavaScript", generator, path, source], process.env);
      const reader = new MacTotpQrReader(assets);
      const result = await reader.read(source === "file" ? { source, path } : { source });
      assert.equal(result.length, 1);
      assert.deepEqual(result[0], { secret: "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ", issuer: "Fixture", account: "alice", algorithm: "SHA1", digits: "6", period: "30" });
      if (source === "file") await assert.rejects(reader.read({ source, path: join(temp, "missing.png") }), (error: Error) => /Could not read the QR image/.test(error.message) && !error.message.includes(temp));
    } finally { await rm(temp, { recursive: true, force: true }); }
  });
}
