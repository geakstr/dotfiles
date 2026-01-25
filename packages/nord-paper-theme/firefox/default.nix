{ pkgs }:

# Signed extension - just copy the pre-signed .xpi
pkgs.runCommand "firefox-nord-paper-theme-1.0.5" {} ''
  mkdir -p $out
  cp ${./nord-paper-theme-signed.xpi} $out/nord-paper-theme.xpi
''
