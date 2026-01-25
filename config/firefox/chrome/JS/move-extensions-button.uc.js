// ==UserScript==
// @name           Move Extensions Button
// @description    Move extensions button to page-action area in urlbar
// ==/UserScript==

(function() {
  'use strict';

  function moveButton() {
    const pageActions = document.getElementById('page-action-buttons');
    const extButton = document.getElementById('unified-extensions-button');

    if (pageActions && extButton) {
      // Always ensure button is last child
      if (extButton.parentNode !== pageActions || extButton !== pageActions.lastElementChild) {
        pageActions.appendChild(extButton);
      }
    }
  }

  function init() {
    moveButton();

    // Watch for changes to page-action-buttons (Firefox rebuilds it on navigation)
    const pageActions = document.getElementById('page-action-buttons');
    if (pageActions) {
      const observer = new MutationObserver(() => {
        moveButton();
      });
      observer.observe(pageActions, { childList: true });
    }

    // Also watch nav-bar in case button gets moved back
    const navBar = document.getElementById('nav-bar-customization-target');
    if (navBar) {
      const observer = new MutationObserver(() => {
        moveButton();
      });
      observer.observe(navBar, { childList: true });
    }
  }

  // Run on various events to ensure we catch initialization
  if (document.readyState === 'complete') {
    init();
  } else {
    window.addEventListener('load', init);
  }

  // Fallback timers
  setTimeout(init, 100);
  setTimeout(init, 500);
  setTimeout(init, 1000);
})();
