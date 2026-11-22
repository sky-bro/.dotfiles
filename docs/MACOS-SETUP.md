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
./setup.sh --apply
source ~/.zshrc
```

在同一张清单勾选软件和配置，确认后应用。Shell 插件作为一项软件选择，涵盖
Oh My Zsh、Powerlevel10k 和 zsh-autosuggestions。

## 软件与配置选择

[`Brewfile`](../Brewfile) 是默认开启的清单，包含终端、Shell 和 GPG 工具、mise、
GitHub CLI、ShellCheck 与 VS Code。默认关闭项放在
[`Brewfile.optional`](../Brewfile.optional)，包括 Hugo、Poppler、MacTeX、
Docker/Colima、Tailscale、Clash Verge Rev、CopyQ、Stats、VLC、Vicinae、HSTracker 与 Xcode。
同一个 `# group: NAME` 下的条目一起选择。要调整仓库默认值，在两份清单之间移动
对应条目；对成组的软件，移动整组。

配置组件的默认值定义在 [`setup.sh`](../setup.sh) 的 `config_components` 中，包含
Shell、mise、VS Code、容器和命令工具。CopyQ、Claude Code 和 SSH/GnuPG/Git
配置默认关闭。启用 SSH/GnuPG/Git 前，先核对 `config/identity.env` 中的身份。

### 终端勾选

```sh
./setup.sh --apply        # 勾选并确认
./setup.sh --interactive  # 仅勾选和预览
```

方向键移动，空格切换勾选。`S` 清空软件选择，`C` 清空配置选择，再按一次可恢复
该组的默认勾选。回车查看最终清单和配置变更，`Esc` 取消。
使用 `--apply` 时，只有在确认提示输入 `y` 或 `yes` 才会开始安装。安装时会显示
Homebrew 的进度和结果。

