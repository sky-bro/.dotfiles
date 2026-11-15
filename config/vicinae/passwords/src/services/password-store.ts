import { createHash, randomUUID } from "node:crypto";
import { copyFile, link, lstat, mkdir, mkdtemp, readFile, readdir, realpath, rename, rm, unlink, writeFile } from "node:fs/promises";
import { homedir, tmpdir } from "node:os";
import { dirname, join, relative } from "node:path";
import { PassError, SavedWithoutCommit, BusyError, PartialOperationError } from "../domain/errors.ts";
import { splitRecord, validateName } from "../domain/entry.ts";
import type { Entry, RecordValue, DeletedEntry } from "../domain/entry.ts";
import { acquireStoreLock } from "./store-lock.ts";
import { checkCancelled } from "./command.ts";
import { execute } from "./command.ts";
import { GitStore } from "./git-store.ts";

export class PasswordStore {
  private busy = false;
  private readonly git = new GitStore({ path: (name) => this.path(name), root: () => this.root(), env: () => this.env() });
  readonly store: string;
  readonly pass: string;
  readonly baseEnv: NodeJS.ProcessEnv;
  constructor(store = process.env.PASSWORD_STORE_DIR || join(homedir(), ".password-store"),
    pass = "pass", baseEnv = process.env) {
    this.store = store; this.pass = pass; this.baseEnv = baseEnv;
  }

  env(store = this.store): NodeJS.ProcessEnv {
    const env = {
      ...this.baseEnv, PATH: `${this.baseEnv.PATH || "/usr/bin:/bin"}:/opt/homebrew/bin:/usr/local/bin`,
      PASSWORD_STORE_DIR: store, PASSWORD_STORE_ENABLE_EXTENSIONS: "false"
    };
    for (const name of ["GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_COMMON_DIR", "GIT_NAMESPACE", "GIT_OBJECT_DIRECTORY", "GIT_ALTERNATE_OBJECT_DIRECTORIES"]) delete (env as NodeJS.ProcessEnv)[name];
    return env;
  }

  async root() {
    try { return await realpath(this.store); }
    catch { throw new PassError("Password store not found. Restore your existing pass store first."); }
  }

  async path(name: string) {
    validateName(name);
    const root = await this.root();
    const parts = `${name}.gpg`.split("/");
    let current = root;
    for (const [i, part] of parts.entries()) {
      current = join(current, part);
      try {
        const stat = await lstat(current);
        if (stat.isSymbolicLink() || (i < parts.length - 1 ? !stat.isDirectory() : !stat.isFile())) {
          throw new PassError("Entry paths must use regular files and directories, without symbolic links.");
        }
      } catch (error) {
        if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
      }
    }
    return current;
  }

  async version(name: string): Promise<string | undefined> {
    try { return createHash("sha256").update(await readFile(await this.path(name))).digest("hex"); }
    catch (error) { if ((error as NodeJS.ErrnoException).code === "ENOENT") return; throw error; }
  }

  async assertVersion(name: string, expected?: string) {
    if (await this.version(name) !== expected) throw new PassError("This entry changed or already exists. Refresh before saving.");
  }

  async list(): Promise<Entry[]> {
    const root = await this.root();
    const entries: Entry[] = [];
    const visit = async (dir: string) => {
      for (const item of await readdir(dir, { withFileTypes: true })) {
        if ([".git", ".extensions"].includes(item.name)) continue;
        const path = join(dir, item.name);
        if (item.isDirectory()) await visit(path);
        else if (item.isFile() && item.name.endsWith(".gpg")) {
          const name = relative(root, path).slice(0, -4);
          try { validateName(name); } catch { continue; }
          // Only encrypted bytes are read while browsing.
          const version = await this.version(name);
          if (version) entries.push({ name, version });
        }
      }
    };
    await visit(root);
    return entries.sort((a, b) => a.name.localeCompare(b.name));
  }

  async read(entry: Entry, signal?: AbortSignal): Promise<RecordValue> {
    await this.assertVersion(entry.name, entry.version);
    const text = await execute(this.pass, ["show", "--", entry.name], this.env(), undefined, { signal });
    await this.assertVersion(entry.name, entry.version);
    return { ...entry, ...splitRecord(text), content: text };
  }

  private async exclusive<T>(operation: () => Promise<T>): Promise<T> {
    if (this.busy) throw new BusyError("Another password operation is still running.");
    this.busy = true;
    let release: (() => Promise<void>) | undefined;
    try {
      release = await acquireStoreLock(await this.root());
      return await operation();
    } finally { if (release) await release(); this.busy = false; }
  }

