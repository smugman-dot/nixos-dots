{
  config,
  pkgs,
  inputs,
  ...
}:
let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    niri = "niri";
    swayimg = "swayimg";
    fastfetch = "fastfetch";
  };
in
{
  imports = [
    inputs.spicetify-nix.homeManagerModules.default
    inputs.noctalia.homeModules.default
    ./zsh.nix
    ./kitty.nix
    ./helix.nix
    ./mpv.nix
  ];
  home.username = "walid";
  home.homeDirectory = "/home/walid";
  home.stateVersion = "26.05";
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "thorium.desktop" ];
      "x-scheme-handler/http" = [ "thorium.desktop" ];
      "x-scheme-handler/https" = [ "thorium.desktop" ];
      "x-scheme-handler/about" = [ "thorium.desktop" ];
      "x-scheme-handler/unknown" = [ "thorium.desktop" ];

      "text/plain" = [ "Helix.desktop" ];
      "application/markdown" = [ "Helix.desktop" ];

      "audio/mpeg" = [ "mpv.desktop" ];
      "audio/ogg" = [ "mpv.desktop" ];
      "audio/flac" = [ "mpv.desktop" ];
      "audio/mp4" = [ "mpv.desktop" ];
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];
      "video/quicktime" = [ "mpv.desktop" ];

      "image/jpeg" = [ "swayimg.desktop" ];
      "image/png" = [ "swayimg.desktop" ];
      "image/gif" = [ "swayimg.desktop" ];
      "image/webp" = [ "swayimg.desktop" ];
      "image/svg+xml" = [ "swayimg.desktop" ];
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [
      "--cmd cd"
    ];
  };
  programs.git = {
    enable = true;
    settings = {
      user.name = "smugman-dot";
      user.email = "wbsmoke101@gmail.com";
      init.defaultBranch = "main";
      credential.helper = [
        "store"
        "oauth"
      ];
    };
  };
  programs.spicetify =
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      enable = true;
      enabledExtensions = with spicePkgs.extensions; [
        adblock
        hidePodcasts
        shuffle
        spicy-lyrics
      ];
      enabledCustomApps = with spicePkgs.apps; [
        marketplace
      ];
    };

  home.pointerCursor = {
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
  home.file.".local/share/Steam/compatibilitytools.d/proton-cachyos".source =
    "${pkgs.proton-cachyos-x86_64_v3}/share/steam/compatibilitytools.d/proton-cachyos-x86_64-v3";
  xdg.configFile = (
    builtins.mapAttrs (name: value: {
      source = create_symlink "${dotfiles}/${value}";
    }) configs
  );

  home.packages = with pkgs; [
    ripgrep
    swayimg
    htop
    python3Packages.python-lsp-server
    python3Packages.pylsp-mypy
    python3Packages.pylsp-rope
    python3Packages.python-lsp-black
    black
    eza
    btop
    dua
    aria2
    git-credential-oauth
    fastfetch
    pavucontrol
    umu-launcher
    playerctl
    qbittorrent
    wl-clipboard
    nwg-look
    nil
    ffmpeg
    nixfmt
    # vtsls
    # prettier
    ruff
    nixpkgs-fmt
    zoxide
    yazi
    nodejs
    gcc
    rofi
  ];
}
