# =============================================================================
# zsh.nix - Home Manager module, translated from ~/.zshrc
#
# Usage: import this from home.nix, e.g.
#   { ... }: { imports = [ ./zsh.nix ]; }
# or merge its attributes straight into home.nix. Works fine with
# home-manager run standalone on a non-NixOS distro too.
# =============================================================================
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [ ./starship.nix ];
  # ---------------------------------------------------------------------
  # [1] Environment Variables & PATH
  # ---------------------------------------------------------------------
  home.sessionVariables = {
    TERMINAL = "kitty";
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";
    EDITOR = "hx";
    VISUAL = "hx";
    MAKEFLAGS = "-j$(nproc)";
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=60";
  };

  home.sessionPath = [
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
    "/opt/thorium-browser"
  ];

  # ---------------------------------------------------------------------
  # [2] History
  # ---------------------------------------------------------------------
  programs.zsh.history = {
    size = 50000;
    save = 25000;
    path = "${config.home.homeDirectory}/.zsh_history";
    append = true;
    share = true;
    ignoreDups = true;
    ignoreSpace = true;
    expireDuplicatesFirst = true;
  };

  # ---------------------------------------------------------------------
  # [3] + [4] Completion, keybindings, shell options
  # ---------------------------------------------------------------------
  programs.zsh.defaultKeymap = "viins"; # bindkey -v

  programs.zsh.initContent = lib.mkMerge [
    # Must run before Home Manager's own compinit call (order 570)
    (lib.mkOrder 550 ''
      setopt EXTENDED_GLOB

      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*:descriptions' format '%B%F{yellow}%d%f%b'
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
    '')

    # Same slot the old `initExtra` occupied
    (lib.mkOrder 1000 ''
      setopt HIST_VERIFY
      setopt INTERACTIVE_COMMENTS
      setopt GLOB_DOTS
      setopt NO_CASE_GLOB
      setopt AUTO_PUSHD
      setopt PUSHD_IGNORE_DUPS

      export KEYTIMEOUT=1

      autoload -U edit-command-line
      zle -N edit-command-line
      bindkey -M vicmd v edit-command-line

      autoload -U history-search-end
      zle -N history-beginning-search-backward-end history-search-end
      zle -N history-beginning-search-forward-end history-search-end
      bindkey "''${terminfo[kcuu1]:-^[[A}" history-beginning-search-backward-end
      bindkey "''${terminfo[kcud1]:-^[[B}" history-beginning-search-forward-end

      # -------------------------------------------------------------
      # [5] eza (conditional - kept manual to preserve exact fallback)
      # -------------------------------------------------------------
      if command -v eza >/dev/null; then
          alias ls='eza --icons --group-directories-first'
          alias ll='eza --icons --group-directories-first -l --git'
          alias la='eza --icons --group-directories-first -la --git'
          alias lt='eza --icons --group-directories-first --tree --level=2'
      else
          alias ls='ls --color=auto'
          alias ll='ls -lh'
          alias la='ls -A'
      fi

      # -------------------------------------------------------------
      # [5] Functions
      # -------------------------------------------------------------
      function y() {
          local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
          yazi "$@" --cwd-file="$tmp"
          if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
              builtin cd -- "$cwd"
          fi
          rm -f -- "$tmp"
      }

      sudo() {
          case "$1" in
              nvim|hx|helix)
                  shift
                  [[ $# -gt 0 ]] || {
                      echo "Error: sudoedit requires a filename."
                      return 1
                  }
                  EDITOR=hx command sudoedit "$@"
                  ;;
              *)
                  command sudo "$@"
                  ;;
          esac
      }

      mkcd() {
        mkdir -p "$1" && cd "$1"
      }

      # -------------------------------------------------------------
      # [6] External modules - unmanaged, still loaded from disk
      # -------------------------------------------------------------
      local conf_dir="$HOME/.config/zshrc"
      local -a my_modules=(
          batstat git kvm lmstudio logs logs_old mon_info
          pkg res_mon vfio waydroid win10 wthr cmd_atlas
          sshfile scripts neovim_delta
      )

      for mod in "''${my_modules[@]}"; do
          [[ -f "$conf_dir/$mod" ]] && source "$conf_dir/$mod"
      done

      unset conf_dir my_modules mod
    '')
  ];

  # ---------------------------------------------------------------------
  # [5] Simple aliases (native)
  # ---------------------------------------------------------------------
  programs.zsh.shellAliases = {
    cp = "cp -iv";
    mv = "mv -iv";
    rm = "rm -I";
    ln = "ln -v";
    df = "df -hT";
    nvim = "helix";
    diff = "delta --side-by-side";
    grep = "grep --color=auto";
    egrep = "egrep --color=auto";
    fgrep = "fgrep --color=auto";
  };

  # ---------------------------------------------------------------------
  # [7] Prompt & tool integration
  # replaces the manual self-healing cache logic entirely - Nix bakes
  # these init scripts into the store at build time, nothing to
  # regenerate at shell startup.
  # ---------------------------------------------------------------------
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # ---------------------------------------------------------------------
  # [8] Plugins
  # autosuggestions-before-syntax-highlighting ordering is handled
  # automatically when both use native options - no "must be last" rule
  # to maintain by hand.
  # ---------------------------------------------------------------------
  programs.zsh.enable = true;
  programs.zsh.autosuggestion.enable = true;
  programs.zsh.syntaxHighlighting.enable = true;
}
