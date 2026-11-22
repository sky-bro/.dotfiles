# 环境与组件手册

这里是 dotfiles 的知识入口。配置文件回答“机器如何运行”，本文档回答
“为什么这样配置、如何安装、如何验证、出问题去哪里查”。

## 核心组件地图

| 组件 | 用途 | 仓库配置 | 个人文档 | 官方资料 |
| --- | --- | --- | --- | --- |
| Setup | 在同一张清单勾选软件和配置，预览并确认 | [`setup.sh`](../setup.sh)、[`勾选界面`](../config/macos/checklist.py) | [macOS Setup](MACOS-SETUP.md) | — |
| Kill Window / Swift | 点选卡死窗口、确认所属进程并强制结束；Linux/macOS 共用入口 | [`bin/kill-window.sh`](../bin/kill-window.sh)、[`config/kill-window/`](../config/kill-window/) | [Kill Window](KILL-WINDOW.md) | [Core Graphics](https://developer.apple.com/documentation/coregraphics)、[Swift VS Code](https://github.com/swiftlang/vscode-swift) |
| Homebrew | macOS 软件包管理、默认与按需安装 | [`Brewfile`](../Brewfile)、[`Brewfile.optional`](../Brewfile.optional) | [软件与配置选择](MACOS-SETUP.md#软件与配置选择) | [Homebrew docs](https://docs.brew.sh/), [Brew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile) |
| Tailscale / Clash Verge | `tailscale-travel` 一键刷新外出分流、修复家庭路由并验证访问 | [`config/tailscale/`](../config/tailscale/)、`Brewfile.optional` | [Tailscale 与 Clash](TAILSCALE.md) | [Tailscale CLI](https://tailscale.com/docs/reference/tailscale-cli), [Clash Verge docs](https://www.clashverge.dev/) |
| Zsh | macOS 交互式 shell，以及 Linux 服务器的精简命令建议配置 | [`profiles/macos/zshrc`](../profiles/macos/zshrc)、[`profiles/linux-server/zshrc`](../profiles/linux-server/zshrc) | [Shell](SHELL.md) | [Zsh manual](https://zsh.sourceforge.io/Doc/Release/)、[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) |
| Oh My Zsh | Zsh 插件框架 | setup 自动安装 | [Shell](SHELL.md) | [Oh My Zsh wiki](https://github.com/ohmyzsh/ohmyzsh/wiki) |
| Powerlevel10k | Shell prompt 与 Nerd Font 图标 | [`profiles/macos/p10k.zsh`](../profiles/macos/p10k.zsh)、`Brewfile` | [Shell](SHELL.md) | [Powerlevel10k](https://github.com/romkatv/powerlevel10k), [Nerd Fonts](https://www.nerdfonts.com/) |
| fzf | 模糊搜索与 shell 补全 | `Brewfile`、Zsh plugin | [Shell](SHELL.md) | [fzf README](https://github.com/junegunn/fzf/blob/master/README.md) |
| mise / uv | 语言运行时、开发工具与 Python 项目管理 | [`config/mise/config.toml`](../config/mise/config.toml)、`Brewfile`、Zsh activation | [Shell](SHELL.md) | [mise docs](https://mise.jdx.dev/), [uv docs](https://docs.astral.sh/uv/) |
| Go / Hugo | Go 开发、语言服务、调试、静态分析与静态网站生成 | [`config/mise/config.toml`](../config/mise/config.toml)、[`config/vscode/`](../config/vscode/)、`Brewfile.optional` | [Go 与 Hugo](GO-HUGO.md) | [Go docs](https://go.dev/doc/), [Hugo docs](https://gohugo.io/documentation/) |
| Rust | Rust 工具链、格式化、Clippy、语言服务与调试 | [`config/mise/config.toml`](../config/mise/config.toml)、[`config/vscode/`](../config/vscode/) | [Rust](RUST.md) | [Rust install](https://rust-lang.org/tools/install/), [mise Rust](https://mise.jdx.dev/lang/rust.html) |
| TeX / PDF | 中文简历与文档排版、PDF 元数据检查和页面渲染 | `Brewfile.optional` | [TeX 与 PDF 工具](TEX.md) | [MacTeX](https://www.tug.org/mactex/), [Poppler](https://poppler.freedesktop.org/) |
| Docker / Colima | macOS 上的容器 CLI、Compose、Buildx 与轻量 Linux VM | [`config/colima/default.yaml`](../config/colima/default.yaml)、`Brewfile.optional` | [Docker 与 Colima](DOCKER.md) | [Colima docs](https://colima.run/docs/), [Docker docs](https://docs.docker.com/) |
| Xcode / iPadOS | Apple 平台 SDK、模拟器、真机调试、签名与发布 | [`config/xcode/`](../config/xcode/)、`Brewfile.optional` | [Xcode 与 iPadOS](XCODE.md) | [Xcode support](https://developer.apple.com/support/xcode/), [Xcode documentation](https://developer.apple.com/documentation/xcode) |
| Visual Studio Code | 跨语言编辑、格式化、静态检查与容器开发 | [`config/vscode/`](../config/vscode/)、`Brewfile` | [Visual Studio Code](VSCODE.md) | [VS Code docs](https://code.visualstudio.com/docs) |
| Codex CLI | 终端编程助手，独立安装、代理更新与失败检查 | [`profiles/macos/zshrc`](../profiles/macos/zshrc) | [Codex CLI](CODEX.md) | [Codex CLI 官方文档](https://learn.chatgpt.com/docs/codex/cli) |
| DeepSeek Harness / dsh | 插件式 agent 与 Web UI，Codex 订阅作为主模型 | [`config/dsh/`](../config/dsh/)、用户级 npm 包 | [DeepSeek Harness](DSH.md) | [官方项目](https://github.com/deepseek-ai/deepseek-harness) |
| Claude Code / DeepSeek | 终端编程助手，使用 DeepSeek Flash API 与 macOS 钥匙串 | [`config/claude/`](../config/claude/) | [Claude Code 与 DeepSeek](CLAUDE-CODE.md) | [Claude Code quickstart](https://code.claude.com/docs/en/quickstart), [DeepSeek 接入指南](https://api-docs.deepseek.com/zh-cn/quick_start/agent_integrations/claude_code/) |
| CopyQ | 剪贴板历史、全局快捷键和图片分类 | [`config/copyq/`](../config/copyq/)、`Brewfile.optional` | [CopyQ](COPYQ.md) | [CopyQ documentation](https://copyq.readthedocs.io/) |
| pass / Passwords | Vicinae 中管理 pass/GPG 条目、字段浏览、用户名/密码自动输入、TOTP 专用表单与本地二维码导入、最近使用与机密复制 | [`config/pass/`](../config/pass/)、[`Vicinae 扩展`](../config/vicinae/passwords/)、`Brewfile`、`Brewfile.optional` | [密码管理](PASSWORDS.md) | [pass](https://www.passwordstore.org/)、[Vicinae extensions](https://docs.vicinae.com/extensions/create) |
| Stats | 在 macOS 菜单栏显示实时网络吞吐 | `Brewfile.optional`、应用内偏好设置 | [Stats](STATS.md) | [Stats](https://github.com/exelban/stats) |
| VLC | 本地音视频与网络媒体播放 | `Brewfile.optional` | [VLC](VLC.md) | [VideoLAN VLC](https://www.videolan.org/vlc/), [Homebrew cask](https://formulae.brew.sh/cask/vlc) |
| HSTracker | macOS 炉石传说记牌与卡组管理 | `Brewfile.optional` | [炉石与 HSTracker](HEARTHSTONE.md) | [HSTracker](https://github.com/HearthSim/HSTracker) |
| Vicinae / Sesswitch | 搜索、查看并聚焦 AI agent session | [`config/vicinae/`](../config/vicinae/)、`Brewfile.optional` | [Vicinae 与 Sesswitch](VICINAE.md) | [Vicinae docs](https://docs.vicinae.com/), [Codex app-server](https://developers.openai.com/zh-Hans/docs/app-server) |
| WezTerm | macOS 终端、Gruvbox Light 与字体显示 | [`profiles/macos/wezterm.lua`](../profiles/macos/wezterm.lua)、`Brewfile` | [WezTerm](WEZTERM.md) | [WezTerm configuration](https://wezterm.org/config/files.html) |
| tmux | 持久终端会话、pane 交换／标记后方向插入、标记当前位置的跨 session/window 移动菜单 | [`.tmux.conf`](../.tmux.conf), [`.tmux.conf.sh`](../.tmux.conf.sh) | [tmux](TMUX.md) | [tmux wiki](https://github.com/tmux/tmux/wiki), [Getting Started](https://github.com/tmux/tmux/wiki/Getting-Started) |
| GnuPG | 主身份、加密、签名与 SSH 子密钥 | [`.gnupg/`](../.gnupg/) | [GPG 与 SSH](GPG.md), [迁移手册](GPG-MIGRATION.md) | [GnuPG manual](https://gnupg.org/documentation/manuals/gnupg/), [gpg-agent](https://www.gnupg.org/documentation/manuals/gnupg26/gpg-agent.1.html) |
| OpenSSH | GitHub/OpenWrt 客户端与 macOS Remote Login 服务 | [`config/ssh/config`](../config/ssh/config)、[`config/sshd/`](../config/sshd/) | [SSH](SSH.md) | [Apple Remote Login](https://support.apple.com/guide/mac-help/mchlp1066/mac), [OpenSSH manual pages](https://www.openssh.com/manual.html) |
| Git/GitHub | 代码身份、签名提交与 SSH | `setup.sh` 写入全局 Git 配置 | [Git 与 GitHub](GIT-GITHUB.md) | [Git docs](https://git-scm.com/doc), [GitHub authentication](https://docs.github.com/authentication) |

## Linux 桌面组件

这些配置暂不参与 macOS 自动 setup，但仍属于仓库维护范围。

| 组件 | 配置 | 官方资料 |
| --- | --- | --- |
| i3 | [`.config/i3/`](../.config/i3/), [`.config/i3status/`](../.config/i3status/) | [i3 User's Guide](https://i3wm.org/docs/userguide.html) |
| rofi | [`.config/rofi/`](../.config/rofi/), [`.config/rofi-pass/`](../.config/rofi-pass/) | [rofi documentation](https://davatorium.github.io/rofi/) |
| picom/compfy | [`.config/picom/`](../.config/picom/), [`.config/compfy/`](../.config/compfy/) | [picom manual](https://picom.app/) |
| Emacs | [`.emacs.d/`](../.emacs.d/) | [GNU Emacs manual](https://www.gnu.org/software/emacs/manual/) |
| Vim | [`.vimrc`](../.vimrc) | [Vim documentation](https://www.vim.org/docs.php) |
| Zathura | [`.config/zathura/`](../.config/zathura/) | [pwmt.org projects](https://pwmt.org/projects/zathura/) |
| Utility scripts | [`bin/`](../bin/) | [`bin/README.org`](../bin/README.org) |

## 文档维护约定

新增或修改组件时，同时更新：

1. 组件地图中的用途、配置入口和官方资料；
2. 对应专题页中的安装、个人约定、验证和故障排查；
3. `Brewfile`、`Brewfile.optional` 或 profile（如适用）；
4. `setup.sh` 的幂等部署逻辑；
5. `AGENTS.md` 中影响自动化与安全的规则。

不要复制大段上游文档；记录个人决策，并链接到官方资料。
