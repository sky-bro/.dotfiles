# macOS Setup

## 设计目标

- 默认只检查，不直接覆盖文件；
- 明确列出受管理文件，避免把 Linux/i3 配置链接到 macOS；
- 替换前备份到 `~/.local/state/dotfiles-backups/`；
- 重复执行不会产生额外修改；
- 软件包、shell 插件和配置由一个入口部署；
- 私钥迁移保持独立、交互、可审计。

## 标准流程

```sh
git clone git@github.com:sky-bro/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh --check
./setup.sh --install-packages --apply
source ~/.zshrc
```

`--install-packages` 会安装 `Brewfile` 中的工具，以及缺失的 Oh My Zsh、
Powerlevel10k 和 zsh-autosuggestions。网络下载和 Home 目录变更应由用户明确
批准。

Powerlevel10k 图标字体由 Brewfile 安装。安装后在终端应用中选择
`MesloLGS Nerd Font Mono`，再运行 `p10k configure` 调整提示符。

GnuPG 使用 Brewfile 安装的 `pinentry-mac` 显示本地口令弹窗，即使发起签名
的 GUI 程序没有 TTY 也能请求解锁私钥。详见 [GPG 与 SSH](GPG.md)。

WezTerm 也由 Brewfile 管理。setup 将
[`profiles/macos/wezterm.lua`](../profiles/macos/wezterm.lua) 链接为
`~/.wezterm.lua`；主题、字体与验证方式见 [WezTerm 手册](WEZTERM.md)。

CopyQ 也由 Brewfile 安装，`--apply` 会在应用可正常启动时写入可移植配置。
辅助功能授权以及未签名应用的本地修复不会自动执行，详见
[CopyQ 手册](COPYQ.md)。

## Homebrew

本仓库只使用官方 Homebrew 与 GitHub 源。setup 在运行 `brew bundle` 时显式
清除以下继承变量：

```text
HOMEBREW_API_DOMAIN
HOMEBREW_BOTTLE_DOMAIN
HOMEBREW_BREW_GIT_REMOTE
HOMEBREW_CORE_GIT_REMOTE
```

检查当前来源：

```sh
brew config | grep -E '^(ORIGIN|HOMEBREW_)'
git -C "$(brew --repository)" remote -v
```

资料：

- [Homebrew documentation](https://docs.brew.sh/)
- [Homebrew Bundle and Brewfile](https://docs.brew.sh/Brew-Bundle-and-Brewfile)
- [`brew` manual](https://docs.brew.sh/Manpage)

## 验证

```sh
./setup.sh --check
tmux -V
wezterm --version
wezterm --config-file ~/.wezterm.lua show-keys >/dev/null
gpg --version
test -x "$(brew --prefix)/bin/pinentry-mac"
mise --version
fzf --version
/Applications/CopyQ.app/Contents/MacOS/CopyQ --version
git config --global --get user.signingkey
```

`./setup.sh --check` 在完成部署后应全部显示 `ok`。

## 回退

setup 不删除冲突文件。查看最近备份：

```sh
ls -lt ~/.local/state/dotfiles-backups
```

若要回退，先移除对应符号链接，再把备份文件移动回原位置。不要对整个 Home
目录执行递归删除或强制覆盖。