`Default` 显示仓库默认值。`Status` 根据本机的 Homebrew 与 Mac App Store 记录
显示已安装、未安装、部分安装或状态未知。手动安装的应用可能没有这些记录。
交互界面需要实际终端和 Python 3。无终端的安装需要显式传入 `--non-interactive`。
安装状态命令见 [Homebrew](https://docs.brew.sh/Manpage#list-ls-options-installed_formula-installed_cask-) 和 [mas](https://github.com/mas-cli/mas)。

### 命令行参数

```sh
./setup.sh --list
./setup.sh --check --without software
./setup.sh --apply --without software
./setup.sh --apply --non-interactive --without software --without configuration --with config-vscode
```

`--list` 输出每项的默认值、当次选中状态和可用于参数的名称。`--with` 和
`--without` 可重复使用，针对同一名称时以最后一次选择为准。在交互界面中，这些参数
设置初始勾选，仍可手动调整。`software` 和 `configuration` 可以整组启用或跳过。
`--non-interactive` 直接应用选中的项目。`--check` 默认输出文本预览。
取消某项勾选会保留现有软件和配置。Homebrew 会为选中的软件安装所需依赖。

mise 的运行时、VS Code 扩展和 Vicinae 的 Passwords 扩展在软件和对应配置都选中时安装。
旧命令中的 `--install-packages` 仍可使用，采用同一套清单和确认流程。

## 组件说明

Powerlevel10k 图标字体由 Brewfile 安装。安装后在终端应用中选择
`MesloLGS Nerd Font Mono`，再运行 `p10k configure` 调整提示符。

GnuPG 使用 Brewfile 安装的 `pinentry-mac` 显示本地口令弹窗，即使发起签名
的 GUI 程序没有 TTY 也能请求解锁私钥。详见 [GPG 与 SSH](GPG.md)。

WezTerm 也由 Brewfile 管理。setup 将
[`profiles/macos/wezterm.lua`](../profiles/macos/wezterm.lua) 链接为
`~/.wezterm.lua`；主题、字体与验证方式见 [WezTerm 手册](WEZTERM.md)。

Visual Studio Code 由 Brewfile 管理。选中 VS Code 配置会链接用户设置，同时选中软件时还会安装仓库记录的扩展。个人约定和验证方式见
[Visual Studio Code 手册](VSCODE.md)。

Codex CLI 使用 OpenAI 官方独立安装器，安装于 `~/.local/bin/codex`，不由
npm、mise 或 Brewfile 重复管理。setup 不自动安装；安装、更新、迁移与验证见
[Codex CLI](CODEX.md)。

Claude Code 使用官方原生安装器，以获得自动更新。setup 只链接不含密钥的
DeepSeek 配置和钥匙串录入脚本；安装、密钥录入和验证见
[Claude Code 与 DeepSeek](CLAUDE-CODE.md)。

DeepSeek Harness（`dsh`）使用官方 npm 包独立安装到 `~/.local`，复用 mise
的 Node.js，不由整套 setup 重复安装。安装、Web 启动和 Codex 接入见
[DeepSeek Harness](DSH.md)。

Go 运行时及其语言工具由 mise 管理，Hugo 可用 `--with hugo` 安装。
同时选中 mise 软件和配置时，setup 会在链接全局 mise 配置后安装声明的运行时。详见
[Go 与 Hugo](GO-HUGO.md)。

Rust 工具链也由 mise 管理，语言服务和调试扩展由 VS Code 安装；详见
[Rust 手册](RUST.md)。

完整 MacTeX 可用 `--with mactex` 安装，提供 TeX Live、XeLaTeX、`latexmk` 和常用
宏包；Poppler 提供 PDF 元数据检查与页面渲染工具。安装体积、PATH 刷新、简历
构建和验证方式见 [TeX 与 PDF 工具](TEX.md)。

CopyQ 可用 `--with copyq` 安装。应用可正常启动时，`--with config-copyq` 会部署配置。
辅助功能授权以及未签名应用的本地修复不会自动执行，详见
[CopyQ 手册](COPYQ.md)。

Stats 可用 `--with stats` 安装，用于在菜单栏常驻显示实时上传与下载速度。偏好设置
由应用自身管理，不由 setup 写入未承诺稳定的内部 defaults 键；首次配置与
验证方式见 [Stats 手册](STATS.md)。

Tailscale 与 Clash Verge Rev 可用 `--with tailscale --with clash-verge-rev` 安装。首次登录、服务代理和家庭
内网分流按 [Tailscale 与 Clash](TAILSCALE.md) 完成；接口配置按本机自动生成。

Vicinae 可用 `--with vicinae` 安装。setup 链接仓库管理的 Script Commands，不会
静默授予辅助功能、全磁盘访问或通知权限，也不会修改登录项。AI session 索引
项目、Codex hooks、使用与验证见
[Vicinae 与 Sesswitch](VICINAE.md)。

Docker CLI、Compose、Buildx 和 Colima 可用 `--with docker` 一起安装。setup 部署新
profile 的 Colima 默认模板与 Docker CLI 插件链接，但不会自动启动虚拟机。
资源约定、首次启动和验证见 [Docker 与 Colima](DOCKER.md)。

macOS SSH 服务使用系统内置 Remote Login。因为安装服务端策略和启用服务
需要管理员授权，它不会由普通的 `setup.sh --apply` 静默执行。先运行
`config/sshd/manage.sh --check`，审核后在真实终端运行
`sudo config/sshd/manage.sh --apply`。密码登录策略与验证见
[SSH 手册](SSH.md#macos-server)。

Xcode 稳定版可用 `--with xcode` 通过 Mac App Store 安装。安装后需要在真实终端运行
`sudo config/xcode/configure.sh --apply`，再按需下载 iOS Simulator runtime。
Apple Account、签名资产和真机 Developer Mode 由用户在本机界面配置，详见
[Xcode 与 iPadOS](XCODE.md)。

`config-tools` 链接 `kill-window` 命令和 Vicinae Script Command。后者可在
Vicinae 中搜索 **Kill Window**。编译与验证见 [Kill Window 手册](KILL-WINDOW.md)。

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
xelatex --version
latexmk --version
pdfinfo -v
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

配置完成后，`./setup.sh --check` 应对已部署的文件显示 `ok`。按本机选择运行相应
组件的验证命令。选项名称输错时，用 `./setup.sh --list` 核对 `Name` 一列。

## 回退

setup 不删除冲突文件。查看最近备份：

```sh
ls -lt ~/.local/state/dotfiles-backups
```

若要回退，先移除对应符号链接，再把备份文件移动回原位置。不要对整个 Home
目录执行递归删除或强制覆盖。
