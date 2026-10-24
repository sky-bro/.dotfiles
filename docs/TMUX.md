# tmux

tmux 用于持久保存终端任务、分屏工作以及在 SSH 连接中断后继续工作。

## 当前键位

Prefix 从默认 `Ctrl-b` 改为 `Ctrl-a`。

| 操作 | 键位 |
| --- | --- |
| 垂直分屏 | `Ctrl-a -` |
| 水平分屏 | `Ctrl-a \|` |
| 切换 pane 焦点 | `Ctrl-a h/j/k/l` |
| 向左／下／上／右交换 pane（大写） | `Ctrl-a H/J/K/L` |
| 标记／取消标记当前 pane | `Ctrl-a M` |
| 将标记的 pane 插到目标左／下／上／右侧 | `Ctrl-a ←/↓/↑/→` |
| 选择目标 session / window 移动 pane | `Ctrl-a m` |
| pane 调整大小 | `Ctrl-a Ctrl-h/j/k/l` |
| 新建窗口（继承当前目录） | `Ctrl-a c` |
| 重新加载配置 | `Ctrl-a r` |
| copy mode 开始选择 | `v` |
| copy mode 复制并退出 | `y` |

分屏和新窗口都会继承当前 pane 的工作目录。窗口关闭后会自动重新编号，
滚动历史保留 50,000 行。

macOS 下，copy mode 的 `y` 和鼠标选择都通过 `pbcopy` 进入系统剪贴板；
WSL 使用 `clip.exe`。其他平台的 `y` 仍会复制到 tmux buffer。

## 移动 pane

为了接近 i3 的操作习惯，小写 `h/j/k/l` 切换焦点，大写 `H/J/K/L`
将当前 pane 与对应方向的相邻 pane 交换位置，输入焦点跟随原 pane。
这些键按屏幕方向选择邻居，区别于默认 `{` / `}` 按 pane 编号交换；
方向超出布局边缘时，邻居选择会环绕。复杂布局仍采用 tmux 的相邻 pane
规则，并不具备 i3 的容器树移动语义。

同 window 重组分屏使用“标记 → 选择目标 → 方向插入”：

1. 在源 pane 按 `Ctrl-a M`（大写），顶部出现 `◆ MARKED`。
2. 用 `Ctrl-a h/j/k/l` 或鼠标聚焦目标 pane。
3. 按 `Ctrl-a` 后松开，再按 `←/↓/↑/→`，将源 pane 插入目标对应一侧。

这会按所选方向分割目标、填入原 pane，改变布局结构；`H/J/K/L`
则只交换已有位置。移动完成后焦点跟随源 pane，并自动清除标记。
在标记 pane 上再次按 `Ctrl-a M` 取消；在另一个 pane 上按它会重新标记。
没有标记或源与目标相同时只显示提示；插入失败时保留标记以便重试。
标记是 tmux server 全局唯一的，多个客户端共享，也可用于跨 window
移动：标记后切到目标 window，再按方向插入。
方向键原有的 pane 焦点切换由小写 `h/j/k/l` 承担。

跨 window/session 的目标选择使用 `Ctrl-a m`，打开居中的原生 tmux 菜单，
不依赖 fzf 或其他软件：

1. 用方向键或 `j/k` 选择目标 session，按回车进入。
2. 选择已有 window，将当前 pane 放到该 window 活动 pane 的右侧；
   或按 `n` 选择 `New window`，在目标 session 中创建独立 window。
3. 完成后自动跳转到目标 session / window，继续操作原 pane。

第二级菜单按 `b` 返回 session 列表；任一级按 `Esc` 取消，不移动 pane。
源 pane 所在的 session 和 window 均标记 `[current]`；当前 session 仍可
进入，以选择其中其他 window。当前 window 显示为灰色且不可选，
同 window 的位置调整使用交换快捷键或标记后方向插入。
菜单只列出同一 tmux server 内的 session，不支持跨机器或跨 server 移动。
移动保持原 pane、进程及工作目录；源 window 没有其他 pane 时会消失，
源 session 没有其他 window 时也可能结束。源 session 的其他客户端遵循
各自的 `detach-on-destroy` 设置。
菜单会先将发起操作的客户端切到目标 session，再移动 pane，避免源 session
结束时断开该客户端；移动失败时切回原 session。

