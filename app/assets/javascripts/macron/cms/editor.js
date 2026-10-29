/* MacronCMS CodeMirror Editor Initializer */
(function() {
  function getEditorMode(kind) {
    switch ((kind || "").toLowerCase()) {
      case "markdown":
        return "markdown";
      case "json":
        return { name: "javascript", json: true };
      case "latex":
        return "stex";
      default:
        return "text/plain";
    }
  }

  function initEditorOnTextarea(textarea) {
    if (!window.CodeMirror) return;
    if (textarea.hasAttribute("data-cms-editor-initialized")) return;

    textarea.setAttribute("data-cms-editor-initialized", "true");
    var mode = getEditorMode(textarea.getAttribute("data-cms-editor"));

    var cm = window.CodeMirror.fromTextArea(textarea, {
      mode: mode,
      lineNumbers: true,
      lineWrapping: true,
      tabSize: 2,
      indentWithTabs: false,
      viewportMargin: 20
    });

    textarea._cmsCodeMirror = cm;

    // Synchronize CodeMirror changes to the underlying textarea
    cm.on("change", function() {
      cm.save();
    });

    // Ensure value is synchronized before any form submit
    if (textarea.form) {
      textarea.form.addEventListener("submit", function() {
        cm.save();
      });
    }

    // Refresh when container transitions from hidden to visible
    var checkVisibleAndRefresh = function() {
      if (textarea.offsetParent !== null || cm.getWrapperElement().offsetParent !== null) {
        cm.refresh();
      }
    };

    if (window.ResizeObserver) {
      var ro = new ResizeObserver(function() {
        checkVisibleAndRefresh();
      });
      ro.observe(cm.getWrapperElement());
    }

    // Trigger an initial refresh after microtask
    setTimeout(checkVisibleAndRefresh, 50);
  }

  function initCmsEditors(root) {
    if (!window.CodeMirror) return;
    var scope = root && root.querySelectorAll ? root : document;
    var textareas = scope.querySelectorAll("textarea[data-cms-editor]");
    for (var i = 0; i < textareas.length; i++) {
      initEditorOnTextarea(textareas[i]);
    }
  }

  // Refresh any existing visible editors (useful when edit forms are toggled)
  function refreshAllEditors() {
    var inited = document.querySelectorAll("textarea[data-cms-editor-initialized]");
    for (var i = 0; i < inited.length; i++) {
      if (inited[i]._cmsCodeMirror) {
        inited[i]._cmsCodeMirror.refresh();
      }
    }
  }

  function renderAllLatex(root) {
    if (!window.katex) return;
    var scope = root && root.querySelectorAll ? root : document;
    var elements = scope.querySelectorAll("[data-cms-latex]");
    for (var i = 0; i < elements.length; i++) {
      var el = elements[i];
      var formula = el.getAttribute("data-cms-latex") || el.textContent;
      if (!formula) continue;
      try {
        var isDisplay = el.getAttribute("data-cms-latex-display") !== "false";
        window.katex.render(formula, el, {
          displayMode: isDisplay,
          throwOnError: false
        });
      } catch (err) {
        console.error("KaTeX render error:", err);
      }
    }
  }

  window.MacronCms = window.MacronCms || {};
  window.MacronCms.initEditors = initCmsEditors;
  window.MacronCms.refreshEditors = refreshAllEditors;
  window.MacronCms.renderLatex = renderAllLatex;

  function initAll(root) {
    initCmsEditors(root);
    renderAllLatex(root);
  }

  // Listen to Turbo & DOM lifecycle events
  document.addEventListener("DOMContentLoaded", function() { initAll(); });
  document.addEventListener("turbo:load", function() { initAll(); });
  document.addEventListener("turbo:render", function() { initAll(); });
  document.addEventListener("turbo:frame-load", function() { initAll(); });

  // Listen for clicks that might toggle hidden forms and refresh editors/render latex
  document.addEventListener("click", function(e) {
    var target = e.target;
    if (target && (target.closest("button") || target.closest("a"))) {
      setTimeout(function() {
        initAll();
        refreshAllEditors();
      }, 50);
    }
  });
})();
