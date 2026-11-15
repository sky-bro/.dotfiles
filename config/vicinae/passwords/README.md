# Passwords extension

This is the repository's own pass manager, informed by the community Vicinae
Pass and Raycast Pass extensions. It retains full entry management and uses
pass/GPG for encryption. No upstream extension is installed or vendored.

## Boundaries

| Module | Responsibility |
| --- | --- |
| `src/passwords.tsx` | Compose Vicinae preferences, storage and platform adapters per command instance |
| `src/ui/` | Entry/field lists, forms, navigation, safe toasts and cancellable tasks |
| `src/domain/` | Record types, path validation, field/schema parsing, RFC 6238 TOTP, setup/URI conversion, lossless managed-line updates and safe errors |
| `src/services/command.ts` | Shell-free subprocess I/O, bounded output, typed failures, cancellation of process groups |
| `src/services/password-store.ts` | Encrypted staging, recipient revisions, entry versions and mutations |
| `src/services/store-lock.ts` | Coordinate writes by cooperating extension instances |
| `src/services/git-store.ts` | Discover repositories, commit affected paths and read history |
| `src/services/credentials.ts` | Resolve the selected field, generate current OTP and copy through an injected clipboard |
| `src/services/recent.ts` | Short-lived navigation metadata, with injected key/value storage |
| `src/ui/totp-setup.tsx` | Shared manual/link/QR setup UI for standalone and attached TOTP |
| `src/services/auto-type.ts` | Capture target before decryption, reuse common credential selection and validate the entire input sequence |
| `src/platform/auto-type.ts` | Restore the captured window and send secrets to the bundled Quartz JXA helper over stdin |
| `src/platform/qr.ts` | Injectable local-only QR reader using the bundled Apple Vision JXA helper |
| `src/platform/macos.ts` | Confidential pasteboard and terminal adapters |
| `src/cli.ts` | Shared headless store/credential service for CLI options |
| `assets/` | Bundled clipboard/QR/automatic input helpers and generated CLI; GUI does not depend on a dotfiles symlink |

Core/domain services do not import the Vicinae API. UI dependencies are provided
through `RuntimeContext`. Vicinae mounts pushed pages in separate React roots,
so every page transition must use `usePasswordNavigation`, which reinstates the
runtime provider on the pushed element. Tests use real isolated pass/GPG stores and fake
clipboard/navigation storage where appropriate. New field types belong in the domain parser and shared `credentialValue` resolver,
which both copying and typing use. Schema aliases therefore behave identically
without adding filesystem logic to React views.

## Development

After approving and installing project dependencies with `npm ci`:

```sh
npm run format
npm run format:check
npm run typecheck
npm test
npm run build
```

Navigation regression tests use the real API components with independent React
roots and fake credential services. React and react-test-renderer are pinned to
the SDK's React version as development dependencies; the renderer is not bundled
into the production extension.

Tests create disposable GPG identities in a temporary directory. They never use
or inspect the user's private-key contents. `PASS_TEST_CLIPBOARD=1 npm test`
additionally overwrites the current clipboard with synthetic test text.

`build` bundles the shared CLI with project-owned esbuild, then uses `vici build`
to install the extension. TypeScript owns formatting and typechecking. The shell
`passmenu` entrypoint only dispatches to the native command or installed CLI.

Optional native QR tests use a public RFC fixture and Apple Vision, with no new
packages or language toolchain. Run `PASS_TEST_QR=1 node --experimental-strip-types --test tests/qr.test.ts`;
add `PASS_TEST_QR_CLIPBOARD=1` to also overwrite the clipboard with a synthetic QR.
Run this separately from other clipboard tests. QR sources are explicit user-selected
images or clipboard screenshots; decoded seeds only travel through subprocess pipes.
Standalone authenticators use a first-line URI; attached ones use a subsequent line.
Unknown/multiple authenticator layouts remain raw rather than being rewritten.

Automatic input uses an injected `SecretTyper` and prepared delivery session.
Permission preflight runs before even calling WindowManagement.getActiveWindow,
which itself requires Accessibility. Denial raises a dedicated actionable error
instead of being mistaken for an unavailable target. Both checks precede GPG
decryption. The launcher hides with navigation suspended to keep the extension alive
during delivery, then returns to root. Delivery owns its bounded lifecycle;
non-cancellation failures still notify even when React unmounts.
Quartz events target a fixed PID; PID launch time, window identity and frontmost
application are checked while typing. No clipboard, Apple Events or plaintext files
are involved. Strings cannot contain control characters; only an explicit Tab step
can navigate. No Enter is generated. Tabbed/multi-step web forms remain a user
responsibility: this is focused-field input, not browser DOM autofill.

`PASS_TEST_INPUT=1 node --experimental-strip-types --test tests/auto-type.test.ts`
also verifies native Unicode event construction without posting events. Actual
window delivery requires an Accessibility-authorized local GUI session. The JXA
bridge owns Core Foundation event references; do not manually CFRelease them.
Only the explicitly allocated UTF-16 buffers use calloc/free.

User workflows, setup, concurrency limitations and troubleshooting live in
[docs/PASSWORDS.md](../../../docs/PASSWORDS.md).

## Upstream design references

- [Vicinae community Pass](https://github.com/vicinaehq/extensions/tree/181904331f5289b53ee3443f98cfa5441d399f35/extensions/pass),
  manifest author `tinkerbells`, MIT: service/UI separation, two-level field
  browsing, schema-driven fields, last-used navigation and OTP follow-up.
- [Raycast Pass by capipo](https://www.raycast.com/capipo/pass): configurable
  default action, individual field selection and preserving values containing
  additional colons.
- [RFC 6238](https://www.rfc-editor.org/rfc/rfc6238): TOTP semantics and Appendix B
  test vectors. HMAC comes from Node's standard crypto implementation; OTP seeds
  never become subprocess arguments.

- [Apple Vision](https://developer.apple.com/documentation/vision/vndetectbarcodesrequest):
  on-device QR decoding, without camera/screen capture or remote services.
- [Key URI Format](https://github.com/google/google-authenticator/wiki/Key-Uri-Format):
  setup URI labels and TOTP parameters.

These are design references, not a claim of upstream authorship of this
implementation. No upstream source file is copied. Any future source import
must retain its original license and attribution.

- [Apple Quartz keyboard events](https://developer.apple.com/documentation/coregraphics/cgevent/keyboardsetunicodestring(stringlength:unicodestring:)) and [PID-directed delivery](https://developer.apple.com/documentation/coregraphics/cgevent/posttopid(_:)): automatic input primitives.
