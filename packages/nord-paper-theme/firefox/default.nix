{ pkgs }:

# Signed extension - just copy the pre-signed .xpi
pkgs.runCommand "firefox-nord-paper-theme-1.0.9" {} ''
  mkdir -p $out
  cp ${./nordpaper-theme-signed.xpi} $out/nord-paper-theme.xpi
''
