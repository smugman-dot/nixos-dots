{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-x86_64-v3;

  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [
    "mitigations=off"
    "nowatchdog"
    "nmi_watchdog=0"
    "quiet"
    "splash"
    "nvidia_drm.modeset=1"
    "nvidia_drm.fbdev=1"
    "nvidia.NVreg_UsePageAttributeTable=1"
    "preempt=full"
    "threadirqs"
    "transparent_hugepage=madvise"
    "processor.max_cstate=1"
    "intel_idle.max_cstate=1"
    "pcie_aspm.policy=performance"
    "nvme_core.default_ps_max_latency_us=0"
    "split_lock_detect=off"
    "zswap.enabled=0"
  ];

  boot.tmp.useTmpfs = true;
  boot.kernel.sysctl = {
    "vm.swappiness" = 150;
    "vm.vfs_cache_pressure" = 50;
    "vm.page-cluster" = 0;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;

    "net.core.default_qdisc" = "cake";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "net.core.netdev_max_backlog" = 16384;

    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 1024;

    "kernel.nmi_watchdog" = 0;
    "kernel.split_lock_mitigate" = 0;
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  powerManagement.cpuFreqGovernor = "performance";

  services.fstrim.enable = true;
  services.flatpak.enable = true;
  services.zerotierone.enable = true;

  services.scx = {
    enable = true;
    scheduler = "scx_bpfland";
  };

  fileSystems."/media/ssd" = {
    device = "/dev/disk/by-uuid/8b0d1431-c133-4fe4-8151-46602c5a56a3";
    fsType = "ext4";
    options = [
      "noatime"
      "nofail"
    ];
  };

  fileSystems."/media/windows" = {
    device = "/dev/disk/by-uuid/84386666386656E8";
    fsType = "ntfs3"; # Much faster kernel-level driver
    options = [
      "noatime"
      "nofail"
      "uid=1000"
      "gid=100"
      "dmask=0022"
      "fmask=0133"
    ];
  };

  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
  '';

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libglvnd
      nvidia-vaapi-driver
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      libglvnd
    ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {

    modesetting.enable = true;

    powerManagement.enable = false;

    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    open = true;

    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };
  systemd.services.nvidia-power-limit = {
    description = "Set NVIDIA GPU Power Limit";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pl 150";
    };
  };

  networking.hostName = "smoke";

  networking.useNetworkd = true;
  networking.useDHCP = true;
  networking.networkmanager.enable = false;
  systemd.network = {
    enable = true;
    wait-online.enable = false;
    networks."10-wired" = {
      matchConfig.Name = [
        "en*"
        "eth*"
      ];
      networkConfig = {
        Address = [ "192.168.1.100/24" ];
        Gateway = [ "192.168.1.1" ];
        DNS = [
          "1.1.1.1"
          "1.0.0.1"
        ];
        DHCP = "yes";
      };
      dhcpV4Config.UseDNS = false;
      dhcpV6Config.UseDNS = false;
      ipv6AcceptRAConfig.UseDNS = false;
    };
  };

  time.timeZone = "Africa/Algiers";

  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  services.xserver.xkb.options = "eurosign:e,caps:escape";
  services.displayManager.ly.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    #   extraConfig.pipewire."92-low-latency" = {
    #     "context.properties" = {
    #       "default.clock.rate" = 48000;
    #       "default.clock.quantum" = 256;
    #       "default.clock.min-quantum" = 64;
    #       "default.clock.max-quantum" = 1024;
    #     };
    #   };
    # };

    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 64;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 1024;
      };
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
  };
  users.users.walid = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "input"
      "plocate"
      "adbusers"
    ];
    packages = with pkgs; [
      tree
    ];
  };

  programs.gpu-screen-recorder = {
    package = inputs.gsr-ui-nix.packages.${pkgs.stdenv.hostPlatform.system}.gpu-screen-recorder;
    enable = true;
    ui.enable = true;
  };

  programs.firefox.enable = true;
  programs.niri.enable = true;
  programs.zsh.enable = true;
  programs.xwayland.enable = true;
  programs.gamemode.enable = true;
  programs.thunar.enable = true;
  programs.gamescope.enable = true;
  programs.mango.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  programs.steam = {
    enable = true;

    package = pkgs.steam.overrideAttrs (oldAttrs: {
      postInstall = ''
        mkdir -p $out/bin
        rm -f $out/bin/steam
        echo '#!/bin/sh' > $out/bin/steam
        echo 'exec /home/walid/.local/share/SLSsteam/path/steam "$@"' >> $out/bin/steam
        chmod +x $out/bin/steam
      '';
    });

    extraCompatPackages = [
      pkgs.proton-cachyos-x86_64_v3
    ];

    gamescopeSession = {
      enable = true;
      args = [
        "-b"
        "-W"
        "1920"
        "-H"
        "1080"
        "--force-grab-cursor"
        "--backend"
        "wayland"
      ];
      env = {
        "__GL_VRR_ALLOWED" = "0";
        "__GL_GSYNC_ALLOWED" = "0";
        "DISABLE_VRR" = "1";
        "GAMESCOPE_WSI_HIDE_PRESENT_WAIT_EXT" = "1";
      };

    };

  };
  environment.systemPackages = with pkgs; [
    helix
    wget
    mangohud
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.thorium-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    (discord.override {
      withVencord = true;
    })
    swayimg
    nixfmt
    evtest
    adwaita-icon-theme
    xwayland-satellite
    faugus-launcher
    fuzzel
    _7zz
    file
    waybar
    psmisc
    jq
    git
    adw-gtk3
    parsec-bin
    vulkan-loader
    vulkan-tools
    libnotify
    thunar-archive-plugin
    file-roller
    thunar-volman
    plocate
    superfile
    telegram-desktop
    xeyes
    sbctl
    unrar
    android-tools
    bc
    bubblewrap
    fd
    unzip
    foot
  ];
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    maple-mono.NF
    noto-fonts
    noto-fonts-color-emoji
    font-awesome
    commit-mono
    source-code-pro
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "spotify"
      "spicetify-catppuccin"
    ];

  nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
  nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  environment.variables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
    __GL_SHADER_DISK_CACHE_SIZE = "10737418240";

  };
  environment.sessionVariables.PATH = lib.mkBefore "/home/walid/.local/share/SLSsteam/path:$PATH";
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
