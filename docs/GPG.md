# GPG、SSH 与密钥管理

## 密钥结构

公开标识记录在 [`config/identity.env`](../config/identity.env)：

- 主密钥：认证身份与签发子密钥；
- Signing 子密钥：Git commit/tag 签名；
- Authentication 子密钥：由 gpg-agent 提供给 SSH；
- Encryption 子密钥：加密数据。

私钥、撤销证书、keybox、trustdb 和导出备份均不得进入 Git。

## 仓库管理的内容

- `gpg.conf`：keyserver 和导入清理策略；
- `gpg-agent.conf`：SSH 支持、口令缓存时间与 macOS GUI pinentry；
- `sshcontrol`：允许用于 SSH 的 authentication keygrip；
- Zsh：设置 `GPG_TTY` 与 `SSH_AUTH_SOCK`。

macOS 使用 Homebrew 的 `pinentry-mac`。因此从没有可用 TTY 的 Git GUI、
编辑器或自动化进程请求签名时，gpg-agent 仍可通过本地图形弹窗请求口令。
`GPG_TTY` 仍用于终端和 SSH agent。

GnuPG 新版本把 `sshcontrol` 标记为逐步由 key 文件的 `Use-for-ssh`
属性取代；当前配置与已有密钥流程保持兼容，升级时应重新核对官方
`gpg-agent` 文档。

## 日常检查

```sh
gpg --list-secret-keys --keyid-format long --with-subkey-fingerprint
gpg --list-secret-keys --with-keygrip
ssh-add -L
printf 'signing test\n' | gpg --detach-sign --output /dev/null
```

`sec#` 或 `ssb#` 表示只有 secret-key stub，没有对应私钥材料。

重载 agent：

```sh
gpgconf --kill gpg-agent
gpg-connect-agent /bye
```

确认 GUI pinentry 安装和 agent 配置：

```sh
test -x "$(brew --prefix)/bin/pinentry-mac"
gpg-agent --gpgconf-test
```

修改配置后重启 agent。`pinentry-mac` 需要本地图形会话，不适用于 headless
主机。

## 迁移与备份

完整步骤见 [GPG-MIGRATION.md](GPG-MIGRATION.md)。必须加密导出、校验
SHA-256、在真实终端中导入，并在验证后删除临时文件。

## 资料

- [GnuPG manual](https://gnupg.org/documentation/manuals/gnupg/)
- [gpg-agent manual](https://www.gnupg.org/documentation/manuals/gnupg26/gpg-agent.1.html)
- [Homebrew pinentry-mac](https://formulae.brew.sh/formula/pinentry-mac.html)
- [GitHub authentication documentation](https://docs.github.com/authentication)
- [GitHub signed commits](https://docs.github.com/authentication/managing-commit-signature-verification/signing-commits)
- [个人原始笔记：Key Management With GnuPG](https://k4i.top/posts/key-management-with-gnupg/)
