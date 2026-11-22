# Kill Window

在 macOS 上点选窗口，核对进程名称、PID 和可执行文件路径后确认强制退出。
强制退出会关闭该进程的所有窗口，未保存的内容可能丢失。工具会在发送信号前
再次核对窗口与进程身份，并拒绝结束受保护的桌面组件。

## 使用

macOS 需要 Xcode 或 Command Line Tools 提供的 Swift 工具链。在仓库根目录执行：

```sh
bin/kill-window.sh             # 点选并确认
bin/kill-window.sh --dry-run   # 点选并查看进程身份
bin/kill-window.sh --list      # 列出可见窗口的进程与位置
```

点选时按 Esc 或右键取消。助手在首次运行时编译并缓存。在图形会话中启动可读取
窗口元数据。工具使用自己的选择覆盖层，不要求辅助功能或输入监控权限。

Linux/i3 使用同一入口，通过 `xprop` 读取点选窗口的 PID 并立即结束进程。
需要 `xprop` 和 `notify-send`。

## 验证与开发

```sh
xcrun swift-format lint --strict config/kill-window/WindowPicker.swift
bin/kill-window.sh --build
bin/kill-window.sh --self-test
vicinae script check config/vicinae/scripts/kill-window.sh
```

自测使用自行创建的子进程。验证点选界面时可先运行 `--dry-run`。构建失败时
运行 `xcrun --find swiftc` 确认工具链，或参考 [Xcode 手册](XCODE.md)。

官方 VS Code Swift 扩展提供编辑器集成。编译器、SourceKit-LSP、swift-format
和 LLDB 由 Apple 工具链提供。仓库的 VS Code 配置使用该扩展格式化 Swift 文件。
此工具用 `--self-test` 验证，SwiftPM 项目可用扩展的测试发现或 `swift test`。

- [Core Graphics 窗口列表](https://developer.apple.com/documentation/coregraphics/cgwindowlistcopywindowinfo(_:_:))
- [Swift VS Code 扩展](https://github.com/swiftlang/vscode-swift)
- [Vicinae Script Commands](https://docs.vicinae.com/scripts/getting-started)
