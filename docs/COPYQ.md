# CopyQ

## 个人配置

仓库只管理可移植设置和自定义命令：

- 登录启动、Vi 导航、tab 树和条目计数；
- `Control+Option+H` 显示或隐藏窗口；
- `Control+Option+S` 保存所选内容；
- `Control+Option+M` 用最近两条历史生成并粘贴 Markdown 链接；
- 自动把图片归入 `Images` tab。

剪贴板历史、tab 内容、窗口状态和 macOS 权限不进入仓库。

命令保存在 [`config/copyq/commands.ini`](../config/copyq/commands.ini)。
重复应用时只替换同名命令，保留其他用户命令。

### 粘贴 Markdown 链接

依次复制链接/文件路径和显示文本（顺序不限），然后在目标应用按
`Control+Option+M`。命令读取 clipboard tab 最新两条记录并粘贴：

```text
[显示文本](链接或文件 URI)
```

若两条中只有一条像 URL、`file:` URI、绝对/`~`/相对路径，命令会自动识别；
若两条都像链接或都不像，默认最新一条为显示文本、上一条为目标。Finder 复制的
文件优先读取 `text/uri-list`，普通绝对路径会转换为百分号编码的 `file://` URI。
标题中的反斜杠和方括号会转义；目标中的空格、圆括号、尖括号等字符会使用百分号
编码，因此结果不需要额外的尖括号包裹。生成内容由 CopyQ 标记为自身
写入，不会形成第三条历史记录。

实现位于 [`config/copyq/markdown-link.js`](../config/copyq/markdown-link.js)，
`configure.sh` 在导入命令时注入脚本的实际仓库路径，所以仓库不必固定克隆到
`~/.dotfiles`。

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
/Applications/CopyQ.app/Contents/MacOS/CopyQ eval \
  'commands().some(function(c) {
    return c.name == "Paste Markdown Link"
      && c.globalShortcuts.indexOf("ctrl+alt+m") >= 0
  })'
```

预期依次为 `1`、`true`、`true`、`true`、`true`。

再从其他应用测试 `Control+Option+H`，并用合成的非敏感文本测试
`Control+Option+M`。不要把真实口令、token 或其他敏感剪贴板内容用于测试。

## 故障排查

- `Cannot connect to server`：启动 CopyQ 后重试；
- 命令有效但快捷键无效：检查辅助功能权限与快捷键冲突，然后重启 CopyQ；
- Markdown 的标题/目标顺序不符合预期：当两条都像路径或都不像路径时，先复制
  目标，再复制显示文本；
- Finder 文件没有生成 `file://`：在 CopyQ 的内容对话框确认该条目仍包含
  `text/uri-list`，否则命令只能使用其纯文本表示；
- 日志：`~/Library/Application Support/copyq/copyq/`。

## 官方资料

- [CopyQ documentation](https://copyq.readthedocs.io/)
- [CopyQ scripting API](https://copyq.readthedocs.io/en/stable/scripting-api.html)
- [CopyQ command examples](https://copyq.readthedocs.io/en/stable/command-examples.html)
- [CopyQ repository](https://github.com/hluk/CopyQ)
- [Homebrew CopyQ cask](https://formulae.brew.sh/cask/copyq)
