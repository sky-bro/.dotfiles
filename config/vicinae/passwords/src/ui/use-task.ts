import { useCallback, useEffect, useRef, useState } from "react";
import { Toast, showToast } from "@vicinae/api";
import { AccessibilityRequiredError, CancelledError, PartialOperationError, PassError, SavedWithoutCommit } from "../domain/errors.ts";
export const errorMessage = (error: unknown) => error instanceof PassError ? error.message : "Operation failed. Refresh and check the store in a terminal.";
export async function showFailure(error: unknown) {
  if (error instanceof CancelledError) return;
  await showToast({ title: error instanceof AccessibilityRequiredError ? "Enable Vicinae Accessibility" : error instanceof SavedWithoutCommit ? "Saved; Git Commit Failed" : error instanceof PartialOperationError ? "Operation Partly Completed" : "Operation Failed", message: errorMessage(error), style: Toast.Style.Failure });
}
export function useTask() {
  const controller = useRef<AbortController | undefined>(undefined);
  const mounted = useRef(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string>();
  const cancel = useCallback(() => controller.current?.abort(), []);
  useEffect(() => { mounted.current = true; return () => { mounted.current = false; cancel(); }; }, [cancel]);
  const run = useCallback(async (operation: (signal: AbortSignal) => Promise<void>, onSaved?: () => Promise<void>) => {
    if (controller.current) return;
    const current = new AbortController(); controller.current = current;
    if (mounted.current) { setBusy(true); setError(undefined); }
    try { await operation(current.signal); }
    catch (reason) {
      if (!(reason instanceof CancelledError)) {
        if (mounted.current) setError(errorMessage(reason));
        await showFailure(reason);
        if (mounted.current && reason instanceof SavedWithoutCommit) await onSaved?.();
      }
    } finally {
      if (controller.current === current) controller.current = undefined;
      if (mounted.current) setBusy(false);
    }
  }, []);
  return { busy, error, run, cancel };
}
