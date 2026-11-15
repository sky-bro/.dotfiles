import { dirname, join, relative } from "node:path";
import { lstat } from "node:fs/promises";
import { CommandError, execute } from "./command.ts";
import { SavedWithoutCommit } from "../domain/errors.ts";
import type { Entry } from "../domain/entry.ts";
export class GitStore {
  constructor(privateContext: { path: (name: string) => Promise<string>; root: () => Promise<string>; env: () => NodeJS.ProcessEnv }) { this.context = privateContext; }
  private context: { path: (name: string) => Promise<string>; root: () => Promise<string>; env: () => NodeJS.ProcessEnv };
  async commit(names: string[], message: string) {
    const repos = new Map<string, string[]>();
    for (const name of names) {
      const path = await this.context.path(name);
      let directory = dirname(path);
      let hasGit = false;
      while (true) {
        try { await lstat(join(directory, ".git")); hasGit = true; break; }
        catch (error) { if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw new SavedWithoutCommit("The encrypted change was saved, but Git repository discovery failed."); }
        const parent = dirname(directory); if (parent === directory) break; directory = parent;
      }
      if (hasGit) {
        try {
          const repo = (await execute("git", ["-C", dirname(path), "rev-parse", "--show-toplevel"], this.context.env(), undefined, { timeoutMs: 10_000 })).trim();
          repos.set(repo, [...(repos.get(repo) || []), relative(repo, path)]);
        } catch { throw new SavedWithoutCommit("The encrypted change was saved, but its Git repository could not be read."); }
      }
    }
    for (const [repo, paths] of repos) {
      try {
        await execute("git", ["-C", repo, "add", "--", ...paths], this.context.env());
        let sign = false;
        try { sign = (await execute("git", ["-C", repo, "config", "--bool", "pass.signcommits"], this.context.env())).trim() === "true"; } catch (error) { if (!(error instanceof CommandError && error.exitCode === 1)) throw error; }
        await execute("git", ["-C", repo, "commit", ...(sign ? ["-S"] : []), "--only", "-m", message, "--", ...paths], this.context.env());
      } catch { throw new SavedWithoutCommit("The encrypted change was saved, but the Git commit failed. Check Git status in the store terminal."); }
    }
  }

  async history(entry?: Entry) {
    const root = await this.context.root();
    const path = entry ? await this.context.path(entry.name) : undefined;
    return execute("git", ["-C", path ? dirname(path) : root, "log", "-20", "--date=short", "--format=%h %ad %s", ...(path ? ["--", path] : [])], this.context.env());
  }

}
