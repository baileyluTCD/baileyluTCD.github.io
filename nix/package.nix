{
  pkgs,
  system,
  flake,
  ...
}:
pkgs.stdenvNoCC.mkDerivation {
  name = "personal-website";
  src = flake;

  nativeBuildInputs = [
    flake.packages.${system}.zine
  ];

  buildPhase = ''
    zine release
  '';

  installPhase = ''
    mkdir -p $out/site

    cp -r public/. $out/site
  '';
}
