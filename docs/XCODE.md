# Xcode 与 iPadOS 开发

## 个人约定

本机安装 Mac App Store 的稳定版 Xcode，不安装 beta，也不使用第三方镜像。
Xcode 的 App Store ID 是 `497799835`，由 `Brewfile` 通过 `mas` 声明。
Command Line Tools 可以与完整 Xcode 共存，但活动开发目录应指向
`/Applications/Xcode.app/Contents/Developer`。

Apple Account、开发团队、签名证书和 provisioning profile 是敏感的本机与
云端状态，不写入 dotfiles。项目优先使用 Xcode 的 automatic signing。

## 安装

先审核普通 dotfiles 与软件包变化：

```sh
./setup.sh --check
./setup.sh --install-packages --apply
```

Xcode 由 Mac App Store 下载，体积较大。`mas` 要求已经在 App Store 登录，
并可能弹出 Touch ID 或 Apple Account 验证。认证只在 macOS 界面中完成，
不要把密码输入聊天或脚本。

若自动安装因 App Store 登录或确认而暂停，打开 Xcode 的
[Mac App Store 页面](https://apps.apple.com/app/xcode/id497799835)，完成
登录并继续下载。

## 首次配置

安装完成后，在真实终端运行：

```sh
sudo config/xcode/configure.sh --apply
```

这会选择完整 Xcode、接受许可，并安装首次启动工具。然后以普通用户检查：

```sh
config/xcode/configure.sh --check
```

如果没有列出可用的 iOS Simulator runtime：

```sh
config/xcode/configure.sh --download-ios
```

该下载可能很大。也可以在 Xcode 的 **Settings → Components** 中选择需要的
iOS Simulator 版本；不默认下载 watchOS、tvOS 或 visionOS runtime。

## Apple Account 与签名

打开 Xcode 的 **Settings → Accounts**，登录 Apple Account。账户密码和双重
认证只在 Xcode 的系统界面中输入。

创建项目后：

1. 在 target 的 **Signing & Capabilities** 选择正确的 Team；
2. 保持 **Automatically manage signing** 开启；
3. 使用反向域名格式且唯一的 Bundle Identifier；
4. 只添加项目确实需要的 capability。

普通 Apple Account 可用于受限的本机开发测试。TestFlight 和 App Store
发布需要有效的 Apple Developer Program 成员资格。

## iPad 真机

用 USB 首次连接 iPad，在两端确认信任关系。在 iPad 的
**设置 → 隐私与安全性 → 开发者模式** 中启用 Developer Mode，并按设备提示
重启和确认。之后在 Xcode 的运行目标中选择该 iPad。

Developer Mode 只用于运行开发签名的构建，不影响 App Store 或 TestFlight
安装。

## 验证

```sh
xcode-select -p
xcodebuild -version
xcrun swift --version
xcrun --sdk iphoneos --show-sdk-version
xcrun simctl list runtimes
config/xcode/configure.sh --check
```

活动目录应为 `/Applications/Xcode.app/Contents/Developer`。Xcode 版本和
SDK 版本可能不同，这是 Apple 发布方式的正常结果。

## 故障排查

- `tool 'xcodebuild' requires Xcode`：活动目录仍指向 Command Line Tools，
  运行 `sudo config/xcode/configure.sh --apply`。
- App Store 要求登录或 Touch ID：只在本机系统界面完成认证，然后重新运行
  `mas install 497799835` 或 `brew bundle`。
- `Agreeing to the Xcode/iOS license requires admin privileges`：在真实终端用
  `sudo` 运行配置脚本。
- iPad 不出现在运行目标：解锁设备、确认信任关系、检查数据线，并确认
  Developer Mode 已开启。
- Simulator runtime 不可用：运行
  `config/xcode/configure.sh --download-ios`，或通过 Xcode Components 下载。

## 官方资料

- [Xcode support and compatibility](https://developer.apple.com/support/xcode/)
- [Xcode system requirements](https://developer.apple.com/xcode/system-requirements/)
- [Xcode documentation](https://developer.apple.com/documentation/xcode)
- [Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)
- [Certificates overview](https://developer.apple.com/help/account/certificates/certificates-overview/)
- [Provisioning profiles](https://developer.apple.com/help/account/provisioning-profiles/)
