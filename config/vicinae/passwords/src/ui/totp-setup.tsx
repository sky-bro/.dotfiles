import { Action, Form } from "@vicinae/api";
import { useState } from "react";
import { emptyTotp, parseTotpInput, totpUri } from "../domain/totp-config.ts";
import type { TotpConfiguration } from "../domain/totp-config.ts";
import type { QrSource } from "../platform/qr.ts";
import { useRuntime } from "./runtime.tsx";
import { useTask } from "./use-task.ts";
export function useTotpSetup(initiallyEnabled = false) {
  const { qr } = useRuntime(); const task = useTask();
  const [enabled, setEnabled] = useState(initiallyEnabled);
  const [config, setConfig] = useState(emptyTotp); const [advanced, setAdvanced] = useState(false);
  const [candidates, setCandidates] = useState<TotpConfiguration[]>([]); const [selected, setSelected] = useState("");
  const load = (value: TotpConfiguration) => { setConfig(value); setEnabled(true); setAdvanced(value.algorithm !== "SHA1" || value.digits !== "6" || value.period !== "30"); };
  const change = (key: keyof TotpConfiguration, value: string) => {
    if (key === "secret" && /^otpauth:/i.test(value.trim())) {
      try { load(parseTotpInput(value)); return; } catch { /* Submit reports a sanitized validation error. */ }
    }
    setConfig((current) => ({ ...current, [key]: value }));
  };
  const importQr = (source: QrSource) => task.run(async (signal) => {
    const values = await qr.read(source, signal);
    setCandidates(values.length > 1 ? values : []); setSelected("");
    if (values.length === 1) load(values[0]);
    else setEnabled(true);
  });
  return {
    enabled, setEnabled, config, load, change, advanced, setAdvanced, candidates, selected,
    choose: (value: string) => { setSelected(value); if (value) load(candidates[Number(value) - 1]); },
    importQr, task, uri: () => totpUri(config)
  };
}
export type TotpSetup = ReturnType<typeof useTotpSetup>;
export function TotpActions({ setup }: { setup: TotpSetup }) {
  return <Action title="Import TOTP QR from Clipboard" shortcut={{ modifiers: ["cmd", "shift"], key: "v" }} onAction={() => setup.importQr({ source: "clipboard" })} />;
}
export function TotpFields({ setup, standalone = false }: { setup: TotpSetup; standalone?: boolean }) {
  const { config, change } = setup;
  return <>
    <Form.Separator />
    {!standalone && <Form.Checkbox id="totp-enabled" title="Two-Factor Authentication" label="Save a TOTP authenticator with this password" value={setup.enabled} onChange={setup.setEnabled} storeValue={false} />}
    {standalone && <Form.Description title="Authenticator (TOTP)" text="Enter a setup key or otpauth link, choose a QR image, or use Import TOTP QR from Clipboard (⌘⇧V)." />}
    {setup.enabled && <>
      {!standalone && <Form.Description title="TOTP Setup" text="Enter a setup key or otpauth link, choose a QR image, or import a clipboard screenshot (⌘⇧V)." />}
      <Form.FilePicker id="totp-qr" title="Import QR Image" value={[]} onChange={(paths) => { if (paths[0]) void setup.importQr({ source: "file", path: paths[0] }); }} allowMultipleSelection={false} canChooseDirectories={false} canChooseFiles storeValue={false} />
      {setup.candidates.length > 1 && <Form.Dropdown id="totp-candidate" title="Choose QR Account" value={setup.selected} onChange={setup.choose} storeValue={false}>
        <Form.Dropdown.Item value="" title="Select an account…" />
        {setup.candidates.map((item, index) => <Form.Dropdown.Item key={index} value={String(index + 1)} title={`${index + 1}. ${item.issuer || "Authenticator"} — ${item.account || "Unnamed account"}`} />)}
      </Form.Dropdown>}
      <Form.PasswordField id="totp-secret" title="Setup Key / otpauth Link" value={config.secret} onChange={(value) => change("secret", value)} storeValue={false} placeholder="Base32 key, or paste otpauth://totp/…" />
      <Form.TextField id="totp-issuer" title="Service" value={config.issuer} onChange={(value) => change("issuer", value)} storeValue={false} placeholder="e.g. GitHub" />
      <Form.TextField id="totp-account" title="Account" value={config.account} onChange={(value) => change("account", value)} storeValue={false} placeholder="e.g. alice@example.com" />
      <Form.Checkbox id="totp-advanced" title="Advanced" label="Customize algorithm, digits and interval" value={setup.advanced} onChange={setup.setAdvanced} storeValue={false} />
      {setup.advanced && <>
        <Form.Dropdown id="totp-algorithm" title="Algorithm" value={config.algorithm} onChange={(value) => change("algorithm", value)} storeValue={false}>{["SHA1", "SHA256", "SHA512"].map((value) => <Form.Dropdown.Item key={value} title={value} value={value} />)}</Form.Dropdown>
        <Form.Dropdown id="totp-digits" title="Digits" value={config.digits} onChange={(value) => change("digits", value)} storeValue={false}>{["6", "8"].map((value) => <Form.Dropdown.Item key={value} title={value} value={value} />)}</Form.Dropdown>
        <Form.TextField id="totp-period" title="Interval (Seconds)" value={config.period} onChange={(value) => change("period", value)} storeValue={false} />
      </>}
    </>}
    {setup.task.error && <Form.Description title="QR Import" text={setup.task.error} />}
  </>;
}
