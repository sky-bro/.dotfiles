# WezTerm

## 个人约定

- 使用 WezTerm 内置的 `GruvboxLight`（也称 Gruvbox Light）配色；
- 使用 `MesloLGS Nerd Font Mono`，与 Powerlevel10k 的图标字体保持一致；
- 默认窗口为 120 × 32，保留少量边距，并为每个 tab 保存 10,000 行回滚；
- 仅有一个 tab 时隐藏 tab bar，关闭声音提示；
- 启用 macOS 输入法（IME），方便直接输入中文；
- 保留 WezTerm 默认快捷键，不设置 leader，避免与 tmux 的 `Ctrl-a` 冲突。

配置入口是
[`profiles/macos/wezterm.lua`](../profiles/macos/wezterm.lua)，setup 将它链接为
`~/.wezterm.lua`。WezTerm 会自动重载，也可按 `Ctrl-Shift-R` 强制重载。

## 安装与应用

```sh
./setup.sh --check
./setup.sh --install-packages --apply
```

## 验证

```sh
wezterm --version
wezterm --config-file ~/.wezterm.lua show-keys >/dev/null
wezterm ls-fonts | sed -n '1,20p'
```

Primary font 应为 `MesloLGS Nerd Font Mono`。同时检查中文输入和
Powerlevel10k 图标。

## 调整与故障排查

- 当前字号为 20；按屏幕和观看距离调整 `font_size`；
- 需要更柔和或更硬的浅色背景时，可把 `color_scheme` 改为
  `Gruvbox light, soft (base16)` 或 `Gruvbox light, hard (base16)`；
- 字体找不到时运行 `wezterm ls-fonts --list-system`，并确认 Brewfile 字体已安装；
- 修改 `use_ime` 后彻底退出并重启 WezTerm。

## 官方资料

- [配置文件与自动重载](https://wezterm.org/config/files.html)
- [字体与 fallback](https://wezterm.org/config/fonts.html)
- [Gruvbox Light 配色](https://wezterm.org/colorschemes/g/index.html)
- [回滚缓冲区](https://wezterm.org/scrollback.html)
- [macOS 输入法](https://wezterm.org/config/lua/config/use_ime.html)
