# VLC 播放器

使用 VLC 播放本地音视频和网络媒体，由 Homebrew 的稳定版 cask 管理。
应用安装在 `/Applications/VLC.app`，播放偏好设置由应用管理。

## 安装与部署

VLC 已记录在 `Brewfile` 中，完整部署使用仓库标准流程。
仅安装 VLC 时运行：

```sh
env -u HOMEBREW_API_DOMAIN -u HOMEBREW_BOTTLE_DOMAIN \
    -u HOMEBREW_BREW_GIT_REMOTE -u HOMEBREW_CORE_GIT_REMOTE \
    brew install --cask vlc
```

不需要创建 dotfiles 链接。通过应用程序文件夹或 Spotlight 打开 VLC。

## 验证

```sh
brew list --cask --versions vlc
/Applications/VLC.app/Contents/MacOS/VLC --version
```

打开一个本地媒体文件，确认画面和声音正常。

## 故障排查

若下载失败，检查网络连接并重试上述安装命令，使用官方来源。
若 Homebrew 报告已有同名应用，先确认现有安装来源，再决定是否迁移，
不要自动覆盖。播放异常时先检查 VLC 的音轨、字幕和输出设备选择。

## 官方资料

- [VideoLAN VLC](https://www.videolan.org/vlc/)
- [VLC macOS 下载](https://www.videolan.org/vlc/download-macosx.html)
- [Homebrew VLC cask](https://formulae.brew.sh/cask/vlc)
