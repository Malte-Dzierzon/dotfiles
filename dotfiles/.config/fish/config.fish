function fish_greeting
    set_color white
    echo '    _   _            _        ___    '
    echo '   / | / /___  _____/ /_____ _/ (_)___ _'
    echo '  /  |/ / __ \/ ___/ __/ __ `/ / / __ `/'
    echo ' / /|  / /_/ / /__/ /_/ /_/ / / / /_/ / '
    echo '/_/ |_/\____/\___/\__/\__,_/_/_/\__,_/  '
    set_color normal
    echo

    fastfetch
end

# --- Defaults: Zed + Zen (statt nano/firefox) ---
set -gx EDITOR "zeditor --wait"
set -gx VISUAL "zeditor --wait"
set -gx SUDO_EDITOR "zeditor --wait"
set -gx GIT_EDITOR "zeditor --wait"
set -gx BROWSER zen
set -gx TERMINAL foot
fish_add_path -P $HOME/.local/bin

# --- Starship Prompt ---
if command -q starship
  starship init fish | source
end

# --- direnv (nix-direnv, systemweit an) ---
if command -q direnv
  direnv hook fish | source
end

