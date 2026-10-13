{
  osConfig,
  pkgs,
  ...
}: {
  # fish belongs to the INSTALLER (~/.config/fish as a writable repo link).
  # HM module stays OFF: it would generate ~/.config/fish/config.fish and
  # thus fail ("conflicts with recursively symlinked file", config is
  # silently discarded). Repo config provides prompt + env (see
  # dotfiles/.config/fish/config.fish).
  programs.fish.enable = false;
  # Git identity from hosts/nixos/settings.nix (lysec.git).
  programs.git = {
    enable = true;
    settings.user.name = osConfig.lysec.git.name;
    settings.user.email = osConfig.lysec.git.email;
    # Empty signingKey (default) -> no signing; if set -> commit.gpgsign on.
    settings.commit.gpgsign = osConfig.lysec.git.signingKey != "";
  };
  # starship WITHOUT the HM module: binary comes from the core bundle, config as
  # repo link (dotfiles/.config/starship/starship.toml, Noctalia writes the
  # palette back). The module would generate starship.toml -> collision.
  # Init per shell manually (fish: config.fish, zsh: below).
  # Login shell is zsh (modules/nixos/user.nix) — fish stays as an interactive
  # alternative with identical defaults (repo is the source of truth for both).
  # Oh My Zsh + QoL block: ported from the laptop (.zshrc, 274 lines).
  # HM manages OMZ declaratively (no ~/.oh-my-zsh clone). fzf-tab comes as an
  # HM zsh plugin from nixpkgs; eager instead of lazy (the PC is fast enough).
  # Order: initExtraFirst (BEFORE omz) -> omz -> plugins -> initContent.
  programs.zsh = {
    enable = true;
    initExtraFirst = ''
      # Skip compaudit on every start + no update check
      # (must come BEFORE oh-my-zsh.sh).
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

      # ===== History: large + shared + no duplicates =====
      HISTSIZE=50000
      SAVEHIST=50000
      setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_VERIFY

      # ===== Behavior: automatic =====
      setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS
      ZSH_AUTOSUGGEST_STRATEGY=(history completion)
      ZSH_ALIAS_FINDER_AUTOMATIC=true

      # ===== Completion fine-tuning (MUST come after the omz source) =====
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

      # ===== EZA / files (mirrors fish config.fish; scripts keep /bin/ls) =====
      if command -v eza &>/dev/null; then
        alias ls='eza --group-directories-first --icons=auto'
        alias ll='eza -lh --group-directories-first --icons=auto --git'
        alias la='eza -la --group-directories-first --icons=auto --git'
        alias lt='eza --tree --level=2 --icons=auto --git'
        alias lta='lt -a'
      fi
      # EZA_COLORS: plain ANSI names track the Noctalia-synced terminal palette.
      export EZA_COLORS="di=1;34:fi=0:ex=1;32:ln=1;36:or=1;31:ur=33:uw=31:ux=1;32:gr=33:gw=31:gx=1;32:tr=33:tw=31:tx=1;32:sn=32:sb=32:nb=2;32:xa=36:gm=33:ga=32:gd=31:gc=1;31:xx=2:da=2:in=2:bl=2:hd=2;4:hl=36"
      if [[ "$TERM" == "xterm-kitty" ]]; then
        alias ff="fzf --preview 'case \$(file --mime-type -b {}) in image/*) kitty icat --clear --transfer-mode=memory --stdin=no --place=''${FZF_PREVIEW_COLUMNS}x''${FZF_PREVIEW_LINES}@0x0 {} ;; *) bat --style=numbers --color=always {} ;; esac'"
      else
        alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
      fi
      alias eff='$EDITOR "$(ff)"'

      # ===== Directories + git + tools =====
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
  # mpd as a user service. NOTE: the service uses a GENERATED config
  # (nix store), NOT dotfiles/.config/mpd/mpd.conf (kept as
  # reference/docs + for manual launches). Mirror the relevant values here:
  # rmpc expects 127.0.0.1:6600, audio goes over PipeWire.
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
