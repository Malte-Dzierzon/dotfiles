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

# --- eza (ls replacement, interactive only; scripts keep /bin/ls) ---
if command -q eza
    alias ls='eza --group-directories-first --icons=auto'
    alias ll='eza -lh --group-directories-first --icons=auto --git'
    alias la='eza -la --group-directories-first --icons=auto --git'
    alias lt='eza --tree --level=2 --icons=auto --git'
    alias lta='lt -a'
end

# --- EZA_COLORS: plain ANSI names track the Noctalia-synced terminal palette ---
# (foot/kitty/Noctalia templates set the actual hues; no hex duplication here)
set -gx EZA_COLORS "di=1;34:fi=0:ex=1;32:ln=1;36:or=1;31:ur=33:uw=31:ux=1;32:gr=33:gw=31:gx=1;32:tr=33:tw=31:tx=1;32:sn=32:sb=32:nb=2;32:xa=36:gm=33:ga=32:gd=31:gc=1;31:xx=2:da=2:in=2:bl=2:hd=2;4:hl=36"

