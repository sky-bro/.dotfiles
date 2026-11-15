import { PassError } from "./errors.ts";

export type Entry = { name: string; version: string };
export type RecordValue = Entry & { password: string; details: string; content: string };
export type DeletedEntry = { name: string; encrypted: Buffer; warning?: string };

export function validateName(name: string): string {
  if (!name || name.startsWith("/") || /[\\\x00-\x1f\x7f]/.test(name) ||
    name.split("/").some((part) => !part || [".", "..", ".git", ".extensions", ".gpg-id", ".gpg-id.sig"].includes(part))) {
    throw new PassError("Use a relative entry name, such as websites/example/account, without .gpg.");
  }
  return name;
}

export function splitRecord(text: string) {
  const newline = text.indexOf("\n");
  return newline < 0 ? { password: text, details: "" } : { password: text.slice(0, newline), details: text.slice(newline + 1) };
}
