/**
 * markdown-preview.nvim 预览页：图片/流程图「放大查看」增强（lightbox）
 *
 * 功能（原生 JavaScript，无第三方依赖）：
 *   1. 点击正文中的图片或流程图（<img>、mermaid/flowchart/dot/sequence 的
 *      SVG、chart.js 的 <canvas>）即打开全屏遮罩弹层，独立查看原图内容。
 *   2. 弹层内：
 *        - 滚轮：以鼠标指针为中心放大/缩小（比例范围 20% ~ 500%）；
 *        - 按住左键拖动：平移内容，可看清任意细节；
 *        - 双击内容：重置为自适应大小；
 *        - 点击弹层空白、按 Esc、或点右上角 ×：关闭。
 *   3. 左下角实时显示当前缩放比例，顶部提示操作方式。
 *
 * 实现要点：
 *   - 事件全部委托在 document / 弹层上，不依赖 React 渲染时机，
 *     预览内容动态刷新后依然有效。
 *   - 弹层节点由 JS 动态创建并即时移除，不污染预览原有 DOM。
 *   - 缩放用 content 的 transform: translate(tx,ty) scale(s) 实现，
 *     滚轮缩放时按“光标处内容不动”的锚点公式回推 tx/ty。
 *
 * 注入方式：见仓库 scripts/patch-markdown-preview.sh —— 把本文件复制到插件
 * app/_static/mkdp-zoom.js，并在 app/out/index.html 的 </body> 前注入
 * <script src="/_static/mkdp-zoom.js">。
 */
