{ pkgs, lib, config, inputs, ... }:

{

  # https://devenv.sh/packages/
  packages = [ 
    pkgs.git 
    pkgs.gnumake
    pkgs.fd
    pkgs.sd
    pkgs.nodePackages.sass
    pkgs.vscode-langservers-extracted
    pkgs.watchexec
    pkgs.lightningcss
    pkgs.sqlite
    pkgs.litecli
    # Required for copilot
    pkgs.nodejs
    pkgs.elmPackages.elm-review
    pkgs.elmPackages.elm-json
    ];

  # https://devenv.sh/languages/
  languages.elm.enable = true;
  languages.python.enable = true;
}
