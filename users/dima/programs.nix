{ pkgs, personal, claude-code, ... }:

{
  programs.claude-code = {
    enable = true;
    package = claude-code.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = personal.userName;
      user.email = personal.userEmail;
      core.pager = "delta-themed";
      interactive.diffFilter = "delta-themed --color-only";
      diff.colorMoved = "default";
    };
    ignores = [
      ".stignore" ".stfolder" ".stversions"
      ".DS_Store" "Thumbs.db"
      "*.swp" "*.swo" "*~"
      "**/.claude/settings.local.json"
    ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = false;
    options = {
      side-by-side = false;
      line-numbers = true;
      line-numbers-left-format = "{nm} ";
      line-numbers-right-format = "{np} ";
      file-style = "bold";
      file-decoration-style = "none";
      hunk-header-style = "omit";
    };
  };

  programs.lazygit = {
    enable = true;
    settings = {
      git.pagers = [
        {
          colorArg = "always";
          pager = "delta-themed --paging=never";
        }
      ];
    };
  };

  programs.bat = {
    enable = true;
    config = { paging = "auto"; };
  };

  programs.mpv = {
    enable = true;
    config = {
      hwdec = "auto";
      vo = "gpu-next";
      video-sync = "audio";
      video-sync-max-audio-change = 0;
      video-sync-max-video-change = 0;
      osd-font = "CaskaydiaCove Nerd Font";
      osd-font-size = 20;
      osd-duration = 1000;
      border = false;
    };
    scriptOpts = {
      osc = {
        scalewindowed = 0.4;
        scalefullscreen = 0.4;
        hidetimeout = 1500;
      };
    };
  };

  programs.yazi = {
    enable = true;
    settings.mgr.show_hidden = true;
  };

  programs.swaylock = {
    enable = true;
    settings = {
      color = "000000";
      show-failed-attempts = true;
    };
  };
}
