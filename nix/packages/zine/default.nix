{
  pkgs,
  ...
}:
let
  rev = "a16c9f1d3f3166337da47fda2de0f4addc719b92";
  src = pkgs.fetchFromGitHub {
    owner = "kristoff-it";
    repo = "zine";
    inherit rev;
    hash = "sha256-rm3vPGHS/8r/NiUmbtm/mR2NXhXY1N4aTHlMW62qiwU=";
  };
  deps = pkgs.callPackage ./deps.nix { };
in
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "zine";
  version = "0.11.2-unstable-${builtins.substring 0 8 rev}";
  inherit src;

  nativeBuildInputs = [
    pkgs.zig_0_16.hook
  ];

  zigBuildFlags = [
    "--system"
    "${deps}"
  ];

  dontUseZigCheck = true;

  meta = with pkgs.lib; {
    description = "Fast, scalable, flexible static site generator (SSG)";
    homepage = "https://zine-ssg.io";
    license = licenses.mit;
    mainProgram = "zine";
    inherit (pkgs.zig_0_16.meta) platforms;
  };
})