菜单实现在 `.tmux.conf.sh`，通过 pane/window/session ID 定位目标，
不依赖会自动变化的 window 编号；session 和 window 名称只用于显示。

## 活动 pane 提示

为便于在 Gruvbox Light 浅色背景下识别焦点，活动 pane 使用深橙色边框，
其他边框使用灰色。边框同时显示方向箭头；只有两个 pane 时，还会通过
半段边框着色指示焦点位于哪一侧。

每个 pane 顶部保留一行边框状态：活动 pane 显示橙底的 `▶ ACTIVE` 和
pane 编号，其他 pane 只显示灰色编号。这会占用每个 pane 的一行高度，
用于在共享分隔线或复杂布局中明确标识当前输入位置。
被标记的源 pane 另显示 `◆ MARKED`，切换焦点后仍保留，直到取消或插入成功。

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

本次只更新 tmux，且上述两个文件已正确链接时，直接重新加载即可，
无需运行完整 setup 或安装软件包。

诊断：

```sh
tmux -V
tmux show-options -g
tmux list-keys
tmux show-options -gw pane-active-border-style
tmux show-options -gw pane-border-indicators
tmux show-options -gw pane-border-status
printf '\033[38;2;255;100;0mtruecolor\033[0m\n'
```

如果启动时报 `unknown terminal: tmux-256color`，确认 tmux 是通过 Homebrew
安装，并检查 `infocmp tmux-256color`。如果复制没有进入 macOS 剪贴板，
确认 `command -v pbcopy` 有输出，并用 `tmux list-keys -T copy-mode-vi`
检查 `y` 和 `MouseDragEnd1Pane` 的绑定。

切换两个或更多 pane，确认 `▶ ACTIVE` 跟随焦点移动。若边框样式未变化，
先重新加载配置，再用上述 `show-options -gw` 命令检查深橙色、`both` 和
`top` 是否生效；如某个窗口有单独设置，用 `tmux show-options -w` 检查
是否覆盖了全局窗口选项。样式和边框选项的完整说明见本机 `man tmux`
的 `pane-active-border-style`、`pane-border-indicators` 和 `pane-border-status`。

移动功能验证：在测试 session 中分出左右和上下 pane，分别用
`H/L`、`K/J` 交换，确认 `▶ ACTIVE` 跟随原 pane；运行 `sleep 300`
后经菜单移动到同 session 的其他 window、另一 session 的已有 window、
以及新建 window，确认任务仍运行。取消菜单和返回上一级均不应移动 pane。
脚本检查使用 `bash -n .tmux.conf.sh` 和 `shellcheck .tmux.conf.sh`。
标记插入验证：标记源 pane 后聚焦另一 pane，分别测试四个方向插入，
确认布局改变、源进程继续运行、焦点跟随、标记清除；再次标记同 pane
应取消。未标记和目标为自身时应保持布局，空间不足时应保留标记。
若菜单没有出现，先按 `Ctrl-a r`，再检查 `tmux list-keys -T prefix m`；
若选择时目标刚被关闭，tmux 会报找不到目标，重新打开菜单即可。
终端过小时可能放不下菜单，可扩大终端后重试。

## 资料

- [tmux wiki](https://github.com/tmux/tmux/wiki)
- [Getting Started](https://github.com/tmux/tmux/wiki/Getting-Started)
- [Installing tmux](https://github.com/tmux/tmux/wiki/Installing)
- [tmux FAQ](https://github.com/tmux/tmux/wiki/FAQ)
- [官方手册：swap-pane、display-menu、move-pane、break-pane](https://github.com/tmux/tmux/blob/master/tmux.1)
- 本地完整参考：`man tmux`
