{ pkgs, inputs, ... }:
pkgs.mkShell {
  packages = with pkgs; [
    inputs.zine.packages.${system}.default 
  ];
}
