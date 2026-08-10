# Visual Studio Code

## 个人约定

VS Code 由 Homebrew Cask 安装。用户设置保存在
[`config/vscode/settings.json`](../config/vscode/settings.json)，由 setup
显式链接到 macOS 的 `~/Library/Application Support/Code/User/settings.json`。
这样只管理单个设置文件，不会覆盖 VS Code 的缓存、登录状态或其他用户数据。

配置使用与 WezTerm 一致的 `MesloLGS Nerd Font Mono` 和 Gruvbox Light。VS Code
固定使用 `jdinhlife.gruvbox` 提供的 `Gruvbox Light Medium`，不跟随系统深浅色自动
切换。编辑器启用保存时格式化、行尾空白清理、文件末尾换行、括号配色和 80/100
列参考线，并关闭遥测。工作区信任保持启用，首次打开陌生仓库时应先审查其中的
任务、调试配置和扩展建议。

编辑操作使用 `vscodevim.vim`：Space 是 leader，未命名寄存器连接系统剪贴板，
搜索与 yank 有高亮，Normal/Visual 模式显示相对行号，Insert 模式显示绝对行号。
没有添加 `jj` 等个人插入模式映射，Esc 和原生 Vim motions 保持默认行为。
`config/vscode/configure.sh` 会关闭 macOS 对 VS Code 的长按字符选择，以允许按住
`h/j/k/l` 连续移动；这一系统偏好变更需注销并重新登录后完全生效。

[`config/vscode/extensions.txt`](../config/vscode/extensions.txt) 记录常用扩展：
EditorConfig、Gruvbox、Vim、Go、Python、Ruff、Docker 与 ShellCheck。
`--install-packages` 会通过 `code --install-extension` 幂等安装它们；命令行
依赖由 Brewfile 或 mise 管理。

## 新增语言的配套规则

新增编程语言不能只安装编译器。每次应同时检查并记录：

1. 运行时或 SDK 及其版本管理方式（优先使用已有的 mise，系统级工具使用
   Brewfile）；
2. 维护方推荐的 VS Code 扩展，并加入 `config/vscode/extensions.txt`；
3. language server、formatter、linter、debugger 与测试工具的安装归属，避免
   VS Code 和 mise 重复管理同一工具；
4. `settings.json` 中对应的语言作用域、默认 formatter、保存动作和必要诊断；
5. 组件文档中的安装、验证、故障排查与官方链接；
6. 至少一次真实的 format/build/test 或等价 smoke test。

只声明确有个人意图且非默认的设置；扩展已经提供合适默认值时，不复制整份默认
配置。项目专属版本、build tags、lint 规则和 formatter 选项放在项目仓库，不能
污染全局 dotfiles。

## 安装与应用

先检查将发生的变化：

```sh
./setup.sh --check
```

确认没有意外替换后：

```sh
./setup.sh --install-packages --apply
```

如果 VS Code 已在安装期间运行，应用后执行 “Developer: Reload Window” 或重启
应用以载入设置。Settings Sync 属于账号数据，不由 dotfiles 自动开启。

## 验证

```sh
code --version
code --list-extensions
shellcheck --version
python3 -m json.tool config/vscode/settings.json >/dev/null
bash config/vscode/configure.sh --check
test "$(readlink "$HOME/Library/Application Support/Code/User/settings.json")" \
  = "$PWD/config/vscode/settings.json"
```

扩展列表应包含 `editorconfig.editorconfig`、`charliermarsh.ruff`、
`golang.go`、`jdinhlife.gruvbox`、`ms-azuretools.vscode-docker`、
`ms-python.python`、`timonwong.shellcheck` 和 `vscodevim.vim`（CLI 输出通常转换
为小写）。`configure.sh --check` 应显示 `ok`。

## 故障排查

- `code: command not found`：确认 Cask 已安装，重新打开终端，并检查
  `$(brew --prefix)/bin` 是否位于 `PATH`。
- 字体或图标显示异常：确认 `font-meslo-lg-nerd-font` 已由 Brewfile 安装，
  然后重启 VS Code。
- 保存时没有格式化：目标语言需要提供 formatter 的内置功能或扩展；在命令面板
  运行 “Format Document With...” 选择默认 formatter。
- ShellCheck 没有结果：运行 `shellcheck --version`，再查看 VS Code 的
  Output 面板中 ShellCheck 通道。
- 按住 `h/j/k/l` 不能连续移动：运行 `bash config/vscode/configure.sh --check`；
  应用后注销并重新登录 macOS，再重启 VS Code。
- Vim 与 VS Code 快捷键冲突：优先使用 macOS 的 Cmd 快捷键；确需把 Ctrl 组合键
  交回 VS Code 时，在 `vim.handleKeys` 中针对单个按键设为 `false`。

官方资料：

- [Visual Studio Code on macOS](https://code.visualstudio.com/docs/setup/mac)
- [User and workspace settings](https://code.visualstudio.com/docs/configure/settings)
- [Extension Marketplace](https://code.visualstudio.com/docs/configure/extensions/extension-marketplace)
- [Workspace Trust](https://code.visualstudio.com/docs/editing/workspaces/workspace-trust)
- [Command-line interface](https://code.visualstudio.com/docs/configure/command-line)
- [Gruvbox theme](https://marketplace.visualstudio.com/items?itemName=jdinhlife.gruvbox)
- [VSCodeVim](https://marketplace.visualstudio.com/items?itemName=vscodevim.vim)
