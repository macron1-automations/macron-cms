/* MacronCMS KaTeX LaTeX Widget Renderer (Turbo compatible) */
(function() {
  "use strict";

  function renderLatexEquations(root) {
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

  window.renderMacronLatex = renderLatexEquations;

  document.addEventListener("DOMContentLoaded", function() { renderLatexEquations(); });
  document.addEventListener("turbo:load", function() { renderLatexEquations(); });
  document.addEventListener("turbo:render", function() { renderLatexEquations(); });
  document.addEventListener("turbo:frame-load", function() { renderLatexEquations(); });
})();
