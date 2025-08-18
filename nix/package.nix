{
  pkgs,
  inputs,
  flake,
  ...
}:
pkgs.stdenvNoCC.mkDerivation {
  name = "personal-website";
  src = flake;

  nativeBuildInputs = with pkgs; [
    inputs.zine.packages.${system}.default
  ];

  buildPhase = ''
    zine release
  '';

  installPhase = ''
    mkdir -p $out/site

    cp -r public/. $out/site
  '';
}
