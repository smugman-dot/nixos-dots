{ pkgs, ... }:

{
  programs.helix = {
    enable = true;

    settings = {
      theme = "noctalia";
      editor = {
        auto-format = true;
        line-number = "relative";
      };
    };

    languages = {
      language-server = {
        vtsls = {
          command = "vtsls";
          args = [ "--stdio" ];
        };
        pylsp = {
          command = "pylsp";
          config.pylsp.plugins = {
            pycodestyle.enabled = false;
            pyflakes.enabled = false;
            mccabe.enabled = false;
            flake8.enabled = false;
          };
        };
        ruff = {
          command = "ruff";
          args = [
            "server"
            "--preview"
          ];
        };
      };

      language = [
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = "nixfmt";
          };
        }
        {
          name = "typescript";
          auto-format = true;
          formatter = {
            command = "prettier";
            args = [
              "--parser"
              "typescript"
            ];
          };
          language-servers = [ "vtsls" ];
        }
        {
          name = "python";
          auto-format = true;
          formatter = {
            command = "ruff";
            args = [
              "format"
              "-"
            ];
          };
          language-servers = [
            "pylsp"
            "ruff"
          ];
        }
      ];
    };

  };
}
