# Shell

## 组成

- Zsh：交互式 shell；
- Oh My Zsh：插件装载；
- Powerlevel10k：prompt；
- fzf：历史、文件和目录模糊搜索；
- mise：语言运行时、项目工具和任务；
- GPG Agent：提供 `SSH_AUTH_SOCK` 和签名 pinentry。

macOS 入口是 [`profiles/macos/zshrc`](../profiles/macos/zshrc)。Linux 原有
`.zshrc` 保留为历史 profile，不应直接链接到 macOS。

## 个人约定

- 清除 Homebrew 镜像环境变量，固定使用官方源；
- 只有在工具存在时才初始化，避免新机器首个 shell 启动失败；
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
```

字体和图标异常时，先确认终端应用的字体设置，而不是只检查系统是否已安装字体。

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
