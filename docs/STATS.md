# Stats

## 个人约定

Stats 只承担菜单栏实时网络吞吐显示，避免与 macOS 自带项目以及其他监控
工具重复。默认只启用 Network 模块，以字节每秒显示上传和下载速度；网卡由
应用自动检测，以便在 Wi-Fi、以太网和 VPN 之间切换。

应用偏好由 Stats 自身管理。仓库不直接写入 `eu.exelban.Stats` 的内部
defaults 键，因为这些键不是稳定的公开配置接口，并且部分菜单栏状态由
macOS 单独保存。

## 安装与首次配置

Stats 由 [`Brewfile`](../Brewfile) 管理。按仓库标准流程安装：

```sh
./setup.sh --check
./setup.sh --install-packages --apply
```

首次启动 Stats 后：

1. 在模块列表中只启用 **Network**；按需关闭 CPU、GPU、RAM、Disk、
   Sensors、Battery、Bluetooth、Clock 和 Remote。
2. 为 Network 选择 **Speed** 菜单栏组件，同时显示 upload 与 download。
3. Reader type 使用 **Interface**，Network interface 使用
   **Autodetection**。
4. Base 使用 **Byte**，Units 使用自动单位；保留 1 秒刷新间隔。
5. 不启用 Public IP 自动刷新；它对实时吞吐无帮助，并会产生额外外部请求。
6. 开启登录时启动。若登录后不稳定，先关闭此项并手动启动，再检查上游
   issue。

在刘海屏或菜单栏空间紧张的 MacBook 上，可启用阈值隐藏功能，或只显示
download；按住 Command 拖动菜单栏项目可以调整位置。

macOS 26 及之后若 Stats 正在运行但菜单栏没有任何项目，打开 **系统设置 →
菜单栏**，明确允许 Stats 显示菜单栏项目。

## 验证

```sh
test -d /Applications/Stats.app
pgrep -x Stats
defaults read eu.exelban.Stats Network_state
defaults read eu.exelban.Stats Network_base
```

随后下载一个已知的大文件，确认菜单栏 download 数值上升；上传文件时确认
upload 数值上升。点击网络项目，确认弹窗中的网卡与当前连接一致。

## 故障排查

- 一直显示 0：在 Network 设置中保持 Interface + Autodetection；若只在
  VPN 下出现，尝试 VPN mode 或明确选择对应的 `utun` 接口。
- 菜单栏不显示：确认 Network 模块和 Speed 组件已启用，再检查系统的菜单栏
  权限以及可用空间。
- 登录时崩溃：关闭登录时启动并改为登录后手动启动，升级到最新稳定版后再
  测试。
- 卸载时使用 Stats 应用内附带的卸载脚本，确保一并移除它可能安装的 SMC
  helper；不要只删除应用后遗留特权 helper。

## 官方资料

- [Stats 项目与安装说明](https://github.com/exelban/stats)
- [Homebrew Formulae: stats](https://formulae.brew.sh/cask/stats)
