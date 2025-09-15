{
  pkgs,
  flake,
  system,
  ...
}:
let
  tex = pkgs.texliveSmall.withPackages (
    ps: with ps; [
      latex-bin
    ]
  );

  python = (
    pkgs.python3.withPackages (python-pkgs: [
      python-pkgs.beautifulsoup4
    ])
  );
in

pkgs.stdenvNoCC.mkDerivation {
  name = "cv.pdf";
  src = flake.packages.${system}.default;

  nativeBuildInputs = with pkgs; [
    pandoc
    adwaita-fonts
    fontconfig
    ipafont
    tex
    python
    poppler-utils
  ];

  buildPhase = ''
    python ${./strip-cv-from-html.py} ./site/cv/index.html ./cv.html
  '';

  installPhase = ''
    pandoc ./cv.html \
      -o $out \
      -V geometry:margin=0.5cm,scale=0.8 \
      -V colorlinks=true -V linkcolor=blue -V urlcolor=cyan \
      -V linestretch=0.0 \
      -V pagestyle=empty \
      --pdf-engine=xelatex
  '';
}
