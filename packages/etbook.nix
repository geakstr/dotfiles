{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "etbook";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "edwardtufte";
    repo = "et-book";
    rev = "gh-pages";
    sha256 = "1bhpk1fbp8jdhzc5j8y5v3bpnzy2sz3dpgjgzclb0dnm51hqqrpn";
  };

  installPhase = ''
    runHook preInstall
    install -Dm644 et-book/*/*.ttf -t $out/share/fonts/truetype/
    runHook postInstall
  '';

  meta = with lib; {
    description = "ET Book font used in Edward Tufte's books";
    homepage = "https://edwardtufte.github.io/et-book/";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