(function () {
  "use strict";

  // 命中的可缩放元素（限定在预览正文 .markdown-body 内的图片/图）
  var SELECTOR =
    ".markdown-body img, " +
    ".markdown-body .mermaid svg, " +
    ".markdown-body .flowchart svg, " +
    ".markdown-body .dot svg, " +
    ".markdown-body .sequence-diagrams svg, " +
    ".markdown-body .chartjs";

  var MIN_SCALE = 0.2; // 最小缩放 20%
  var MAX_SCALE = 5.0; // 最大缩放 500%
  var ZOOM_STEP = 1.25; // 滚轮每格缩放系数

  var overlay = null; // lightbox 遮罩
  var zoomViewport = null; // 用于捕获滚轮/拖拽的视口层
  var zoomStage = null; // 被 transform 的舞台层（放内容）
  var contentEl = null; // 舞台层内的内容图节点
  var current = null; // { scale, tx, ty, contentW, contentH }
  var drag = null; // 拖拽状态 { startX, startY, startTx, startTy }

  // ---------------- 工具 ----------------
  function clamp(v, lo, hi) {
    return v < lo ? lo : v > hi ? hi : v;
  }

  // 把被点击的元素转成能放入弹层的节点。
  function buildNodeFromTarget(el) {
    // 注意：<img>/<canvas> 的 tagName 是大写（IMG/CANVAS），而 SVG 元素的
    // tagName 是小写（svg）。统一 toLowerCase 判断，避免把 SVG 图漏掉。
    var tag = el.tagName ? el.tagName.toLowerCase() : "";
    if (tag === "img") {
      var img = document.createElement("img");
      img.src = el.currentSrc || el.src || el.getAttribute("src");
      img.alt = el.alt || "";
      return img;
    }
    if (tag === "svg") {
      // 矢量图直接克隆 DOM，保留完整结构和样式
      return el.cloneNode(true);
    }
    if (tag === "canvas") {
      // 已绘制的 canvas 不能克隆内容，转成 <img> 数据
      var img2 = document.createElement("img");
      try {
        img2.src = el.toDataURL();
      } catch (err) {
        img2.alt = "(图片无法导出)";
      }
      return img2;
    }
    return null;
  }

  // 读元素自然尺寸
  function readNaturalSize(el) {
    var tag = el.tagName ? el.tagName.toLowerCase() : "";
    if (tag === "img") {
      return {
        w: el.naturalWidth || el.clientWidth || 600,
        h: el.naturalHeight || el.clientHeight || 400,
      };
    }
    if (tag === "canvas") {
      return { w: el.width || 600, h: el.height || 400 };
    }
    if (tag === "svg") {
      var vb = el.viewBox && el.viewBox.baseVal;
      if (vb && vb.width) {
        return { w: vb.width, h: vb.height };
      }
      return {
        w: el.clientWidth || el.getBoundingClientRect().width || 600,
        h: el.clientHeight || el.getBoundingClientRect().height || 400,
      };
    }
    return { w: 600, h: 400 };
  }

  // 计算自适应初值：内容等比例放进视口（留边距）并居中
  function fitState(contentW, contentH, vw, vh) {
    var pad = 48; // 四周留白
    var s = Math.min((vw - pad) / contentW, (vh - pad) / contentH, 1);
    s = clamp(s, MIN_SCALE, MAX_SCALE);
    return {
      scale: s,
      tx: (vw - contentW * s) / 2,
      ty: (vh - contentH * s) / 2,
      contentW: contentW,
      contentH: contentH,
    };
  }

  function applyTransform() {
    if (zoomStage && current) {
      zoomStage.style.transform =
        "translate(" + current.tx + "px, " + current.ty + "px) scale(" + current.scale + ")";
    }
  }

  function updateScaleLabel() {
    var label = overlay && overlay.querySelector("#mkdp-zoom-scale");
    if (label && current) {
      label.textContent = Math.round(current.scale * 100) + "%";
    }
  }

  // ---------------- 打开 / 关闭 ----------------
  function closeLightbox() {
    if (!overlay) return;
    document.body.style.overflow = "";
    if (overlay.parentNode) overlay.parentNode.removeChild(overlay);
    overlay = null;
    zoomViewport = null;
    zoomStage = null;
    contentEl = null;
    current = null;
    drag = null;
  }

  function openLightbox(targetEl) {
    var node = buildNodeFromTarget(targetEl);
    if (!node) return;
    if (overlay) closeLightbox();

    var size = readNaturalSize(targetEl);
    var contentW = size.w;
    var contentH = size.h;

    // ---- 遮罩 ----
    overlay = document.createElement("div");
    overlay.className = "mkdp-zoom-overlay";
    overlay.style.cssText =
      "position:fixed;inset:0;z-index:2147483000;background:rgba(255,255,255,0.9);" +
      "display:flex;align-items:center;justify-content:center;cursor:grab;";

    // ---- 视口层（接收滚轮/拖拽）----
    zoomViewport = document.createElement("div");
    zoomViewport.id = "mkdp-zoom-viewport";
    zoomViewport.style.cssText =
      "position:absolute;inset:0;overflow:hidden;cursor:grab;";
    zoomStage = document.createElement("div");
    zoomStage.id = "mkdp-zoom-stage";
    zoomStage.style.cssText =
      "position:absolute;top:0;left:0;will-change:transform;";

    // ---- 内容图 ----
    contentEl = node;
    contentEl.style.cssText = "width:" + contentW + "px;height:" + contentH +
      "px;max-width:none;max-height:none;margin:0;display:block;";
    zoomStage.appendChild(contentEl);
    zoomViewport.appendChild(zoomStage);
    overlay.appendChild(zoomViewport);

    // ---- 右上角关闭按钮 ----
    var closeBtn = document.createElement("button");
    closeBtn.id = "mkdp-zoom-close";
    closeBtn.textContent = "\u2715";
    closeBtn.setAttribute("aria-label", "关闭放大查看");
    closeBtn.style.cssText =
      "position:absolute;top:12px;right:16px;z-index:6;color:#333;" +
      "background:rgba(0,0,0,0.06);border:1px solid rgba(0,0,0,0.25);" +
      "font-size:20px;line-height:1;padding:6px 12px;border-radius:6px;cursor:pointer;";
    closeBtn.addEventListener("click", function (e) {
      e.stopPropagation();
      closeLightbox();
    });
    overlay.appendChild(closeBtn);

    // ---- 顶部操作提示 ----
    var hint = document.createElement("div");
    hint.id = "mkdp-zoom-hint";
    hint.textContent = "滚轮缩放 · 拖动平移 · 双击复原 · Esc / 点击空白关闭";
    hint.style.cssText =
      "position:absolute;top:16px;left:50%;transform:translateX(-50%);z-index:6;" +
      "color:#444;font-size:13px;background:rgba(0,0,0,0.1);" +
      "padding:4px 12px;border-radius:4px;white-space:nowrap;pointer-events:none;";
    overlay.appendChild(hint);

    // ---- 左下角缩放比例 ----
    var scaleLabel = document.createElement("div");
    scaleLabel.id = "mkdp-zoom-scale";
    scaleLabel.style.cssText =
      "position:absolute;left:16px;bottom:12px;z-index:6;color:#333;font-size:14px;" +
      "background:rgba(0,0,0,0.1);padding:2px 10px;border-radius:4px;" +
      "font-variant-numeric:tabular-nums;pointer-events:none;";
    overlay.appendChild(scaleLabel);

    // ---- 挂载并初始化 ----
    document.body.appendChild(overlay);
    document.body.style.overflow = "hidden";

    var vw = zoomViewport.clientWidth || window.innerWidth;
    var vh = zoomViewport.clientHeight || window.innerHeight;
    current = fitState(contentW, contentH, vw, vh);
    applyTransform();
    updateScaleLabel();

    // ---- 事件绑定（视口层） ----
    zoomViewport.addEventListener("wheel", onWheel, { passive: false });
    zoomViewport.addEventListener("mousedown", onMouseDown);
    zoomViewport.addEventListener("dblclick", onDblClick);
    document.addEventListener("mousemove", onMouseMove);
    document.addEventListener("mouseup", onMouseUp);
  }

  // ---------------- 事件处理 ----------------
  function onWheel(e) {
    e.preventDefault();
    if (!current) return;
    var rect = zoomViewport.getBoundingClientRect();
    var mx = e.clientX - rect.left;
    var my = e.clientY - rect.top;
    var factor = e.deltaY < 0 ? ZOOM_STEP : 1 / ZOOM_STEP;
    var ns = clamp(current.scale * factor, MIN_SCALE, MAX_SCALE);
    if (ns === current.scale) return;

    var ratio = ns / current.scale;
    // 以光标点为锚保持该处内容不动：tx' = mx - (mx - tx) * ratio
    current.tx = mx - (mx - current.tx) * ratio;
    current.ty = my - (my - current.ty) * ratio;
    current.scale = ns;
    applyTransform();
    updateScaleLabel();
  }

  function onMouseDown(e) {
    if (e.button !== 0 || !current) return; // 仅左键
    drag = {
      startX: e.clientX,
      startY: e.clientY,
      startTx: current.tx,
      startTy: current.ty,
    };
    zoomViewport.style.cursor = "grabbing";
    e.preventDefault();
  }

  function onMouseMove(e) {
    if (!drag || !current) return;
    current.tx = drag.startTx + (e.clientX - drag.startX);
    current.ty = drag.startTy + (e.clientY - drag.startY);
    applyTransform();
  }

  function onMouseUp() {
    if (!drag) return;
    drag = null;
    if (zoomViewport) zoomViewport.style.cursor = "grab";
  }

  function onDblClick(e) {
    e.preventDefault();
    if (!current) return;
    var vw = zoomViewport.clientWidth || window.innerWidth;
    var vh = zoomViewport.clientHeight || window.innerHeight;
    current = fitState(current.contentW, current.contentH, vw, vh);
    applyTransform();
    updateScaleLabel();
  }

  // ---------- 全局委托：Esc 关闭 / 点击打开 ----------
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape" || e.key === "Esc" || e.keyCode === 27) {
      closeLightbox();
    }
  });

  document.addEventListener("click", function (e) {
    if (overlay) return; // 弹层开着时由弹层自身逻辑处理
    var t = e.target;
    if (!t || !t.closest || !t.closest(SELECTOR)) return;
    e.stopPropagation();
    openLightbox(t.closest(SELECTOR));
  });
})();