import { join } from "node:path";
import { AccessibilityRequiredError, PassError } from "../domain/errors.ts";
import { validateInputSteps } from "../domain/auto-type.ts";
import type { SecretTyper, InputStep } from "../domain/auto-type.ts";
import { checkCancelled, execute } from "../services/command.ts";
type InputWindow = { id: string; focus(): Promise<boolean> };
type Target = { windowId: string; pid: number; launched: number };
export class MacSecretTyper implements SecretTyper {
  private helper: string;
  private env: NodeJS.ProcessEnv;
  private activeWindow: () => Promise<InputWindow>;
  private runCommand: typeof execute;
  private hide: () => Promise<void>;
  constructor(assetsPath: string, env: NodeJS.ProcessEnv, activeWindow: () => Promise<InputWindow>, hide: () => Promise<void>, runCommand = execute) {
    this.helper = join(assetsPath, "auto-type.js"); this.env = env; this.activeWindow = activeWindow; this.hide = hide; this.runCommand = runCommand;
  }
  private async request(value: unknown, signal?: AbortSignal) {
    let response;
    try { response = JSON.parse(await this.runCommand("/usr/bin/osascript", ["-l", "JavaScript", this.helper], this.env, JSON.stringify(value), { signal, timeoutMs: 60000 })); }
    catch (error) { checkCancelled(signal); throw new PassError((value as { operation?: string }).operation === "type" ? "Automatic input was interrupted. Some characters may already have been entered; check the fields before retrying." : "Automatic input failed. No clipboard fallback was used."); }
    if (response.error === "permission") throw new AccessibilityRequiredError("System Settings → Privacy & Security → Accessibility: enable Vicinae, then quit and reopen it. Use Auto-Type Permissions to open settings.");
    if (response.error) {
      const messages: Record<string, string> = {
        target: "The original input window is unavailable. Focus the login field, reopen Passwords, and retry.",
        focus: "The target window changed. Automatic input stopped; focus the login field and retry.",
        modifiers: "Release the shortcut keys before automatic input begins and retry.",
      };
      throw new PassError((messages[response.error] || "Automatic input failed.") + (response.partial ? " Some characters may already have been entered; check the fields before retrying." : ""));
    }
    return response;
  }
  async prepare(signal?: AbortSignal) {
    checkCancelled(signal);
    // WindowManagement itself needs Accessibility. Check the actual helper
    // first so a permission failure cannot be mistaken for a missing window.
    const permission = await this.request({ operation: "permissions" }, signal);
    if (permission.ready !== true) throw new PassError("Could not verify automatic input permission. Reopen Vicinae and retry.");
    checkCancelled(signal);
    let window: InputWindow;
    try { window = await this.activeWindow(); } catch { throw new PassError("Vicinae could not access the previous window. Verify Vicinae Accessibility permission, quit and reopen Vicinae, then focus a login field before opening Passwords."); }
    if (!window || !/^\d+$/.test(window.id)) throw new PassError("No login window was found. Focus a login field before opening Passwords.");
    const response = await this.request({ operation: "prepare", windowId: window.id }, signal);
    const target: Target = response.target;
    if (!target || target.windowId !== window.id || !Number.isInteger(target.pid) || target.pid <= 0 || !Number.isFinite(target.launched)) throw new PassError("The input window could not be verified. Focus a login field and reopen Passwords.");
    return {
      send: async (steps: InputStep[]) => {
        validateInputSteps(steps); checkCancelled(signal);
        // The UI hides with navigation suspended so the extension process survives
        // delivery. It returns to root after successful input and recent metadata.
        // Once hiding begins, delivery owns its bounded lifecycle; no abort signal.
        await this.hide();
        if (!await window.focus()) throw new PassError("Could not restore the original input window. Nothing was typed.");
        const result = await this.request({ operation: "type", target, steps });
        if (result.sent !== true) throw new PassError("Automatic input failed.");
      }
    };
  }
}
