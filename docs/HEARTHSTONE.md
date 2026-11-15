# 炉石传说与 HSTracker

## 个人约定

在 Mac 上使用网易国服《炉石传说》，以 HSTracker 作为记牌与卡组管理工具。
游戏与战网由官方安装器管理，HSTracker 由 Homebrew 管理并记录在 `Brewfile`。
Windows 的 Hearthstone Deck Tracker（HDT）不用于本机。

## 安装与使用

单独安装记牌器，不必部署其他 dotfiles：

```sh
env -u HOMEBREW_API_DOMAIN -u HOMEBREW_BOTTLE_DOMAIN \
    -u HOMEBREW_BREW_GIT_REMOTE -u HOMEBREW_CORE_GIT_REMOTE \
    brew install --cask hstracker
open -a HSTracker
```

整机安装仍按 [macOS Setup](MACOS-SETUP.md) 先检查、审核替换，再执行
`./setup.sh --install-packages --apply`。

先启动 HSTracker，再启动炉石。首次启动按应用提示设置游戏路径及系统权限；
需要用户在本机界面确认的权限不自动授予。检查 HSReplay 对局上传选项，
按自己的偏好设置。使用网易国服时，实际进游戏验证识别与悬浮窗。

## 验证

```sh
brew list --cask --versions hstracker
test -d /Applications/HSTracker.app
open -a HSTracker
```

进入一局练习模式，确认能识别当前卡组、显示剩余卡牌，并在出牌后更新。
安装成功与对局识别成功分开验证。

2026-11-06 本机安装 3.7.3，确认包含 arm64 架构且可启动。首次启动提示
`You must restart Hearthstone for logs to be used`，需重启炉石后再验证记牌。
额外运行 `codesign --verify --deep --strict /Applications/HSTracker.app`
返回非零，原文为 `invalid signature (code or signature have been modified)`，
`In architecture: arm64`。没有修改签名或关闭系统安全保护；能启动不代表
签名验证通过。后续版本可再次核验，并向上游核查。

## 故障排查

- 更新炉石后不识别：退出游戏和记牌器，更新 HSTracker，再先开记牌器后开游戏。
- 没有悬浮窗：检查应用内显示选项、游戏路径，以及系统设置中应用请求的权限。
- 开关均开启仍不显示：检查「系统设置 → 隐私与安全性 → 辅助功能」中
  HSTracker 的状态。2026-11-06 本机权限已开启，但旧进程曾记录
  `SizeHelper.reload() - Accessability error: -25204` 且没有开始跟踪。
  退出并重新启动 **HSTracker** 后恢复，无需退出正在进行的炉石对局；
  日志出现 `Start Tracking`，并实际显示战棋胜率、回合及随从种族悬浮层。
- HSReplay 上传失败：检查网络与账号连接；不要把上传成功作为本地记牌可用的前提。
- 国服或新补丁兼容问题：查看上游 releases 与 issues，不安装来源不明的修改版。
- 参加比赛前查看具体赛事规则，部分比赛禁止记牌器。

## 官方资料

- [HSTracker 项目与使用说明](https://github.com/HearthSim/HSTracker)
- [HSTracker releases](https://github.com/HearthSim/HSTracker/releases)
- [HSTracker issues](https://github.com/HearthSim/HSTracker/issues)
- [Homebrew cask](https://formulae.brew.sh/cask/hstracker)
- [炉石传说国服](https://hs.blizzard.cn/)
