# Git 与 GitHub

## 身份链

```text
GPG primary identity
├── signing subkey ──> Git commit/tag signature ──> GitHub Verified
└── auth subkey ─────> gpg-agent SSH socket ─────> git@github.com
```

`setup.sh` 配置姓名和邮箱，并在检测到目标 secret key 后启用签名：

```sh
git config --global user.name '<name>'
git config --global user.email '<email>'
git config --global user.signingkey '<signing-subkey>!'
git config --global commit.gpgsign true
git config --global gpg.program "$(command -v gpg)"
```

末尾的 `!` 强制 Git 使用指定 signing subkey，避免 GPG 自动选择其他密钥。

## 验证

检查配置：

```sh
gh auth status
git config --global --get user.signingkey
git config --global --get commit.gpgsign
git config --global --get gpg.program
```

验证 GitHub SSH：

```sh
ssh -T git@github.com
```

看到 `You've successfully authenticated` 即成功。GitHub 不提供 shell，因此该
命令正常情况下也可能返回非零退出码。

创建一次可丢弃的签名提交进行端到端测试：

```sh
tmp="$(mktemp -d)"
git -C "$tmp" init
git -C "$tmp" commit --allow-empty -m 'test signed commit'
git -C "$tmp" log --show-signature -1
```

## 故障排查

- `No secret key`：检查 signing subkey 是否完整导入，是否显示 `ssb#`；
- `Inappropriate ioctl for device`：在真实 TTY 中执行并设置 `GPG_TTY`;
- `Permission denied (publickey)`：运行 `ssh-add -L`，确认 GPG Agent 暴露密钥；
- GitHub 账号不正确：比较 `ssh-add -L` 与 GitHub 账户登记的 SSH 公钥；
- 提交未显示 Verified：确认 GitHub 账户已登记对应 GPG 公钥和匹配邮箱。

## 资料

- [Git documentation](https://git-scm.com/doc)
- [GitHub authentication](https://docs.github.com/authentication)
- [Connecting to GitHub with SSH](https://docs.github.com/authentication/connecting-to-github-with-ssh)
- [Signing commits](https://docs.github.com/authentication/managing-commit-signature-verification/signing-commits)
