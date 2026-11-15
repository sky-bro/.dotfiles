import { PassError } from "../domain/errors.ts";
import type { Entry } from "../domain/entry.ts";
import { parseFields, selectField } from "../domain/fields.ts";
import type { SchemaItem } from "../domain/fields.ts";
import { validateInputSteps } from "../domain/auto-type.ts";
import type { InputStep, SecretTyper } from "../domain/auto-type.ts";
import { credentialValue } from "./credentials.ts";
import type { PasswordStore } from "./password-store.ts";
import type { RecentEntries } from "./recent.ts";
import { checkCancelled } from "./command.ts";
export async function typeEntry(store: Pick<PasswordStore, "read">, typer: SecretTyper, recent: Pick<RecentEntries, "record">,
  entry: Entry, mode: "password" | "username" | "login" | "field", schema?: SchemaItem[], signal?: AbortSignal, fieldId?: string) {
  // Capture the target and check permissions before GPG can take focus.
  const input = await typer.prepare(signal);
  const record = await store.read(entry, signal);
  const fields = parseFields(record.content, schema);
  const password = fields.find((field) => field.type === "password");
  const username = selectField(fields, "username")?.value;
  const field = selectField(fields, mode === "field" ? fieldId || "" : "password");
  let steps: InputStep[];
  if (mode === "login") {
    if (!password?.value || !username) throw new PassError("This entry needs both a password and username/user/login field for automatic login input.");
    steps = [{ text: username }, { key: "tab" }, { text: password.value }];
  } else if (mode === "username") {
    if (!username) throw new PassError("This entry does not contain a username/user/login field.");
    steps = [{ text: username }];
  } else {
    if (!field?.value) throw new PassError("This entry does not contain the requested field.");
    steps = [{ text: credentialValue(field).text }];
  }
  validateInputSteps(steps); checkCancelled(signal);
  await input.send(steps);
  // Navigation metadata is best effort after delivery; never report a failed
  // login input just because its optional recent-entry cache could not persist.
  try { await recent.record(entry.name, mode === "username" ? "username" : field?.id || "password", mode === "username" ? "field" : field?.type || "password"); } catch { }
}
