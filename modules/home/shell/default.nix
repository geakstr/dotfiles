{ ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "eza --icons=auto";
      la = "eza --all --long --icons=auto --git --git-repos --octal-permissions";
      nrs = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      files = "yazi";
      audio = "pulsemixer";
      asciimap = "telnet mapscii.me";
      bat = "bat-themed";
      email = "aerc";
      sway = "sway --unsupported-gpu";
    };
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    historyControl = [ "ignoredups" "erasedups" ];
    historySize = 10000;
    historyFileSize = 100000;
    shellOptions = [
      "histappend"
      "cmdhist"
    ];
    initExtra = ''
      set -o vi
      bind 'set vi-ins-mode-string \1\e[6 q\2'  # beam cursor
      bind 'set vi-cmd-mode-string \1\e[2 q\2'  # block cursor
      bind 'set show-mode-in-prompt on'

      translate() {
        ollama run mistral:7b "Translate to Russian. Reply with ONLY the translation: $*"
      }

      translate-to() {
        local lang="$1"
        shift
        ollama run mistral:7b "Translate to $lang. Reply with ONLY the translation: $*"
      }

      if [[ $TERM != "dumb" ]]; then
        eval "$(starship init bash)"
      fi

      PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
    '';
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = false;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$rust$nix_shell$cmd_duration$line_break$character";

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };

      directory = {
        style = "bold cyan";
        truncation_length = 3;
      };

      git_branch = {
        symbol = "";
        format = "[|](bright-black) [$branch]($style) ";
        style = "bold purple";
      };

      git_status = {
        format = "[$all_status$ahead_behind]($style) ";
        style = "bold red";
      };

      rust = {
        symbol = "";
        format = "[|](bright-black) [rust]($style) ";
        style = "bold orange";
        detect_files = ["Cargo.toml"];
        detect_extensions = [];
        detect_folders = [];
      };

      nix_shell = {
        symbol = "";
        format = "[|](bright-black) [nix $state]($style) ";
        style = "bold blue";
      };

      cmd_duration = {
        format = "[|](bright-black) [$duration]($style) ";
        style = "bold yellow";
        min_time = 2000;
      };
    };
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;

    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [ "--reverse" ];

    fileWidgetOptions = [
      "--reverse"
      "--walker-skip .git,node_modules,target"
      "--preview 'bat-themed -p --color=always {}'"
      "--bind 'ctrl-/:change-preview-window(down|hidden|)'"
      "--bind 'ctrl-e:execute(\\$EDITOR {})+abort'"
    ];

    changeDirWidgetCommand = "fd --type d --hidden --exclude .git";
    changeDirWidgetOptions = [
      "--reverse"
      "--preview 'eza --tree --level=2 --icons {}'"
    ];

    historyWidgetOptions = [
      "--tac"
      "--info=inline"
      "--with-nth 2.."
      "--bind 'ctrl-/:toggle-preview'"
      "--preview 'echo {2..}'"
      "--preview-window up:3:hidden:wrap"
      "--bind 'ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'"
    ];
  };
}
