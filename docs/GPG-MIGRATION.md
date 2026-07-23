# GPG identity migration

This repository stores only public identifiers and GnuPG configuration. It does
not contain private keys.

## Preconditions

- Install `gnupg` on both machines.
- Use a private network or another trusted transport.
- Keep both machines attended during the migration.

## Source machine

Confirm the intended key:

```sh
gpg --list-secret-keys --keyid-format long --with-subkey-fingerprint
```

Create a private temporary directory and export the complete key plus trust:

```sh
umask 077
mkdir -p ~/.gpg-transfer
gpg --export-secret-keys --export-options backup \
  --output ~/.gpg-transfer/private.gpg \
  F4CD0E4A366165D162E6B6CE7D36AE6055B060A6
gpg --export-ownertrust > ~/.gpg-transfer/ownertrust.gpg
sha256sum ~/.gpg-transfer/*
```

Enter the GPG passphrase only in the source machine's terminal.

## Destination Mac

Copy with `scp`, then compare the destination SHA-256 values with the source:

```sh
mkdir -m 700 ~/.gpg-transfer
scp source-host:~/.gpg-transfer/{private.gpg,ownertrust.gpg} ~/.gpg-transfer/
shasum -a 256 ~/.gpg-transfer/*
```

Import from a real interactive terminal so pinentry can request the passphrase:

```sh
gpg --import ~/.gpg-transfer/private.gpg
gpg --import-ownertrust ~/.gpg-transfer/ownertrust.gpg
gpg --list-secret-keys --keyid-format long --with-subkey-fingerprint
```

Every `sec`/`ssb` line must appear without `#`. A `#` means the corresponding
secret component was not imported.

Apply the managed configuration:

```sh
cd ~/.dotfiles
./setup.sh --check
./setup.sh --apply
source ~/.zshrc
```

## Verification

```sh
ssh-add -L
printf 'signing test\n' | gpg --detach-sign --output /dev/null
ssh -T git@github.com
```

GitHub success is the message `You've successfully authenticated`; GitHub
normally exits non-zero because it does not provide shell access.

After all checks pass, permanently remove `~/.gpg-transfer` on both machines.
