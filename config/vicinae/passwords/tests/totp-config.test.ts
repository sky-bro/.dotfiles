import assert from "node:assert/strict";
import { test } from "node:test";
import { attachTotp, parseTotpInput, qrTotpCandidates, separateTotp, totpUri } from "../src/domain/totp-config.ts";
const secret = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ";
const uri = `otpauth://totp/Example:alice%40example.com?secret=${secret}&issuer=Example&algorithm=SHA256&digits=8&period=60`;
test("setup key normalization and URI configuration round trip", () => {
  const raw = parseTotpInput("gezd gnbv gy3t qojq gezd gnbv gy3t qojq");
  assert.equal(raw.secret, secret); assert.equal(raw.period, "30");
  const config = parseTotpInput(uri);
  assert.deepEqual(config, { secret, issuer: "Example", account: "alice@example.com", algorithm: "SHA256", digits: "8", period: "60" });
  assert.deepEqual(parseTotpInput(totpUri(config)), config);
});
test("malformed or unsupported setup data yields errors without echoing input", () => {
  for (const input of ["invalid-secret-sensitive", "otpauth://hotp/a?secret=" + secret, uri + "&secret=OTHER", uri.replace("period=60", "period=-1"), uri.replace(secret, ""), "otpauth-migration://offline?data=sensitive"]) {
    assert.throws(() => parseTotpInput(input), (error: Error) => !error.message.includes(input) && /valid Base32/.test(error.message));
  }
});
test("managed TOTP line can be restored without changing unknown fields or order", () => {
  const details = `username: alice\notp: ${uri}  \nrecovery: keep:colons\nfreeform note\n`;
  const split = separateTotp(details);
  assert.equal(split.blocked, false); assert.ok(split.config);
  assert.equal(attachTotp(split.details, uri, split.config ? split.location : undefined), details);
  assert.equal(attachTotp("", uri), uri);
});
test("multiple or unsupported OTP lines stay untouched", () => {
  for (const details of [`${uri}\n${uri}`, "otp: otpauth://hotp/a?secret=" + secret]) {
    const split = separateTotp(details); assert.equal(split.details, details); assert.equal(split.blocked, true); assert.equal(split.config, undefined);
  }
});
test("QR import filters unrelated codes, rejects unsupported ones, and deduplicates", () => {
  assert.equal(qrTotpCandidates(["https://example.invalid", uri, uri]).length, 1);
  assert.equal(qrTotpCandidates([uri, uri.replace("alice%40", "bob%40")]).length, 2);
  for (const values of [[], ["https://example.invalid"], ["otpauth://hotp/a?secret=" + secret], {}, new Array(65).fill(uri)]) assert.throws(() => qrTotpCandidates(values));
});

test("TOTP-only records preserve leading/trailing blank lines exactly", () => {
  for (const details of [uri, `${uri}\n`, `\n${uri}`, `\n${uri}\n`, `otp: ${uri}  \n`]) {
    const split = separateTotp(details); assert.ok(split.config);
    assert.equal(attachTotp(split.details, split.uri, split.location), details);
  }
});
test("embedded documentation links are kept in notes rather than extracted", () => {
  const details = `Setup guide: paste this example ${uri}`;
  const split = separateTotp(details); assert.equal(split.details, details); assert.equal(split.config, undefined);
});
