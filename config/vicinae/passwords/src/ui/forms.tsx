import { Action, ActionPanel, Alert, Form, Icon, Toast, confirmAlert, showToast } from "@vicinae/api";
import { useEffect, useRef, useState } from "react";
import { PassError } from "../domain/errors.ts";
import { validateName } from "../domain/entry.ts";
import type { Entry, RecordValue } from "../domain/entry.ts";
import { usePasswordNavigation, useRuntime } from "./runtime.tsx";
import type { TotpLocation } from "../domain/totp-config.ts";
import { attachTotp, parseTotpInput, separateTotp } from "../domain/totp-config.ts";
import { TotpActions, TotpFields, useTotpSetup } from "./totp-setup.tsx";
import { errorMessage, useTask } from "./use-task.ts";
type Done = { onDone: () => Promise<void> };
export function EntryEditor({ entry, onDone, authenticator = false, setupTotp = false }: Done & { entry?: Entry; authenticator?: boolean; setupTotp?: boolean }) {
  const { store } = useRuntime(); const { pop } = usePasswordNavigation(); const task = useTask();
  const otp = useTotpSetup(authenticator || setupTotp);
  const [standalone, setStandalone] = useState(authenticator); const [blocked, setBlocked] = useState(false);
  const [loading, setLoading] = useState(!!entry); const [ready, setReady] = useState(!entry);
  const [name, setName] = useState(entry?.name || ""); const [password, setPassword] = useState("");
  const [confirmation, setConfirmation] = useState(""); const [username, setUsername] = useState("");
  const [url, setUrl] = useState(""); const [details, setDetails] = useState("");
  const [revealed, setRevealed] = useState(false); const [loadError, setLoadError] = useState<string>();
  const original = useRef<RecordValue | undefined>(undefined);
  const managed = useRef<{ config: string; uri: string; location?: TotpLocation } | undefined>(undefined);
  useEffect(() => {
    const controller = new AbortController();
    if (entry) void store.read(entry, controller.signal).then((record) => {
      if (controller.signal.aborted) return;
      original.current = record; setPassword(record.password); setDetails(record.details);
      if (/^otpauth:/i.test(record.password)) {
        try {
          const config = parseTotpInput(record.password); otp.load(config); setStandalone(true);
          managed.current = { config: JSON.stringify(config), uri: record.password };
        } catch { setBlocked(true); }
      } else {
        const split = separateTotp(record.details); setBlocked(split.blocked);
        if (split.config) {
          otp.load(split.config); setDetails(split.details);
          managed.current = { config: JSON.stringify(split.config), uri: split.uri, location: split.location };
        }
      }
      setReady(true);
    }).catch((error) => { if (!controller.signal.aborted) setLoadError(errorMessage(error)); })
      .finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => { controller.abort(); original.current = undefined; managed.current = undefined; };
  }, [entry, store]);
  const done = async () => { await onDone(); pop(); };
  async function submit() {
    if (!ready || otp.task.busy) return;
    await task.run(async (signal) => {
      validateName(name);
      if (!standalone && !entry && (!password || password !== confirmation)) throw new PassError("Enter and confirm the same nonempty password.");
      if (/[\r\n]/.test(password) || /[\r\n]/.test(username) || /[\r\n]/.test(url)) throw new PassError("Password, username and URL must each occupy one line.");
      let extra = entry ? details : [username && `username: ${username}`, url && `url: ${url}`, details].filter(Boolean).join("\n");
      let first = password;
      if (!blocked && otp.enabled) {
        if (otp.candidates.length > 1 && !otp.selected) throw new PassError("Choose which QR account to import before saving.");
        const uri = managed.current?.config === JSON.stringify(otp.config) ? managed.current.uri : otp.uri();
        if (standalone) first = uri;
        else {
          if (/otpauth:\/\//i.test(extra)) throw new PassError("Another authenticator link is already present in Notes / Extra Fields. Keep it there or use the TOTP section, without duplicating it.");
          extra = attachTotp(extra, uri, managed.current?.location);
        }
      } else if (managed.current && !standalone && !await confirmAlert({ title: "Remove Stored Authenticator?", message: "This removes the saved TOTP setup key. It does not disable two-factor authentication on the website.", primaryAction: { title: "Remove Authenticator", style: Alert.ActionStyle.Destructive } })) return;
      if (entry && original.current?.password === first && original.current.details === extra) { pop(); return; }
      await store.save(name, `${first}\n${extra}`, entry?.version, signal);
      await showToast({ title: "Entry Saved", style: Toast.Style.Success }); await done();
    }, done);
  }
  const PasswordInput = revealed ? Form.TextField : Form.PasswordField;
  return <Form navigationTitle={entry ? `Edit ${entry.name}` : standalone ? "New Authenticator (TOTP)" : "New Password"} enableDrafts={false} isLoading={loading || task.busy || otp.task.busy}
    actions={<ActionPanel><Action.SubmitForm title="Save Entry" icon={Icon.Checkmark} onSubmit={submit} />
      {!blocked && <TotpActions setup={otp} />}
      {!standalone && <Action title={revealed ? "Hide Password" : "Show Password"} icon={Icon.Eye} onAction={() => setRevealed(!revealed)} />}</ActionPanel>}>
    {entry ? <Form.Description title="Entry" text={entry.name} /> : <Form.TextField id="name" title="Entry Name" value={name} onChange={setName} storeValue={false} placeholder={standalone ? "otp/example/account" : "websites/example/account"} autoFocus />}
    {(loadError || task.error) && <Form.Description title="Status" text={loadError || task.error || ""} />}
    {ready && <>
      {!standalone && <>
        <PasswordInput id="password" title="Password" value={password} onChange={setPassword} storeValue={false} />
        {!entry && <Form.PasswordField id="confirmation" title="Confirm Password" value={confirmation} onChange={setConfirmation} storeValue={false} />}
        {!entry && <Form.TextField id="username" title="Username" value={username} onChange={setUsername} storeValue={false} />}
        {!entry && <Form.TextField id="url" title="Website URL" value={url} onChange={setUrl} storeValue={false} />}
      </>}
      {!blocked && <TotpFields setup={otp} standalone={standalone} />}
      {blocked && <Form.Description title="Authenticator" text="Multiple or unsupported authenticator links are preserved in the original fields. Edit those lines carefully in Notes / Extra Fields or use pass in a terminal." />}
      <Form.Separator />
      <Form.TextArea id="details" title="Notes / Extra Fields" value={details} onChange={setDetails} storeValue={false} placeholder="Optional notes or custom fields (e.g. recovery-email: …)" />
    </>}
  </Form>;
}
export function GenerateForm({ entry, onDone }: Done & { entry?: Entry }) {
  const { store, settings } = useRuntime(); const { pop } = usePasswordNavigation(); const task = useTask();
  const [name, setName] = useState(entry?.name || ""); const [length, setLength] = useState(settings.defaultLength);
  const [symbols, setSymbols] = useState(settings.includeSymbols);
  const done = async () => { await onDone(); pop(); };
  const submit = () => task.run(async (signal) => {
    validateName(name);
    if (!/^\d+$/.test(length) || Number(length) < 1 || Number(length) > 1024) throw new PassError("Choose a length between 1 and 1024.");
    if (entry && !await confirmAlert({ title: "Replace Stored Password?", message: `Replace the first line of ${name}; all following fields are preserved. Update the website separately.`, primaryAction: { title: "Replace Password", style: Alert.ActionStyle.Destructive } })) return;
    await store.generate(name, Number(length), symbols, entry?.version, signal);
    await showToast({ title: "Password Generated and Saved", style: Toast.Style.Success }); await done();
  }, done);
  return <Form navigationTitle={entry ? "Replace Password" : "Generate Password"} enableDrafts={false} isLoading={task.busy}
    actions={<ActionPanel><Action.SubmitForm title="Generate and Save" icon={Icon.Key} onSubmit={submit} /></ActionPanel>}>
    {entry ? <Form.Description title="Entry" text={entry.name} /> : <Form.TextField id="name" title="Entry Name" value={name} onChange={setName} storeValue={false} autoFocus />}
    <Form.TextField id="length" title="Length" value={length} onChange={setLength} storeValue={false} />
    <Form.Checkbox id="symbols" title="Characters" label="Include symbols" value={symbols} onChange={setSymbols} storeValue={false} />
    {task.error && <Form.Description title="Status" text={task.error} />}
  </Form>;
}
export function TransferForm({ entry, move, onDone }: Done & { entry: Entry; move: boolean }) {
  const { store } = useRuntime(); const { pop } = usePasswordNavigation(); const task = useTask();
  const [destination, setDestination] = useState(move ? entry.name : `${entry.name}-copy`);
  const done = async () => { await onDone(); pop(); };
  const submit = () => task.run(async (signal) => {
    await store.transfer(entry, destination, move, signal);
    await showToast({ title: move ? "Entry Moved" : "Entry Duplicated", style: Toast.Style.Success }); await done();
  }, done);
  return <Form navigationTitle={move ? "Rename / Move Entry" : "Duplicate Entry"} enableDrafts={false} isLoading={task.busy}
    actions={<ActionPanel><Action.SubmitForm title={move ? "Move Entry" : "Duplicate Entry"} onSubmit={submit} /></ActionPanel>}>
    <Form.Description title="Source" text={entry.name} />
    <Form.TextField id="destination" title="Destination Name" value={destination} onChange={setDestination} storeValue={false} autoFocus />
    <Form.Description title="Recipients" text="Uses the destination folder's GPG recipients. Existing entries are never overwritten." />
    {task.error && <Form.Description title="Status" text={task.error} />}
  </Form>;
}
export function SearchForm({ onSearch }: { onSearch: (query: string) => void }) {
  const { pop } = usePasswordNavigation(); const [query, setQuery] = useState("");
  return <Form navigationTitle="Search Entry Contents" enableDrafts={false}
    actions={<ActionPanel><Action.SubmitForm title="Search Contents" onSubmit={() => { if (query.trim()) { pop(); onSearch(query); } }} /></ActionPanel>}>
    <Form.PasswordField id="query" title="Search Text" value={query} onChange={setQuery} storeValue={false} autoFocus />
    <Form.Description title="Search" text="Decrypts entries one at a time. Returns matching names only; no decrypted index is saved." />
  </Form>;
}
