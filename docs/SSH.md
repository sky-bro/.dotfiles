# SSH

## macOS server

macOS uses the built-in Remote Login service rather than a Homebrew SSH
daemon. The repository policy is stored in
[`config/sshd/010-dotfiles.conf`](../config/sshd/010-dotfiles.conf) and is
installed as the root-owned
`/etc/ssh/sshd_config.d/010-dotfiles.conf`.

Personal server policy:

- only the local `sky` account may log in;
- root login and empty passwords are disabled;
- both public-key and macOS account-password authentication are enabled;
- password authentication is an explicit convenience choice;
- login time and authentication attempts are limited;
- SSH agent forwarding, X11 forwarding, and tunnel devices are disabled;
- Remote Login full-disk access is not enabled;
- `authorized_keys` is not created or changed automatically.

The daemon may listen on every active network interface because launchd owns
the SSH listener. Do not forward TCP port 22 from an internet-facing router.
The macOS Application Firewall is a separate system-wide choice and is not
changed by this repository.

### Check, enable, and disable

The default action validates the candidate config with a temporary host key
and reports whether the system drop-in would be created or replaced:

```sh
config/sshd/manage.sh --check
```

Review every `replace` before applying. Application requires an administrator
password in a real terminal:

```sh
sudo config/sshd/manage.sh --apply
```

On recent macOS releases, `systemsetup` may require the terminal application
to have Full Disk Access. If macOS rejects the command, enable Remote Login
manually under **System Settings → General → Sharing → Remote Login**, choose
**Only these users**, and retain only `sky`. Do not enable “Allow full disk
access for remote users.”

Disable the service without removing the audited config:

```sh
sudo config/sshd/manage.sh --disable
```

### Server verification

Keep the local session open until remote login is proven to work. On the Mac:

```sh
sudo /usr/sbin/systemsetup -getremotelogin
sudo /usr/sbin/sshd -t
sudo /usr/sbin/sshd -T | grep -E \
  '^(allowusers|permitrootlogin|pubkeyauthentication|passwordauthentication|kbdinteractiveauthentication|maxauthtries) '
nc -G 3 -z localhost 22
```

From another device on the trusted network:

```sh
ssh sky@<mac-address>
```

The macOS ED25519 host-key fingerprint generated on 2026-07-25 is:

```text
SHA256:BV1+3ghF1spjSfVNSO/nmkhshIbe0fTAeWgMK9esWN8
```

Verify this value on the client before accepting the host key. The LAN address
is assigned by DHCP and should not be recorded as a permanent identity.

Enter the macOS account password only in that client's real terminal. Never
put the password in this repository, a command-line argument, or chat.

### Server troubleshooting

- `Turning Remote Login on or off requires Full Disk Access privileges`: use
  System Settings or grant Full Disk Access to the terminal temporarily.
- `Permission denied`: confirm the account name is exactly `sky` and use the
  macOS login password, not a GPG passphrase.
- Connection timeout: confirm Remote Login is on, TCP port 22 is reachable,
  and no router or firewall rule blocks the trusted network.
- A changed server policy is not active: run
  `sudo config/sshd/manage.sh --apply` again, then reconnect.

## Personal model

GPG Agent is the only SSH agent. Private SSH key material remains in GnuPG;
`~/.ssh/openwrt-gpg.pub` is a generated public-key selector, not a private key.

The managed OpenWrt alias uses:

- host: `192.168.31.2`;
- user: `root`;
- authentication key: the dedicated Ed25519 authentication subkey;
- `IdentitiesOnly yes` so OpenSSH does not try the GitHub RSA key first;
- public-key-only client authentication, with no password fallback.

OpenWrt currently limits Dropbear to the LAN interface. Server-side password
authentication is deliberately not managed by this repository, so PVE console
recovery remains possible before it is disabled separately.

## Install

Import the complete GPG identity first, following
[GPG-MIGRATION.md](GPG-MIGRATION.md), then apply the dotfiles:

```sh
cd ~/.dotfiles
./setup.sh --check
./setup.sh --apply
source ~/.zshrc
```

The setup script configures `Use-for-ssh`, exports the public key atomically,
and links `config/ssh/config` to `~/.ssh/config`.

The public key must already be authorized on OpenWrt. Initial installation is
an explicit interactive operation because it requires the current root
password:

```sh
ssh-copy-id -f -i ~/.ssh/openwrt-gpg.pub root@192.168.31.2
```

## Verify

```sh
ssh-add -L | ssh-keygen -lf -
ssh -G openwrt | grep -E \
  '^(hostname|user|identityfile|identitiesonly|passwordauthentication) '
ssh -o BatchMode=yes openwrt true
```

The expected OpenWrt user-key fingerprint is:

```text
SHA256:P5s52XSi+gIvo6FFSpz3qfcbLkF1PsXZDERiFmf2VxM
```

The OpenWrt Ed25519 host-key fingerprint observed on 2026-07-24 is:

```text
SHA256:chJjj81vahMawPFmtiuAu3l2vhe5JdJi2cP6JnUszg0
```

If the host key changes, verify it through the PVE console before modifying
`known_hosts`.

## Troubleshooting

- `Identity file ... not accessible`: rerun `./setup.sh --apply` after
  importing the OpenWrt authentication subkey.
- Too many authentication failures: confirm `IdentitiesOnly yes` and the
  generated public `IdentityFile`.
- No identities from `ssh-add -L`: compare `SSH_AUTH_SOCK` with
  `gpgconf --list-dirs agent-ssh-socket`, then reload the agent.
- `ssh-copy-id` searches for a nonexistent private-key file: add `-f`; the
  private key intentionally exists only inside GnuPG.

## References

- [Apple Remote Login](https://support.apple.com/guide/mac-help/mchlp1066/mac)
- [OpenSSH manual pages](https://www.openssh.com/manual.html)
- [GnuPG gpg-agent manual](https://www.gnupg.org/documentation/manuals/gnupg26/gpg-agent.1.html)
- [OpenWrt Dropbear configuration](https://openwrt.org/docs/guide-user/base-system/dropbear)
