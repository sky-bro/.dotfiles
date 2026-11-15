import { PassError } from "./errors.ts";
import { decodeBase32, otpCode } from "./otp.ts";
export type TotpConfiguration = { secret: string; issuer: string; account: string; algorithm: string; digits: string; period: string };
export const emptyTotp = (): TotpConfiguration => ({ secret: "", issuer: "", account: "", algorithm: "SHA1", digits: "6", period: "30" });
function normalizedSecret(value: string) {
  const bytes = decodeBase32(value); bytes.fill(0);
  return value.toUpperCase().replace(/\s/g, "").replace(/=+$/, "");
}
export function parseTotpInput(input: string): TotpConfiguration {
  try {
    if (input.length > 8192) throw new Error();
    const value = input.trim();
    if (!/^otpauth:/i.test(value)) {
      return { ...emptyTotp(), secret: normalizedSecret(value) };
    }
    const uri = new URL(value);
    if (uri.protocol !== "otpauth:" || uri.hostname !== "totp" || uri.hash || uri.username || uri.password) throw new Error();
    for (const key of ["secret", "issuer", "algorithm", "digits", "period"]) if (uri.searchParams.getAll(key).length > 1) throw new Error();
    otpCode(value, 0);
    const label = decodeURIComponent(uri.pathname.slice(1));
    const colon = label.indexOf(":");
    const issuer = uri.searchParams.get("issuer") || (colon >= 0 ? label.slice(0, colon) : "");
    return {
      secret: normalizedSecret(uri.searchParams.get("secret") || ""), issuer, account: colon >= 0 ? label.slice(colon + 1) : label,
      algorithm: (uri.searchParams.get("algorithm") || "SHA1").toUpperCase(), digits: String(Number(uri.searchParams.get("digits") || 6)), period: String(Number(uri.searchParams.get("period") || 30))
    };
  } catch { throw new PassError("Enter a valid Base32 setup key or an otpauth://totp link. HOTP and migration QR codes are not supported."); }
}
export function totpUri(config: TotpConfiguration): string {
  const parsed = parseTotpInput(config.secret);
  const value = /^otpauth:/i.test(config.secret.trim()) ? parsed : { ...config, secret: parsed.secret };
  if (/[\r\n:]/.test(value.issuer) || /[\r\n:]/.test(value.account)) throw new PassError("Service and account must each occupy one line without a colon.");
  const label = value.issuer ? `${encodeURIComponent(value.issuer)}:${encodeURIComponent(value.account)}` : encodeURIComponent(value.account);
  const params = new URLSearchParams({ secret: value.secret, algorithm: value.algorithm, digits: value.digits, period: value.period });
  if (value.issuer) params.set("issuer", value.issuer);
  const uri = `otpauth://totp/${label}?${params}`;
  otpCode(uri, 0); return uri;
}
export type TotpLocation = { index: number; prefix: string; suffix: string; emptyDetailsLine: boolean };
type SeparatedTotp = { details: string; blocked: boolean; config?: undefined } |
{ details: string; blocked: false; config: TotpConfiguration; uri: string; location: TotpLocation };
// Only manage a complete URI line or a named field whose whole value is a URI.
// Ambiguous/unsupported records stay raw; remaining blank lines are significant.
export function separateTotp(details: string): SeparatedTotp {
  const lines = details.split("\n");
  const matches = lines.flatMap((line, index) => {
    const match = line.match(/^(\s*|[^:]+:\s*)(otpauth:\/\/\S+)(\s*)$/i);
    return match ? [{ index, prefix: match[1], uri: match[2], suffix: match[3] }] : [];
  });
  if (matches.length !== 1) return { details, blocked: matches.length > 1 };
  const { index, prefix, uri, suffix } = matches[0];
  try {
    const config = parseTotpInput(uri);
    lines.splice(index, 1);
    return {
      details: lines.join("\n"), blocked: false, config, uri,
      location: { index, prefix, suffix, emptyDetailsLine: lines.length === 1 && lines[0] === "" }
    };
  } catch { return { details, blocked: true }; }
}
export function attachTotp(details: string, uri: string, location?: TotpLocation) {
  const lines = details || location?.emptyDetailsLine ? details.split("\n") : [];
  lines.splice(Math.min(location?.index ?? lines.length, lines.length), 0, `${location?.prefix || ""}${uri}${location?.suffix || ""}`);
  return lines.join("\n");
}
export function qrTotpCandidates(values: unknown): TotpConfiguration[] {
  if (!Array.isArray(values) || values.length > 64) throw new PassError("Could not read the QR image.");
  const found: TotpConfiguration[] = []; const seen = new Set<string>();
  for (const value of values) {
    if (typeof value !== "string" || !/^otpauth:\/\//i.test(value)) continue;
    try { const config = parseTotpInput(value); const key = totpUri(config); if (!seen.has(key)) { found.push(config); seen.add(key); } } catch { /* Ignore other barcode formats. */ }
  }
  if (!found.length) throw new PassError("No supported TOTP QR code found. Choose a clear setup QR image; HOTP and migration QR codes are not supported.");
  return found;
}
