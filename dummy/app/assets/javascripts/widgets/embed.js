/* MacronCMS Embed Fullscreen Controller (HTML5 Fullscreen API + Turbo) */
(function() {
  "use strict";

  function requestFullscreen(element) {
    if (element.requestFullscreen) {
      return element.requestFullscreen();
    } else if (element.webkitRequestFullscreen) {
      return element.webkitRequestFullscreen();
    } else if (element.msRequestFullscreen) {
      return element.msRequestFullscreen();
    }
    return Promise.reject(new Error("Fullscreen API is not supported"));
  }

  function exitFullscreen() {
    if (document.exitFullscreen) {
      return document.exitFullscreen();
    } else if (document.webkitExitFullscreen) {
      return document.webkitExitFullscreen();
    } else if (document.msExitFullscreen) {
      return document.msExitFullscreen();
    }
    return Promise.reject(new Error("Fullscreen API is not supported"));
  }

  function getFullscreenElement() {
    return document.fullscreenElement ||
      document.webkitFullscreenElement ||
      document.mozFullScreenElement ||
      document.msFullscreenElement ||
      null;
  }

  function updateEmbedState(card) {
    var isFs = getFullscreenElement() === card;
    card.setAttribute("data-fullscreen", isFs ? "true" : "false");

    var iframe = card.querySelector("iframe");
    var btn = card.querySelector("[data-embed-fullscreen-btn]");
    var enterIcon = card.querySelector("[data-icon-enter-fullscreen]");
    var exitIcon = card.querySelector("[data-icon-exit-fullscreen]");

    if (isFs) {
      card.classList.add("is-fullscreen");
      if (iframe) iframe.classList.add("is-fullscreen-iframe");
      if (enterIcon) enterIcon.classList.add("hidden");
      if (exitIcon) exitIcon.classList.remove("hidden");
      if (btn) {
        btn.setAttribute("aria-label", "Exit Fullscreen");
        btn.setAttribute("title", "Exit Fullscreen");
      }
    } else {
      card.classList.remove("is-fullscreen");
      if (iframe) iframe.classList.remove("is-fullscreen-iframe");
      if (enterIcon) enterIcon.classList.remove("hidden");
      if (exitIcon) exitIcon.classList.add("hidden");
      if (btn) {
        btn.setAttribute("aria-label", "Maximize");
        btn.setAttribute("title", "Maximize");
      }
    }
  }

  function onFullscreenChange() {
    var cards = document.querySelectorAll("[data-embed-card]");
    for (var i = 0; i < cards.length; i++) {
      updateEmbedState(cards[i]);
    }
  }

  function initEmbedCards(root) {
    var scope = root && root.querySelectorAll ? root : document;
    var cards = scope.querySelectorAll("[data-embed-card]");

    for (var i = 0; i < cards.length; i++) {
      var card = cards[i];
      if (card.__embedFullscreenInitialized) continue;
      card.__embedFullscreenInitialized = true;

      var btn = card.querySelector("[data-embed-fullscreen-btn]");
      if (btn) {
        btn.addEventListener("click", function(e) {
          e.preventDefault();
          e.stopPropagation();
          var targetCard = this.closest("[data-embed-card]");
          if (!targetCard) return;

          if (getFullscreenElement() === targetCard) {
            exitFullscreen().catch(function(err) {
              console.warn("Failed to exit fullscreen:", err);
            });
          } else {
            requestFullscreen(targetCard).catch(function(err) {
              console.warn("Failed to enter fullscreen:", err);
            });
          }
        });
      }

      updateEmbedState(card);
    }
  }

  // Register fullscreen change events across standard & legacy prefixed events
  document.addEventListener("fullscreenchange", onFullscreenChange);
  document.addEventListener("webkitfullscreenchange", onFullscreenChange);
  document.addEventListener("mozfullscreenchange", onFullscreenChange);
  document.addEventListener("MSFullscreenChange", onFullscreenChange);

  // Turbo & DOM lifecycle
  document.addEventListener("DOMContentLoaded", function() { initEmbedCards(); });
  document.addEventListener("turbo:load", function() { initEmbedCards(); });
  document.addEventListener("turbo:render", function() { initEmbedCards(); });
  document.addEventListener("turbo:frame-load", function(e) { initEmbedCards(e.target); });

  window.MacronEmbed = {
    init: initEmbedCards,
    requestFullscreen: requestFullscreen,
    exitFullscreen: exitFullscreen
  };
})();
