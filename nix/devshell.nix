{ pkgs, inputs, ... }:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    inputs.zine.packages.${system}.default
  ];
}
