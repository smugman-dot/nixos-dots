# =============================================================================
# kitty.nix - Home Manager module, translated from kitty.conf + current-theme.conf
#
# Usage: import from home.nix, e.g. { imports = [ ./kitty.nix ]; }
#
# Notes:
#   - Home Manager's kitty module has a `themeFile` option, but that only
#     works for themes shipped in the kitty-themes repo it vendors. Since
#     "Noctalia" is a custom/local theme, the colors are inlined directly
#     into `settings` instead - functionally identical to your
#     current-theme.conf + `include` setup, just merged into one file
#     that Nix manages.
#   - font_family is set via `programs.kitty.font.name` rather than the
#     raw setting - Home Manager renders it back into the config as
#     font_family anyway.
# =============================================================================
{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.kitty = {
    enable = true;

    font = {
      name = "Maple Mono NF";
    };

    settings = {
      background_opacity = "0.85";
      dynamic_background_opacity = "yes";
      enable_audio_bell = "no";
      cursor_trail = "5";
      confirm_os_window_close = "0";

    };
    extraConfig = ''
      include themes/noctalia.conf
    '';
  };
}
