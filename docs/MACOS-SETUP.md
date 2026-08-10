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

Visual Studio Code 由 Brewfile 管理。setup 链接用户设置，并在
`--install-packages` 阶段安装仓库记录的扩展；个人约定和验证方式见
[Visual Studio Code 手册](VSCODE.md)。

Go 运行时及其语言工具由 mise 管理，Hugo 由 Brewfile 管理。
`--install-packages` 会在链接全局 mise 配置后安装声明的运行时；详见
[Go 与 Hugo](GO-HUGO.md)。

CopyQ 也由 Brewfile 安装，`--apply` 会在应用可正常启动时写入可移植配置。
辅助功能授权以及未签名应用的本地修复不会自动执行，详见
[CopyQ 手册](COPYQ.md)。

Docker CLI、Compose、Buildx 和 Colima 由 Brewfile 安装。setup 部署新
profile 的 Colima 默认模板与 Docker CLI 插件链接，但不会自动启动虚拟机。
资源约定、首次启动和验证见 [Docker 与 Colima](DOCKER.md)。

macOS SSH 服务使用系统内置 Remote Login。因为安装服务端策略和启用服务
需要管理员授权，它不会由普通的 `setup.sh --apply` 静默执行。先运行
`config/sshd/manage.sh --check`，审核后在真实终端运行
`sudo config/sshd/manage.sh --apply`。密码登录策略与验证见
[SSH 手册](SSH.md#macos-server)。

Xcode 稳定版由 Brewfile 通过 Mac App Store 管理。安装后需要在真实终端运行
`sudo config/xcode/configure.sh --apply`，再按需下载 iOS Simulator runtime。
Apple Account、签名资产和真机 Developer Mode 由用户在本机界面配置，详见
[Xcode 与 iPadOS](XCODE.md)。

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
code --version
shellcheck --version
go version
gopls version
dlv version
staticcheck -version
hugo version
gpg --version
test -x "$(brew --prefix)/bin/pinentry-mac"
mise --version
uv --version
fzf --version
colima version
docker version
docker compose version
docker buildx version
config/sshd/manage.sh --check
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version
config/xcode/configure.sh --check
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
