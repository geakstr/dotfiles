{ pkgs, lib, ... }:

let
  colors = import ../theme/colors.nix;
  sandbox = import ./lib.nix { inherit pkgs lib; };

  # URL/file opener - writes to a FIFO that's read outside the sandbox
  openUrl = pkgs.writeShellScriptBin "open-url" ''
    OPEN_FIFO="$HOME/.cache/aerc-open/open-fifo"
    if [ -p "$OPEN_FIFO" ]; then
      # Convert relative paths to absolute
      case "$1" in
        /*) echo "$1" > "$OPEN_FIFO" ;;
        file://*) echo "$1" > "$OPEN_FIFO" ;;
        http://*|https://*) echo "$1" > "$OPEN_FIFO" ;;
        *) echo "$(pwd)/$1" > "$OPEN_FIFO" ;;
      esac
    else
      echo "Error: FIFO $OPEN_FIFO not found. Start the opener service." >&2
      exit 1
    fi
  '';

  # Sandboxed aerc wrapper
  aercSandboxed = sandbox.mkSandbox {
    name = "aerc";
    binary = "${pkgs.aerc}/bin/aerc";
    enableTerminal = true;
    enableNetwork = true;  # Needs localhost for protonmail-bridge

    # Config and state directories
    roBindsTry = [
      { src = "$HOME/.config/aerc"; dst = "$HOME/.config/aerc"; }
    ];

    bindsTry = [
      { src = "$HOME/.local/share/aerc"; dst = "$HOME/.local/share/aerc"; }
      { src = "$HOME/.local/state/aerc"; dst = "$HOME/.local/state/aerc"; }
      { src = "$HOME/Downloads"; dst = "$HOME/Downloads"; }  # For saving attachments
      { src = "$HOME/.cache/aerc-open"; dst = "$HOME/.cache/aerc-open"; }  # Shared with Firefox
      { src = "$HOME/mail"; dst = "$HOME/mail"; }  # Local maildir
    ];

    env = {
      TERM = "$TERM";
      COLORTERM = "$COLORTERM";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
      TMPDIR = "$HOME/.cache/aerc-open";
      BROWSER = "${openUrl}/bin/open-url";
      EDITOR = "${pkgs.neovim}/bin/nvim";
      PAGER = "${pkgs.less}/bin/less -R";
      PATH = lib.makeBinPath [
        pkgs.aerc
        pkgs.bash
        pkgs.chafa
        pkgs.w3m
        pkgs.less
        pkgs.neovim
        pkgs.coreutils
        openUrl
      ] + ":/run/current-system/sw/bin";
    };

    preExec = ''
      [ -n "$TMUX" ] && ${pkgs.tmux}/bin/tmux rename-window aerc
      # Apply current theme after aerc starts
      THEME_FILE="$HOME/.local/state/theme"
      STYLE=$([ -f "$THEME_FILE" ] && grep -q light "$THEME_FILE" && echo paper || echo nord)
      (sleep 0.1 && [ -n "$TMUX" ] && ${pkgs.tmux}/bin/tmux send-keys ":reload -s $STYLE" Enter) &
    '';
    postExec = ''[ -n "$TMUX" ] && ${pkgs.tmux}/bin/tmux set-option -w automatic-rename on'';
  };

  # Theme stylesets
  mkStyleset = theme: ''
    # ${if theme == colors.nord then "Nord (dark)" else "Paper (light)"} theme for aerc
    *.default = true
    *.normal = true

    # Selected/cursor line highlighting
    *.selected.bg = ${theme.bgHighlight}
    *.selected.fg = ${theme.fg}
    *.selected.bold = true
    *.selected.reverse = true

    title.bg = ${theme.bgAlt}
    title.fg = ${theme.fg}
    title.bold = true

    header.bg = ${theme.bg}
    header.fg = ${theme.cyan}
    header.bold = true

    *error.fg = ${theme.red}
    *warning.fg = ${theme.yellow}
    *success.fg = ${theme.green}

    statusline_default.bg = ${theme.bgAlt}
    statusline_default.fg = ${theme.fg}
    statusline_error.bg = ${theme.red}
    statusline_error.fg = ${theme.fg}
    statusline_success.bg = ${theme.green}
    statusline_success.fg = ${theme.bg}

    msglist_default.bg = ${theme.bg}
    msglist_default.fg = ${theme.fg}
    msglist_unread.fg = ${theme.cyan}
    msglist_unread.bold = true
    msglist_read.fg = ${theme.fgDim}
    msglist_marked.bg = ${theme.bgHighlight}
    msglist_marked.fg = ${theme.yellow}
    msglist_deleted.fg = ${theme.red}

    dirlist_default.bg = ${theme.bg}
    dirlist_default.fg = ${theme.fg}
    dirlist_unread.fg = ${theme.cyan}
    dirlist_unread.bold = true
    dirlist_recent.fg = ${theme.green}

    completion_default.bg = ${theme.bgAlt}
    completion_default.fg = ${theme.fg}
    completion_pill.bg = ${theme.cyan}
    completion_pill.fg = ${theme.bg}

    tab.bg = ${theme.bg}
    tab.fg = ${theme.fgMuted}
    tab.selected.bg = ${theme.bgAlt}
    tab.selected.fg = ${theme.cyan}
    tab.selected.bold = true

    selector_default.bg = ${theme.bg}
    selector_default.fg = ${theme.fg}
    selector_focused.bg = ${theme.cyan}
    selector_focused.fg = ${theme.bg}
    selector_focused.bold = true
    selector_chooser.bg = ${theme.bgAlt}
    selector_chooser.fg = ${theme.fg}

    border.bg = ${theme.bg}
    border.fg = ${theme.bgHighlight}
  '';

  nordStyleset = mkStyleset colors.nord;
  paperStyleset = mkStyleset colors.paper;

in
{
  # Packages needed for aerc and bridge
  home.packages = with pkgs; [
    protonmail-bridge
    chafa
    w3m
    isync  # mbsync for local mail backup
  ];

  # Ensure mail directory exists (for mbsync)
  home.file."mail/.keep".text = "";

  # mbsync config template (copy to ~/.mbsyncrc and fill in credentials)
  home.file.".mbsyncrc.example".text = ''
    # Proton Mail via Bridge
    # Copy to ~/.mbsyncrc and fill in your email

    IMAPAccount proton
    Host 127.0.0.1
    Port 1143
    User YOUR_EMAIL@protonmail.com
    PassCmd "cat ~/.config/protonmail/mbsync-pass"
    SSLType None
    AuthMechs LOGIN

    IMAPStore proton-remote
    Account proton

    MaildirStore proton-local
    Path ~/mail/
    Inbox ~/mail/INBOX
    SubFolders Verbatim

    Channel proton
    Far :proton-remote:
    Near :proton-local:
    Patterns *
    Create Both
    Expunge Both
    SyncState *
  '';

  # mbsync systemd service
  systemd.user.services.mbsync = {
    Unit = {
      Description = "Mailbox synchronization";
      After = [ "protonmail-bridge.service" "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.isync}/bin/mbsync -a";
      # Retry on failure (bridge might not be ready)
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
      Environment = "PATH=${pkgs.coreutils}/bin";
    };
  };

  # mbsync timer - sync every 5 minutes
  systemd.user.timers.mbsync = {
    Unit = {
      Description = "Mailbox synchronization timer";
    };
    Timer = {
      OnBootSec = "1min";
      OnUnitActiveSec = "5min";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # Sandboxed aerc binary
  home.file.".local/bin/aerc" = {
    executable = true;
    source = "${aercSandboxed}/bin/aerc";
  };

  # Ensure state directories exist
  home.file.".local/share/aerc/.keep".text = "";
  home.file.".local/state/aerc/.keep".text = "";
  home.file.".cache/aerc-open/.keep".text = "";  # Shared temp for opening attachments

  # aerc config files (outside sandbox, read-only mounted)
  home.file.".config/aerc/aerc.conf".text = ''
    [general]
    unsafe-accounts-conf = true

    [ui]
    index-columns = date<20,name<20,flags>4,subject<*
    column-date = {{.DateAutoFormat .Date.Local}}
    column-name = {{index (.From | names) 0}}
    column-flags = {{.Flags | join ""}}
    column-subject = {{.Subject}}
    timestamp-format = 2006-01-02 15:04
    this-day-time-format = 15:04
    this-week-time-format = Mon 15:04
    this-year-time-format = Jan 02
    mouse-enabled = true
    styleset-name = nord
    sort = -r date

    [viewer]
    pager = less -R
    alternatives = text/html,text/plain
    open-cmd = ${openUrl}/bin/open-url

    [compose]
    header-layout = To|From,Subject
    address-book-cmd =
    reply-to-self = false

    [filters]
    text/plain = colorize
    text/calendar = calendar
    message/delivery-status = colorize
    message/rfc822 = colorize
    text/html = w3m -I utf-8 -T text/html -dump -o display_link_number=1
    image/* = chafa -f sixel -s ''${COLUMNS}x-
  '';

  home.file.".config/aerc/binds.conf".text = ''
    # Global bindings (before any section)
    <C-p> = :prev-tab<Enter>
    <C-n> = :next-tab<Enter>
    <C-t> = :term<Enter>
    ? = :help keys<Enter>

    [messages]
    q = :quit<Enter>
    j = :next<Enter>
    <Down> = :next<Enter>
    k = :prev<Enter>
    <Up> = :prev<Enter>
    gg = :select 0<Enter>
    G = :select -1<Enter>
    <C-d> = :next 50%<Enter>
    <C-u> = :prev 50%<Enter>
    <C-f> = :next 100%<Enter>
    <C-b> = :prev 100%<Enter>
    <PgDn> = :next -s 100%<Enter>
    <PgUp> = :prev -s 100%<Enter>
    J = :next-folder<Enter>
    K = :prev-folder<Enter>
    <Enter> = :view<Enter>
    l = :view<Enter>
    D = :delete<Enter>
    A = :archive flat<Enter>
    <Space> = :read -t<Enter>
    v = :mark -t<Enter>
    V = :mark -v<Enter>
    C = :compose<Enter>
    rr = :reply -a<Enter>
    rq = :reply -aq<Enter>
    Rr = :reply<Enter>
    Rq = :reply -q<Enter>
    c = :cf<space>
    / = :search<space>
    \ = :filter<space>
    n = :next-result<Enter>
    N = :prev-result<Enter>
    <Esc> = :clear<Enter>

    [messages:folder=Drafts]
    l = :recall<Enter>
    <Enter> = :recall<Enter>

    [view]
    q = :close<Enter>
    | = :pipe<space>
    D = :delete<Enter>
    S = :save<space>
    A = :archive flat<Enter>
    O = :open<Enter>
    o = :open-link<space>
    g = :open<Enter>
    f = :forward<Enter>
    rr = :reply -a<Enter>
    rq = :reply -aq<Enter>
    Rr = :reply<Enter>
    Rq = :reply -q<Enter>
    H = :toggle-headers<Enter>
    <C-k> = :prev-part<Enter>
    <C-j> = :next-part<Enter>
    J = :next<Enter>
    K = :prev<Enter>

    [view::passthrough]
    $noinherit = true
    $ex = <C-x>
    <Esc> = :toggle-key-passthrough<Enter>

    [compose]
    $ex = <C-x>
    <C-k> = :prev-field<Enter>
    <C-j> = :next-field<Enter>
    <tab> = :next-field<Enter>

    [compose::editor]
    $noinherit = true
    $ex = <C-x>
    <C-k> = :prev-field<Enter>
    <C-j> = :next-field<Enter>
    <C-p> = :prev-tab<Enter>
    <C-n> = :next-tab<Enter>

    [compose::review]
    y = :send<Enter>
    n = :abort<Enter>
    v = :preview<Enter>
    p = :postpone<Enter>
    q = :choose -o d discard abort -o p postpone postpone<Enter>
    e = :edit<Enter>
    a = :attach<space>
    d = :detach<space>

    [terminal]
    $noinherit = true
    $ex = <C-x>
    <C-p> = :prev-tab<Enter>
    <C-n> = :next-tab<Enter>
  '';

  home.file.".config/aerc/stylesets/nord".text = nordStyleset;
  home.file.".config/aerc/stylesets/paper".text = paperStyleset;

  # Accounts template
  home.file.".config/aerc/accounts.conf.example".text = ''
    # Proton Mail via Bridge
    # 1. Run: protonmail-bridge --cli
    # 2. Login and get the bridge password
    # 3. Copy this to accounts.conf and fill in your details

    # Option A: IMAP (direct from bridge, no local storage)
    [Proton]
    source = imap://username:bridge-password@127.0.0.1:1143
    outgoing = smtp://username:bridge-password@127.0.0.1:1025
    default = INBOX
    from = Your Name <your@protonmail.com>
    copy-to = Sent

    # Option B: Maildir (local backup, offline access, sorting)
    # Requires mbsync setup - see ~/.mbsyncrc
    # [Proton]
    # source = maildir://~/mail
    # outgoing = smtp://username:bridge-password@127.0.0.1:1025
    # default = INBOX
    # from = Your Name <your@protonmail.com>
    # copy-to = Sent
  '';

  # Proton Mail Bridge as systemd user service with hardening
  systemd.user.services.protonmail-bridge = {
    Unit = {
      Description = "Proton Mail Bridge";
      After = [ "network-online.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive --log-level info";
      Restart = "on-failure";
      RestartSec = 10;

      # Hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ReadWritePaths = [
        "%h/.config/protonmail"
        "%h/.cache/protonmail"
        "%h/.local/share/protonmail"
      ];
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      PrivateDevices = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      MemoryDenyWriteExecute = true;
      LockPersonality = true;
      SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ];
      SystemCallArchitectures = "native";
      CapabilityBoundingSet = "";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Ensure bridge directories exist
  home.file.".config/protonmail/.keep".text = "";
  home.file.".cache/protonmail/.keep".text = "";
  home.file.".local/share/protonmail/.keep".text = "";

  # Aerc opener service - reads from FIFO and opens files/URLs outside sandbox
  systemd.user.services.aerc-opener = {
    Unit = {
      Description = "Aerc URL/File Opener";
    };

    Service = {
      Type = "simple";
      Environment = [
        "PATH=/run/current-system/sw/bin:%h/.local/bin"
        "XDG_CURRENT_DESKTOP=sway"
        "XDG_DATA_DIRS=/run/current-system/sw/share"
        "DISPLAY=:0"
      ];
      ExecStartPre = "/run/current-system/sw/bin/bash -c 'mkdir -p %h/.cache/aerc-open && rm -f %h/.cache/aerc-open/open-fifo && mkfifo %h/.cache/aerc-open/open-fifo'";
      ExecStart = "/run/current-system/sw/bin/bash -c 'while true; do if read -r line < %h/.cache/aerc-open/open-fifo; then %h/.local/bin/firefox \"$line\" & fi; done'";
      Restart = "always";
      RestartSec = 1;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
