# Bwrap Sandbox Builder Library
# Creates sandboxed application wrappers with sensible defaults
#
# Examples:
#
# Basic graphical app (Wayland + GPU + Audio):
#   firefoxSandboxed = sandbox.mkSandbox {
#     name = "firefox";
#     binary = "${pkgs.firefox}/bin/firefox";
#     enableWayland = true;
#     enableGpu = true;
#     enableAudio = true;
#     enableDbus = true;
#     binds = [
#       { src = "$HOME/.mozilla"; dst = "$HOME/.mozilla"; }
#       { src = "$HOME/Downloads"; dst = "$HOME/Downloads"; }
#     ];
#     env = {
#       MOZ_ENABLE_WAYLAND = "1";
#       WAYLAND_DISPLAY = "$WAYLAND_DISPLAY";
#       XDG_RUNTIME_DIR = "$XDG_RUNTIME_DIR";
#     };
#   };
#
# Terminal app (no graphics):
#   claudeSandboxed = sandbox.mkSandbox {
#     name = "claude";
#     binary = "${pkgs.claude}/bin/claude";
#     enableTerminal = true;
#     binds = [
#       { src = "$HOME/.claude"; dst = "$HOME/.claude"; }
#       { src = "$HOME/code"; dst = "$HOME/code"; }
#     ];
#     env = { TERM = "$TERM"; };
#   };
#
# Using bindsTry for optional directories (won't fail if missing):
#   mkSandbox {
#     name = "myapp";
#     binary = "${pkgs.myapp}/bin/myapp";
#     bindsTry = [
#       { src = "$HOME/.cache/myapp"; dst = "$HOME/.cache/myapp"; }
#       { src = "$SSH_AUTH_SOCK"; dst = "$SSH_AUTH_SOCK"; }  # Optional SSH agent
#     ];
#   };
#
# App needing nix-ld (for non-Nix binaries like VS Code):
#   vscodeSandboxed = sandbox.mkSandbox {
#     name = "code";
#     binary = "$HOME/.local/share/vscode/bin/code";
#     enableNixLd = true;  # Enables /lib64, /usr/bin/env, /bin/sh
#     enableSys = true;    # Electron apps need /sys
#     env = {
#       NIX_LD = "/run/current-system/sw/share/nix-ld/lib/ld.so";
#       NIX_LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
#     };
#   };
#
# Using preExec/postExec for tmux window naming:
#   mkSandbox {
#     name = "myapp";
#     binary = "${pkgs.myapp}/bin/myapp";
#     preExec = ''[ -n "$TMUX" ] && tmux rename-window myapp'';
#     postExec = ''[ -n "$TMUX" ] && tmux set-option -w automatic-rename on'';
#   };
#
{ pkgs, lib }:

