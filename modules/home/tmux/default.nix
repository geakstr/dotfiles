{ ... }:

let
  colors = import ../theme/colors.nix;
in
{
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    baseIndex = 1;
    mouse = true;
    terminal = "tmux-256color";
    keyMode = "vi";

    extraConfig = ''
      set -sg escape-time 10
      set -g allow-passthrough on
      set -g status off

      set -g pane-border-style "fg=${colors.nord.fgMuted}"
      set -g pane-active-border-style "fg=${colors.nord.border}"

      bind b split-window -h -c "#{pane_current_path}"
      bind v split-window -v -c "#{pane_current_path}"

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind -n C-Tab next-window
      bind -n C-BTab previous-window

      set -s copy-command "wl-copy"
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi y send -X copy-pipe-and-cancel
      bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel

      bind 1 select-window -t 1
      bind 2 select-window -t 2
      bind 3 select-window -t 3
      bind 4 select-window -t 4
      bind 5 select-window -t 5
      bind 6 select-window -t 6
      bind 7 select-window -t 7
      bind 8 select-window -t 8
      bind 9 select-window -t 9

      bind c new-window -a -c "#{pane_current_path}"
      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded"

      bind u run-shell "tmux capture-pane -pJ | grep -oE 'https?://[^[:space:]\"<>]+' | sed 's/[).,;:]+$//' | sort -u | fzf-tmux -p --reverse | xargs -r xdg-open"
      bind -T copy-mode-vi u run-shell "tmux capture-pane -pJ -S - | grep -oE 'https?://[^[:space:]\"<>]+' | sed 's/[).,;:]+$//' | sort -u | fzf-tmux -p --reverse | xargs -r xdg-open"

      set -ag terminal-overrides ",xterm-256color:RGB"
      set -g set-titles on
      set -g set-titles-string "❮#S❯    #{W:#{?window_active,⬤ #W,  #W}    }"
    '';
  };
}
