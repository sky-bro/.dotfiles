# 环境与组件手册

这里是 dotfiles 的知识入口。配置文件回答“机器如何运行”，本文档回答
“为什么这样配置、如何安装、如何验证、出问题去哪里查”。

## 核心组件地图

| 组件 | 用途 | 仓库配置 | 个人文档 | 官方资料 |
| --- | --- | --- | --- | --- |
| Setup | 安全、幂等地部署 dotfiles | [`setup.sh`](../setup.sh) | [macOS Setup](MACOS-SETUP.md) | — |
| Homebrew | macOS 软件包管理 | [`Brewfile`](../Brewfile) | [macOS Setup](MACOS-SETUP.md#homebrew) | [Homebrew docs](https://docs.brew.sh/), [Brew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile) |
| Zsh | 交互式 shell | [`profiles/macos/zshrc`](../profiles/macos/zshrc) | [Shell](SHELL.md) | [Zsh manual](https://zsh.sourceforge.io/Doc/Release/) |
| Oh My Zsh | Zsh 插件框架 | setup 自动安装 | [Shell](SHELL.md) | [Oh My Zsh wiki](https://github.com/ohmyzsh/ohmyzsh/wiki) |
| Powerlevel10k | Shell prompt 与 Nerd Font 图标 | [`profiles/macos/p10k.zsh`](../profiles/macos/p10k.zsh)、`Brewfile` | [Shell](SHELL.md) | [Powerlevel10k](https://github.com/romkatv/powerlevel10k), [Nerd Fonts](https://www.nerdfonts.com/) |
| fzf | 模糊搜索与 shell 补全 | `Brewfile`、Zsh plugin | [Shell](SHELL.md) | [fzf README](https://github.com/junegunn/fzf/blob/master/README.md) |
| mise | 语言运行时、工具与任务管理 | `Brewfile`、Zsh activation | [Shell](SHELL.md) | [mise docs](https://mise.jdx.dev/) |
| CopyQ | 剪贴板历史、全局快捷键和图片分类 | [`config/copyq/`](../config/copyq/)、`Brewfile` | [CopyQ](COPYQ.md) | [CopyQ documentation](https://copyq.readthedocs.io/) |
| WezTerm | macOS 终端、Gruvbox Light 与字体显示 | [`profiles/macos/wezterm.lua`](../profiles/macos/wezterm.lua)、`Brewfile` | [WezTerm](WEZTERM.md) | [WezTerm configuration](https://wezterm.org/config/files.html) |
| tmux | 持久终端会话与分屏 | [`.tmux.conf`](../.tmux.conf), [`.tmux.conf.sh`](../.tmux.conf.sh) | [tmux](TMUX.md) | [tmux wiki](https://github.com/tmux/tmux/wiki), [Getting Started](https://github.com/tmux/tmux/wiki/Getting-Started) |
| GnuPG | 主身份、加密、签名与 SSH 子密钥 | [`.gnupg/`](../.gnupg/) | [GPG 与 SSH](GPG.md), [迁移手册](GPG-MIGRATION.md) | [GnuPG manual](https://gnupg.org/documentation/manuals/gnupg/), [gpg-agent](https://www.gnupg.org/documentation/manuals/gnupg26/gpg-agent.1.html) |
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
3. `Brewfile` 或 profile（如适用）；
4. `setup.sh` 的幂等部署逻辑；
5. `AGENTS.md` 中影响自动化与安全的规则。

不要复制大段上游文档；记录个人决策，并链接到官方资料。
