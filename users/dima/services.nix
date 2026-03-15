{ pkgs, personal, ... }:

let
  colors = import ../../modules/home/theme/colors.nix;
in
{
  services.wlsunset = {
    enable = true;
    sunrise = personal.sunrise;
    sunset = personal.sunset;
    temperature.day = 6500;
    temperature.night = 2700;
  };

  services.mako = {
    enable = true;
    settings = {
      background-color = colors.nord.bg;
      text-color = colors.nord.fg;
      border-size = 1;
      border-color = colors.nord.fgMuted;
      border-radius = 0;
      padding = "10";
      font = "Inter 11";
      default-timeout = 5000;
    };
  };

  # AC: 10min lock, 1hr sleep | Battery: 3min lock, 15min sleep
  systemd.user.services.swayidle-power-aware = {
    Unit = {
      Description = "Idle manager with power-aware timeouts";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      Restart = "always";
      RestartSec = 5;
      ExecStart = let
        swayidle = "${pkgs.swayidle}/bin/swayidle";
        swaylock = "${pkgs.swaylock}/bin/swaylock";
        cat = "${pkgs.coreutils}/bin/cat";
        stdbuf = "${pkgs.coreutils}/bin/stdbuf";
        udevadm = "${pkgs.systemd}/bin/udevadm";
        script = pkgs.writeShellScript "swayidle-power-aware" ''
          get_power_state() {
            if [ -f /sys/class/power_supply/AC/online ]; then
              ${cat} /sys/class/power_supply/AC/online
            elif [ -f /sys/class/power_supply/ACAD/online ]; then
              ${cat} /sys/class/power_supply/ACAD/online
            else
              echo "1"
            fi
          }

          start_swayidle() {
            if [ "$(get_power_state)" = "1" ]; then
              ${swayidle} -w \
                timeout 600 '${swaylock} -f' \
                timeout 3600 'systemctl suspend' \
                before-sleep '${swaylock} -f' &
            else
              ${swayidle} -w \
                timeout 180 '${swaylock} -f' \
                timeout 900 'systemctl suspend' \
                before-sleep '${swaylock} -f' &
            fi
            swayidle_pid=$!
          }

          cleanup() {
            kill $swayidle_pid 2>/dev/null
            wait $swayidle_pid 2>/dev/null
          }
          trap cleanup EXIT

          start_swayidle

          # Watch for AC power changes via kernel uevent (no dbus)
          ${stdbuf} -oL ${udevadm} monitor --subsystem-match=power_supply --udev 2>/dev/null | \
            while read -r line; do
              case "$line" in
                *change*power_supply*)
                  kill $swayidle_pid 2>/dev/null
                  wait $swayidle_pid 2>/dev/null
                  start_swayidle
                  ;;
              esac
            done
        '';
      in "${script}";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
