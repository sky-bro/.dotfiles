# Rust

## 个人约定与工具归属

- 全局默认使用 mise 的 `rust = { version = "latest", profile = "default", components = ["rust-src"] }`。mise 的 Rust backend 通过 rustup 安装并选择工具链；`default` profile 提供 `rustc`、Cargo、rustfmt、Clippy 和本地文档，`rust-src` 供语言服务读取标准库源码。具体项目应在自己的 `mise.toml` 中固定版本。
- 不通过 Homebrew 再安装 Rust，也不通过 VS Code 安装第二份 rustfmt 或 Clippy。Xcode Command Line Tools 提供 macOS 构建所需的 C 编译器和链接器。
- VS Code 使用 `rust-lang.rust-analyzer` 提供语言服务和保存时格式化；该扩展自带语言服务器。保存时通过工具链中的 Clippy 运行诊断。`vadimcn.vscode-lldb` 提供 LLDB 调试。调试配置放在项目的 `.vscode/launch.json`，不写入全局设置。
- Cargo 依赖、features、targets、lint 规则及格式化选项由各项目维护；全局配置只设置通用开发能力。

## 安装与应用

先运行 `./setup.sh --check`，审查所有将替换的文件。获得安装和备份授权后：

```sh
./setup.sh --install-packages --apply
exec zsh
```

setup 会安装 Brewfile 中缺失的软件、mise 工具链及扩展。已有 macOS profile 会激活 mise。重启 VS Code 或运行 “Developer: Reload Window”，使扩展读取更新后的 PATH。

## 验证

```sh
mise current rust
rustc --version
cargo --version
cargo fmt --version
cargo clippy --version
rustup component list --installed
code --list-extensions | grep -E '^(rust-lang.rust-analyzer|vadimcn.vscode-lldb)$'
```

组件列表应包含 `rustfmt`、`clippy`、`rust-src`。用临时 Cargo 项目执行一次 `cargo fmt --check`、`cargo build`、`cargo clippy --all-targets -- -D warnings` 和 `cargo test`。在 VS Code 中打开该项目，确认 rust-analyzer 诊断、保存时格式化及 CodeLLDB 断点调试。调试器的图形界面检查需在本地完成。

## 故障排查

- `rustc: command not found`：执行 `mise current rust`、`mise install rust`，再运行 `exec zsh`。从 Dock 启动的 VS Code 若仍找不到 Cargo，请重启 VS Code 并查看 rust-analyzer Output。
- 缺少标准库跳转或源码：检查 `rustup component list --installed` 中的 `rust-src`；执行 `mise install rust` 可补装配置声明的组件。
- Clippy 诊断未出现：先在终端运行 `cargo clippy`，然后查看 VS Code 的 rust-analyzer Output；`rust-analyzer.check.command` 设置为 `clippy`。
- 格式化失败：先运行 `cargo fmt --check`，确认当前工具链包含 `rustfmt`，并在 VS Code “Format Document With...” 中检查默认格式化器。
- 调试无法启动：先确认 `cargo build` 成功，再检查项目的 CodeLLDB launch 配置及 VS Code 的 CodeLLDB Output。
- 项目要求不同工具链：在项目中固定 mise 版本；若使用 `rust-toolchain.toml`，参照 mise 的 idiomatic version file 设置，避免与全局版本选择冲突。

## 官方资料

- [Rust 安装](https://rust-lang.org/tools/install/)
- [Cargo 手册](https://doc.rust-lang.org/cargo/)
- [rustup profiles](https://rust-lang.github.io/rustup/concepts/profiles.html)
- [mise Rust backend](https://mise.jdx.dev/lang/rust.html)
- [VS Code Rust 指南](https://code.visualstudio.com/docs/languages/rust)
- [rust-analyzer VS Code 扩展](https://rust-analyzer.github.io/book/vs_code.html)
- [CodeLLDB](https://github.com/vadimcn/codelldb)
