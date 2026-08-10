# Shell

## 组成

- Zsh：交互式 shell；
- Oh My Zsh：插件装载；
- Powerlevel10k：prompt；
- fzf：历史、文件和目录模糊搜索；
- mise：Node、Python、Go 等语言运行时、项目工具和任务；
- uv：Python 项目依赖、虚拟环境、锁文件和 Python CLI；
- GPG Agent：提供 `SSH_AUTH_SOCK` 和签名 pinentry。

macOS 入口是 [`profiles/macos/zshrc`](../profiles/macos/zshrc)。Linux 原有
`.zshrc` 保留为历史 profile，不应直接链接到 macOS。

## 个人约定

- 清除 Homebrew 镜像环境变量，固定使用官方源；
- 只有在工具存在时才初始化，避免新机器首个 shell 启动失败；
- Node、Python、Go 和 uv 的全局版本声明由
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

## 资料

- [Zsh manual](https://zsh.sourceforge.io/Doc/Release/)
- [Oh My Zsh wiki](https://github.com/ohmyzsh/ohmyzsh/wiki)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [fzf shell integration](https://github.com/junegunn/fzf/blob/master/README.md#setting-up-shell-integration)
- [mise documentation](https://mise.jdx.dev/)
- [mise Python and uv integration](https://mise.jdx.dev/lang/python.html)
- [uv documentation](https://docs.astral.sh/uv/)
