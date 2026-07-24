{ pkgs, ... }:
let
  mpv-cut = pkgs.mpvScripts.buildLua {
    pname = "mpv-cut";
    version = "unstable-2026-07-19";
    src = pkgs.fetchFromGitHub {
      owner = "familyfriendlymikey";
      repo = "mpv-cut";
      rev = "release";
      hash = "sha256-QJOEC+uoQPSkl5hR9cE6PGS+sxfDLYvSZYE6HjQmxoI=";
    };
    postPatch = ''
      cp main.lua cut.lua
    '';
  };
in
{
  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      uosc
      mpv-cut
    ];
    config = {
      osc = "no";
      border = "no";
      osd-bar = "no";
      keep-open = "yes";
      keepaspect-window = "no";
    };
    scriptOpts.uosc = {
      window_border_size = 0;
    };
  };
}
