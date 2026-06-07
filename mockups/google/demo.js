/* Mockup-only helper: theme switcher (light / dark / auto) so both modes
   can be previewed & screenshotted. NOT part of the shipped theme — the
   real theme switches via the `simple_style` preference -> html.theme-*. */
(function () {
  var html = document.documentElement;
  var saved = localStorage.getItem("g-mock-theme");
  if (saved) { html.className = html.className.replace(/theme-\w+/, "theme-" + saved); }

  function set(mode) {
    html.className = html.className.replace(/theme-\w+/, "theme-" + mode);
    localStorage.setItem("g-mock-theme", mode);
    document.querySelectorAll("[data-theme-btn]").forEach(function (b) {
      b.setAttribute("aria-pressed", b.dataset.themeBtn === mode);
    });
  }

  document.addEventListener("click", function (e) {
    var btn = e.target.closest("[data-theme-btn]");
    if (btn) { set(btn.dataset.themeBtn); }
  });

  // reflect current mode on load
  var cur = (html.className.match(/theme-(\w+)/) || [, "auto"])[1];
  document.querySelectorAll("[data-theme-btn]").forEach(function (b) {
    b.setAttribute("aria-pressed", b.dataset.themeBtn === cur);
  });
})();
