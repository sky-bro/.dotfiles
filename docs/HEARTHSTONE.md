# 炉石传说与 HSTracker

炉石传说通过战网客户端安装。HSTracker 是可选的 macOS 记牌和卡组管理工具。

## 安装

从炉石官网下载安装战网客户端，再通过战网安装游戏。然后在 dotfiles 清单中
勾选 `hstracker`，或单独安装：

```sh
brew install --cask hstracker
open -a HSTracker
```

先启动 HSTracker，再启动炉石。按应用提示选择游戏路径并检查所需的 macOS
权限与 HSReplay 上传偏好。

## 验证与排查

进入练习模式，确认记牌器能识别卡组并在出牌后更新。应用首次开启游戏日志后，
重启炉石再测试。悬浮层未显示时，检查应用设置和所需权限，然后重新启动记牌器。
游戏更新后出现兼容问题，可查看上游版本和问题列表。

- [炉石传说国服](https://hs.blizzard.cn/)
- [HSTracker](https://github.com/HearthSim/HSTracker)
- [Homebrew cask](https://formulae.brew.sh/cask/hstracker)
