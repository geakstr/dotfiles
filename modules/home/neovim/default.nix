{ pkgs, ... }:

let
  colors = import ../theme/colors.nix;

  # Generate colors.lua from colors.nix
  colorsLua = pkgs.writeText "colors.lua" ''
    -- Auto-generated from modules/home/theme/colors.nix
    return {
      nord = {
        bg = "${colors.nord.bg}",
        bgDark = "${colors.nord.bgDark}",
        bgAlt = "${colors.nord.bgAlt}",
        bgHighlight = "${colors.nord.bgHighlight}",
        fg = "${colors.nord.fg}",
        fgDim = "${colors.nord.fgDim}",
        fgBright = "${colors.nord.fgBright}",
        fgMuted = "${colors.nord.fgMuted}",
        border = "${colors.nord.border}",
        borderInactive = "${colors.nord.borderInactive}",
        red = "${colors.nord.red}",
        green = "${colors.nord.green}",
        yellow = "${colors.nord.yellow}",
        blue = "${colors.nord.blue}",
        magenta = "${colors.nord.magenta}",
        cyan = "${colors.nord.cyan}",
      },
      paper = {
        bg = "${colors.paper.bg}",
        bgDark = "${colors.paper.bgDark}",
        bgAlt = "${colors.paper.bgAlt}",
        bgHighlight = "${colors.paper.bgHighlight}",
        bgHover = "${colors.paper.bgHover}",
        bgActive = "${colors.paper.bgActive}",
        fg = "${colors.paper.fg}",
        fgDim = "${colors.paper.fgDim}",
        fgBright = "${colors.paper.fgBright}",
        fgMuted = "${colors.paper.fgMuted}",
        fgSubtle = "${colors.paper.fgSubtle}",
        border = "${colors.paper.border}",
        borderInactive = "${colors.paper.borderInactive}",
        red = "${colors.paper.red}",
        green = "${colors.paper.green}",
        yellow = "${colors.paper.yellow}",
        blue = "${colors.paper.blue}",
        magenta = "${colors.paper.magenta}",
        cyan = "${colors.paper.cyan}",
      },
    }
  '';
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  home.packages = with pkgs; [
    typescript-language-server
    typescript
    nil # Nix language server
  ];

  xdg.configFile."nvim/init.lua".source = ./init.lua;
  xdg.configFile."nvim/lua/plugins" = { source = ./lua/plugins; force = true; };
  xdg.configFile."nvim/lua/config/options.lua" = { source = ./lua/config/options.lua; force = true; };
  xdg.configFile."nvim/lua/config/keymaps.lua" = { source = ./lua/config/keymaps.lua; force = true; };
  xdg.configFile."nvim/lua/config/autocmds.lua" = { source = ./lua/config/autocmds.lua; force = true; };
  xdg.configFile."nvim/lua/config/theme.lua" = { source = ./lua/config/theme.lua; force = true; };
  xdg.configFile."nvim/lua/config/colors.lua" = { source = colorsLua; force = true; };
}
