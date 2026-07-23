local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Keep the terminal aligned with the light Gruvbox theme used elsewhere.
config.color_scheme = "GruvboxLight"

-- Meslo is installed by Brewfile and contains the glyphs used by Powerlevel10k.
-- WezTerm appends its built-in fallback fonts for emoji and missing glyphs.
config.font_dirs = { wezterm.home_dir .. "/Library/Fonts" }
config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size = 20.0
config.line_height = 1.05

config.initial_cols = 120
config.initial_rows = 32
config.window_padding = {
  left = 10,
  right = 10,
  top = 8,
  bottom = 8,
}

config.scrollback_lines = 10000
config.enable_scroll_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_max_width = 32

config.audible_bell = "Disabled"
config.default_cursor_style = "SteadyBlock"
config.use_ime = true

-- Keep WezTerm's default shortcuts. In particular, do not introduce a leader
-- key that would conflict with the Ctrl-a prefix used by tmux.

return config
