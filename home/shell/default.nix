{
  osConfig,
  pkgs,
  ...
}: {
  # fish gehoert dem INSTALLER (~/.config/fish als beschreibbarer Repo-Link).
  # HM-Modul bleibt AUS: es wuerde ~/.config/fish/config.fish generieren und
  # damit bauen ("conflicts with recursively symlinked file", Config wird
  # still verworfen). Repo-config versorgt Prompt + Env (siehe
  # dotfiles/.config/fish/config.fish).
  programs.fish.enable = false;
  # Git-Identitaet aus hosts/nixos/settings.nix (lysec.git).
  programs.git = {
    enable = true;
    settings.user.name = osConfig.lysec.git.name;
    settings.user.email = osConfig.lysec.git.email;
    # signingKey leer (Default) -> kein Signieren; gesetzt -> commit.gpgsign an.
    settings.user.signingkey = osConfig.lysec.git.signingKey;
    settings.commit.gpgsign = osConfig.lysec.git.signingKey != "";
  };
  # starship OHNE HM-Modul: Binary kommt aus dem core-Bundle, Config als
  # Repo-Link (dotfiles/.config/starship/starship.toml, Noctalia schreibt
  # Palette zurueck). Das Modul wuerde starship.toml generieren -> Kollision.
  # Init je Shell manuell (fish: config.fish, zsh: unten).
  # Login-Shell ist zsh (modules/nixos/user.nix) — fish bleibt als interaktive
  # Alternative mit identischen Defaults (Repo = Wahrheit fuer beide).
  # Oh My Zsh + QoL-Block: portiert aus Laptop (.zshrc, 274 Zeilen).
  # HM verwaltet OMZ deklarativ (kein ~/.oh-my-zsh-Clone). fzf-tab kommt als
  # HM-zsh-Plugin aus nixpkgs; eager statt lazy (PC ist schnell genug).
  # Reihenfolge: initExtraFirst (VOR omz) -> omz -> Plugins -> initContent.
  programs.zsh = {
    enable = true;
    initExtraFirst = ''
      # compaudit bei jedem Start ueberspringen + kein Update-Check
      # (muss VOR oh-my-zsh.sh stehen).
      export ZSH_DISABLE_COMPFIX="true"
    '';
    oh-my-zsh = {
      enable = true;
      theme = "";
      plugins = [
        "git"
        "sudo"
        "command-not-found"
        "copyfile"
        "copypath"
        "dirhistory"
        "extract"
        "fzf"
        "zoxide"
        "gh"
        "docker"
        "systemd"
        "tmux"
        "history-substring-search"
        "safe-paste"
      ];
    };
    autosuggestion = {
      enable = true;
      strategy = ["history" "completion"];
    };
    syntaxHighlighting.enable = true;
    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];
    initContent = ''
      export EDITOR="zeditor --wait"
      export VISUAL="zeditor --wait"
      export SUDO_EDITOR="zeditor --wait"
      export GIT_EDITOR="zeditor --wait"
      export BROWSER=zen
      export TERMINAL=foot
      export PATH="$HOME/.local/bin:$PATH"
      export BAT_THEME=ansi
      export MANROFFOPT="-c"
      export MANPAGER="sh -c 'col -bx | bat -l man -p'"
      command -v starship >/dev/null 2>&1 && [[ "$TERM" != "dumb" ]] && eval "$(starship init zsh)"
      command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

      # ===== History: gross + geteilt + ohne Doppel =====
      HISTSIZE=50000
      SAVEHIST=50000
      setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_VERIFY

      # ===== Verhalten: automatisch =====
      setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS
      ZSH_AUTOSUGGEST_STRATEGY=(history completion)
      ZSH_ALIAS_FINDER_AUTOMATIC=true

      # ===== Completion-Feintuning (MUSS nach omz-source stehen) =====
      [[ -d "$HOME/.oh-my-zsh/cache/completions" ]] || mkdir -p "$HOME/.oh-my-zsh/cache/completions"
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "$HOME/.oh-my-zsh/cache/completions"
      zstyle ':completion:*' menu select
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*:descriptions' format '[%d]'
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':fzf-tab:*' use-fzf-default-opts yes
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons=auto --color=always $realpath 2>/dev/null || ls -1 $realpath'

      # ===== FZF env =====
      if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
      fi

      # ===== EZA / Dateien =====
      if command -v eza &>/dev/null; then
        alias ls='eza -lh --group-directories-first --icons=auto'
        alias lsa='ls -a'
        alias lt='eza --tree --level=2 --long --icons --git'
        alias lta='lt -a'
      fi
      if [[ "$TERM" == "xterm-kitty" ]]; then
        alias ff="fzf --preview 'case \$(file --mime-type -b {}) in image/*) kitty icat --clear --transfer-mode=memory --stdin=no --place=''${FZF_PREVIEW_COLUMNS}x''${FZF_PREVIEW_LINES}@0x0 {} ;; *) bat --style=numbers --color=always {} ;; esac'"
      else
        alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
      fi
      alias eff='$EDITOR "$(ff)"'

      # ===== Ordner + Git + Tools =====
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
      alias zb='zen'
      n() { if [ "$#" -eq 0 ]; then command zed .; else command zed "$@"; fi; }
      open() (xdg-open "$@" >/dev/null 2>&1 &)
      y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        command yazi "$@" --cwd-file="$tmp"
        IFS= read -r -- cwd < "$tmp"
        rm -f -- "$tmp"
        if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
      }
      if command -v bat &>/dev/null; then
        alias cat='bat --paging=never --style=plain'
      fi
      mkcd() { mkdir -p "$1" && cd "$1"; }
    '';
  };
  # mpd als User-Service. ACHTUNG: der Service nutzt eine GENERIERTE Config
  # (nix store), NICHT dotfiles/.config/mpd/mpd.conf (diese bleibt als
  # Referenz/Doku + fuer manuelle Launches). Relevante Werte hier spiegeln:
  # rmpc erwartet 127.0.0.1:6600, Audio geht ueber PipeWire.
  services.mpd = {
    enable = true;
    musicDirectory = "~/Music";
    network.port = 6600;
    extraConfig = ''
      audio_output {
          type "pipewire"
          name "PipeWire"
      }
    '';
  };
}
