# Vicinae 与 Sesswitch

## 个人约定

Vicinae 是 macOS 上的键盘启动器，用于从一个模糊搜索列表定位 AI agent
session。核心索引与聚焦逻辑由独立项目
`~/repos/sesswitch` 提供；Vicinae 只承担展示和选择，避免把 Codex、tmux、
WezTerm 等宿主逻辑绑定到某个 launcher。

当前 MVP 通过 Codex 官方 app-server `thread/list` 查询完整历史，并通过 Claude
Code 官方 hooks 索引被观察到的 Claude 会话。provider hooks 记录 session ID、
agent 进程 PID/启动时间/TTY、tmux pane ID、WezTerm pane ID 和最后活动时间，
不读取或持久化 transcript。没有可用 live pane 时，选择结果会在 WezTerm 中
运行相应 provider 的 resume 命令。

Sesswitch 内部已拆分 provider、host 与 launcher 边界：Codex 和 Claude 是当前
provider；tmux/WezTerm 是当前完整 host adapter。registry 使用 provider 命名空间，
hook 入口分别为 `sesswitch hook codex` 和 `sesswitch hook claude`，避免 ID 冲突。
开发 Mac 已安装 Claude Code，用户级 settings 也声明了 Sesswitch hooks。Claude
adapter 不解析其内部历史 transcript；只有安装 hooks 后启动或恢复过的会话进入列表。

状态按两个维度呈现：hook 或 app-server 观察到的运行状态，以及用户明确标记的
任务状态。`needs approval` 是待确认权限，`working` 是正在处理，
`turn ended · review` 仅说明一轮停止，**不代表整个任务完成**。可以用
`mark done` 明确标记任务完成，再用 `mark clear` 撤销。`list --json` 保留原始
app-server 状态、active flags、事件来源和观察时间。状态 hook 不读取提示词、
工具参数或对话记录。

Vicinae 的主入口是 Sesswitch 项目中的原生 React/TypeScript extension：
`~/repos/sesswitch/extensions/vicinae`。它使用 provider 的图片 logo、独立标题/
副标题和右侧彩色状态 tag。Script Command 位于
[`config/vicinae/scripts/ai-sessions.sh`](../config/vicinae/scripts/ai-sessions.sh)，
由 setup 链接到 `~/.local/share/vicinae/scripts/ai-sessions.sh`，只作为
**AI Sessions (Legacy)** 文本 fallback。

## 安装与应用

按仓库标准流程安装 Vicinae 并链接 Script Command：

```sh
./setup.sh --check
./setup.sh --install-packages --apply
```

构建独立项目并安装 Codex location hooks：

```sh
cd ~/repos/sesswitch
make test
make build
make install-codex-hook
```

安装原生 Vicinae extension（npm 依赖只安装在项目子目录）：

```sh
cd ~/repos/sesswitch/extensions/vicinae
npm install
npm run typecheck
npm run build
vicinae server --replace
```

`vici build` 会把产物安装到
`~/.local/share/vicinae/extensions/sesswitch/`。Codex logo 来自本机
ChatGPT.app 随附的官方资源，Claude logo 使用橙色品牌 SVG。

Claude Code 安装后，可再显式安装 Claude hooks（当前 setup 不自动修改 hooks）：

```sh
cd ~/repos/sesswitch
make install-claude-hook
```

hook 安装器会保留已有 hooks，并在
`~/.local/state/sesswitch/backups/` 写入带时间戳的备份。Codex 第一次看到
变化时可能要求用户在交互界面确认信任；不要绕过该确认或手工伪造 trusted hash。

首次运行 Vicinae 时，辅助功能、全磁盘访问和通知都不是 AI Sessions 的必要
条件。只有确实需要窗口管理、全盘文件搜索或通知时才分别授权。全局快捷键和
登录启动由用户在 Vicinae 设置中选择，不由 setup 修改系统隐私设置或登录项。

## 使用