  // Encrypt in a private staging directory before touching an existing entry.
  // Only public recipient configuration and ciphertext are ever written there.
  private async encrypt(name: string, args: string[], input?: string, original?: Buffer, signal?: AbortSignal) {
    const destination = await this.path(name);
    const root = await this.root();
    let parent = dirname(destination);
    let recipients: string | undefined;
    const recipientVersions = new Map<string, string | undefined>();
    const configVersion = async (path: string) => {
      try {
        if (!(await lstat(path)).isFile()) throw new PassError("Recipient configuration must be a regular file.");
        return createHash("sha256").update(await readFile(path)).digest("hex");
      } catch (error) { if ((error as NodeJS.ErrnoException).code === "ENOENT") return undefined; throw error; }
    };
    while (parent.startsWith(root)) {
      const candidate = join(parent, ".gpg-id");
      recipientVersions.set(candidate, await configVersion(candidate));
      recipientVersions.set(`${candidate}.sig`, await configVersion(`${candidate}.sig`));
      try {
        if ((await lstat(candidate)).isSymbolicLink()) throw new PassError("Recipient configuration must not be a symbolic link.");
        recipients = candidate;
        break;
      } catch (error) { if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error; }
      if (parent === root) break;
      parent = dirname(parent);
    }
    if (!recipients && !this.baseEnv.PASSWORD_STORE_KEY) throw new PassError("No .gpg-id recipient configuration found.");
    const stage = await mkdtemp(join(tmpdir(), "vicinae-pass-"));
    try {
      if (recipients) {
        await copyFile(recipients, join(stage, ".gpg-id"));
        try {
          if ((await lstat(`${recipients}.sig`)).isSymbolicLink()) throw new PassError("Recipient signatures must not be symbolic links.");
          await copyFile(`${recipients}.sig`, join(stage, ".gpg-id.sig"));
        }
        catch (error) { if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error; }
      }
      if (original) {
        await mkdir(dirname(join(stage, `${name}.gpg`)), { recursive: true, mode: 0o700 });
        await writeFile(join(stage, `${name}.gpg`), original, { mode: 0o600 });
      }
      await execute(this.pass, args, this.env(stage), input, { signal });
      const encrypted = await readFile(join(stage, `${name}.gpg`));
      return {
        encrypted, checkRecipients: async () => {
          for (const [path, expected] of recipientVersions) {
            if (await configVersion(path) !== expected) throw new PassError("GPG recipient configuration changed during encryption. Refresh and retry.");
          }
        }
      };
    } finally { await rm(stage, { recursive: true, force: true }); }
  }

  private async install(name: string, encrypted: Buffer, expected?: string) {
    await this.assertVersion(name, expected);
    const path = await this.path(name);
    await mkdir(dirname(path), { recursive: true, mode: 0o700 });
    const temporary = join(dirname(path), `.vicinae-${randomUUID()}.tmp`);
    try {
      await writeFile(temporary, encrypted, { mode: 0o600, flag: "wx" });
      await this.assertVersion(name, expected);
      if (expected) await rename(temporary, path);
      else await link(temporary, path); // exclusive create, never overwrite
    } finally { await rm(temporary, { force: true }); }
  }

  private commit(names: string[], message: string) { return this.git.commit(names, message); }
  history(entry?: Entry) { return this.git.history(entry); }

  save(name: string, text: string, expected?: string, signal?: AbortSignal) {
    return this.exclusive(async () => {
      if (!text || text.includes("\0")) throw new PassError("Enter nonempty text without null characters.");
      await this.assertVersion(name, expected);
      const prepared = await this.encrypt(name, ["insert", "--multiline", "--force", "--", name], text, undefined, signal);
      checkCancelled(signal);
      await prepared.checkRecipients();
      await this.install(name, prepared.encrypted, expected);
      await this.commit([name], `${expected ? "Edit" : "Add"} password for ${name}.`);
    });
  }

  generate(name: string, length: number, symbols: boolean, expected?: string, signal?: AbortSignal) {
    return this.exclusive(async () => {
      if (!Number.isInteger(length) || length < 1 || length > 1024) throw new PassError("Password length must be between 1 and 1024.");
      await this.assertVersion(name, expected);
      const original = expected ? await readFile(await this.path(name)) : undefined;
      const args = ["generate", ...(symbols ? [] : ["--no-symbols"]), ...(expected ? ["--in-place"] : []), "--", name, String(length)];
      const prepared = await this.encrypt(name, args, undefined, original, signal);
      checkCancelled(signal);
      await prepared.checkRecipients();
      await this.install(name, prepared.encrypted, expected);
      await this.commit([name], `${expected ? "Replace" : "Add"} generated password for ${name}.`);
    });
  }

  transfer(entry: Entry, destination: string, move: boolean, signal?: AbortSignal) {
    return this.exclusive(async () => {
      await this.assertVersion(destination);
      const record = await this.read(entry, signal);
      const prepared = await this.encrypt(destination, ["insert", "--multiline", "--force", "--", destination], record.content, undefined, signal);
      checkCancelled(signal);
      await prepared.checkRecipients();
      await this.assertVersion(entry.name, entry.version);
      await this.install(destination, prepared.encrypted);
      if (move) {
        try {
          await this.assertVersion(entry.name, entry.version);
          await unlink(await this.path(entry.name));
        } catch {
          // Compensate only our exact ciphertext; never delete another writer's
          // subsequent replacement. A failed compensation is an explicit state.
          const installed = createHash("sha256").update(prepared.encrypted).digest("hex");
          try {
            await this.assertVersion(destination, installed);
            await unlink(await this.path(destination));
          } catch {
            throw new PartialOperationError("Move incomplete: the source was not removed and the destination copy could not be rolled back. Inspect both entries before retrying.");
          }
          throw new PassError("Move cancelled: the source could not be removed. The new destination was rolled back.");
        }
      }
      await this.commit(move ? [entry.name, destination] : [destination], `${move ? "Rename" : "Copy"} ${entry.name} to ${destination}.`);
    });
  }

  async remove(entry: Entry): Promise<DeletedEntry> {
    return this.exclusive(async () => {
      await this.assertVersion(entry.name, entry.version);
      const encrypted = await readFile(await this.path(entry.name));
      await unlink(await this.path(entry.name));
      // Return the encrypted undo record even if automatic Git signing fails.
      try { await this.commit([entry.name], `Remove ${entry.name} from store.`); }
      catch (error) { if (error instanceof SavedWithoutCommit) return { name: entry.name, encrypted, warning: error.message }; throw error; }
      return { name: entry.name, encrypted };
    });
  }

  restore(entry: DeletedEntry) {
    return this.exclusive(async () => {
      await this.install(entry.name, entry.encrypted);
      await this.commit([entry.name], `Restore ${entry.name}.`);
    });
  }

}
