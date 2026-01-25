// Nord theme (dark)
const nordTheme = {
  colors: {
    // Main chrome
    frame: "#2E3440",
    frame_inactive: "#2E3440",
    tab_background_text: "#ECEFF4",
    tab_selected: "#3B4252",
    tab_text: "#ECEFF4",
    tab_line: "#88C0D0",

    // Toolbar
    toolbar: "#3B4252",
    toolbar_text: "#ECEFF4",
    toolbar_field: "#3B4252",
    toolbar_field_text: "#ECEFF4",
    toolbar_field_border: "transparent",
    toolbar_field_focus: "#3B4252",
    toolbar_field_text_focus: "#ECEFF4",
    toolbar_field_border_focus: "transparent",
    toolbar_top_separator: "transparent",
    toolbar_bottom_separator: "#4C566A",

    // URL bar
    urlbar_popup_separator: "#4C566A",

    // Popup menus
    popup: "#3B4252",
    popup_text: "#ECEFF4",
    popup_border: "#4C566A",
    popup_highlight: "#4C566A",
    popup_highlight_text: "#ECEFF4",

    // Sidebar
    sidebar: "#2E3440",
    sidebar_text: "#ECEFF4",
    sidebar_border: "#4C566A",
    sidebar_highlight: "#4C566A",
    sidebar_highlight_text: "#ECEFF4",

    // Misc
    ntp_background: "#2E3440",
    ntp_text: "#ECEFF4",
    button_background_hover: "#4C566A",
    button_background_active: "#434C5E",
    icons: "#D8DEE9",
    icons_attention: "#88C0D0"
  }
};

// Paper theme (light)
const paperTheme = {
  colors: {
    // Main chrome
    frame: "#fffff4",
    frame_inactive: "#f7f7ed",
    tab_background_text: "#111111",
    tab_selected: "#fffff4",
    tab_text: "#111111",
    tab_line: "#bd7c16",

    // Toolbar
    toolbar: "#fffff4",
    toolbar_text: "#111111",
    toolbar_field: "#fffff4",
    toolbar_field_text: "#111111",
    toolbar_field_border: "transparent",
    toolbar_field_focus: "#fffff4",
    toolbar_field_text_focus: "#111111",
    toolbar_field_border_focus: "transparent",
    toolbar_top_separator: "transparent",
    toolbar_bottom_separator: "#ecece2",

    // URL bar
    urlbar_popup_separator: "#ecece2",

    // Popup menus
    popup: "#fffff4",
    popup_text: "#111111",
    popup_border: "#ecece2",
    popup_highlight: "#e3e3d9",
    popup_highlight_text: "#111111",

    // Sidebar
    sidebar: "#fffff4",
    sidebar_text: "#111111",
    sidebar_border: "#ecece2",
    sidebar_highlight: "#e3e3d9",
    sidebar_highlight_text: "#111111",

    // Misc
    ntp_background: "#fffff4",
    ntp_text: "#111111",
    button_background_hover: "#e3e3d9",
    button_background_active: "#d9d9d0",
    icons: "#4c4c49",
    icons_attention: "#bd7c16"
  }
};

// Apply theme based on system preference
function applyTheme(isDark) {
  browser.theme.update(isDark ? nordTheme : paperTheme);
}

// Check and apply current theme
function checkTheme() {
  const isDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
  applyTheme(isDark);
}

// Initial apply
checkTheme();

// Use alarms API for persistent polling (survives MV3 background script suspension)
browser.alarms.create("checkTheme", { periodInMinutes: 0.05 }); // ~3 seconds

browser.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === "checkTheme") {
    checkTheme();
  }
});

// Also listen for change event as backup
window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", (e) => {
  applyTheme(e.matches);
});
