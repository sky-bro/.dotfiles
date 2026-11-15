import { spawn } from "node:child_process";
import { CancelledError, PassError } from "../domain/errors.ts";

export type CommandOptions = { signal?: AbortSignal; timeoutMs?: number };
export class CommandError extends PassError {
  readonly kind: "missing" | "timeout" | "failed" | "overflow";
  readonly exitCode: number | null;
  constructor(kind: CommandError["kind"], exitCode: number | null = null) {
    const messages = {
      missing: "Required command was not found. Check executable paths.",
      timeout: "The command timed out. Check the local GPG prompt and retry.",
      failed: "The command failed. Check GPG, Git, and the store configuration.",
      overflow: "Command output exceeded the permitted size.",
    };
    super(messages[kind]); this.kind = kind; this.exitCode = exitCode;
  }
}
export function checkCancelled(signal?: AbortSignal) {
  if (signal?.aborted) throw new CancelledError("Operation cancelled.");
}
// No shell, raw stderr, argv, stdout, or child error object is attached to errors.
export function execute(binary: string, args: string[], env: NodeJS.ProcessEnv, input?: string, options: CommandOptions = {}): Promise<string> {
  checkCancelled(options.signal);
  return new Promise((accept, reject) => {
    const child = spawn(binary, args, { env, stdio: ["pipe", "pipe", "pipe"], detached: process.platform !== "win32" });
    const chunks: Buffer[] = [];
    let size = 0;
    let failure: Error | undefined;
    let force: ReturnType<typeof setTimeout> | undefined;
    function kill(signal: NodeJS.Signals) {
      if (!child.pid) return;
      try {
        if (process.platform === "win32") child.kill(signal);
        else process.kill(-child.pid, signal);
      } catch { /* child may already have exited */ }
    }
    function stop(error: Error) {
      failure ||= error;
      kill("SIGTERM");
      force ||= setTimeout(() => kill("SIGKILL"), 1000);
    }
    const abort = () => stop(new CancelledError("Operation cancelled."));
    const timer = setTimeout(() => stop(new CommandError("timeout")), options.timeoutMs ?? 300_000);
    const cleanup = () => { clearTimeout(timer); if (force) clearTimeout(force); options.signal?.removeEventListener("abort", abort); };
    options.signal?.addEventListener("abort", abort, { once: true });
    if (options.signal?.aborted) abort();
    child.stdout.on("data", (chunk: Buffer) => {
      size += chunk.length;
      if (size > 4 * 1024 * 1024) stop(new CommandError("overflow"));
      else chunks.push(chunk);
    });
    child.stderr.resume();
    child.stdin.on("error", () => { });
    child.on("error", (error: NodeJS.ErrnoException) => { cleanup(); reject(new CommandError(error.code === "ENOENT" ? "missing" : "failed")); });
    child.on("close", (code) => {
      cleanup();
      if (failure) reject(failure);
      else if (code !== 0) reject(new CommandError("failed", code));
      else accept(Buffer.concat(chunks).toString("utf8"));
    });
    child.stdin.end(input);
  });
}
