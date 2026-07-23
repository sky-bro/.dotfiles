# tmux

tmux 用于持久保存终端任务、分屏工作以及在 SSH 连接中断后继续工作。

## 当前键位

Prefix 从默认 `Ctrl-b` 改为 `Ctrl-a`。

| 操作 | 键位 |
| --- | --- |
| 垂直分屏 | `Ctrl-a -` |
| 水平分屏 | `Ctrl-a \|` |
| pane 移动 | `Ctrl-a h/j/k/l` |
| pane 调整大小 | `Ctrl-a Ctrl-h/j/k/l` |
| 新建窗口（继承当前目录） | `Ctrl-a c` |
| 重新加载配置 | `Ctrl-a r` |
| copy mode 开始选择 | `v` |
| copy mode 复制并退出 | `y` |

分屏和新窗口都会继承当前 pane 的工作目录。窗口关闭后会自动重新编号，
滚动历史保留 50,000 行。

macOS 下，copy mode 的 `y` 和鼠标选择都通过 `pbcopy` 进入系统剪贴板；
WSL 使用 `clip.exe`。其他平台的 `y` 仍会复制到 tmux buffer。

## 安装与应用

先预览 setup 将进行的所有操作：

```sh
./setup.sh --check
```

确认冲突文件的备份计划后，安装 Homebrew 依赖并应用全部 macOS 配置：

```sh
./setup.sh --install-packages --apply
```

如果 tmux 已安装且只想启用本组件，可手动为 `.tmux.conf` 和
`.tmux.conf.sh` 创建指向仓库文件的符号链接；不要使用 `stow .`。

## 常用命令

```sh
tmux new-session -s work
tmux list-sessions
tmux attach-session -t work
tmux kill-session -t work
```

重新加载配置：

```sh
tmux source-file ~/.tmux.conf
```

运行中的 tmux 也可以按 `Ctrl-a r`。

诊断：

```sh
tmux -V
tmux show-options -g
tmux list-keys
printf '\033[38;2;255;100;0mtruecolor\033[0m\n'
```

如果启动时报 `unknown terminal: tmux-256color`，确认 tmux 是通过 Homebrew
安装，并检查 `infocmp tmux-256color`。如果复制没有进入 macOS 剪贴板，
确认 `command -v pbcopy` 有输出，并用 `tmux list-keys -T copy-mode-vi`
检查 `y` 和 `MouseDragEnd1Pane` 的绑定。

## 资料

- [tmux wiki](https://github.com/tmux/tmux/wiki)
- [Getting Started](https://github.com/tmux/tmux/wiki/Getting-Started)
- [Installing tmux](https://github.com/tmux/tmux/wiki/Installing)
- [tmux FAQ](https://github.com/tmux/tmux/wiki/FAQ)
- 本地完整参考：`man tmux`
