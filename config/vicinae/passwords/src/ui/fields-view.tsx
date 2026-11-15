import { Action, ActionPanel, Icon, List, Toast, popToRoot, closeMainWindow, showToast } from "@vicinae/api";
import { useEffect, useState } from "react";
import type { Entry } from "../domain/entry.ts";
import { parseFields } from "../domain/fields.ts";
import type { SecretField } from "../domain/fields.ts";
import { typeEntry } from "../services/auto-type.ts";
import { copyEntryField } from "../services/credentials.ts";
import { useRuntime } from "./runtime.tsx";
import { errorMessage, useTask } from "./use-task.ts";
export function FieldsView({ entry }: { entry: Entry }) {
  const runtime = useRuntime(); const task = useTask();
  const [fields, setFields] = useState<SecretField[]>([]); const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>(); const [revealed, setRevealed] = useState<string>();
  useEffect(() => {
    const controller = new AbortController();
    void (async () => {
      const record = await runtime.store.read(entry, controller.signal);
      const parsed = parseFields(record.content, runtime.settings.schema);
      const recent = await runtime.recent.get();
      if (recent?.name === entry.name && recent.type === "password") parsed.sort((a, b) => Number(b.type === "otp") - Number(a.type === "otp"));
      if (!controller.signal.aborted) setFields(parsed);
    })().catch((reason) => { if (!controller.signal.aborted) setError(errorMessage(reason)); })
      .finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [entry, runtime]);
  const copy = (field: SecretField) => task.run(async (signal) => {
    await copyEntryField(runtime.store, runtime.clipboard, runtime.recent, entry, field.id, runtime.settings.schema, signal);
    await showToast({ title: "Field Copied", style: Toast.Style.Success });
    await closeMainWindow({ clearRootSearch: true });
  });
  const type = (field: SecretField) => task.run(async (signal) => {
    await typeEntry(runtime.store, runtime.typer, runtime.recent, entry, "field", runtime.settings.schema, signal, field.id);
    try { await popToRoot({ clearSearchBar: true }); } catch { /* Input already completed. */ }
  });
  function display(field: SecretField) {
    if (revealed !== field.id) return field.type === "otp" ? "One-time code · generated when copied" : "Value hidden";
    if (field.type === "otp") return "OTP values are generated when copied";
    return field.value;
  }
  return <List navigationTitle={entry.name} isLoading={loading || task.busy} searchBarPlaceholder="Search field names…">
    <List.EmptyView title="No Fields Available" description={error || task.error || "This entry is empty."} />
    {fields.map((field) => <List.Item key={field.id} title={field.title} subtitle={display(field)} icon={field.type === "otp" ? Icon.Clock : Icon.Key}
      actions={<ActionPanel>
        <Action title={field.type === "otp" ? "Copy Current OTP" : "Copy Field"} icon={Icon.CopyClipboard} onAction={() => copy(field)} />
        <Action title={field.type === "otp" ? "Type Current OTP" : "Type Field"} icon={Icon.Keyboard} shortcut={{ modifiers: ["cmd"], key: "return" }} onAction={() => type(field)} />
        {field.type !== "otp" && <Action title={revealed === field.id ? "Hide Value" : "Show Value"} icon={Icon.Eye} onAction={() => setRevealed(revealed === field.id ? undefined : field.id)} />}
      </ActionPanel>} />)}
  </List>;
}
