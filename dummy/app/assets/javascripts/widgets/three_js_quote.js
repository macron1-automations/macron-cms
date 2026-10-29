/* MacronCMS Three.js Rotating Quote Widget (React + Three.js + Turbo) */
(function() {
  "use strict";

  var DEFAULT_COLOR = "#18181b";
  var ROTATION_SPEED_RAD_PER_SEC = 0.95;
  var MAX_CHARS_PER_LINE = 24;
  var mountedRoots = new Map();

  function normalizeForFont(input) {
    return String(input || "")
      .replace(/[\u201C\u201D\u201E\u201F]/g, '"')
      .replace(/[\u2018\u2019\u201A\u201B]/g, "'")
      .replace(/[\u2013\u2014]/g, "-")
      .replace(/\u2026/g, "...")
      .replace(/\s+/g, " ")
      .trim();
  }

  function wrapQuoteLines(rawText, maxChars) {
    var normalized = normalizeForFont(rawText);
    if (!normalized) return [];

    var words = normalized.split(" ");
    var lines = [];
    var current = "";

    for (var i = 0; i < words.length; i++) {
      var word = words[i];
      if (!current) {
        current = word;
      } else if (current.length + 1 + word.length <= maxChars) {
        current += " " + word;
      } else {
        lines.push(current);
        current = word;
      }
    }
    if (current) {
      lines.push(current);
    }
    return lines;
  }

  function ThreeJsQuoteScene(props) {
    var React = window.React;
    var hostRef = React.useRef(null);
    var stateTuple = React.useState(false);
    var webglFailed = stateTuple[0];
    var setWebglFailed = stateTuple[1];

    var quoteText = props.text || "";
    var quoteColor = props.color || DEFAULT_COLOR;
    var rotationAxis = props.rotationAxis || "x";
    var backgroundColor = props.backgroundColor || null;
    var backgroundImage = props.backgroundImage || null;
    var backgroundMode = props.backgroundMode || "stretch";

    React.useEffect(function() {
      var host = hostRef.current;
      var THREE = window.THREE;
      if (!host || !THREE || !THREE.TextGeometry || !THREE.HelvetikerFont) {
        setWebglFailed(true);
        return undefined;
      }

      var lines = wrapQuoteLines(quoteText, MAX_CHARS_PER_LINE);
      if (lines.length === 0) {
        return undefined;
      }

      var disposed = false;
      var initRafId = null;
      var animateRafId = null;
      var resizeObserver = null;
      var renderer = null;
      var material = null;
      var geometries = [];
      var canvas = null;
      var onWindowResize = null;
      var backgroundTexture = null;

      // Defer WebGL context & geometry setup until after the browser paints the Turbo transition
      initRafId = window.requestAnimationFrame(function() {
        if (disposed || !host.isConnected) return;

        try {
          renderer = new THREE.WebGLRenderer({
            antialias: true,
            alpha: true,
            powerPreference: "high-performance"
          });
        } catch (_err) {
          if (!disposed) setWebglFailed(true);
          return;
        }

        setWebglFailed(false);

        renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
        if (THREE.SRGBColorSpace && "outputColorSpace" in renderer) {
          renderer.outputColorSpace = THREE.SRGBColorSpace;
        }

        canvas = renderer.domElement;
        canvas.className = "block w-full h-full";
        canvas.setAttribute("data-three-js-canvas", "true");
        host.innerHTML = "";
        host.appendChild(canvas);

        var scene = new THREE.Scene();
        var camera = new THREE.PerspectiveCamera(42, 1, 0.1, 1000);

        if (backgroundColor) {
          try {
            scene.background = new THREE.Color(backgroundColor);
          } catch (_bgColErr) {
            // Ignore invalid color string
          }
        }

        if (backgroundImage && THREE.TextureLoader) {
          var loader = new THREE.TextureLoader();
          loader.load(
            backgroundImage,
            function(texture) {
              if (disposed) {
                texture.dispose();
                return;
              }
              backgroundTexture = texture;
              if (THREE.SRGBColorSpace && "colorSpace" in texture) {
                texture.colorSpace = THREE.SRGBColorSpace;
              }
              if (backgroundMode === "tile") {
                texture.wrapS = THREE.RepeatWrapping;
                texture.wrapT = THREE.RepeatWrapping;
                texture.repeat.set(4, 4);
              } else {
                texture.wrapS = THREE.ClampToEdgeWrapping;
                texture.wrapT = THREE.ClampToEdgeWrapping;
              }
              scene.background = texture;
              if (renderer) {
                renderer.render(scene, camera);
              }
            },
            undefined,
            function(_loadErr) {
              // Silently handle texture loading failure
            }
          );
        }

        // Multi-directional lighting so extruded faces stay legible throughout rotation
        var ambientLight = new THREE.AmbientLight(0xffffff, 1.4);
        scene.add(ambientLight);

        var keyLight = new THREE.DirectionalLight(0xffffff, 1.85);
        keyLight.position.set(4, 6, 8);
        scene.add(keyLight);

        var fillLight = new THREE.DirectionalLight(0xffffff, 0.95);
        fillLight.position.set(-5, -4, 6);
        scene.add(fillLight);

        var rimLight = new THREE.DirectionalLight(0xffffff, 0.75);
        rimLight.position.set(0, 3, -7);
        scene.add(rimLight);

        var threeColor;
        try {
          threeColor = new THREE.Color(quoteColor);
        } catch (_colorErr) {
          threeColor = new THREE.Color(DEFAULT_COLOR);
        }

        material = new THREE.MeshStandardMaterial({
          color: threeColor,
          roughness: 0.32,
          metalness: 0.12
        });

        var pivotGroup = new THREE.Group();
        var textContainer = new THREE.Group();
        var lineSpacing = 1.48;

        for (var i = 0; i < lines.length; i++) {
          var lineGeo = new THREE.TextGeometry(lines[i], {
            font: THREE.HelvetikerFont,
            size: 1,
            depth: 0.28,
            curveSegments: 8,
            bevelEnabled: true,
            bevelThickness: 0.04,
            bevelSize: 0.025,
            bevelSegments: 4
          });
          lineGeo.computeBoundingBox();
          if (lineGeo.boundingBox) {
            var lineOffsetX = -0.5 * (lineGeo.boundingBox.max.x + lineGeo.boundingBox.min.x);
            lineGeo.translate(lineOffsetX, 0, 0);
          }
          geometries.push(lineGeo);

          var lineMesh = new THREE.Mesh(lineGeo, material);
          lineMesh.position.y = -i * lineSpacing;
          textContainer.add(lineMesh);
        }

        // Shift textContainer so pivotGroup's (0, 0, 0) centroid aligns with rotation pivot
        var combinedBox = new THREE.Box3().setFromObject(textContainer);
        var boxCenter = new THREE.Vector3();
        var boxSize = new THREE.Vector3();
        combinedBox.getCenter(boxCenter);
        combinedBox.getSize(boxSize);

        textContainer.position.sub(boxCenter);
        pivotGroup.add(textContainer);
        scene.add(pivotGroup);

        function updateLayoutAndCamera() {
          if (disposed || !renderer) return;
          var width = Math.max(host.clientWidth || 0, 1);
          var height = Math.max(host.clientHeight || 0, 1);

          renderer.setSize(width, height, false);
          camera.aspect = width / height;
          camera.updateProjectionMatrix();

          var vFov = THREE.MathUtils.degToRad(camera.fov);
          var hFov = 2 * Math.atan(Math.tan(vFov / 2) * camera.aspect);

          // Account for full rotational sweep across X, Y, or Z rotation
          var maxRotRadius = Math.hypot(boxSize.x, boxSize.y, boxSize.z) * 0.5;
          var distY = maxRotRadius / Math.tan(vFov / 2);
          var distX = maxRotRadius / Math.tan(Math.max(hFov / 2, 0.05));
          var distance = Math.max(distX, distY, 2.5) * 1.35;

          camera.position.set(0, 0, distance);
          camera.lookAt(0, 0, 0);
        }

        onWindowResize = updateLayoutAndCamera;
        updateLayoutAndCamera();
        renderer.render(scene, camera);

        if (window.ResizeObserver) {
          resizeObserver = new ResizeObserver(function() {
            if (disposed || !renderer) return;
            updateLayoutAndCamera();
            renderer.render(scene, camera);
          });
          resizeObserver.observe(host);
        } else {
          window.addEventListener("resize", onWindowResize);
        }

        var lastTime = performance.now();

        host._threeQuoteDebug = {
          getRotationX: function() { return pivotGroup.rotation.x; },
          getRotationY: function() { return pivotGroup.rotation.y; },
          getRotationZ: function() { return pivotGroup.rotation.z; },
          getRotationAxis: function() { return rotationAxis; },
          getBackgroundMode: function() { return backgroundMode; },
          lineCount: lines.length
        };

        function animate(now) {
          if (disposed) return;
          var dt = Math.min(Math.max((now - lastTime) / 1000, 0), 0.1);
          lastTime = now;

          if (rotationAxis === "y") {
            pivotGroup.rotation.y += ROTATION_SPEED_RAD_PER_SEC * dt;
          } else if (rotationAxis === "z") {
            pivotGroup.rotation.z += ROTATION_SPEED_RAD_PER_SEC * dt;
          } else {
            pivotGroup.rotation.x += ROTATION_SPEED_RAD_PER_SEC * dt;
          }
          renderer.render(scene, camera);

          animateRafId = window.requestAnimationFrame(animate);
        }

        animateRafId = window.requestAnimationFrame(animate);
      });

      return function cleanup() {
        disposed = true;
        if (initRafId !== null) {
          window.cancelAnimationFrame(initRafId);
        }
        if (animateRafId !== null) {
          window.cancelAnimationFrame(animateRafId);
        }
        if (resizeObserver) {
          resizeObserver.disconnect();
        } else if (onWindowResize) {
          window.removeEventListener("resize", onWindowResize);
        }

        if (backgroundTexture) {
          backgroundTexture.dispose();
          backgroundTexture = null;
        }

        for (var g = 0; g < geometries.length; g++) {
          geometries[g].dispose();
        }
        if (material) {
          material.dispose();
        }
        if (renderer) {
          renderer.dispose();
        }
        if (canvas && canvas.parentNode === host) {
          host.removeChild(canvas);
        }
        delete host._threeQuoteDebug;
      };
    }, [quoteText, quoteColor, rotationAxis, backgroundColor, backgroundImage, backgroundMode]);

    if (webglFailed) {
      var fallbackStyle = { color: quoteColor };
      if (backgroundColor) {
        fallbackStyle.backgroundColor = backgroundColor;
      }
      return React.createElement(
        "div",
        {
          className: "flex h-full w-full items-center justify-center px-6 text-center",
          "data-three-js-fallback": "true",
          style: fallbackStyle
        },
        React.createElement(
          "p",
          { className: "text-xl sm:text-2xl font-semibold tracking-tight" },
          quoteText
        )
      );
    }

    return React.createElement("div", {
      ref: hostRef,
      className: "w-full h-full",
      "data-three-js-scene-host": "true"
    });
  }

  function unmountEntry(el, entry) {
    try {
      if (window.ReactDOM && typeof window.ReactDOM.flushSync === "function") {
        window.ReactDOM.flushSync(function() {
          entry.root.unmount();
        });
      } else {
        entry.root.unmount();
      }
    } catch (_err) {
      // Ignore unmount errors on already-detached trees
    }
    el.innerHTML = "";
    mountedRoots.delete(el);
  }

  function cleanupDetachedRoots() {
    mountedRoots.forEach(function(entry, el) {
      if (!document.documentElement.contains(el)) {
        unmountEntry(el, entry);
      }
    });
  }

  function mountQuoteElement(el) {
    if (!window.React || !window.ReactDOM || typeof window.ReactDOM.createRoot !== "function") {
      return;
    }

    var text = el.getAttribute("data-quote-text") || "";
    var color = el.getAttribute("data-quote-color") || DEFAULT_COLOR;
    var axis = (el.getAttribute("data-rotation-axis") || "x").toLowerCase();
    if (axis !== "x" && axis !== "y" && axis !== "z") {
      axis = "x";
    }
    var backgroundColor = el.getAttribute("data-background-color") || null;
    var backgroundImage = el.getAttribute("data-background-image") || null;
    var backgroundMode = (el.getAttribute("data-background-mode") || "stretch").toLowerCase();
    if (backgroundMode !== "tile") {
      backgroundMode = "stretch";
    }

    if (!text.trim()) return;

    var propsKey = [text, color, axis, backgroundColor || "", backgroundImage || "", backgroundMode].join("\u0000");
    var sceneProps = {
      text: text,
      color: color,
      rotationAxis: axis,
      backgroundColor: backgroundColor,
      backgroundImage: backgroundImage,
      backgroundMode: backgroundMode
    };

    var existing = mountedRoots.get(el);

    if (existing) {
      if (existing.propsKey === propsKey) {
        return;
      }
      existing.propsKey = propsKey;
      existing.root.render(
        window.React.createElement(ThreeJsQuoteScene, sceneProps)
      );
      return;
    }

    var root = window.ReactDOM.createRoot(el);
    mountedRoots.set(el, { root: root, propsKey: propsKey });
    root.render(
      window.React.createElement(ThreeJsQuoteScene, sceneProps)
    );
  }

  function mountAll(scope) {
    cleanupDetachedRoots();
    var rootNode = scope && typeof scope.querySelectorAll === "function" ? scope : document;
    var targets = rootNode.querySelectorAll("[data-three-js-quote-mount]");
    for (var i = 0; i < targets.length; i++) {
      mountQuoteElement(targets[i]);
    }
  }

  function unmountAll() {
    var entries = Array.from(mountedRoots.entries());
    for (var i = 0; i < entries.length; i++) {
      unmountEntry(entries[i][0], entries[i][1]);
    }
  }

  window.MacronThreeJsQuote = {
    mountAll: mountAll,
    unmountAll: unmountAll,
    getMountedCount: function() { return mountedRoots.size; }
  };

  document.addEventListener("DOMContentLoaded", function() { mountAll(); });
  document.addEventListener("turbo:load", function() { mountAll(); });
  document.addEventListener("turbo:render", function() { mountAll(); });
  document.addEventListener("turbo:frame-load", function(e) { mountAll(e.target); });
  document.addEventListener("turbo:before-render", function() { cleanupDetachedRoots(); });
  document.addEventListener("turbo:before-cache", function() { unmountAll(); });

  if (document.readyState !== "loading") {
    mountAll();
  }
})();
