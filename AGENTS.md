# Dotfiles setup instructions for AI agents

This is a personal, cross-platform dotfiles repository. The current automated
profile targets macOS. Existing Linux desktop files are historical and must not
be linked wholesale on macOS.

## Required workflow

1. Read `README.org`, `setup.sh`, and `docs/README.md`. Follow any component
   guide linked from the index, including `docs/GPG-MIGRATION.md` for keys.
2. Run `./setup.sh --check` and report every replacement before applying.
3. Inspect `git status`; preserve unrelated user changes.
4. Ask before installing packages or moving conflicting home-directory files.
5. With approval, run `./setup.sh --install-packages --apply`.
6. Run the verification commands from the README and report exact failures.

## Security rules

- Never print, inspect, paste, commit, or transmit private-key contents.
- Never copy all of `~/.gnupg`; migrate keys with encrypted
  `gpg --export-secret-keys --export-options backup` and import them
  interactively.
- Do not track or deploy `sshcontrol`, and do not edit private-key files
  directly. Restore SSH key selection with `gpg-connect-agent KEYATTR` from the
  public keygrips in `config/identity.env`.
- Passphrases and SSH passwords must be entered by the user in a real terminal.
- Public fingerprints, keygrips, and SSH public keys are safe to compare.
- Verify transferred files with SHA-256 before importing.
- Remove temporary exports from both machines after successful verification.
- Do not change `authorized_keys`, publish keys, or upload keys without an
  explicit user request.
- Never add Homebrew mirrors. Clear inherited mirror variables and use the
  official Homebrew/GitHub sources.

## Idempotency

`setup.sh` is dry-run by default. `--apply` backs up conflicts under
`~/.local/state/dotfiles-backups/` and creates explicit symlinks. Do not replace
this with `stow .`; doing so would mix Linux-only and macOS configuration.

## Documentation rule

Configuration changes are incomplete until the relevant component entry and
guide under `docs/` are updated. Document personal intent, install/apply steps,
verification, troubleshooting, and official upstream links. Link upstream
material instead of copying it.

## VS Code language integration

When adding a programming language, also review its maintained VS Code
extension, language server, formatter, linter, debugger, test integration, and
language-scoped settings. Record tool ownership so VS Code does not duplicate
tools managed by mise or Homebrew. Update `config/vscode/extensions.txt`,
`config/vscode/settings.json`, and the component guide as applicable, then run a
real format/build/test smoke check.
