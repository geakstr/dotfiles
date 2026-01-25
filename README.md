# dotfiles

My NixOS setup. Sway on Wayland, Neovim, Firefox, and a bunch of terminal tools.

## What's here

- **Sway** with mako notifications, swayidle, swaylock
- **Neovim** with LSP, telescope, completion
- **Firefox** hardened with custom user.js, sandboxed via bubblewrap
- **Foot** terminal (fast, Wayland-native)
- **Theming** — Nord (dark) and Paper (light), switchable everywhere with one script

VS Code and Claude Code are also sandboxed.

## Setup

Clone to `~/dotfiles`, then:

```bash
# grab your hardware config
cp /etc/nixos/hardware-configuration.nix ~/dotfiles/hosts/nixos/

# symlink so the nrs alias works
sudo ln -sf ~/dotfiles /etc/nixos

# build it
sudo nixos-rebuild switch --flake ~/dotfiles#nixos
```

After that, `nrs` rebuilds the system.

## Structure

```
flake.nix           # entry point
config/             # personal stuff (name, email, firefox settings)
hosts/nixos/        # machine-specific config
modules/
  nixos/            # system-level (boot, networking, audio, etc)
  home/             # user-level (neovim, sway, shell, apps)
users/dima/         # my user config
packages/           # custom nix packages (themes, input-handler)
scripts/            # shell scripts that get deployed to ~/.local/bin
```

## Theme switching

`toggle-theme` flips between light and dark across Sway, foot, GTK, VS Code, bat, delta, btop. Foot uses signals so no restart needed.

Sunrise/sunset times are in `config/personal.nix` if you want automatic switching with wlsunset.

## Notes

This is tailored to my machine and workflow. If you want to use it, you'll need to:

- Replace `hosts/nixos/hardware-configuration.nix` with yours
- Update `config/personal.nix` with your details
- Probably remove or adjust the display config in `modules/home/sway/` (I have a laptop + external monitor setup)

The sandboxing in `modules/home/apps/` might be useful if you want to isolate apps.
