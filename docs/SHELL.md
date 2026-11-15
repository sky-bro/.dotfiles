# Shell

## 组成

- Zsh：交互式 shell；
- Oh My Zsh：插件装载；
- Powerlevel10k：prompt；
- fzf：历史、文件和目录模糊搜索；
- mise：Node、Python、Go、Rust 等语言运行时、项目工具和任务；
- uv：Python 项目依赖、虚拟环境、锁文件和 Python CLI；
- GPG Agent：提供 `SSH_AUTH_SOCK` 和签名 pinentry。

macOS 入口是 [`profiles/macos/zshrc`](../profiles/macos/zshrc)。Linux 原有
`.zshrc` 保留为历史 profile，不应直接链接到 macOS。

## 个人约定

- 将 `~/.local/bin` 加入 PATH 并去重，用于 Codex、Claude Code、Sesswitch 等用户级 CLI；这些工具不依赖 mise 的 Node 版本；GUI 应用仍可能使用不同的 PATH，见 [Codex CLI](CODEX.md)；
- 清除 Homebrew 镜像环境变量，固定使用官方源；
- 只有在工具存在时才初始化，避免新机器首个 shell 启动失败；
- Node、Python、Go、Rust 和 uv 的全局版本声明由
  [`config/mise/config.toml`](../config/mise/config.toml) 管理；Python 解释器由
  mise 安装，uv 负责项目环境和依赖，避免重复管理解释器；
- 交互式 shell 设置 `GPG_TTY` 并更新 gpg-agent 的 startup TTY；
- `SSH_AUTH_SOCK` 指向 GPG Agent 的 SSH socket；
- Powerlevel10k 使用仓库中的 `profiles/macos/p10k.zsh`，由 setup 链接为
  `~/.p10k.zsh`；
- 终端字体使用 `MesloLGS Nerd Font Mono`，以正确显示 Nerd Font 图标。

重新运行 `p10k configure` 会通过符号链接直接更新仓库中的配置。提交前应检查
相应 diff。

## 常用检查

```sh
zsh -n ~/.zshrc
echo "$SSH_AUTH_SOCK"
gpgconf --list-dirs agent-ssh-socket
ssh-add -L
mise doctor
uv --version
go version
gopls version
```

字体和图标异常时，先确认终端应用的字体设置，而不是只检查系统是否已安装字体。

如果 uv 找不到预期的 Python，先运行 `mise current python` 和
`uv python find`，确认当前项目的 Python 约束与 mise 激活的版本一致。不要再用
uv 全局安装同一份 Python。

重新加载配置：

```sh
exec zsh
```

`bab` 的 Zsh 补全由它自己的安装器提供，profile 只在
`${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions/_bab` 存在时注册，
不固定用户名路径；未安装 bab 的新机器不会加载不存在的函数。可用
`zsh -n profiles/macos/zshrc` 检查语法，交互 shell 中用 `whence -w _bab`
确认函数已注册，再输入 `bab` 按 Tab 验证实际补全。

## Linux 服务器：pro5000-8x

`pro5000-8x` 使用独立的精简配置
[`profiles/linux-server/zshrc`](../profiles/linux-server/zshrc)。目标是让 SSH
命令行具有与 Mac 相同的历史命令建议，使用 Ubuntu 软件包直接加载
`zsh-autosuggestions`。提示符显示用户、主机和目录，root 用户名使用红色，
无需 Oh My Zsh、Powerlevel10k 或 Nerd Font。

- 灰色文字来自当前用户已执行的 Zsh 历史，按右方向键接受；
- Tab 补全支持菜单和大小写不敏感匹配；
- 输入命令前缀后按上／下方向键搜索，`Ctrl-R` 搜索完整历史；
- 多个会话共享历史，保存 20000 条；以空格开头的命令不写入历史；
- 不导入 Bash 历史，不部署 macOS 的工具、GPG Agent 和运行时配置。

### 安装与应用

先检查远端系统、登录 shell 和现有 `.zshrc`。安装软件包和移动冲突文件前
须取得确认；已有 `.zshrc` 时先审阅，不能直接覆盖。macOS 的 `setup.sh`
不适用于这台 Linux 服务器。

以下命令从本仓库执行，适用于远端尚无 `.zshrc` 的情况：

```sh
ssh pro5000-8x 'apt-get -s install --no-install-recommends zsh zsh-autosuggestions'
# 确认安装计划后执行：
ssh pro5000-8x 'apt-get install -y --no-install-recommends zsh zsh-autosuggestions'
ssh pro5000-8x 'set -eu; umask 077; test ! -e "$HOME/.zshrc"; test ! -L "$HOME/.zshrc"; set -C; cat > "$HOME/.zshrc"; zsh -n "$HOME/.zshrc"' < profiles/linux-server/zshrc
ssh pro5000-8x 'chsh -s /usr/bin/zsh root'
```

重新连接 `ssh pro5000-8x` 生效，已有会话可运行 `exec zsh`。
更新配置前先比较远端文件并确认冲突处理，不直接重复上面的首次部署命令。

### 验证与排查

```sh
ssh pro5000-8x 'getent passwd root; zsh --version; zsh -n ~/.zshrc'
ssh pro5000-8x 'zsh -ic '\''(( $+functions[_zsh_autosuggest_start] )); bindkey "^[[C"; print -r -- "$ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE"'\'''
shasum -a 256 profiles/linux-server/zshrc
ssh pro5000-8x 'sha256sum ~/.zshrc'
```

交互验证：先执行 `echo zsh-suggestion-ok`，再输入 `echo zsh-s`，应显示灰色
后缀；按右方向键接受，按 Enter 执行。第一次使用时历史为空，需先执行一些命令。
建议不出现时检查 `dpkg -L zsh-autosuggestions`、插件路径和终端颜色；补全报
权限警告时运行 `compaudit` 检查目录所有权，不禁用安全检查。

回退登录 shell：`ssh pro5000-8x 'chsh -s /bin/bash root'`，然后重新连接。
`.zshrc` 可保留，不影响 Bash。

2026-11-04 已在 `pro5000-8x` 的 root 用户应用，安装版本为 Zsh
`5.9-6ubuntu2`、zsh-autosuggestions `0.7.0-1`。已验证新 SSH 登录、插件加载、
灰色建议、右方向键接受及 `compaudit`，远端配置与仓库文件的 SHA-256 一致。

该次安装遇到服务器访问软件源的 HTTP／HTTPS 连接超时。本机从
`https://archive.ubuntu.com/ubuntu/` 下载上述两个包和同版本 `zsh-common`，
逐一比对远端 APT 索引中 `apt-cache show` 的 SHA-256，经 SSH 传输后再次
校验，再用 `dpkg -i` 安装，`dpkg --audit` 无输出。`apt-get --no-download`
在此环境仍报 `Unable to fetch some archives`，因此未采用它完成离线安装。
未修改服务器的软件源配置；后续正常在线安装仍使用上面的 APT 流程。

## 资料

- [Zsh manual](https://zsh.sourceforge.io/Doc/Release/)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [Ubuntu zsh package](https://packages.ubuntu.com/noble/zsh)
- [Ubuntu zsh-autosuggestions package](https://packages.ubuntu.com/noble/zsh-autosuggestions)
- [Oh My Zsh wiki](https://github.com/ohmyzsh/ohmyzsh/wiki)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [fzf shell integration](https://github.com/junegunn/fzf/blob/master/README.md#setting-up-shell-integration)
- [mise documentation](https://mise.jdx.dev/)
- [mise Python and uv integration](https://mise.jdx.dev/lang/python.html)
- [uv documentation](https://docs.astral.sh/uv/)
