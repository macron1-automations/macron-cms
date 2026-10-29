/* MacronCMS CodeMirror Editor Initializer */
(function() {
  function getEditorMode(kind) {
    switch ((kind || "").toLowerCase()) {
      case "markdown":
        return "markdown";
      case "json":
        return { name: "javascript", json: true };
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

  window.MacronCms = window.MacronCms || {};
  window.MacronCms.initEditors = initCmsEditors;
  window.MacronCms.refreshEditors = refreshAllEditors;

  // Listen to Turbo & DOM lifecycle events
  document.addEventListener("DOMContentLoaded", function() { initCmsEditors(); });
  document.addEventListener("turbo:load", function() { initCmsEditors(); });
  document.addEventListener("turbo:render", function() { initCmsEditors(); });
  document.addEventListener("turbo:frame-load", function() { initCmsEditors(); });

  // Listen for clicks that might toggle hidden forms and refresh editors
  document.addEventListener("click", function(e) {
    var target = e.target;
    if (target && (target.closest("button") || target.closest("a"))) {
      setTimeout(function() {
        initCmsEditors();
        refreshAllEditors();
      }, 50);
    }
  });
})();
