import { PassError } from "../domain/errors.ts";
import type { Entry } from "../domain/entry.ts";
import { parseFields, selectField } from "../domain/fields.ts";
import type { SecretField, SchemaItem } from "../domain/fields.ts";
import { otpCode } from "../domain/otp.ts";
import type { PasswordStore } from "./password-store.ts";
import type { SecretClipboard } from "../platform/macos.ts";
import type { RecentEntries } from "./recent.ts";
import { checkCancelled } from "./command.ts";
export async function copyEntryField(store: Pick<PasswordStore, "read">, clipboard: SecretClipboard, recent: Pick<RecentEntries, "record">,
  entry: Entry, id = "password", schema?: SchemaItem[], signal?: AbortSignal) {
  const record = await store.read(entry, signal);
  const fields = parseFields(record.content, schema);
  const field = selectField(fields, id);
  const value = id === "all" ? { text: record.content } : field ? credentialValue(field) : undefined;
  const text = value?.text;
  const lifetime = value?.lifetime;
  if (!text) throw new PassError("This entry does not contain the requested field.");
  checkCancelled(signal);
  await clipboard.copy(text, lifetime);
  await recent.record(entry.name, field?.id || id, field?.type || "field");
}

export function credentialValue(field: SecretField): { text: string; lifetime?: number } {
  if (field.type !== "otp") return { text: field.value };
  const { code, remaining } = otpCode(field.value);
  return { text: code, lifetime: remaining };
}
