{ pkgs, ... }:

let
  input-handler = pkgs.callPackage ../../packages/input-handler { };
in
{
  systemd.services.input-handler = {
    description = "Keyboard remapper (CAPS+hjkl, Meta layout switch)";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udevd.service" ];
    serviceConfig = {
      ExecStart = "${input-handler}/bin/input-handler";
      Restart = "always";
      RestartSec = 1;
      User = "dima";
      SupplementaryGroups = [ "input" "uinput" ];
    };
  };
}
