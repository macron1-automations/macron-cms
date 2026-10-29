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
    var rotationSpeed = typeof props.rotationSpeed === "number" ? props.rotationSpeed : 1.0;
    var fontSize = props.fontSize || "md";
    var font = props.font || "helvetiker";
    var backgroundColor = props.backgroundColor || null;
    var backgroundImage = props.backgroundImage || null;
    var backgroundMode = props.backgroundMode || "stretch";
    var scanlinesIntensity = props.scanlinesIntensity || "off";
    var scanlinesDensity = props.scanlinesDensity || "medium";
    var scanlinesSpeed = props.scanlinesSpeed || "normal";

    React.useEffect(function() {
      var host = hostRef.current;
      var THREE = window.THREE;
      var resolvedFont = (window.THREE && window.THREE.Fonts && window.THREE.Fonts[font]) ||
                         (window.THREE && window.THREE.HelvetikerFont);

      if (!host || !THREE || !THREE.TextGeometry || !resolvedFont) {
        setWebglFailed(true);
        return undefined;
      }

      var FONT_SIZE_SCALES = {
        sm: { scale: 0.85, maxChars: 28 },
        md: { scale: 1.15, maxChars: 24 },
        lg: { scale: 1.5, maxChars: 20 },
        xl: { scale: 1.9, maxChars: 16 }
      };
      var sizeConfig = FONT_SIZE_SCALES[fontSize] || FONT_SIZE_SCALES.md;

      var INTENSITY_VALUES = {
        off: 0.0,
        subtle: 0.22,
        medium: 0.48,
        strong: 0.78
      };
      var DENSITY_VALUES = {
        fine: 750.0,
        medium: 400.0,
        coarse: 200.0
      };
      var SPEED_VALUES = {
        still: 0.0,
        slow: 0.35,
        normal: 1.1,
        fast: 2.4
      };
      var intensityVal = INTENSITY_VALUES[scanlinesIntensity] || 0.0;
      var densityVal = DENSITY_VALUES[scanlinesDensity] || DENSITY_VALUES.medium;
      var speedVal = SPEED_VALUES[scanlinesSpeed] || SPEED_VALUES.normal;

      var lines = wrapQuoteLines(quoteText, sizeConfig.maxChars);
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
      var renderTarget = null;
      var postScene = null;
      var postCamera = null;
      var postMaterial = null;
      var postQuad = null;

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

        if (intensityVal > 0.0 && THREE.WebGLRenderTarget && THREE.ShaderMaterial && THREE.OrthographicCamera && THREE.PlaneGeometry) {
          renderTarget = new THREE.WebGLRenderTarget(1, 1, {
            minFilter: THREE.LinearFilter,
            magFilter: THREE.LinearFilter,
            format: THREE.RGBAFormat
          });

          postMaterial = new THREE.ShaderMaterial({
            uniforms: {
              tDiffuse: { value: renderTarget.texture },
              time: { value: 0 },
              intensity: { value: intensityVal },
              density: { value: densityVal },
              speed: { value: speedVal }
            },
            vertexShader: [
              "varying vec2 vUv;",
              "void main() {",
              "  vUv = uv;",
              "  gl_Position = vec4(position, 1.0);",
              "}"
            ].join("\n"),
            fragmentShader: [
              "uniform sampler2D tDiffuse;",
              "uniform float time;",
              "uniform float intensity;",
              "uniform float density;",
              "uniform float speed;",
              "varying vec2 vUv;",
              "void main() {",
              "  vec4 baseColor = texture2D(tDiffuse, vUv);",
              "  if (intensity <= 0.0) {",
              "    gl_FragColor = baseColor;",
              "    return;",
              "  }",
              "  float scanline = sin((vUv.y + time * speed) * density * 3.14159);",
              "  scanline = (scanline + 1.0) * 0.5;",
              "  float factor = 1.0 - (intensity * (1.0 - scanline));",
              "  gl_FragColor = vec4(baseColor.rgb * factor, baseColor.a);",
              "}"
            ].join("\n")
          });

          postCamera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
          postQuad = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), postMaterial);
          postScene = new THREE.Scene();
          postScene.add(postQuad);
        }

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
        var lineSpacing = 1.48 * sizeConfig.scale;

        for (var i = 0; i < lines.length; i++) {
          var lineGeo = new THREE.TextGeometry(lines[i], {
            font: resolvedFont,
            size: 1 * sizeConfig.scale,
            depth: 0.28 * sizeConfig.scale,
            curveSegments: 8,
            bevelEnabled: true,
            bevelThickness: 0.04 * sizeConfig.scale,
            bevelSize: 0.025 * sizeConfig.scale,
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

        function renderScene() {
          if (disposed || !renderer) return;
          if (renderTarget && postScene && postCamera) {
            renderer.setRenderTarget(renderTarget);
            renderer.render(scene, camera);
            renderer.setRenderTarget(null);
            renderer.render(postScene, postCamera);
          } else {
            renderer.render(scene, camera);
          }
        }

        function updateLayoutAndCamera() {
          if (disposed || !renderer) return;
          var width = Math.max(host.clientWidth || 0, 1);
          var height = Math.max(host.clientHeight || 0, 1);

          renderer.setSize(width, height, false);
          if (renderTarget) {
            renderTarget.setSize(width, height);
          }

          camera.aspect = width / height;
          camera.updateProjectionMatrix();

          var vFov = THREE.MathUtils.degToRad(camera.fov);
          var hFov = 2 * Math.atan(Math.tan(vFov / 2) * camera.aspect);

          // Calculate exact rotational bounding envelope per axis
          var rotHeight, rotWidth;
          if (rotationAxis === "y") {
            rotHeight = boxSize.y;
            rotWidth = Math.hypot(boxSize.x, boxSize.z);
          } else if (rotationAxis === "z") {
            rotHeight = Math.hypot(boxSize.x, boxSize.y);
            rotWidth = rotHeight;
          } else {
            // "x" axis: flips top-to-bottom around X
            rotHeight = Math.hypot(boxSize.y, boxSize.z);
            rotWidth = boxSize.x;
          }

          var distY = (rotHeight * 0.5) / Math.tan(vFov / 2);
          var distX = (rotWidth * 0.5) / Math.tan(Math.max(hFov / 2, 0.05));
          var distance = Math.max(distX, distY, 2.0) * 1.18;

          camera.position.set(0, 0, distance);
          camera.lookAt(0, 0, 0);
        }

        onWindowResize = updateLayoutAndCamera;
        updateLayoutAndCamera();
        renderScene();

        if (window.ResizeObserver) {
          resizeObserver = new ResizeObserver(function() {
            if (disposed || !renderer) return;
            updateLayoutAndCamera();
            renderScene();
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
          getRotationSpeed: function() { return rotationSpeed; },
          getFontSize: function() { return fontSize; },
          getFont: function() { return font; },
          getBackgroundMode: function() { return backgroundMode; },
          getScanlinesIntensity: function() { return scanlinesIntensity; },
          hasScanlinesShader: function() { return !!renderTarget; },
          lineCount: lines.length
        };

        function animate(now) {
          if (disposed) return;
          var dt = Math.min(Math.max((now - lastTime) / 1000, 0), 0.1);
          lastTime = now;

          if (rotationSpeed > 0) {
            var dRot = ROTATION_SPEED_RAD_PER_SEC * rotationSpeed * dt;
            if (rotationAxis === "y") {
              pivotGroup.rotation.y += dRot;
            } else if (rotationAxis === "z") {
              pivotGroup.rotation.z += dRot;
            } else {
              pivotGroup.rotation.x += dRot;
            }
          }

          if (renderTarget && postMaterial) {
            postMaterial.uniforms.time.value += dt;
          }

          renderScene();

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

        if (renderTarget) {
          renderTarget.dispose();
          renderTarget = null;
        }

        if (postMaterial) {
          postMaterial.dispose();
          postMaterial = null;
        }

        if (postQuad) {
          if (postQuad.geometry) postQuad.geometry.dispose();
          postQuad = null;
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
    }, [quoteText, quoteColor, rotationAxis, rotationSpeed, fontSize, font, backgroundColor, backgroundImage, backgroundMode, scanlinesIntensity, scanlinesDensity, scanlinesSpeed]);

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
    var rotationSpeed = parseFloat(el.getAttribute("data-rotation-speed") || "1");
    if (isNaN(rotationSpeed) || rotationSpeed < 0) {
      rotationSpeed = 1.0;
    }
    var fontSize = (el.getAttribute("data-font-size") || "md").toLowerCase();
    if (fontSize !== "sm" && fontSize !== "md" && fontSize !== "lg" && fontSize !== "xl") {
      fontSize = "md";
    }
    var font = (el.getAttribute("data-font") || "helvetiker").toLowerCase();
    var backgroundColor = el.getAttribute("data-background-color") || null;
    var backgroundImage = el.getAttribute("data-background-image") || null;
    var backgroundMode = (el.getAttribute("data-background-mode") || "stretch").toLowerCase();
    if (backgroundMode !== "tile") {
      backgroundMode = "stretch";
    }
    var scanlinesIntensity = (el.getAttribute("data-scanlines-intensity") || "off").toLowerCase();
    var scanlinesDensity = (el.getAttribute("data-scanlines-density") || "medium").toLowerCase();
    var scanlinesSpeed = (el.getAttribute("data-scanlines-speed") || "normal").toLowerCase();

    if (!text.trim()) return;

    var propsKey = [
      text, color, axis, rotationSpeed, fontSize, font,
      backgroundColor || "", backgroundImage || "", backgroundMode,
      scanlinesIntensity, scanlinesDensity, scanlinesSpeed
    ].join("\u0000");

    var sceneProps = {
      text: text,
      color: color,
      rotationAxis: axis,
      rotationSpeed: rotationSpeed,
      fontSize: fontSize,
      font: font,
      backgroundColor: backgroundColor,
      backgroundImage: backgroundImage,
      backgroundMode: backgroundMode,
      scanlinesIntensity: scanlinesIntensity,
      scanlinesDensity: scanlinesDensity,
      scanlinesSpeed: scanlinesSpeed
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