在 Vicinae 根搜索中运行原生 **AI Sessions**，输入标题、仓库名、agent、宿主或
状态过滤，然后按 Enter。左侧图片区分 Codex/Claude，中间副标题只显示项目，
右侧独立环境图标与彩色 tag 分别显示运行宿主和 `Action needed`、
`Working`、`Ready to review` 等状态。宿主名称及具体 tmux pane 保留在环境图标
tooltip 和搜索关键词中，不在每一行重复显示；tmux 使用绿色品牌图标。
agent 名称同样保留在左侧 logo tooltip 和搜索关键词中，不与 logo 重复显示。
搜索框右侧可以切换组织方式，并记住上次选择：默认 **Focus** 按 `Needs You`、
`Active`、`Recent`、`Done` 分区；**Recent** 使用全局最近更新时间；**Project**
按工作目录项目分组；**Agent** 按 Codex/Claude 分组。Project 和 Agent 模式在
各组内部仍优先展示需要介入和待 review 的会话，再按更新时间排序。
全程可以使用键盘：`⌘P` 打开组织方式下拉框，方向键选择、Enter 确认；也可以
直接按 `⌘⇧O` 在 Focus、Recent、Project、Agent 之间循环。左侧图标继续表示
agent 身份，右侧状态标签前的独立 host 图标表示 tmux、WezTerm/普通终端、
VS Code、Chrome 或 Desktop，避免把“谁”和“在哪里”混成一个维度。
定位成功后 Vicinae 会自动收起。选中条目后按 `⌘B` 打开 session action panel：
Codex 可以重命名，所有 provider 都可以标记/取消任务完成、刷新列表或复制
session key。重命名通过 Codex app-server 的 `thread/name/set` 完成，不直接改写
rollout 文件；Claude 尚无对应的稳定接口，因此暂不显示 Rename action。
本机显式绑定 `toggle-action-panel` 为 `⌘B`，避开当前 macOS 版本中 `⌘J/K`
被列表导航抢占的上游冲突；即使不打开面板，也可以直接使用
`⌘E` 重命名 Codex session、`⌘⇧D` 切换完成标记、`⌘R` 刷新，以及 `⌘⇧C`
复制 session key。
也可以直接运行：

```sh
~/repos/sesswitch/bin/sesswitch pick
~/repos/sesswitch/bin/sesswitch list
~/repos/sesswitch/bin/sesswitch open codex:<thread-id>
~/repos/sesswitch/bin/sesswitch mark done codex:<thread-id>
~/repos/sesswitch/bin/sesswitch mark clear codex:<thread-id>
~/repos/sesswitch/bin/sesswitch rename codex:<thread-id> "新的会话名"
```

若不想先打开根搜索再查找命令，可给 **AI Sessions** 绑定命令级全局快捷键：

1. 在 Vicinae 根搜索中选中 **AI Sessions**；
2. 按 `⌘B` 打开 action panel；
3. 选择 **Set Global Shortcut**，建议使用 `⌘⇧Space`，同时保留 `⌘Space`
   打开 Vicinae 根搜索。

Vicinae 中原生命令的稳定 entrypoint ID 是
`@sky-bro/sesswitch:ai-sessions`，也可以用下面的
命令直接进入 session picker，不经过根搜索：

```sh
vicinae cmd launch @sky-bro/sesswitch:ai-sessions
```

旧文本入口仍可用 `vicinae cmd launch scripts:ai-sessions.sh` 启动，但不再绑定
全局快捷键。

直接快捷键仍会展示 session 列表，因为 Sesswitch 需要知道要定位哪一个会话；
它省略的是“先搜索 AI Sessions 命令”这一步。

默认打开顺序是：已登记的 tmux/WezTerm pane、否则在 WezTerm 恢复会话。
列表中的 `linked · tmux` 表示已登记 pane，打开时会重新验证进程和 TTY；
`saved` 表示只有 provider
历史记录，选择后会在新 WezTerm 窗口恢复。Codex app-server 原始的
`notLoaded` 只是“当前未载入服务内存”，不是错误，列表会将它显示为 `saved`。
若已有 hook 观察记录，则优先显示该记录；临时的 `working` / `needs approval`
还需进程身份仍有效。`SessionEnd` 表示会话关闭，不等于任务完成。

hook 通过父进程找到对应 agent CLI，再将其 TTY 与 `tmux list-panes` 的 pane TTY
关联；不依赖可能只显示 shell 的 `pane_current_command`。已登记的 tmux pane
即使被 detach，仍可定位：优先把现有 WezTerm 中已连接的
tmux client 切到目标 pane；若 tmux 已无 client，则在当前 WezTerm 窗口中新建
tab 并 attach 原 session。只有 WezTerm 整体不在运行时才新建窗口，而且仍是
attach 原 tmux session，不会重复运行 `codex resume`。
完成 pane 切换后会先让 WezTerm 激活目标 pane，再把 WezTerm 应用提升到 macOS
前台，避免焦点继续停留在 Vicinae；此过程不依赖辅助功能权限。
`open --target app` 使用本机 Codex App 的 `codex://threads/<id>` 深链；该深链
不是当前官方稳定接口，因此代码保留显式 target，不把它作为默认恢复路径。

