import { PassError } from "./errors.ts";
export type InputStep = { text: string } | { key: "tab" };
export interface PreparedInput { send(steps: InputStep[]): Promise<void> }
export interface SecretTyper { prepare(signal?: AbortSignal): Promise<PreparedInput> }
export function validateInputSteps(steps: InputStep[]) {
  if (!steps.length || steps.length > 3) throw new PassError("Invalid automatic input sequence.");
  for (const step of steps) {
    if ("text" in step) {
      if (!step.text || step.text.length > 1024 || /[\x00-\x1f\x7f-\x9f\u2028\u2029]/.test(step.text)) throw new PassError("Automatic input requires nonempty, single-line fields of at most 1024 characters, without control characters. Use Copy Field for multiline content.");
    } else if (step.key !== "tab") throw new PassError("Invalid automatic input sequence.");
  }
}
