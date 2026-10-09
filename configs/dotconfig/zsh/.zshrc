# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# Starship übernimmt den Prompt (siehe ~/.config/starship.toml) — OMZ-Theme deaktiviert
ZSH_THEME=""

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# compaudit (compfix) bei jedem Start überspringen: spart ~0.1s, single-user NixOS braucht den Insecure-Dir-Check nicht
ZSH_DISABLE_COMPFIX="true"
zstyle ':omz:update' mode disabled  # kein Update-Check beim Start (macht `omz update` manuell)

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# fzf-tab/autosuggestions/syntax-highlighting laden lazy (siehe Block unter `source`), bleiben hier raus.
plugins=(
  git
  sudo
  command-not-found
  copyfile
  copypath
  dirhistory
  extract
  fzf
  zoxide
  gh
  docker
  systemd
  tmux
  history-substring-search
  safe-paste
)

# Hinweis: Completion-Feintuning steht weiter unten NACH `source $ZSH/oh-my-zsh.sh`,
# damit es OMZ-Defaults überschreibt (OMZ setzt eigene zstyles beim Laden).

source $ZSH/oh-my-zsh.sh
# Starship manuell (statt OMZ-Plugin): kein Spam unter TERM=dumb
if command -v starship &>/dev/null && [[ "$TERM" != "dumb" ]]; then
  eval "$(starship init zsh)"
fi
# ===== Lazy-Load: schwere Plugins erst beim ersten Befehl =====
# Prompt ist sofort da; fzf-tab/autosuggest/highlighting laden beim ersten Befehl nach.
# Tradeoff: keine Autosuggest-Vorschläge in der allerersten getippten Zeile.
_omz_lazy_plugins=(fzf-tab zsh-autosuggestions zsh-syntax-highlighting)
_omz_lazy_load() {
  add-zsh-hook -d preexec _omz_lazy_load
  unset -f _omz_lazy_load
  for _p in "${_omz_lazy_plugins[@]}"; do
    if [[ -f "$ZSH_CUSTOM/plugins/$_p/$_p.plugin.zsh" ]]; then
      source "$ZSH_CUSTOM/plugins/$_p/$_p.plugin.zsh"
    elif [[ -f "$ZSH/plugins/$_p/$_p.plugin.zsh" ]]; then
      source "$ZSH/plugins/$_p/$_p.plugin.zsh"
    fi
  done
  unset _p _omz_lazy_plugins
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _omz_lazy_load


# ===== User configuration: QoL-Basics (Omarchy-angepasst) =====

# PATH: ~/.local/bin (wie in Omarchy-Bash)
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$PATH:$HOME/.local/bin" ;;
esac

# Editor / Pager: Zed statt nano/nvim, Browser: Zen
export EDITOR="zed --wait"
export VISUAL="zed --wait"
export SUDO_EDITOR="zed --wait"
export GIT_EDITOR="zed --wait"
export BROWSER="zen"
export BAT_THEME=ansi
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# ===== History: groß + geteilt + ohne Doppel =====
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# ===== Verhalten: automatisch, ohne Shortcuts zu lernen =====
# Ordnernamen direkt tippen ohne `cd` (z.B. `Documents` + Enter)
setopt AUTO_CD
# `cd -` Verlauf merken, automatisch Dubletten ignorieren
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# Autosuggest: History + Completion
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Alias-Finder: automatisch zeigen, wenn Alias existiert
ZSH_ALIAS_FINDER_AUTOMATIC=true

# ===== Completion: Registry einmal bauen, immer wieder nutzen (MUSS nach source stehen) =====
# Dein „Registry": compinit schreibt ~/.zcompdump (einmal generiert, danach wiederverwendet).
# use-cache legt zusätzlich Ergebnisse unter ~/.oh-my-zsh/cache/completions ab.
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.oh-my-zsh/cache/completions"
# Menü mit Pfeiltasten begehbar, Gruppen benannt, Groß/Klein + Teilstücke egal
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# fzf-tab: gleiche TAB-Taste wie bisher, nur fuzzy + Vorschau statt starrer Liste
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons=auto --color=always $realpath 2>/dev/null || ls -1 $realpath'

# ===== FZF: schneller + Vorschau =====
# fd als Standard (schneller, respektiert .gitignore)
if command -v fd &>/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
fi
# CTRL+R = Verlauf, CTRL+T = Dateien, ALT+C = Ordner, **+TAB = Fuzzy-Completion
# (kommt vom OMZ fzf-Plugin via `fzf --zsh`)

# ===== EZA / Dateien (Omarchy-Stil) =====
if command -v eza &>/dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

# FZF-Dateisuche mit Vorschau (Bild direkt in Kitty, Rest mit bat)
if [[ "$TERM" == "xterm-kitty" ]]; then
  alias ff="fzf --preview 'case \$(file --mime-type -b {}) in image/*) kitty icat --clear --transfer-mode=memory --stdin=no --place=\${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES}@0x0 {} ;; *) bat --style=numbers --color=always {} ;; esac'"
else
  alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
fi
alias eff='$EDITOR "$(ff)"'

# ===== Ordner + Git + Tools (Omarchy-Stil, für ZSH entschärft) =====
# Hinweis: `z <name>` springt zu oft genutzten Ordnern (zoxide). `cd` bleibt normal.
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'
alias lg='lazygit'
alias d='docker'
alias t='tmux attach || tmux new -s Work'
n() { if [ "$#" -eq 0 ]; then command zed .; else command zed "$@"; fi; }
open() (xdg-open "$@" >/dev/null 2>&1 &)
# Zed-CLI: `zed` zeigt auf ~/.local/bin/zed (Shim auf zeditor, Systempaket)
# Bei NixOS-Rebuild ggf. Shim neu setzen: ln -sf "$(readlink -f "$(command -v zeditor)")" ~/.local/bin/zed
# Zen: Binary heißt `zen`, `zen-browser` ist ein Komfort-Symlink auf dasselbe
alias zb='zen-browser'

# Yazi: `y` wechselt nach Beenden ins zuletzt besuchte Verzeichnis (offizielle Shell-Wrapper)
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -- cwd < "$tmp"
  rm -f -- "$tmp"
  if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
}

