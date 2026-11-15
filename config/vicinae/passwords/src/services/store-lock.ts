import { randomUUID } from "node:crypto";
import { lstat, open, readFile, unlink } from "node:fs/promises";
import { hostname } from "node:os";
import { join } from "node:path";
import { BusyError } from "../domain/errors.ts";

export async function acquireStoreLock(root: string): Promise<() => Promise<void>> {
  const path = join(root, ".vicinae-pass.lock");
  const owner = { pid: process.pid, host: hostname(), token: randomUUID() };
  let file;
  try { file = await open(path, "wx", 0o600); }
  catch (error) {
    if ((error as NodeJS.ErrnoException).code === "EEXIST") throw new BusyError("This store is locked by another Passwords operation. If it crashed, inspect .vicinae-pass.lock before retrying.");
    throw error;
  }
  try { await file.writeFile(JSON.stringify(owner)); }
  finally { await file.close(); }
  return async () => {
    try {
      if (!(await lstat(path)).isFile()) return;
      const current = JSON.parse(await readFile(path, "utf8")) as typeof owner;
      if (current.token === owner.token) await unlink(path);
    } catch { /* never remove a lock now owned by another writer */ }
  };
}
