import { join } from "node:path";
import { CancelledError, PassError } from "../domain/errors.ts";
import { qrTotpCandidates } from "../domain/totp-config.ts";
import type { TotpConfiguration } from "../domain/totp-config.ts";
import { execute } from "../services/command.ts";
export type QrSource = { source: "clipboard" } | { source: "file"; path: string };
export interface TotpQrReader { read(source: QrSource, signal?: AbortSignal): Promise<TotpConfiguration[]> }
export class MacTotpQrReader implements TotpQrReader {
  private assetsPath: string;
  private env: NodeJS.ProcessEnv;
  constructor(assetsPath: string, env = process.env) { this.assetsPath = assetsPath; this.env = env; }
  async read(source: QrSource, signal?: AbortSignal) {
    let output;
    try { output = await execute("/usr/bin/osascript", ["-l", "JavaScript", join(this.assetsPath, "qr-reader.js")], this.env, JSON.stringify(source), { signal, timeoutMs: 20000 }); }
    catch (error) { if (error instanceof CancelledError) throw error; throw new PassError("Could not read the QR image. Use a local PNG/JPEG/TIFF image or copy a screenshot to the clipboard (up to 20 MB / 40 megapixels)."); }
    let decoded: unknown;
    try { decoded = JSON.parse(output); } catch { throw new PassError("Could not read the QR image."); }
    return qrTotpCandidates(decoded);
  }
}
