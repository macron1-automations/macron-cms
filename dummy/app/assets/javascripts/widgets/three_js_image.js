/* MacronCMS Three.js Image FX Widget (Three.js WebGL Shaders + Turbo) */
(function() {
  "use strict";

  var mountedInstances = new Map();

  var SPEED_MULTIPLIERS = {
    slow: 0.5,
    normal: 1.0,
    fast: 2.0
  };

  var INTENSITY_MULTIPLIERS = {
    subtle: 0.45,
    medium: 1.0,
    strong: 1.8
  };

  var VERTEX_SHADER = [
    "varying vec2 vUv;",
    "void main() {",
    "  vUv = uv;",
    "  gl_Position = vec4(position, 1.0);",
    "}"
  ].join("\n");

  var FRAGMENT_SHADER = [
    "precision highp float;",
    "varying vec2 vUv;",
    "uniform sampler2D u_texture;",
    "uniform float u_time;",
    "uniform float u_speed;",
    "uniform float u_intensity;",
    "uniform int u_effect;", // 0: ripple, 1: wave, 2: glitch
    "uniform int u_fit_mode;", // 0: cover, 1: contain
    "uniform vec2 u_resolution;",
    "uniform vec2 u_image_resolution;",

    "vec2 computeFittedUv(vec2 uv) {",
    "  float canvasAspect = u_resolution.x / max(u_resolution.y, 1.0);",
    "  float imageAspect = u_image_resolution.x / max(u_image_resolution.y, 1.0);",
    "  vec2 scale = vec2(1.0);",
    "  if (u_fit_mode == 0) {", // cover
    "    if (canvasAspect > imageAspect) {",
    "      scale = vec2(1.0, imageAspect / canvasAspect);",
    "    } else {",
    "      scale = vec2(canvasAspect / imageAspect, 1.0);",
    "    }",
    "  } else {", // contain
    "    if (canvasAspect > imageAspect) {",
    "      scale = vec2(canvasAspect / imageAspect, 1.0);",
    "    } else {",
    "      scale = vec2(1.0, imageAspect / canvasAspect);",
    "    }",
    "  }",
    "  return (uv - 0.5) * scale + 0.5;",
    "}",

    "vec2 applyWaterRipple(vec2 uv, float t, float intensity) {",
    "  vec2 total = vec2(0.0);",
    "  vec2 centers[4];",
    "  centers[0] = vec2(0.50, 0.50);",
    "  centers[1] = vec2(0.25, 0.68);",
    "  centers[2] = vec2(0.75, 0.35);",
    "  centers[3] = vec2(0.40, 0.22);",
    "  float offsets[4];",
    "  offsets[0] = 0.0;",
    "  offsets[1] = 1.3;",
    "  offsets[2] = 2.6;",
    "  offsets[3] = 3.9;",

    "  for (int i = 0; i < 4; i++) {",
    "    float phase = mod(t * 1.25 + offsets[i], 4.0);",
    "    float dist = distance(uv, centers[i]);",
    "    float waveFront = phase * 0.42;",
    "    float delta = dist - waveFront;",
    "    float envelope = exp(-dist * 2.5) * exp(-(delta * delta) / 0.018);",
    "    float wave = sin(dist * 38.0 - phase * 12.0) * envelope;",
    "    vec2 dir = (dist > 0.001) ? normalize(uv - centers[i]) : vec2(0.0);",
    "    total += dir * wave * 0.038 * intensity;",
    "  }",
    "  return total;",
    "}",

    "vec2 applyUnderwaterWave(vec2 uv, float t, float intensity) {",
    "  float w1 = sin(uv.y * 12.0 + t * 2.2);",
    "  float w2 = cos(uv.x * 10.0 - t * 1.8);",
    "  float w3 = sin((uv.x + uv.y) * 8.0 + t * 2.8);",
    "  float dx = (w1 * 0.016 + w3 * 0.010) * intensity;",
    "  float dy = (w2 * 0.016 - w3 * 0.010) * intensity;",
    "  return vec2(dx, dy);",
    "}",

    "void main() {",
    "  float t = u_time * u_speed;",
    "  vec2 uv = vUv;",
    "  vec2 displacedUv = uv;",

    "  if (u_effect == 0) {", // Water Ripple
    "    displacedUv += applyWaterRipple(uv, t, u_intensity);",
    "    vec2 texUv = computeFittedUv(displacedUv);",
    "    if (u_fit_mode == 1 && (texUv.x < 0.0 || texUv.x > 1.0 || texUv.y < 0.0 || texUv.y > 1.0)) {",
    "      gl_FragColor = vec4(0.05, 0.05, 0.08, 1.0);",
    "    } else {",
    "      vec4 col = texture2D(u_texture, clamp(texUv, 0.0, 1.0));",
    "      // Add subtle watery specular sheen",
    "      float sheen = length(applyWaterRipple(uv, t, u_intensity)) * 3.5 * u_intensity;",
    "      gl_FragColor = vec4(col.rgb + vec3(sheen * 0.25, sheen * 0.35, sheen * 0.45), col.a);",
    "    }",
    "  } else if (u_effect == 1) {", // Underwater Wave
    "    displacedUv += applyUnderwaterWave(uv, t, u_intensity);",
    "    vec2 texUv = computeFittedUv(displacedUv);",
    "    if (u_fit_mode == 1 && (texUv.x < 0.0 || texUv.x > 1.0 || texUv.y < 0.0 || texUv.y > 1.0)) {",
    "      gl_FragColor = vec4(0.05, 0.05, 0.08, 1.0);",
    "    } else {",
    "      gl_FragColor = texture2D(u_texture, clamp(texUv, 0.0, 1.0));",
    "    }",
    "  } else {", // RGB Glitch
    "    float slice = sin(uv.y * 65.0 + t * 9.0);",
    "    float pulse = step(0.85, sin(t * 3.1) * cos(t * 1.7));",
    "    float glitchOffset = (sin(t * 22.0) * 0.015 + slice * 0.009) * pulse * u_intensity;",
    "    vec2 baseUv = uv + vec2(glitchOffset, 0.0);",
    "    float rgbShift = (0.012 + 0.018 * pulse) * u_intensity;",
    "    vec2 texR = computeFittedUv(baseUv + vec2(rgbShift, 0.0));",
    "    vec2 texG = computeFittedUv(baseUv);",
    "    vec2 texB = computeFittedUv(baseUv - vec2(rgbShift, 0.0));",
    "    vec4 colR = texture2D(u_texture, clamp(texR, 0.0, 1.0));",
    "    vec4 colG = texture2D(u_texture, clamp(texG, 0.0, 1.0));",
    "    vec4 colB = texture2D(u_texture, clamp(texB, 0.0, 1.0));",
    "    if (u_fit_mode == 1 && (texG.x < 0.0 || texG.x > 1.0 || texG.y < 0.0 || texG.y > 1.0)) {",
    "      gl_FragColor = vec4(0.05, 0.05, 0.08, 1.0);",
    "    } else {",
    "      gl_FragColor = vec4(colR.r, colG.g, colB.b, (colR.a + colG.a + colB.a) / 3.0);",
    "    }",
    "  }",
    "}"
  ].join("\n");

  function ThreeJsImageInstance(container) {
    this.container = container;
    this.placeholder = container.querySelector("[data-three-js-image-placeholder]");
    this.imageUrl = container.getAttribute("data-image-url");
    this.effect = container.getAttribute("data-effect") || "ripple";
    this.speedKey = container.getAttribute("data-animation-speed") || "normal";
    this.intensityKey = container.getAttribute("data-intensity") || "medium";
    this.fitMode = container.getAttribute("data-fit-mode") || "cover";

    this.effectCode = (this.effect === "wave") ? 1 : ((this.effect === "glitch") ? 2 : 0);
    this.fitModeCode = (this.fitMode === "contain") ? 1 : 0;
    this.speedVal = SPEED_MULTIPLIERS[this.speedKey] || 1.0;
    this.intensityVal = INTENSITY_MULTIPLIERS[this.intensityKey] || 1.0;

    this.renderer = null;
    this.scene = null;
    this.camera = null;
    this.material = null;
    this.geometry = null;
    this.texture = null;
    this.rafId = null;
    this.startTime = null;
    this.resizeObserver = null;
    this.destroyed = false;

    this.init();
  }

  ThreeJsImageInstance.prototype.init = function() {
    var self = this;
    var THREE = window.THREE;
    if (!THREE || !this.imageUrl) {
      return;
    }

    var width = this.container.clientWidth || 300;
    var height = this.container.clientHeight || 240;

    try {
      this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: "high-performance" });
      this.renderer.setSize(width, height);
      this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
      this.renderer.domElement.className = "w-full h-full block";
      this.container.appendChild(this.renderer.domElement);
    } catch (e) {
      console.warn("WebGL initialization failed:", e);
      return;
    }

    this.scene = new THREE.Scene();
    this.camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
    this.geometry = new THREE.PlaneGeometry(2, 2);

    var loader = new THREE.TextureLoader();
    loader.setCrossOrigin("anonymous");
    loader.load(
      this.imageUrl,
      function(texture) {
        if (self.destroyed) {
          texture.dispose();
          return;
        }

        texture.wrapS = THREE.ClampToEdgeWrapping;
        texture.wrapT = THREE.ClampToEdgeWrapping;
        texture.minFilter = THREE.LinearFilter;
        texture.magFilter = THREE.LinearFilter;
        self.texture = texture;

        var imgWidth = texture.image ? (texture.image.naturalWidth || texture.image.width || 1) : 1;
        var imgHeight = texture.image ? (texture.image.naturalHeight || texture.image.height || 1) : 1;

        self.material = new THREE.ShaderMaterial({
          vertexShader: VERTEX_SHADER,
          fragmentShader: FRAGMENT_SHADER,
          uniforms: {
            u_texture: { value: texture },
            u_time: { value: 0.0 },
            u_speed: { value: self.speedVal },
            u_intensity: { value: self.intensityVal },
            u_effect: { value: self.effectCode },
            u_fit_mode: { value: self.fitModeCode },
            u_resolution: { value: new THREE.Vector2(width, height) },
            u_image_resolution: { value: new THREE.Vector2(imgWidth, imgHeight) }
          },
          depthTest: false,
          depthWrite: false
        });

        var mesh = new THREE.Mesh(self.geometry, self.material);
        self.scene.add(mesh);

        // Hide placeholder
        if (self.placeholder) {
          self.placeholder.style.opacity = "0";
          setTimeout(function() {
            if (self.placeholder && self.placeholder.parentNode) {
              self.placeholder.style.display = "none";
            }
          }, 320);
        }

        self.startAnimationLoop();
        self.setupResizeObserver();
      },
      undefined,
      function(err) {
        console.warn("Failed to load image texture for Three.js:", err);
      }
    );
  };

  ThreeJsImageInstance.prototype.startAnimationLoop = function() {
    var self = this;
    this.startTime = performance.now();

    function renderFrame(now) {
      if (self.destroyed) return;
      var elapsed = (now - self.startTime) * 0.001;

      if (self.material && self.material.uniforms) {
        self.material.uniforms.u_time.value = elapsed;
      }

      if (self.renderer && self.scene && self.camera) {
        self.renderer.render(self.scene, self.camera);
      }

      self.rafId = requestAnimationFrame(renderFrame);
    }

    this.rafId = requestAnimationFrame(renderFrame);
  };

  ThreeJsImageInstance.prototype.setupResizeObserver = function() {
    var self = this;
    if (typeof window.ResizeObserver === "function") {
      this.resizeObserver = new ResizeObserver(function(entries) {
        for (var i = 0; i < entries.length; i++) {
          var entry = entries[i];
          var w = entry.contentRect.width;
          var h = entry.contentRect.height;
          if (w > 0 && h > 0 && self.renderer && self.material) {
            self.renderer.setSize(w, h);
            self.material.uniforms.u_resolution.value.set(w, h);
          }
        }
      });
      this.resizeObserver.observe(this.container);
    }
  };

  ThreeJsImageInstance.prototype.destroy = function() {
    this.destroyed = true;

    if (this.rafId) {
      cancelAnimationFrame(this.rafId);
      this.rafId = null;
    }

    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
      this.resizeObserver = null;
    }

    if (this.material) {
      this.material.dispose();
      this.material = null;
    }

    if (this.geometry) {
      this.geometry.dispose();
      this.geometry = null;
    }

    if (this.texture) {
      this.texture.dispose();
      this.texture = null;
    }

    if (this.renderer) {
      if (this.renderer.domElement && this.renderer.domElement.parentNode) {
        this.renderer.domElement.parentNode.removeChild(this.renderer.domElement);
      }
      this.renderer.dispose();
      this.renderer = null;
    }

    this.scene = null;
    this.camera = null;
  };

  function computeInstanceKey(el) {
    return [
      el.getAttribute("data-image-url") || "",
      el.getAttribute("data-effect") || "",
      el.getAttribute("data-animation-speed") || "",
      el.getAttribute("data-intensity") || "",
      el.getAttribute("data-canvas-height") || "",
      el.getAttribute("data-fit-mode") || ""
    ].join("::");
  }

  function mountElement(el) {
    var currentKey = computeInstanceKey(el);
    var existing = mountedInstances.get(el);
    if (existing) {
      if (existing.key === currentKey) {
        return;
      }
      existing.instance.destroy();
      mountedInstances.delete(el);
    }

    var instance = new ThreeJsImageInstance(el);
    mountedInstances.set(el, { instance: instance, key: currentKey });
  }

  function cleanupDetached() {
    var entries = Array.from(mountedInstances.entries());
    for (var i = 0; i < entries.length; i++) {
      var el = entries[i][0];
      var entry = entries[i][1];
      if (!document.body.contains(el)) {
        entry.instance.destroy();
        mountedInstances.delete(el);
      }
    }
  }

  function mountAll(scope) {
    cleanupDetached();
    var rootNode = scope && typeof scope.querySelectorAll === "function" ? scope : document;
    var targets = rootNode.querySelectorAll("[data-three-js-image-mount]");
    for (var i = 0; i < targets.length; i++) {
      mountElement(targets[i]);
    }
  }

  function unmountAll() {
    var entries = Array.from(mountedInstances.entries());
    for (var i = 0; i < entries.length; i++) {
      var entry = entries[i][1];
      entry.instance.destroy();
    }
    mountedInstances.clear();
  }

  window.MacronThreeJsImage = {
    mountAll: mountAll,
    unmountAll: unmountAll,
    getMountedCount: function() { return mountedInstances.size; }
  };

  document.addEventListener("DOMContentLoaded", function() { mountAll(); });
  document.addEventListener("turbo:load", function() { mountAll(); });
  document.addEventListener("turbo:render", function() { mountAll(); });
  document.addEventListener("turbo:frame-load", function(e) { mountAll(e.target); });
  document.addEventListener("turbo:before-render", function() { cleanupDetached(); });
  document.addEventListener("turbo:before-cache", function() { unmountAll(); });

  if (document.readyState !== "loading") {
    mountAll();
  }
})();