没有 live 坐标时会按来源路由：Codex Desktop 使用 thread 深链；Chrome
sidepanel 和 VS Code 会聚焦对应应用；CLI 历史在 WezTerm 恢复。Chrome 与 VS
Code 目前没有对外提供稳定的 session→tab/panel 坐标，所以只能准确聚焦应用，
不能保证选中应用内的那条对话；后续需要分别增加扩展 bridge。

## 验证

```sh
vicinae version
vicinae script check config/vicinae/scripts/ai-sessions.sh
test "$(readlink "$HOME/.local/share/vicinae/scripts/ai-sessions.sh")" \
  = "$PWD/config/vicinae/scripts/ai-sessions.sh"
cd ~/repos/sesswitch
make test
make check-vicinae-extension
vicinae cmd ls | rg '@sky-bro/sesswitch:ai-sessions'
./bin/sesswitch doctor
./bin/sesswitch list --limit 5
```

构建扩展后重启 Vicinae，再确认原生 **AI Sessions** 可以打开带 provider logo 的
列表；**AI Sessions (Legacy)** 仅用于诊断扩展运行时问题。新建或恢复一个终端
Codex 或 Claude session 后，location
registry 应在 `~/.local/state/sesswitch/locations/` 出现权限为 `0600` 的 JSON
文件。

## 故障排查

- 根搜索没有原生 AI Sessions：运行 `make check-vicinae-extension`，确认
  `vicinae cmd ls` 包含 `@sky-bro/sesswitch:ai-sessions`，再重启 Vicinae；文本
  fallback 可通过 **Reload Script Directories** 重新加载；
- `Codex app-server` 初始化失败：确认正常用户环境可以读写 `~/.codex`；严格
  沙盒环境可能阻止 SQLite 初始化；
- 选择后总是新开终端：确认 Codex 已信任 location hooks，Codex CLI 有实际 TTY，
  且 tmux 能列出该 TTY 对应的 pane；在 Codex CLI 中运行 `/hooks`，确保 Agent
  Locator 的 `SessionStart`、`UserPromptSubmit`、`PermissionRequest`、
  `PostToolUse`、`Stop`、`Interrupt`、`SessionEnd` 都已信任。长时间运行的 tmux
  server 还可能保留已经退出的 WezTerm GUI socket；Sesswitch 会忽略不存在的
  `WEZTERM_UNIX_SOCKET` 并重新发现当前 GUI；
- 等待确认没有显示：先检查 `/hooks` 中新事件是否已信任；CLI hook 仅覆盖
  Codex 的受支持审批路径，浏览器与 VS Code 形态仍需单独事件桥接；
- pane 已关闭却仍显示 linked：标签表示“曾登记”，不是实时存活；打开时验证
  PID、启动时间和 TTY。仅确认进程已退出时才自动恢复；定位/聚焦失败会报错，
  不会偷偷新开一个重复 Codex；
- macOS 全局快捷键无效：在 Vicinae 设置中重新绑定；只有需要全局窗口操作时才
  前往系统设置授予辅助功能权限。

## 官方资料

- [Vicinae macOS 安装](https://docs.vicinae.com/install/macos)
- [Vicinae Script Commands](https://docs.vicinae.com/scripts/getting-started)
- [Vicinae extensions](https://docs.vicinae.com/extensions/create)
- [Vicinae List API](https://docs.vicinae.com/extensions/api/list)
- [Codex app-server](https://developers.openai.com/zh-Hans/docs/app-server)
- [Codex hooks](https://developers.openai.com/zh-Hans/docs/hooks)
- [Claude Code CLI](https://code.claude.com/docs/en/cli-reference)
- [Claude Code hooks](https://code.claude.com/docs/en/hooks)
- [WezTerm CLI](https://wezterm.org/cli/cli/index.html)
- [tmux manual](https://man7.org/linux/man-pages/man1/tmux.1.html)
