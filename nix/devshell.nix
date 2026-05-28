{
  pkgs,
  system,
  flake,
  ...
}:
pkgs.mkShellNoCC {
  packages = [
    flake.packages.${system}.zine
  ];
}
