import { Action, ActionPanel, Alert, Icon, List, Toast, popToRoot, closeMainWindow, confirmAlert, open, openExtensionPreferences, showToast } from "@vicinae/api";
import type { Keyboard } from "@vicinae/api";
import { useCallback, useEffect, useRef, useState } from "react";
import type { DeletedEntry, Entry } from "../domain/entry.ts";
import { SavedWithoutCommit } from "../domain/errors.ts";
import { typeEntry } from "../services/auto-type.ts";
import { copyEntryField } from "../services/credentials.ts";
import type { RecentEntry } from "../services/recent.ts";
import { checkCancelled } from "../services/command.ts";
import { EntryEditor, GenerateForm, SearchForm, TransferForm } from "./forms.tsx";
import { FieldsView } from "./fields-view.tsx";
import { History } from "./history.tsx";
import { usePasswordNavigation, useRuntime } from "./runtime.tsx";
import { errorMessage, useTask } from "./use-task.ts";
export function PasswordApp() {
  const runtime = useRuntime(); const { store } = runtime; const { push } = usePasswordNavigation(); const task = useTask();
  const [entries, setEntries] = useState<Entry[]>([]); const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>(); const [folder, setFolder] = useState("");
  const [nameQuery, setNameQuery] = useState(""); const [matches, setMatches] = useState<Set<string>>();
  const [deleted, setDeleted] = useState<DeletedEntry>(); const [recent, setRecent] = useState<RecentEntry>();
  const generation = useRef(0);
  const refresh = useCallback(async () => {
    task.cancel(); const current = ++generation.current;
    setLoading(true); setError(undefined); setMatches(undefined);
    try {
      const [items, last] = await Promise.all([store.list(), runtime.recent.get()]);
      if (current !== generation.current) return;
      setEntries(items); setRecent(last);
      setFolder((value) => items.some((item) => item.name.startsWith(`${value}/`)) ? value : "");
    } catch (reason) { if (current === generation.current) setError(errorMessage(reason)); }
    finally { if (current === generation.current) setLoading(false); }
  }, [store, runtime, task.cancel]);
  useEffect(() => { void refresh(); return () => { generation.current++; }; }, [refresh]);
  const navigate = (view: React.ReactNode) => { task.cancel(); push(view); };
  const copy = (entry: Entry, id = "password") => task.run(async (signal) => {
    await copyEntryField(store, runtime.clipboard, runtime.recent, entry, id, runtime.settings.schema, signal);
    await showToast({ title: "Copied to Clipboard", style: Toast.Style.Success });
    await closeMainWindow({ clearRootSearch: true });
  });
  const type = (entry: Entry, mode: "password" | "username" | "login" = "password") => task.run(async (signal) => {
    await typeEntry(store, runtime.typer, runtime.recent, entry, mode, runtime.settings.schema, signal);
    try { await popToRoot({ clearSearchBar: true }); } catch { /* Input already completed. */ }
  });
  const remove = (entry: Entry) => task.run(async () => {
    if (!await confirmAlert({ title: "Delete Password Entry?", message: entry.name, primaryAction: { title: "Delete Entry", style: Alert.ActionStyle.Destructive } })) return;
    const undo = await store.remove(entry); setDeleted(undo); await refresh();
    if (undo.warning) throw new SavedWithoutCommit(undo.warning);
    await showToast({ title: "Entry Deleted", message: "Undo remains available until this command closes.", style: Toast.Style.Success });
  });
  const undoDelete = () => task.run(async () => {
    if (!deleted) return;
    await store.restore(deleted); setDeleted(undefined); await refresh();
    await showToast({ title: "Entry Restored", style: Toast.Style.Success });
  }, async () => { setDeleted(undefined); await refresh(); });
  const searchContents = (query: string) => task.run(async (signal) => {
    const found = new Set<string>(); setMatches(found); setNameQuery("");
    try {
      for (const entry of entries) {
        checkCancelled(signal);
        const record = await store.read(entry, signal);
        if (record.content.toLocaleLowerCase().includes(query.toLocaleLowerCase())) found.add(entry.name);
      }
      checkCancelled(signal); setMatches(new Set(found));
    } catch (reason) { setMatches(undefined); throw reason; }
  });
  function credentialActions(entry: Entry) {
    const actions: { id: string; title: string; icon: Icon; shortcut?: Keyboard.Shortcut; onAction: () => void | Promise<void> }[] = [
      { id: "copy", title: "Copy Password / OTP", icon: Icon.CopyClipboard, onAction: () => copy(entry) },
      { id: "type", title: "Type Password / OTP", icon: Icon.Keyboard, shortcut: { modifiers: ["cmd"], key: "return" }, onAction: () => type(entry) },
      { id: "login", title: "Type Username → Tab → Password", icon: Icon.Keyboard, shortcut: { modifiers: ["cmd", "shift"], key: "return" }, onAction: () => type(entry, "login") },
      { id: "fields", title: "Browse Fields", icon: Icon.AppWindowList, shortcut: { modifiers: ["cmd"], key: "o" }, onAction: () => navigate(<FieldsView entry={entry} />) },
    ];
    actions.sort((a, b) => Number(b.id === runtime.settings.defaultAction) - Number(a.id === runtime.settings.defaultAction));
    return actions.map(({ id, ...props }) => <Action key={id} {...props} />);
  }
  const globalActions = <>
    <Action title="New Password" icon={Icon.Plus} shortcut={{ modifiers: ["cmd"], key: "n" }} onAction={() => navigate(<EntryEditor onDone={refresh} />)} />
    <Action title="New Authenticator (TOTP)" icon={Icon.Plus} shortcut={{ modifiers: ["cmd", "shift"], key: "t" }} onAction={() => navigate(<EntryEditor authenticator onDone={refresh} />)} />
    <Action title="Generate New Password" icon={Icon.Key} shortcut={{ modifiers: ["cmd", "shift"], key: "n" }} onAction={() => navigate(<GenerateForm onDone={refresh} />)} />
    <Action title="Search Entry Contents" icon={Icon.MagnifyingGlass} shortcut={{ modifiers: ["cmd", "shift"], key: "f" }} onAction={() => navigate(<SearchForm onSearch={(query) => void searchContents(query)} />)} />
    <Action title="Refresh / Cancel Search" icon={Icon.ArrowClockwise} shortcut={{ modifiers: ["cmd"], key: "r" }} onAction={refresh} />
    {deleted && <Action title={`Undo Delete: ${deleted.name}`} icon={Icon.ArrowCounterClockwise} shortcut={{ modifiers: ["cmd"], key: "z" }} onAction={undoDelete} />}
    <Action title="Store Git History" icon={Icon.Clock} onAction={() => navigate(<History />)} />
    <Action title="Open Store in Terminal" icon={Icon.Terminal} onAction={() => task.run(async () => { await runtime.openTerminal(); })} />
    <Action title="Auto-Type Permissions" icon={Icon.Keyboard} onAction={() => open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")} />
    <Action title="Password Settings" icon={Icon.Cog} onAction={openExtensionPreferences} />
  </>;
  const folderSet = new Set<string>();
  for (const { name } of entries) { const parts = name.split("/"); for (let i = 1; i < parts.length; i++) folderSet.add(parts.slice(0, i).join("/")); }
  const visible = entries.filter((entry) => (!folder || entry.name.startsWith(`${folder}/`)) && (!matches || matches.has(entry.name)));
  const pinned = recent && visible.find((entry) => entry.name === recent.name);
  if (pinned) { visible.splice(visible.indexOf(pinned), 1); visible.unshift(pinned); }
  return <List isLoading={loading || task.busy} searchText={nameQuery} onSearchTextChange={setNameQuery} filtering
    searchBarPlaceholder="Search entry names…" actions={<ActionPanel>{globalActions}</ActionPanel>}
    searchBarAccessory={<List.Dropdown tooltip="Folder" value={folder} onChange={setFolder}>
      <List.Dropdown.Item title="All Folders" value="" />
      {[...folderSet].sort().map((value) => <List.Dropdown.Item key={value} title={value} value={value} />)}
    </List.Dropdown>}>
    <List.EmptyView title={error ? "Cannot Load Passwords" : "No Matching Entries"} description={error || task.error || "Use New Password or Generate New Password to create an entry."} icon={Icon.Key} />
    <List.Section title={matches ? "Content Search Results" : "pass"} subtitle={`${visible.length} entries`}>
      {visible.map((entry) => <List.Item key={`${entry.name}:${entry.version}`} id={entry.name} title={entry.name} icon={Icon.Key}
        accessories={pinned?.name === entry.name ? [{ text: "Recent" }] : []}
        actions={<ActionPanel><ActionPanel.Section title="Entry">
          {credentialActions(entry)}
          <Action title="Type Username" icon={Icon.Keyboard} onAction={() => type(entry, "username")} />
          <Action title="View / Edit Entry" icon={Icon.Pencil} shortcut={{ modifiers: ["cmd"], key: "e" }} onAction={() => navigate(<EntryEditor entry={entry} onDone={refresh} />)} />
          <Action title="Set Up / Edit TOTP" onAction={() => navigate(<EntryEditor entry={entry} setupTotp onDone={refresh} />)} />
          <Action title="Copy Username" onAction={() => copy(entry, "username")} />
          <Action title="Copy Website URL" onAction={() => copy(entry, "url")} />
          <Action title="Copy Full Entry" onAction={() => copy(entry, "all")} />
          <Action title="Replace with Generated Password" icon={Icon.Key} onAction={() => navigate(<GenerateForm entry={entry} onDone={refresh} />)} />
          <Action title="Rename / Move Entry" onAction={() => navigate(<TransferForm entry={entry} move onDone={refresh} />)} />
          <Action title="Duplicate Entry" onAction={() => navigate(<TransferForm entry={entry} move={false} onDone={refresh} />)} />
          <Action title="Entry Git History" icon={Icon.Clock} onAction={() => navigate(<History entry={entry} />)} />
          <Action title="Delete Entry" icon={Icon.Trash} style={Action.Style.Destructive} shortcut={{ modifiers: ["ctrl"], key: "x" }} onAction={() => remove(entry)} />
        </ActionPanel.Section><ActionPanel.Section title="Store">{globalActions}</ActionPanel.Section></ActionPanel>} />)}
    </List.Section>
  </List>;
}