# OMZ-Helfer: ESC 2x = sudo davor (sudo-Plugin), `alias-finder`, `aliases`, `x` = entpacken, copyfile/copypath
alias zshconfig="$EDITOR ~/.zshrc"
alias ohmyzsh="$EDITOR ~/.oh-my-zsh"
# `cat` automatisch schöner (bat), ohne Paging für kurze Dateien
if command -v bat &>/dev/null; then
  alias cat='bat --paging=never --style=plain'
fi
# Ordner erstellen + direkt reingehen (ein Befehl, kein Shortcut)
mkcd() { mkdir -p "$1" && cd "$1"; }
# Beispiele (nichts auswendig lernen, alles gleiche Tasten wie bisher):
#   sudo !!        -> letzten Befehl mit sudo
#   aliases        -> alle Aliase zeigen (aliases-Plugin ist in OMZ-Lib)
#   alias-finder git status -> zeigt dir, dass `gst` existiert
#   copyfile ~/.zshrc       -> Dateiinhalt in Clipboard
#   copypath                -> aktuellen Pfad in Clipboard
#   x archiv.zip            -> entpackt alles (extract-Plugin)
#   Alt+Links/Rechts        -> Verlauf vor/zurück (dirhistory-Plugin)
#   Hoch/Runter             -> sucht Verlauf passend zu Getipptem (history-substring-search, automatisch)
#   Einfügen per CTRL+Shift+V entschärft URLs automatisch (safe-paste, automatisch)
#   Lange Befehle melden sich per Notification (bgnotify, automatisch)

# bun completions
[ -s "/home/xealom/.bun/_bun" ] && source "/home/xealom/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# omp (Oh My Pi) completions — gecacht: `omp completions zsh` spawnt pro Start
# das ~270MB-Binary (~0.6s). Cache wird nur neu gebaut, wenn omp neuer ist.
OMP_ZSH_COMPLETIONS="$HOME/.cache/omp/completions.zsh"
if command -v omp >/dev/null 2>&1; then
  if [[ ! -s "$OMP_ZSH_COMPLETIONS" || "$(command -v omp)" -nt "$OMP_ZSH_COMPLETIONS" ]]; then
    mkdir -p "${OMP_ZSH_COMPLETIONS:h}"
    omp completions zsh >| "$OMP_ZSH_COMPLETIONS" &>/dev/null
  fi
  [[ -r "$OMP_ZSH_COMPLETIONS" ]] && source "$OMP_ZSH_COMPLETIONS"
fi
export PATH="$HOME/.opencode/bin:$PATH"

# lamps
export PATH="$PATH:/home/xealom/.lamps/bin"

export PATH="/home/xealom/.local/bin:$PATH"
