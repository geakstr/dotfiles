{ pkgs, personal, ... }:

{
  # %t = XDG_RUNTIME_DIR, wayland-1 = default display
  systemd.user.services.theme-light = {
    Unit.Description = "Switch to light theme";
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/toggle-theme.sh light";
      Environment = [
        "DISPLAY=:0"
        "WAYLAND_DISPLAY=wayland-1"
        "XDG_RUNTIME_DIR=%t"
        "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus"
      ];
    };
  };
  systemd.user.timers.theme-light = {
    Unit.Description = "Switch to light theme at sunrise";
    Timer = {
      OnCalendar = "*-*-* ${personal.sunrise}:00";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  systemd.user.services.theme-dark = {
    Unit.Description = "Switch to dark theme";
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/toggle-theme.sh dark";
      Environment = [
        "DISPLAY=:0"
        "WAYLAND_DISPLAY=wayland-1"
        "XDG_RUNTIME_DIR=%t"
        "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus"
      ];
    };
  };
  systemd.user.timers.theme-dark = {
    Unit.Description = "Switch to dark theme at sunset";
    Timer = {
      OnCalendar = "*-*-* ${personal.sunset}:00";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  services.ssh-agent.enable = true;
}
