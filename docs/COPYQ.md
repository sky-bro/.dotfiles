# CopyQ

## 个人配置

仓库只管理可移植设置和自定义命令：

- 登录启动、Vi 导航、tab 树和条目计数；
- `Control+Option+H` 显示或隐藏窗口；
- `Control+Option+S` 保存所选内容；
- 自动把图片归入 `Images` tab。

剪贴板历史、tab 内容、窗口状态和 macOS 权限不进入仓库。

命令保存在 [`config/copyq/commands.ini`](../config/copyq/commands.ini)。
重复应用时只替换同名命令，保留其他用户命令。

## 安装与应用

```sh
./setup.sh --check
./setup.sh --install-packages --apply
```

仅重新应用 CopyQ：

```sh
bash config/copyq/configure.sh
```

## macOS 权限

全局快捷键和粘贴历史需要辅助功能权限：

1. 打开“系统设置 → 隐私与安全性 → 辅助功能”；
2. 添加并启用 `/Applications/CopyQ.app`；
3. 完全退出并重启 CopyQ。

## 签名异常

setup 不会绕过 Gatekeeper。仅在确认安装来源可信且 macOS 报
`Code Signature Invalid` 时修复该应用：

```sh
xattr -dr com.apple.quarantine /Applications/CopyQ.app
codesign --force --deep --sign - /Applications/CopyQ.app
codesign --verify --deep --strict --verbose=2 /Applications/CopyQ.app
open -a CopyQ
```

这是本地 ad-hoc 签名，应用更新后可能需要重做。

## 验证

```sh
/Applications/CopyQ.app/Contents/MacOS/CopyQ --version
/Applications/CopyQ.app/Contents/MacOS/CopyQ config navigation_style
/Applications/CopyQ.app/Contents/MacOS/CopyQ config tab_tree
/Applications/CopyQ.app/Contents/MacOS/CopyQ config show_tab_item_count
/Applications/CopyQ.app/Contents/MacOS/CopyQ config autostart
```

预期依次为 `1`、`true`、`true`、`true`。

再从其他应用测试 `Control+Option+H`。

## 故障排查

- `Cannot connect to server`：启动 CopyQ 后重试；
- 命令有效但快捷键无效：检查辅助功能权限与快捷键冲突，然后重启 CopyQ；
- 日志：`~/Library/Application Support/copyq/copyq/`。

## 官方资料

- [CopyQ documentation](https://copyq.readthedocs.io/)
- [CopyQ repository](https://github.com/hluk/CopyQ)
- [Homebrew CopyQ cask](https://formulae.brew.sh/cask/copyq)
