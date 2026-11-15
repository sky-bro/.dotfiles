import { PopToRootType, WindowManagement, closeMainWindow, Action, ActionPanel, Detail, LocalStorage, environment, getPreferenceValues, openExtensionPreferences } from "@vicinae/api";
import { useMemo } from "react";
import { homedir } from "node:os";
import { join } from "node:path";
import { parseSchema } from "./domain/fields.ts";
import { PasswordStore } from "./services/password-store.ts";
import { RecentEntries } from "./services/recent.ts";
import { MacSecretTyper } from "./platform/auto-type.ts";
import { MacTotpQrReader } from "./platform/qr.ts";
import { MacClipboard, openStoreTerminal } from "./platform/macos.ts";
import { RuntimeContext } from "./ui/runtime.tsx";
import { PasswordApp } from "./ui/password-app.tsx";
export default function Passwords() {
  const runtime = useMemo(() => {
    const prefs = getPreferenceValues<{ storePath?: string; clipboardSeconds?: string; defaultLength?: string; includeSymbols?: boolean; fileSchema?: string; lastUsedSeconds?: string; defaultAction?: string }>();
    const preferred = prefs.storePath?.trim();
    const storePath = preferred?.startsWith("~/") ? join(homedir(), preferred.slice(2)) : preferred;
    const store = new PasswordStore(storePath || undefined);
    let schema;
    try { schema = parseSchema(prefs.fileSchema); } catch { return { error: "Invalid field schema. Correct it in Password Settings." }; }
    return {
      runtime: {
        store,
        typer: new MacSecretTyper(environment.assetsPath, store.env(), WindowManagement.getActiveWindow, () => closeMainWindow({ clearRootSearch: true, popToRootType: PopToRootType.Suspended })),
        qr: new MacTotpQrReader(environment.assetsPath, store.env()),
        clipboard: new MacClipboard(environment.assetsPath, store.env(), prefs.clipboardSeconds?.trim() || process.env.PASSWORD_STORE_CLIP_TIME || "45"),
        recent: new RecentEntries(store.store, { get: (key: string) => LocalStorage.getItem<string>(key), set: LocalStorage.setItem }, Number(prefs.lastUsedSeconds ?? 120)),
        settings: { defaultLength: prefs.defaultLength || "24", includeSymbols: prefs.includeSymbols !== false, schema, defaultAction: prefs.defaultAction === "fields" ? "fields" as const : prefs.defaultAction === "type" ? "type" as const : prefs.defaultAction === "login" ? "login" as const : "copy" as const },
        openTerminal: async () => openStoreTerminal(await store.root(), store.env()),
      }
    };
  }, []);
  if (runtime.error) return <Detail markdown={runtime.error} actions={<ActionPanel><Action title="Password Settings" onAction={openExtensionPreferences} /></ActionPanel>} />;
  return <RuntimeContext.Provider value={runtime.runtime}><PasswordApp /></RuntimeContext.Provider>;
}
