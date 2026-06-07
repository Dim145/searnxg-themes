/*
 * google theme — image lightbox enhancements.
 *
 * Layered on top of simple's bundled JS (which we deliberately do NOT fork).
 * Two behaviours, both Google-Images-like:
 *
 *   1. Backdrop click closes the viewer. Clicking the dark overlay itself —
 *      not the image, the metadata panel, or the close/prev/next buttons —
 *      closes the lightbox by triggering simple's own close button.
 *
 *   2. Full-resolution loading spinner. simple first drops the cached grid
 *      thumbnail into the viewer (so the view is never a black void), then
 *      ~1s later swaps <img src> to the full-resolution `data-src`. That swap
 *      can be slow, so we show a spinner from the moment the hi-res request
 *      starts until it finishes decoding. Fast/cached images never flash it.
 */
(function () {
  "use strict";

  function init() {
    var results = document.getElementById("results");
    if (!results) return;

    /* ---- 2. full-resolution loading spinner ---------------------------- */
    function watchImage(img) {
      var detail = img.closest(".detail");
      if (!detail) return;

      // While `data-src` is still present, simple is showing the interim
      // thumbnail and hasn't requested the hi-res yet — no spinner needed.
      if (img.hasAttribute("data-src")) return;

      // `data-src` consumed → hi-res src is set. If it's already decoded we're
      // done; otherwise it's streaming in, so show the spinner until it lands.
      if (img.complete && img.naturalWidth > 0) {
        detail.classList.remove("is-loading");
        return;
      }
      if (img.dataset.gWatching) return; // a listener is already attached
      img.dataset.gWatching = "1";

      // Only reveal the spinner if the hi-res genuinely takes a moment — cached
      // or fast images shouldn't flash it, only "slow to load" ones should.
      var spinTimer = setTimeout(function () {
        detail.classList.add("is-loading");
      }, 180);
      var clear = function () {
        clearTimeout(spinTimer);
        img.removeEventListener("load", onLoad);
        img.removeEventListener("error", onErr);
        delete img.dataset.gWatching;
      };
      var onLoad = function () {
        detail.classList.remove("is-loading");
        clear();
      };
      var onErr = function () {
        // stop the spinner even if the hi-res fails (simple falls back to the
        // thumbnail via its own onerror handler).
        detail.classList.remove("is-loading");
        clear();
      };
      img.addEventListener("load", onLoad);
      img.addEventListener("error", onErr);
    }

    // simple loads images by mutating <img src>/`data-src`; watch those changes
    // on every viewer image (the swap to hi-res is what we care about).
    var obs = new MutationObserver(function (muts) {
      for (var i = 0; i < muts.length; i++) {
        var t = muts[i].target;
        if (
          t.nodeName === "IMG" &&
          t.parentElement &&
          t.parentElement.classList.contains("result-images-source")
        ) {
          watchImage(t);
        }
      }
    });
    obs.observe(results, {
      subtree: true,
      attributes: true,
      attributeFilter: ["src", "data-src"],
    });

    // handle an image already open on load (e.g. a deep link to #image-viewer)
    var open = results.querySelector(
      ".result[data-vim-selected] .result-images-source img"
    );
    if (open && open.getAttribute("src")) watchImage(open);

    /* ---- 1. click the dark backdrop to close --------------------------- */
    results.addEventListener("click", function (e) {
      if (!results.classList.contains("image-detail-open")) return;
      // The backdrop is the `.detail` node itself. Its children (image link,
      // `.result-images-labels`, the buttons) are never the bare `.detail`,
      // so a click whose target IS `.detail` happened on empty dark space.
      var el = e.target;
      if (el && el.classList && el.classList.contains("detail")) {
        e.preventDefault();
        var close = el.querySelector(".result-detail-close");
        if (close) close.click(); // reuse simple's own closeDetail()
      }
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
