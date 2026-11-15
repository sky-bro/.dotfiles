import { createHmac } from "node:crypto";
import { PassError } from "./errors.ts";
export function decodeBase32(value: string): Buffer {
  const input = value.toUpperCase().replace(/\s/g, "").replace(/=+$/, "");
  if (!input || !/^[A-Z2-7]+$/.test(input) || [1, 3, 6].includes(input.length % 8)) throw new PassError("Invalid Base32 OTP secret.");
  let bits = 0, accumulator = 0;
  const bytes: number[] = [];
  for (const char of input) {
    accumulator = (accumulator << 5) | "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".indexOf(char);
    bits += 5;
    if (bits >= 8) { bits -= 8; bytes.push((accumulator >>> bits) & 255); accumulator &= (1 << bits) - 1; }
  }
  if (accumulator) throw new PassError("Invalid Base32 OTP padding.");
  return Buffer.from(bytes);
}
export function totp(secret: Buffer, algorithm: "sha1" | "sha256" | "sha512", digits: number, period: number, time: number) {
  if (![6, 8].includes(digits) || !Number.isInteger(period) || period < 1 || period > 3600 || !Number.isFinite(time) || time < 0) throw new PassError("Invalid TOTP parameters.");
  const counter = Buffer.alloc(8);
  counter.writeBigUInt64BE(BigInt(Math.floor(time / period)));
  const digest = createHmac(algorithm, secret).update(counter).digest();
  const offset = digest[digest.length - 1] & 15;
  const binary = digest.readUInt32BE(offset) & 0x7fffffff;
  return { code: String(binary % 10 ** digits).padStart(digits, "0"), remaining: period - Math.floor(time) % period };
}
export function otpCode(uri: string, time = Date.now() / 1000) {
  try {
    const parsed = new URL(uri);
    if (parsed.protocol !== "otpauth:" || parsed.hostname !== "totp") throw new Error();
    const algorithm = (parsed.searchParams.get("algorithm") || "SHA1").toLowerCase();
    if (!["sha1", "sha256", "sha512"].includes(algorithm)) throw new Error();
    const secret = decodeBase32(parsed.searchParams.get("secret") || "");
    try { return totp(secret, algorithm as "sha1" | "sha256" | "sha512", Number(parsed.searchParams.get("digits") || 6), Number(parsed.searchParams.get("period") || 30), time); }
    finally { secret.fill(0); }
  } catch { throw new PassError("Invalid or unsupported TOTP URI. Use otpauth://totp with a Base32 secret, SHA1/SHA256/SHA512, and 6 or 8 digits."); }
}