{
  # mkSandbox: Create a sandboxed application wrapper
  #
  # Required:
  #   name     - Name of the wrapper script
  #   binary   - Full path to the executable
  #
  # Optional:
  #   args           - Arguments to pass to the binary
  #   binds          - Read-write bind mounts [ { src, dst } ]
  #   bindsTry       - Optional read-write bind mounts (won't fail if missing)
  #   roBinds        - Read-only bind mounts [ { src, dst } ]
  #   roBindsTry     - Optional read-only bind mounts (won't fail if missing)
  #   env            - Environment variables { NAME = "value"; }
  #   enableWayland  - Bind Wayland socket
  #   enableAudio    - Bind PipeWire socket
  #   enableDbus     - Bind D-Bus socket
  #   enableGpu      - Bind GPU devices and drivers
  #   enableTerminal - Bind tty/pts for terminal apps
  #   enableFonts    - Bind font config and cache
  #   enableNixLd    - Enable nix-ld for running non-Nix binaries
  #   enableSys      - Bind /sys (needed for some apps like Electron)
  #   enableNetwork  - Allow network access (default: true)
  #   preExec        - Commands to run before bwrap (not inside sandbox)
  #   postExec       - Commands to run after bwrap exits (not inside sandbox)
  #   extraFlags     - Additional bwrap flags as a string
  #
  mkSandbox = {
    name,
    binary,
    args ? [],
    binds ? [],
    bindsTry ? [],
    roBinds ? [],
    roBindsTry ? [],
    env ? {},
    enableWayland ? false,
    enableAudio ? false,
    enableDbus ? false,
    enableGpu ? false,
    enableTerminal ? false,
    enableFonts ? false,
    enableNixLd ? false,
    enableSys ? false,
    enableNetwork ? true,
    preExec ? "",
    postExec ? "",
    extraFlags ? "",
  }:
  let
    # Helper to format bind mount
    fmtBind = flag: b: ''${flag} "${b.src}" "${b.dst}"'';
    fmtBinds = flag: list: lib.concatMapStringsSep " \\\n      " (fmtBind flag) list;

    # Helper to format env vars
    fmtEnv = k: v: ''--setenv ${k} "${v}"'';
    fmtEnvs = lib.concatStringsSep " \\\n      " (lib.mapAttrsToList fmtEnv env);

    # Format arguments
    fmtArgs = lib.concatStringsSep " " args;

    # Network flag
    networkFlag = if enableNetwork then "--share-net" else "";

    # GPU flags
    gpuFlags = lib.optionalString enableGpu ''
      --dev-bind /dev/dri /dev/dri \
      --ro-bind /run/opengl-driver /run/opengl-driver'';

    # Wayland flags
    waylandFlags = lib.optionalString enableWayland ''
      --ro-bind "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"'';

    # Audio flags (PipeWire)
    audioFlags = lib.optionalString enableAudio ''
      --ro-bind-try "$XDG_RUNTIME_DIR/pipewire-0" "$XDG_RUNTIME_DIR/pipewire-0" \
      --bind-try "$XDG_RUNTIME_DIR/pulse" "$XDG_RUNTIME_DIR/pulse"'';

    # D-Bus flags
    dbusFlags = lib.optionalString enableDbus ''
      --ro-bind "$XDG_RUNTIME_DIR/bus" "$XDG_RUNTIME_DIR/bus"'';

    # Terminal flags
    terminalFlags = lib.optionalString enableTerminal ''
      --dev-bind /dev/tty /dev/tty \
      --dev-bind /dev/pts /dev/pts'';

    # Font flags
    # Note: We only bind config, not cache. The tmpfs at $HOME/.cache provides
    # a writable cache directory. Binding the host cache would make it read-only.
    fontFlags = lib.optionalString enableFonts ''
      --ro-bind /etc/fonts /etc/fonts \
      --ro-bind-try "$HOME/.config/fontconfig" "$HOME/.config/fontconfig"'';

    # Nix-ld flags (for running non-Nix binaries like VS Code)
    nixLdFlags = lib.optionalString enableNixLd ''
      --ro-bind /lib64 /lib64 \
      --ro-bind /usr/bin/env /usr/bin/env \
      --ro-bind /bin/sh /bin/sh'';

    # /sys flags (needed for Electron apps)
    sysFlags = lib.optionalString enableSys ''
      --ro-bind /sys /sys'';

    # Custom binds
    customBinds = lib.optionalString (binds != []) (fmtBinds "--bind" binds);
    customBindsTry = lib.optionalString (bindsTry != []) (fmtBinds "--bind-try" bindsTry);
    customRoBinds = lib.optionalString (roBinds != []) (fmtBinds "--ro-bind" roBinds);
    customRoBindsTry = lib.optionalString (roBindsTry != []) (fmtBinds "--ro-bind-try" roBindsTry);

    # Custom env
    customEnv = lib.optionalString (env != {}) fmtEnvs;

  in pkgs.writeShellScriptBin name ''
    ${preExec}
    cleanup() {
      ${if postExec != "" then postExec else ":"}
    }
    trap cleanup EXIT
    ${pkgs.bubblewrap}/bin/bwrap \
      --unshare-all \
      ${networkFlag} \
      \
      --unshare-user \
      --disable-userns \
      --assert-userns-disabled \
      --die-with-parent \
      ${if enableTerminal then "" else "--new-session"} \
      --hostname sandbox \
      \
      --clearenv \
      \
      --ro-bind /nix/store /nix/store \
      --ro-bind /run/current-system/sw /run/current-system/sw \
      ${nixLdFlags} \
      \
      --ro-bind /etc/resolv.conf /etc/resolv.conf \
      --ro-bind /etc/hosts /etc/hosts \
      --ro-bind /etc/ssl /etc/ssl \
      --ro-bind /etc/static/ssl /etc/static/ssl \
      --ro-bind /etc/localtime /etc/localtime \
      --ro-bind /etc/profiles/per-user/$USER /etc/profiles/per-user/$USER \
      --ro-bind /etc/passwd /etc/passwd \
      --ro-bind /etc/group /etc/group \
      \
      --size 536870912 \
      --tmpfs "$HOME/.cache" \
      \
      --size 536870912 \
      --tmpfs /tmp \
      \
      --dev /dev \
      --proc /proc \
      ${sysFlags} \
      \
      ${gpuFlags} \
      ${waylandFlags} \
      ${audioFlags} \
      ${dbusFlags} \
      ${terminalFlags} \
      ${fontFlags} \
      \
      ${customBinds} \
      ${customBindsTry} \
      ${customRoBinds} \
      ${customRoBindsTry} \
      \
      --setenv HOME "$HOME" \
      --setenv USER "$USER" \
      ${customEnv} \
      \
      ${extraFlags} \
      \
      ${binary} ${fmtArgs} "$@"
  '';
}
