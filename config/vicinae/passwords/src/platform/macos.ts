import { spawn } from "node:child_process";
import { join } from "node:path";
import { PassError } from "../domain/errors.ts";
import { execute } from "../services/command.ts";

export interface SecretClipboard { copy(text: string, maxSeconds?: number): Promise<void> }
export class MacClipboard implements SecretClipboard {
  private helper: string;
  private env: NodeJS.ProcessEnv;
  private seconds: string;
  constructor(assetsPath: string, env = process.env, seconds = env.PASSWORD_STORE_CLIP_TIME || "45") {
    this.helper = join(assetsPath, "clipboard.js"); this.env = env; this.seconds = seconds;
  }
  async copy(text: string, maxSeconds?: number) {
    if (!text) throw new PassError("This field is empty.");
    if (!/^[1-9][0-9]{0,4}$/.test(this.seconds)) throw new PassError("Invalid clipboard timeout.");
    const seconds = String(maxSeconds ? Math.min(Number(this.seconds), maxSeconds) : Number(this.seconds));
    const generation = (await execute("/usr/bin/osascript", ["-l", "JavaScript", this.helper, "copy"], this.env, text, { timeoutMs: 10_000 })).trim();
    if (!/^\d+$/.test(generation)) throw new PassError("Could not schedule clipboard clearing.");
    // Once clipboard writing begins it runs to completion, independent of view
    // cancellation. Never leave copied secrets without a clearing timer.
    await new Promise<void>((accept, reject) => {
      const timer = spawn("/usr/bin/osascript", ["-l", "JavaScript", this.helper, "clear", generation, seconds],
        { detached: true, stdio: "ignore", env: this.env });
      timer.once("spawn", () => { timer.unref(); accept(); });
      timer.once("error", async () => {
        try { await execute("/usr/bin/osascript", ["-l", "JavaScript", this.helper, "clear", generation, "1"], this.env); } catch { }
        reject(new PassError("Could not start the clipboard timer."));
      });
    });
  }
}
export function openStoreTerminal(root: string, env: NodeJS.ProcessEnv) {
  return execute("wezterm", ["start", "--cwd", root], env, undefined, { timeoutMs: 10_000 });
}
