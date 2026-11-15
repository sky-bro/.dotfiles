import { PasswordStore } from "./services/password-store.ts";
import { MacClipboard } from "./platform/macos.ts";
import { copyEntryField } from "./services/credentials.ts";
import { PassError } from "./domain/errors.ts";

async function main() {
  const args = process.argv.slice(2);
  const store = new PasswordStore();
  if (args.length === 1 && args[0] === "--list") {
    for (const entry of await store.list()) process.stdout.write(`${entry.name}\n`);
  } else if (args.length === 2 && args[0] === "--copy") {
    const entry = (await store.list()).find((item) => item.name === args[1]);
    if (!entry) throw new PassError("Entry not found.");
    await copyEntryField(store, new MacClipboard(__dirname, store.env()), { record: async () => { } }, entry);
    process.stdout.write("Password copied. The clipboard timer is active.\n");
  } else throw new PassError("Usage: passmenu [--list|--copy ENTRY]");
}
void main().catch((error) => {
  process.stderr.write(`${error instanceof PassError ? error.message : "Password operation failed."}\n`);
  process.exitCode = 1;
});
