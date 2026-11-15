import { createContext, useContext } from "react";
import type { ReactNode } from "react";
import { useNavigation } from "@vicinae/api";
import type { PasswordStore } from "../services/password-store.ts";
import type { SecretTyper } from "../domain/auto-type.ts";
import type { TotpQrReader } from "../platform/qr.ts";
import type { SecretClipboard } from "../platform/macos.ts";
import type { RecentEntries } from "../services/recent.ts";
import type { SchemaItem } from "../domain/fields.ts";
export type PasswordRepository = Pick<PasswordStore, "list" | "read" | "save" | "generate" | "transfer" | "remove" | "restore" | "history">;
export type PasswordRuntime = {
  store: PasswordRepository;
  clipboard: SecretClipboard;
  qr: TotpQrReader;
  typer: SecretTyper;
  recent: RecentEntries;
  settings: { defaultLength: string; includeSymbols: boolean; schema?: SchemaItem[]; defaultAction: "copy" | "fields" | "type" | "login" };
  openTerminal(): Promise<unknown>;
};
export const RuntimeContext = createContext<PasswordRuntime | undefined>(undefined);
export function useRuntime() {
  const runtime = useContext(RuntimeContext);
  if (!runtime) throw new Error("Password runtime is missing.");
  return runtime;
}

// Vicinae renders each pushed view as a separate React root. Context from the
// entrypoint does not cross that navigation boundary, so provide it on every
// pushed page rather than assuming ordinary parent/child React inheritance.
export function usePasswordNavigation() {
  const runtime = useRuntime();
  const { push, pop } = useNavigation();
  return {
    pop,
    push: (view: ReactNode) => push(<RuntimeContext.Provider value={runtime}>{view}</RuntimeContext.Provider>),
  };
}
