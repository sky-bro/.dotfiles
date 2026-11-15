import { PassError } from "./errors.ts";
export type FieldType = "password" | "field" | "note" | "otp";
export type SecretField = { id: string; title: string; type: FieldType; value: string };
export type SchemaItem = { key: string; type: FieldType };
export function parseSchema(value?: string): SchemaItem[] | undefined {
  if (!value?.trim()) return;
  try {
    const parsed = JSON.parse(value);
    if (!Array.isArray(parsed) || parsed.some((item) => !item || typeof item.key !== "string" || !item.key.trim() || !["password", "field", "note", "otp"].includes(item.type))) throw new Error();
    return parsed;
  } catch { throw new PassError("Invalid field schema. Use an array of key/type objects in Password Settings."); }
}
export function parseFields(content: string, schema?: SchemaItem[]): SecretField[] {
  const lines = content.replace(/\r\n/g, "\n").split("\n");
  if (schema) return lines.flatMap((value, index) => {
    const item = schema[index];
    return item && value ? [{ id: `line:${index}`, title: item.key, type: item.type, value }] : [];
  });
  return lines.flatMap((raw, index): SecretField[] => {
    if (!raw) return [];
    const id = `line:${index}`;
    if (raw.trim().startsWith("otpauth://")) return [{ id, title: "OTP", type: "otp", value: raw.trim() }];
    if (index === 0) return [{ id, title: "Password", type: "password", value: raw }];
    const colon = raw.indexOf(":");
    if (colon > 0) {
      const title = raw.slice(0, colon).trim();
      const value = raw.slice(colon + 1).trimStart();
      return [{ id, title, type: value.startsWith("otpauth://") ? "otp" : "field", value }];
    }
    return [{ id, title: `Note ${index}`, type: "note", value: raw }];
  });
}

const aliases = { username: ["username", "user", "login"], url: ["url", "website", "uri"] };
// Shared by copying and typing, including custom line-based schemas.
export function selectField(fields: SecretField[], id: string): SecretField | undefined {
  if (id === "password") return fields.find(field => field.type === "password") || fields.find(field => field.type === "otp");
  if (id === "username" || id === "url") {
    return fields.find(field => field.type === "field" && aliases[id].includes(field.title.trim().toLowerCase()));
  }
  return fields.find(field => field.id === id);
}
