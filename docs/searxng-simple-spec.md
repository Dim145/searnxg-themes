# SearXNG "simple" Theme — Implementation-Ready Spec

> Purpose: map the real markup, blocks, CSS/JS contract, class-name hooks, light/dark
> mechanism, design tokens, and theme-name coupling of the SearXNG **simple** theme so a
> new **google** look-alike theme can be forked with HTML that maps cleanly onto SearXNG's
> server-rendered Jinja templates.
>
> Source of truth: `/tmp/searxng-research` (a full SearXNG checkout). Templates live in
> `searx/templates/simple/`, the Less/JS/TS source in `client/simple/src/`, and the build
> output lands in `searx/static/themes/simple/`. Everything below was read from the real
> files; quoted code is verbatim.

---

## 0. How SearXNG resolves a theme (the contract you must satisfy)

A "theme" is **two coupled directories that share a name**:

1. **Templates**: `searx/templates/<theme>/` — Jinja2 templates rendered server-side.
2. **Static build output**: `searx/static/themes/<theme>/` — the compiled CSS/JS/img.

Discovery is purely filesystem-based (`searx/webutils.py:177`):

```python
def get_themes(templates_path):
    """Returns available themes list."""
    return os.listdir(templates_path)
```

So the theme dropdown in preferences is literally "every subdir of `searx/templates/`".
Today that list is just `['simple']` (confirmed: `ls searx/templates/` → `simple`, and
`ls searx/static/themes/` → `simple`). Adding a `google` dir to both locations makes a new
theme selectable.

Static-file resolution falls back to the active theme (`searx/webapp.py:256` `custom_url_for`):
a template call `url_for('static', filename='img/favicon.png')` is rewritten to
`static/themes/<theme_name>/img/favicon.png` when the bare path is not found, where
`theme_name = sxng_request.preferences.get_value("theme")`. **This means most `url_for('static', filename='img/...')`
calls in templates are theme-relative automatically — they do NOT hardcode `simple`.**

Result-template resolution (`searx/webapp.py:246`) also prefers the active theme then falls back to a shared dir:

```python
def get_result_template(theme_name: str, template_name: str):
    themed_path = theme_name + '/result_templates/' + template_name
    if themed_path in result_templates:
        return themed_path
    return 'result_templates/' + template_name
```

**Important caveat:** `results.html` calls this with a *hardcoded* theme name:
`{% include get_result_template('simple', result['template']) %}` (see §7). A fork must
change that literal.

The default theme is set in `searx/settings_defaults.py:235`:
`'default_theme': SettingsValue(str, 'simple')`.

---

## 1. Page skeletons (real markup, trimmed but faithful)

### 1.1 Base layout — `simple/base.html`

The root `<html>` class carries the **theme-style** (light/dark) and **center-alignment**
flags. The `<main>` id is derived from the template name. Stylesheet/script wiring is in
`<head>` (see §3 & §5).

```html
<!DOCTYPE html>
<html class="no-js theme-{{ preferences.get_value('simple_style') or 'auto' }} center-alignment-{{ preferences.get_value('center_alignment') and 'yes' or 'no' }}" lang="{{ locale_rfc5646 }}" {% if rtl %} dir="rtl"{% endif %}>
<head>
  <meta charset="UTF-8">
  <meta name="endpoint" content="{{ endpoint }}">
  <title>{% block title %}{% endblock %}{{ instance_name }}</title>
  <script type="module" src="{{ url_for('static', filename='sxng-core.min.js') }}" client_settings="{{ client_settings }}"></script>
  {% block meta %}{% endblock %}
  {% if rtl %}
  <link rel="stylesheet" href="{{ url_for('static', filename='sxng-rtl.min.css') }}" type="text/css" media="screen">
  {% else %}
  <link rel="stylesheet" href="{{ url_for('static', filename='sxng-ltr.min.css') }}" type="text/css" media="screen">
  {% endif %}
  {% block head %}
  <link title="{{ instance_name }}" type="application/opensearchdescription+xml" rel="search" href="{{ opensearch_url }}">
  {% endblock %}
  <link rel="icon" href="{{ url_for('static', filename='img/favicon.png') }}" sizes="any">
  <link rel="icon" href="{{ url_for('static', filename='img/favicon.svg') }}" type="image/svg+xml">
  <link rel="apple-touch-icon" href="{{ url_for('static', filename='img/favicon.png') }}">
  <link rel="manifest" href="{{ url_for('manifest') }}" />
</head>
<body class="{{ endpoint }}_endpoint" >
  <main id="main_{{  self._TemplateReference__context.name|replace("simple/", "")|replace(".html", "") }}" class="{{body_class}}">
    {% if errors %}<div class="dialog-error" role="alert"> ... </div>{% endif %}

    <nav id="links_on_top">
      {%- from 'simple/icons.html' import icon_big -%}
      {%- block linkto_about -%}<a href="{{ url_for('info', pagename='about') }}" class="link_on_top_about">{{ icon_big('information-circle') }}<span>{{ _('About') }}</span></a>{%- endblock -%}
      {%- block linkto_donate -%}{% if donation_url %}<a href="{{ donation_url }}" class="link_on_top_donate">...</a>{% endif %}{%- endblock -%}
      {%- block linkto_preferences -%}<a href="{{ url_for('preferences') }}" class="link_on_top_preferences">{{ icon_big('settings') }}<span>{{ _('Preferences') }}</span></a>{%- endblock -%}
    </nav>
    {% block header %}{% endblock %}
    {% block content %}{% endblock %}
  </main>
  <footer>
    <p>{{ _('Powered by') }} <a href="...">SearXNG</a> - {{ searxng_version }} — {{ _('a privacy-respecting, open metasearch engine') }}<br>
      <a href="{{ searxng_git_url }}">{{ _('Source code') }}</a> | <a href="...">{{ _('Issue tracker') }}</a>
      {% if enable_metrics %}| <a href="{{ url_for('stats') }}">{{ _('Engine stats') }}</a>{% endif %}
      ...
    </p>
  </footer>
</body>
</html>
```

Notes that matter for a fork:
- The `<main>` id is computed by stripping `"simple/"` from the template path:
  `id="main_{{ self._TemplateReference__context.name|replace("simple/", "")|replace(".html", "") }}"`.
  **This `replace("simple/", "")` is theme-name-coupled** — a `google` fork that wants
  `#main_index`, `#main_results`, etc. must replace `"simple/"` with `"google/"`. CSS keys
  off `#main_index`, `#main_results` (see style.less / style-center.less).
- `<body>` class is `{{ endpoint }}_endpoint` (e.g. `index_endpoint`, `results_endpoint`,
  `preferences_endpoint`, `info_endpoint`, `stats_endpoint`). CSS uses `body.results_endpoint`.
- Top-right nav is `#links_on_top` with `.link_on_top_about`, `.link_on_top_donate`,
  `.link_on_top_preferences`.

### 1.2 Home page — `simple/index.html` (+ `simple/simple_search.html` via `search.html`)

```html
{% extends "simple/base.html" %}
{% from 'simple/icons.html' import icon_big %}
{% block content %}
<div class="index">
    <div class="title"><h1>SearXNG</h1></div>
    {% include 'simple/simple_search.html' %}
</div>
{% endblock %}
```

`.index .title` is a CSS background-image of the logo; the `<h1>` text is
`visibility: hidden` (logo shown via `background: url("./img/searxng.png")` in index.less).
`#main_index` gets `margin-top: 26vh`.

The home page's search box comes from **`simple_search.html`** (the minimal box, no
category tabs / no filters), NOT `search.html`:

```html
<form id="search" method="{{ method or 'POST' }}" action="{{ url_for('search') }}" role="search">
  <div id="search_header">
    <div id="search_view">
      <div class="search_box">
        <input id="q" name="q" type="text" placeholder="{{ _('Search for...') }}" autocomplete="off" ... value="{{ q or '' }}">
        <button id="clear_search" type="reset" aria-label="{{ _('clear') }}">...</button>
        <button id="send_search" type="submit" aria-label="{{ _('search') }}">...</button>
        <div class="autocomplete hide_if_nojs"><ul></ul></div>
      </div>
    </div>
  </div>
  {% for category in selected_categories %}<input type="hidden" name="category_{{ category }}" value="1"></ {% endfor %}
  <input type="hidden" name="language" value="{{ current_language }}">
  <input type="hidden" name="time_range" value="{{ time_range }}">
  <input type="hidden" name="safesearch" value="{{ safesearch }}">
  <input type="hidden" name="theme" value="{{ theme }}">
</form>
```

### 1.3 Search box with tabs + filters — `simple/search.html` (used on the results page)

This is the "full" search header used inside `results.html`. It adds the wordmark logo,
the category tabs (`categories.html`), and the filter selects (`filters/*`):

```html
<form id="search" method="{{ method or 'POST' }}" action="{{ url_for('search') }}" role="search">
  <div id="search_header">
    <a id="search_logo" href="{{ url_for('index') }}" tabindex="0" title="{{ _('Display the front page') }}">
      <span hidden>SearXNG</span>
      {% include 'simple/searxng-wordmark.min.svg' without context %}
    </a>
    <div id="search_view">
      <div class="search_box">
        <input id="q" name="q" type="text" placeholder="{{ _('Search for...') }}" tabindex="1" autocomplete="off" ... value="{{ q or '' }}">
        <button id="clear_search" type="reset" class="hide_if_nojs">...</button>
        <button id="send_search" type="submit" ...>...</button>
        <div class="autocomplete hide_if_nojs"><ul></ul></div>
      </div>
    </div>
    {% set display_tooltip = true %}
    {% include 'simple/categories.html' %}
  </div>
  <div class="search_filters">
    {% include 'simple/filters/languages.html' %}
    {% include 'simple/filters/time_range.html' %}
    {% include 'simple/filters/safesearch.html' %}
  </div>
  <input type="hidden" name="theme" value="{{ theme }}">
  {% if timeout_limit %}<input type="hidden" name="timeout_limit" value="{{ timeout_limit|e }}">{% endif %}
</form>
```

**Category tabs** — `simple/categories.html`. Two render modes: checkbox mode (default) and
`category_button` mode (when `search_on_category_select`). Icons come from a `category_icons` map.

```html
<div id="categories" class="search_categories">
    <div id="categories_container">
        <!-- checkbox mode (default) -->
        <div class="category category_checkbox">
            <input type="checkbox" id="checkbox_{{ category|replace(' ', '_') }}" name="category_{{ category }}" {% if category in selected_categories %}checked="checked"{% endif %}>
            <label for="checkbox_{{ category|replace(' ', '_') }}" class="tooltips">
                {{ icon_big(category_icons[category]) if ... else icon_big('globe') }}
                <div class="category_name">{{ _(category) }}</div>
            </label>
        </div>
        {% if display_tooltip %}<div class="help">{{ _('Click on the magnifier to perform search') }}</div>{% endif %}
        <!-- button mode (search_on_category_select): <button class="category category_button [selected]"> ... -->
    </div>
</div>
```

**Filters** — three `<select>` elements (`filters/languages.html`, `time_range.html`,
`safesearch.html`):

```html
<select class="language" id="language" name="language" aria-label="{{ _('Search language') }}">…</select>
<select class="time_range" id="time_range" name="time_range" aria-label="{{ _('Time range') }}">…</select>
<select class="safesearch" id="safesearch" name="safesearch" aria-label="{{ _('SafeSearch') }}">…</select>
```

### 1.4 Results page — `simple/results.html`

CSS-grid layout with named areas: `corrections`, `answers`, `urls`, `sidebar`,
`pagination` (see §4 grid). Trimmed faithful structure:

```html
{% extends "simple/base.html" %}
{% from 'simple/icons.html' import icon, icon_big, icon_small %}
{% block content %}
{% include 'simple/search.html' %}

{# only_template_<x> class set on #results when every result shares one template #}
<div id="results" class="{{ only_template }}">

  {%- if answers -%}{%- include 'simple/elements/answers.html' -%}{%- endif %}

  <div id="sidebar">
    {%- if infoboxes -%}
      <div id="infoboxes">
        <details open class="sidebar-collapsible">
          <summary class="title">{{ _('Info') }}</summary>
          {%- for infobox in infoboxes -%}{%- include 'simple/elements/infobox.html' -%}{%- endfor -%}
        </details>
      </div>
    {%- endif -%}
    {%- if suggestions -%}{%- include 'simple/elements/suggestions.html' -%}{%- endif -%}
    {%- include 'simple/elements/engines_msg.html' -%}
    {%- if method == 'POST' -%}{%- include 'simple/elements/search_url.html' -%}{%- endif -%}
    {%- if search_formats -%}{%- include 'simple/elements/apis.html' -%}{%- endif -%}
    <div id="sidebar-end-collapsible"></div>
  </div>

  {%- if corrections -%}{%- include 'simple/elements/corrections.html' -%}{%- endif -%}

  <div id="urls" role="main">
    {% for result in results %}
      {% if result.open_group and not only_template %}<div class="template_group_{{ result['template']|replace('.html', '') }}">{% endif %}
      {% set index = loop.index %}
      {% include get_result_template('simple', result['template']) %}
      {% if result.close_group and not only_template %}</div>{% endif %}
    {% endfor %}
    {% if not results and not answers %}{% include 'simple/messages/no_results.html' %}{% endif %}
  </div>

  <div id="backToTop"><a href="#" aria-label="{{ _('Back to top') }}">{{ icon_small('navigate-up') }}</a></div>

  {% if paging %}
  <nav id="pagination" role="navigation">
    {% if pageno > 1 %}<form ... class="previous_page"><div class="left"> ... <button role="link" type="submit">{{ icon_small('navigate-left') }} {{ _('Previous page') }}</button></div></form>{% endif %}
    {%- if results | count > 0 -%}<form ... class="next_page"><div class="right"> ... <button role="link" type="submit">{{ _('Next page') }} {{ icon_small('navigate-right') }}</button></div></form>{%- endif -%}
    <div class="numbered_pagination">
      {% for x in range(pstart, pend) %}
        <form ... class="page_number">
          ... hidden inputs (q, category_*, pageno=x, language, time_range, safesearch, theme, timeout_limit) ...
          {% if pageno == x %}<input role="link" class="page_number_current" type="button" value="{{ x }}">
          {% else %}<input role="link" class="page_number" type="submit" value="{{ x }}">{% endif %}
        </form>
      {% endfor %}
    </div>
  </nav>
  {% endif %}
</div>
{% endblock %}
```

Pagination is **form-based**, not link-based: each page button is a `<form>` that re-POSTs
the query with all filters as hidden inputs. Infinite scroll is JS-driven (`#results.scrolling`
toggles `#backToTop` visibility; `results.ts` handles thumbnail error swap). `only_template`
is `'only_template_' + <template-without-.html>` when all results share one template (drives
the image-grid layout, e.g. `only_template_images`).

The `engine_data_form(engine_data)` macro (defined inline at top of `results.html`) emits
`<input type="hidden" name="engine_data-{engine}-{k}" value="{v}">` and is injected into each
pagination form.

### 1.5 Preferences page — `simple/preferences.html` (extends `page_with_header.html`)

Tabbed UI built from CSS-only radio tabs. Macros `tabs_open / tab_header / tab_footer /
tabs_close` produce `<div class="tabs" role="tablist">` with `<input type="radio"
name="maintab">` + `<label role="tab">` + `<section role="tabpanel">`.

```html
{%- extends "simple/page_with_header.html" -%}
{%- block content -%}
  <h1>{{ _('Preferences') }}</h1>
  <form id="search_form" method="post" action="{{ url_for('preferences') }}" autocomplete="off">
    <div class="tabs" role="tablist">
      <input type="radio" name="maintab" id="tab-general" checked="checked">
      <label id="tab-label-general" for="tab-general" role="tab" aria-controls="tab-content-general">{{ _('General') }}</label>
      <section id="tab-content-general" role="tabpanel" aria-hidden="false">
        <fieldset><legend>{{ _('Default categories') }}</legend>{% include 'simple/categories.html' %}</fieldset>
        {%- include 'simple/preferences/language.html' -%}
        {%- include 'simple/preferences/autocomplete.html' -%}
        {%- include 'simple/preferences/favicon.html' -%}
        {%- include 'simple/preferences/safesearch.html' -%}
        {%- include 'simple/preferences/tokens.html' -%}
        ...
      </section>
      <!-- tab: ui (theme + simple_style + center_alignment + results_on_new_tab + ...) -->
      <!-- tab: privacy (method, image_proxy, query_in_title) -->
      <!-- tab: engines (nested .tabs) -->
      <!-- tab: query (answerers) -->
      <!-- tab: cookies -->
    </div>
    {%- include 'simple/preferences/footer.html' -%}
  </form>
{%- endblock -%}
```

Tab order & section includes: **general / ui / privacy / engines / query / cookies**.
Each fieldset is `<fieldset><legend id="pref_*">…</legend><div class="value">…</div>
<div class="description">…</div></fieldset>`. The on/off toggle is
`input.checkbox-onoff[type="checkbox"]` (and `.reversed-checkbox` variant for plugins).

`page_with_header.html` adds a logo header block:

```html
{%- set body_class = "page_with_header" -%}
{%- extends "simple/base.html" -%}
{%- block header -%}
  <a href="{{ url_for('index') }}"><img class="logo" src="{{ url_for('static', filename='img/searxng.png') }}" alt="SearXNG"></a>
{%- endblock -%}
```

### 1.6 A single web result — `result_templates/default.html` (+ `macros.html`)

`default.html` is thin; the structure comes from `macros.html` (`result_header`,
`result_sub_header`, `result_sub_footer`, `result_footer`). Effective rendered DOM:

```html
<article class="result result-default {% if result.category %}category-{{ result.category }}{% endif %}">
  <a href="{{ result.url }}" class="url_header" rel="noreferrer">      {# results_on_new_tab → target=_blank #}
    {%- if favicon_resolver != "" %}<div class="favicon"><img loading="lazy" src="{{ favicon_url(result.parsed_url.netloc) }}"></div>{% endif -%}
    <div class="url_wrapper">
      {%- for part in get_pretty_url(result.parsed_url) -%}
        <span class="url_o{{loop.index}}"><span class="url_i{{loop.index}}">{{ part }}</span></span>
      {%- endfor %}
    </div>
  </a>
  {# optional thumbnail link (a.thumbnail_link > img.thumbnail [+ span.thumbnail_length]) #}
  <h3><a href="{{ result.url }}" rel="noreferrer">{{ result.title|safe }}</a></h3>

  {# result_sub_header: time.published_date, div.result_length/result_views/result_author, div.highlight (metadata) #}

  {%- if result.iframe_src %}<p class="altlink"><a class="btn-collapse collapsed media-loader disabled_if_nojs" data-target="#result-media-{{ index }}" data-btn-text-collapsed="{{ _('show media') }}" data-btn-text-not-collapsed="{{ _('hide media') }}">{{ icon_small('play') }} {{ _('show media') }}</a></p>{% endif %}

  <p class="content">{{ result.content|safe }}</p>          {# or <p class="content empty_element"> if no description #}

  <div class="engines">{% for engine in result.engines %}<span>{{ engine }}</span>{% endfor %}{{ icon_small('ellipsis-vertical') }}<a href="{{ cache_url }}{{ result.url }}" class="cache_link" rel="noreferrer">{{ _('cached') }}</a></div>
  <div class="break"></div>

  {%- if result.iframe_src %}<div id="result-media-{{ index }}" class="embedded-content invisible"><iframe data-src="{{ result.iframe_src }}" ...></iframe></div>{% endif %}
  {%- if result.audio_src %}<div id="result-media-{{ index }}" class="audio-control"><audio controls><source src="{{ result.audio_src }}"></audio></div>{% endif %}
</article>
```

Key per-result hooks: `article.result.result-<template>.category-<cat>`, `a.url_header`,
`div.favicon`, `div.url_wrapper > span.url_o1/.url_i1` + `.url_o2/.url_i2`, `h3 > a`,
`p.content` (`.empty_element` when blank), `div.engines > span`, `a.cache_link`,
`a.thumbnail_link > img.thumbnail`, `div.break`.

### 1.7 An image result — `result_templates/images.html`

Images do NOT use the macros; they render a self-contained `<article>` plus a hidden
`.detail` lightbox (shown via JS when `#results.image-detail-open` + `article[data-vim-selected]`).

```html
<article class="result result-images {% if result.category %}category-{{ result.category }}{% endif %}">
  <a href="{{ result.img_src }}" rel="noreferrer">
    <img class="image_thumbnail" src="{{ image_proxify(result.thumbnail_src or result.img_src) }}" alt="{{ result.title|striptags }}" loading="lazy" width="200" height="200">
    {%- if result.resolution %}<span class="image_resolution">{{ result.resolution }}</span>{% endif -%}
    <span class="title">{{ result.title|striptags }}</span>
    <span class="source">{{ result.parsed_url.netloc }}</span>
  </a>
  <div class="detail swipe-horizontal">
    <a class="result-detail-close" href="#">{{ icon('close') }}</a>
    <a class="result-detail-previous" href="#">{{ icon('navigate-left') }}</a>
    <a class="result-detail-next" href="#">{{ icon('navigate-right') }}</a>
    <a class="result-images-source" href="{{ result.img_src }}"><img src="" data-src="{{ image_proxify(result.img_src) }}" alt="..."></a>
    <div class="result-images-labels">
      <h4>{{ result.title|striptags }}</h4>
      <p class="result-content">…</p><hr>
      <p class="result-author"><span>{{ _('Author') }}:</span>…</p>
      <p class="result-resolution">…</p><p class="result-format">…</p><p class="result-filesize">…</p>
      <p class="result-source">…</p><p class="result-engine"><span>{{ _('Engine') }}:</span>…</p>
      <p class="result-url"><span>{{ _('View source') }}:</span><a href="{{ result.url }}">{{ result.url }}</a></p>
    </div>
  </div>
</article>
```

Image-grid layout is triggered by `#results.only_template_images` (when every result is an
image). Detail-pane layout keys off `#results.image-detail-open` (see `result_types/image.less`).

### 1.8 A video result — `result_templates/videos.html`

Uses the macros + a collapsible embedded iframe:

```html
{# result_header(...) → article.result.result-videos + a.url_header + url_wrapper + thumbnail_link + h3 #}
{# result_sub_header(...) → published_date / length / views / author / highlight #}
<p class="altlink"><a class="btn-collapse collapsed media-loader disabled_if_nojs" data-target="#result-video-{{ index }}" data-btn-text-collapsed="{{ _('show video') }}" data-btn-text-not-collapsed="{{ _('hide video') }}">{{ icon_small('film') }} {{ _('show video') }}</a></p>
<p class="content">{{ result.content|safe }}</p>
{# result_sub_footer → div.engines + cache_link + div.break #}
<div id="result-video-{{ index }}" class="embedded-video invisible">
  <iframe data-src="{{ result.iframe_src }}" frameborder="0" allowfullscreen ...></iframe>
</div>
{# result_footer → </article> #}
```

Video thumbnails are wider (`.result-videos a.thumbnail_link img.thumbnail { width: 20rem }`)
and the iframe is `aspect-ratio: 16/9`.

---

## 2. Jinja block inventory

Blocks **defined** in `base.html` and where they are **overridden**:

| Block | Defined in `base.html` | Default content | Overridden by |
|---|---|---|---|
| `title` | yes | empty | `search.html` (`{{ q }} - `), `info.html` (`{{ active_page.title }} - `) |
| `meta` | yes | empty | `search.html` (RSS `<link rel="alternate">`) |
| `head` | yes | OpenSearch `<link>` | `preferences.html` (empty), `stats.html` (empty), `info.html` (via parent) |
| `linkto_about` | yes (inside `#links_on_top`) | About link | `info.html` (empty) |
| `linkto_donate` | yes | Donate link (if `donation_url`) | `info.html` (empty) |
| `linkto_preferences` | yes | Preferences link | `preferences.html` (empty — hides self) |
| `header` | yes | empty | `page_with_header.html` (logo `<a><img class="logo"></a>`) → inherited by `preferences.html`, `stats.html`, `info.html` |
| `content` | yes | empty | `index.html`, `search.html` (results), `preferences.html`, `404.html`, `stats.html`, `info.html` |

Template inheritance chains:
- `index.html`, `search.html` (results), `404.html` → `extends "simple/base.html"`.
- `preferences.html`, `stats.html`, `info.html` → `extends "simple/page_with_header.html"` → `extends "simple/base.html"`.

`page_with_header.html` sets `{%- set body_class = "page_with_header" -%}` (drives the
`<main class="{{body_class}}">` → `.page_with_header { margin: 2em auto; width: 85em; }`).

`preferences.html` also defines its own local macros (not blocks): `tabs_open`, `tab_header`,
`tab_footer`, `tabs_close`, `checkbox`, `checkbox_onoff_reversed`, `plugin_preferences`,
`engine_about`, `engine_time`, `engine_reliability`.

---

## 3. CSS / JS contract (what the build must output)

`base.html` references exactly these static assets via `url_for('static', filename=...)`.
Because of `custom_url_for` fallback (§0), the bare names resolve to
`static/themes/<active-theme>/<name>`:

| Asset | `base.html` reference | Notes |
|---|---|---|
| Core JS | `<script type="module" src="{{ url_for('static', filename='sxng-core.min.js') }}" client_settings="{{ client_settings }}">` | ES module; reads `client_settings` attr (JSON) incl. `theme_static_path` |
| LTR CSS | `<link rel="stylesheet" href="{{ url_for('static', filename='sxng-ltr.min.css') }}" media="screen">` | when not RTL |
| RTL CSS | `<link rel="stylesheet" href="{{ url_for('static', filename='sxng-rtl.min.css') }}" media="screen">` | when `rtl` |
| Limiter CSS | `<link rel="stylesheet" href="{{ url_for('client_token', token=link_token) }}">` | only if `server.limiter`/`public_instance` |
| Favicon (png) | `<link rel="icon" href="{{ url_for('static', filename='img/favicon.png') }}" sizes="any">` | |
| Favicon (svg) | `<link rel="icon" href="{{ url_for('static', filename='img/favicon.svg') }}" type="image/svg+xml">` | |
| Apple touch | `<link rel="apple-touch-icon" href="{{ url_for('static', filename='img/favicon.png') }}">` | |
| Manifest | `<link rel="manifest" href="{{ url_for('manifest') }}" />` | served by Flask route, renders `manifest.json` template |

So the **build output for a theme must produce at minimum**:
`sxng-core.min.js`, `sxng-ltr.min.css`, `sxng-rtl.min.css` (and `sxng-rss.min.css` for the
RSS XSL), plus `img/favicon.png`, `img/favicon.svg`, `img/searxng.png`, `img/192.png`,
`img/512.png`, `img/img_load_error.svg`, `img/empty_favicon.svg`, `img/select-light.svg`,
`img/select-dark.svg`, and `img/icons/*.png` (favicon set used by `macros.draw_favicon`).

These names are dictated by `client/simple/vite.config.ts`:

```ts
const PATH = {
  brand: "src/brand/",
  dist: resolve(ROOT, "searx/static/themes/simple/"),     // ← OUTPUT DIR (theme-coupled)
  modules: "node_modules/",
  src: "src/",
  templates: resolve(ROOT, "searx/templates/simple/")      // ← writes searxng-wordmark.min.svg here
};
// rolldown input entrypoints:
//   core: src/js/index.ts → sxng-core.min.js
//   ltr:  src/less/style-ltr.less → sxng-ltr.min.css
//   rtl:  src/less/style-rtl.less → sxng-rtl.min.css
//   rss:  src/less/rss.less → sxng-rss.min.css
output: {
  entryFileNames: "sxng-[name].min.js",
  chunkFileNames: "chunk/[hash].min.js",
  assetFileNames: ... css → "sxng-[name].min[extname]" ...
}
```

`manifest.json` (the PWA manifest template, not the vite build manifest) uses only
**theme-relative** static paths (`img/favicon.svg`, `img/192.png`, `img/512.png`) and
`{{ theme_color }}` / `{{ background_color }}` — no literal `simple`.

The JS reads `theme_static_path` from `client_settings`; in TS:
`client/simple/src/js/main/results.ts:18` uses
`` `${settings.theme_static_path}/img/img_load_error.svg` `` for broken-thumbnail fallback.
`theme_static_path` is set server-side (see §7) to `themes/simple` — **theme-coupled**.

---

## 4. Class-name / id inventory (styling hooks)

### Page chrome
- `html.no-js`, `html.js`, `html.theme-auto`, `html.theme-dark`, `html.theme-black`,
  `html.center-alignment-yes` / `html.center-alignment-no`.
- `body.<endpoint>_endpoint` (`index_endpoint`, `results_endpoint`, `preferences_endpoint`, …).
- `main#main_index`, `main#main_results`, `main#main_preferences`, `main#main_404`,
  `main#main_stats`, `main#main_info` (id pattern `main_<template>`); `.page_with_header`.
- `nav#links_on_top` → `a.link_on_top_about`, `a.link_on_top_donate`, `a.link_on_top_preferences`.
- `footer`.

### Search box / header
- `form#search`, `div#search_header`, `a#search_logo`, `div#search_view`, `div.search_box`,
  `input#q`, `button#clear_search`, `button#send_search`, `div.autocomplete`.
- Categories: `div#categories.search_categories`, `div#categories_container`,
  `div.category.category_checkbox` (+ `input#checkbox_<cat>` + `label.tooltips` + `div.category_name`),
  `button.category.category_button[.selected]`, `div.help`.
- Filters: `select#language.language`, `select#time_range.time_range`, `select#safesearch.safesearch`,
  wrapper `div.search_filters`.

### Results grid
- `div#results` (+ optional `.only_template_<x>`, `.image-detail-open`, `.scrolling`).
- Grid areas (from `#results` grid-template): `corrections`, `answers`, `urls`, `sidebar`, `pagination`.
- `div#urls[role=main]`, `div#sidebar`, `div#sidebar-end-collapsible`, `div#backToTop`.
- `div#answers` (`h4.title`, `div.answer`, `a.answer-url`), `div#corrections` (`h4`, forms with `input[type=submit]`).
- `div#infoboxes` → `aside.infobox` (`h2.title`, `.attributes` dl/dt/dd, `.urls ul li.url`, `.relatedTopics`).
- `div#suggestions` (`details.sidebar-collapsible > summary.title`, `ul.wrapper > li > form > input.suggestion`).
- `div#engines_msg` (`table.engine-stats`, `.engine-name`, `.response-error`, `.response-time`, `.bar-chart-graph/.bar-chart-bar/.bar-chart-value`).
- `div#search_url` (`summary.title`, `button#copy_url.button`, `div.selectable_url > pre`).
- `div#apis` (`details.sidebar-collapsible`, `div.wrapper`, `input[type=submit]`).
- `details.sidebar-collapsible`, `summary.title` (shared collapsible pattern in sidebar).

### Result article (shared)
- `article.result` + modifier `result-<template>` (`result-default`, `result-images`,
  `result-videos`, `result-torrent`, `result-map`, `result-paper`, `result-packages`,
  `result-products`, `result-file`, `result-code`, `result-keyvalue`) + `category-<cat>`.
- `a.url_header`, `div.favicon > img`, `div.url_wrapper` → `span.url_o1 > span.url_i1`,
  `span.url_o2 > span.url_i2`.
- `h3 > a`, `p.content[.empty_element]`, `p.altlink > a.btn-collapse.media-loader`,
  `div.engines > span`, `a.cache_link`, `div.break`, `a.thumbnail_link > img.thumbnail`,
  `span.thumbnail_length`.
- Sub-header: `time.published_date`, `div.result_length`, `div.result_views`,
  `div.result_author`, `div.result_shipping`, `div.result_source_country`,
  `div.result_price`, `div.highlight`.
- `div.attributes` (paper/packages/file: `div > span:first-child` label + `span:nth-child(2)` value).
- Collapsible media containers: `div.embedded-content`, `div.embedded-video`,
  `div.audio-control`, `.invisible` (hidden until JS reveals), `div.osm-map-box`.
- Image-specific: `img.image_thumbnail`, `span.image_resolution`, `span.title`, `span.source`,
  `div.detail.swipe-horizontal`, `a.result-detail-close/-previous/-next`,
  `a.result-images-source`, `div.result-images-labels` (`p.result-content/-author/-resolution/-format/-filesize/-source/-engine/-url`).
- `data-vim-selected` attribute on `<article>` is the keyboard-nav selection hook.
- Grouping wrappers: `div.template_group_<template>` (e.g. `template_group_images`).

### Pagination
- `nav#pagination`, `form.previous_page`, `form.next_page`, `div.left` / `div.right`
  (swapped for RTL), `div.numbered_pagination`, `form.page_number`,
  `input.page_number` / `input.page_number_current`.

### Preferences / toolkit
- `form#search_form`, `div.tabs[role=tablist]`, `input[name=maintab]`, `label[role=tab]`,
  `section[role=tabpanel]`, `fieldset > legend#pref_* + div.value + div.description`.
- `ul.tabs` (info-page tab variant), `input.checkbox-onoff[.reversed-checkbox]`,
  `.dialog-error/.dialog-warning/.dialog-modal/.dialog-error-block/.dialog-warning-block`,
  `.badge`, `.engine-tooltip`, `.stacked-bar-chart*`, `.bar-chart-*`.

### Icon system
- SVG icons inlined from `simple/icons.html` macros `icon` / `icon_small` / `icon_big`,
  which inject classes `sxng-icon-set`, `sxng-icon-set-small`, `sxng-icon-set-big`
  (sized 1rem / 1.5rem in style.less).

---

## 5. Light / dark mechanism (exact)

**Mechanism: a class on `<html>` + a `prefers-color-scheme` media query for "auto".** Not
`data-theme`. All theming is CSS custom properties (`--color-*`) declared on `:root`
(light defaults) and overridden by Less mixins for dark/black.

The class is emitted by `base.html`:

```html
<html class="no-js theme-{{ preferences.get_value('simple_style') or 'auto' }} center-alignment-...">
```

So the possible html classes are `theme-auto`, `theme-light`, `theme-dark`, `theme-black`
(value of the `simple_style` preference; falls back to `auto`).

`definitions.less` defines light values on `:root`, dark/black as Less mixins
`.dark-themes()` / `.black-themes()`, then wires them with these **exact selectors**:

```less
/// Dark Theme (autoswitch based on device pref)
@media (prefers-color-scheme: dark) {
  :root.theme-auto {
    .dark-themes();
  }
}

// Dark Theme by preferences
:root.theme-dark {
  .dark-themes();
}

:root.theme-black {
  .dark-themes();
  .black-themes();
}
```

i.e.:
- `theme-light` → keep `:root` light defaults (no override).
- `theme-dark` → `:root.theme-dark` applies `.dark-themes()`.
- `theme-black` → `:root.theme-black` applies dark + black overrides.
- `theme-auto` → light by default, but `@media (prefers-color-scheme: dark) { :root.theme-auto { … } }`
  flips to dark following the OS.

The `<select>` dropdown arrow SVG also switches by theme (`toolkit.less`):

```less
@media (prefers-color-scheme: dark) {
  html.theme-auto select,
  html.theme-dark select { background-image: data-uri("…", @select-dark-svg-path); }
}
html.theme-dark select { background-image: data-uri("…", @select-dark-svg-path); }
```

**Autocomplete of theme options** (`preferences/theme.html`): the *layout* theme dropdown
iterates `themes` (the filesystem list, §0). The *style* (light/dark) dropdown is a literal list:

```html
<select name="theme" aria-labelledby="pref_theme">
  {%- for name in themes -%}<option value="{{ name }}" ...>{{ name | capitalize }}</option>{%- endfor -%}
</select>
...
<select name="simple_style" aria-labelledby="pref_simple_style">
  {%- for name in ['auto', 'light', 'dark', 'black'] -%}
    <option value="{{ name }}" {%- if name == preferences.get_value('simple_style') %} selected="selected"{%- endif -%}>{{ _(name) | capitalize }}</option>
  {%- endfor -%}
</select>
```

**Naming caveat for a fork:** the style preference key is `simple_style` (not theme-scoped),
and `base.html` reads `preferences.get_value('simple_style')`. A `google` theme reusing this
mechanism can keep `simple_style` (it is theme-agnostic in practice) OR introduce its own
key — but then it must also change the `base.html` html-class line and the
`preferences/theme.html` select `name`. The literal option list `['auto','light','dark','black']`
lives only in `preferences/theme.html`.

---

## 6. Design tokens (Less variables & CSS custom properties)

### 6.1 Sizes / layout (Less vars, `definitions.less` lines 281–316) — single value (not themed)

| Variable | Value | Used for |
|---|---|---|
| `@results-width` | `45rem` | results column width (grid col 1) |
| `@results-sidebar-width` | `25rem` | sidebar width (grid col 2) |
| `@results-offset` | `10rem` | left offset of results block (LTR) |
| `@results-tablet-offset` | `0.5rem` | tablet/phone gutter |
| `@results-gap` | `5rem` | gap between results & sidebar |
| `@results-margin` | `0.125rem` | result vertical margin |
| `@result-padding` | `1rem` | result/answer padding |
| `@results-image-row-height` | `12rem` | image grid row height |
| `@results-image-row-height-phone` | `10rem` | image row height (phone) |
| `@search-width` | `44rem` | max width of `.search_box` |
| `@search-height` | `13rem` | `#search` height (detail offset) |
| `@search-padding-horizontal` | `0.5rem` | search view horizontal padding |
| `@tablet` | `79.75em` | breakpoint: desktop > tablet |
| `@phone` | `50em` | breakpoint: tablet > phone |
| `@small-phone` | `35em` | breakpoint |
| `@ultra-small-phone` | `20rem` | breakpoint |

Center-alignment overrides (`style-center.less`, on `.center-alignment-yes #main_results`)
set a CSS custom property `--center-page-width`: `48rem` (≥phone), `60rem` (≥62rem),
`73rem` (≥tablet). The "Oscar layout" centered widths.

`html { font-size: 0.9em; font-family: sans-serif; }` is the base type scale (style.less);
result `h3` is `1.2rem` / `h3 a` `1.1em`; `.content` `0.9em`; `footer p` `0.9em`.
`.page_with_header { width: 85em; }`.

### 6.2 Color tokens — light (`:root`) vs dark (`.dark-themes()`), most-important subset

(`black` only overrides the five background tokens marked ▸.)

| CSS var | Light | Dark | Black override |
|---|---|---|---|
| `--color-base-font` | `#444` | `#bbb` | — |
| `--color-base-background` ▸ | `#fff` | `#222428` | `#000` |
| `--color-base-background-mobile` ▸ | `#f2f5f8` | `#222428` | `#000` |
| `--color-url-font` | `#334999` | `#8af` | — |
| `--color-url-visited-font` | `#9822c3` | `#c09cd9` | — |
| `--color-header-background` ▸ | `#fdfbff` | `#1e1e22` | `#000` |
| `--color-header-border` | `#ddd` | `#333` | — |
| `--color-footer-background` ▸ | `#fdfbff` | `#1e1e22` | `#000` |
| `--color-footer-border` | `#ddd` | `#333` | — |
| `--color-sidebar-border` | `#ddd` | `#555` | — |
| `--color-sidebar-font` | `#000` | `#fff` | — |
| `--color-sidebar-background` ▸ | `#fff` | `#292c34` | `#000` |
| `--color-btn-background` | `#3050ff` | `#58f` | — |
| `--color-btn-font` | `#fff` | `#222` | — |
| `--color-show-btn-background` | `#bbb` | `#555` | — |
| `--color-search-border` | `#bbb` | `#555` | — |
| `--color-search-background` | `#fff` | `#2b2e36` | — |
| `--color-search-font` | `#222` | `#fff` | — |
| `--color-search-background-hover` | `#3050ff` | `#58f` | — |
| `--color-search-shadow` | `0 2px 8px rgb(34 38 46 / 25%)` | (same) | — |
| `--color-categories-item-selected-font` | `#3050ff` | `#58f` | — |
| `--color-categories-item-border-selected` | `#3050ff` | `#58f` | — |
| `--color-autocomplete-background` | `#fff` | `#2b2e36` | — |
| `--color-autocomplete-background-hover` | `#e3e3e3` | `#1e1e22` | — |
| `--color-answer-background` | `#fff` | `#26292f` | — |
| `--color-answer-font` | `#444` | `#bbb` | — |
| `--color-result-background` | `#fff` | `#26292f` | — |
| `--color-result-border` | `#ddd` | `#333` | — |
| `--color-result-url-font` | `#000` | `#fff` | — |
| `--color-result-link-font` | `#000bbb` | `#8af` | — |
| `--color-result-link-visited-font` | `#9822c3` | `#c09cd9` | — |
| `--color-result-publishdate-font` | `#777` | `#888` | — |
| `--color-result-engines-font` | `#545454` | `#a4a4a4` | — |
| `--color-result-vim-selected` | `#f7f7f7` | `#1f1f23cc` | — |
| `--color-result-vim-arrow` | `#000bbb` | `#8af` | — |
| `--color-result-image-span-font` | `#444` | `#bbb` | — |
| `--color-result-image-background` | `#fff` | `#222` | — |
| `--color-result-detail-background` | `#242424` | `#1a1a1c` | — |
| `--color-result-detail-font` | `#fff` | `#fff` | — |
| `--color-error` | `#db3434` | `#f55b5b` | — |
| `--color-warning` | `#dbba34` | `#f1d561` | — |
| `--color-success` | `#42db34` | `#79f56e` | — |
| `--color-toolkit-select-background` | `#e1e1e1` | `#313338` | — |
| `--color-toolkit-checkbox-onoff-on-mark-background` | `#3050ff` | `#58f` | — |
| `--color-favicon-background-color` | `#ddd` | `#ddd` | — |

(Full set: ~70 tokens in each block; see `definitions.less` lines 10–254 for the exhaustive list, including
`--color-backtotop-*`, `--color-result-keyvalue-*`, `--color-settings-*`, `--color-toolkit-*`,
`--color-bar-chart-*`, `--color-doc-code*`, `--color-line-number`, `--color-image-resolution-*`.)
Note `--color-base-font-rgb` (`68,68,68` light / `187,187,187` dark) is the comma-RGB twin used in `rgb(var(--color-base-font-rgb), 0.x)` for the stacked-bar charts.

Fonts: `@icon-font-path: "../../../fonts/"`, `@icon-font-name: "glyphicons-halflings-regular"`.
Select arrows: `@select-light-svg-path: "../svg/select-light.svg"`, `@select-dark-svg-path: "../svg/select-dark.svg"`.

### 6.3 The key structural grid (style.less `#results`)

```less
#results {
  margin-top: 1rem;
  .ltr-margin-right(2rem);
  .ltr-margin-left(@results-offset);
  display: grid;
  grid-template:
    "corrections sidebar" min-content
    "answers     sidebar" min-content
    "urls        sidebar" 1fr
    "pagination  sidebar" min-content
    / @results-width @results-sidebar-width;
  gap: 0 @results-gap;
}
```

Tablet collapses to a single column (`/ @results-width`, sidebar stacked above urls); phone
to `100%`. Image-only results use `#results.only_template_images` (full-width flex grid).

---

## 7. Theme-name coupling — every place `simple` must become `google`

`grep -rn "themes/simple|'simple'|\"simple\"|/simple/"` over `searx/` (excluding minified
files) and `client/simple/vite.config.ts`. Below is the curated list of **actionable**
occurrences (data files like `engine_traits.json` / `external_bangs.json` are unrelated
matches and excluded).

### 7.1 Filesystem (rename the two directories — implicit, not a grep hit)
- `searx/templates/simple/`  →  `searx/templates/google/`
- `searx/static/themes/simple/`  →  `searx/static/themes/google/` (vite output dir)

### 7.2 Python
| File:line | Code | Change |
|---|---|---|
| `searx/settings_defaults.py:235` | `'default_theme': SettingsValue(str, 'simple')` | only if `google` should be the default; otherwise set per-instance in `settings.yml` (`ui.default_theme: google`). Not strictly required to fork. |
| `searx/webapp.py:377` | `'theme_static_path': custom_url_for('static', filename='themes/simple')` | **must change** to `'themes/google'` (used by JS for img fallback). Better: make it `'themes/' + req_pref.get_value('theme')`. |

`searx/webapp.py:246-250` (`get_result_template`) and `:256-279` (`custom_url_for`) are
**theme-agnostic** (they read the active theme name dynamically) — no change needed.

### 7.3 Jinja templates
| File:line | Code | Change |
|---|---|---|
| `searx/templates/simple/base.html:32` | `id="main_{{ self._TemplateReference__context.name|replace("simple/", "")|replace(".html", "") }}"` | replace `"simple/"` → `"google/"` (so `#main_*` ids keep working) |
| `searx/templates/simple/base.html:2` | `class="...theme-{{ preferences.get_value('simple_style') or 'auto' }}..."` | optional: only if you rename the style pref away from `simple_style` |
| `searx/templates/simple/base.html:45` | `{%- from 'simple/icons.html' import icon_big -%}` | `'google/icons.html'` |
| `searx/templates/simple/results.html:65` | `{% include get_result_template('simple', result['template']) %}` | **must change** first arg `'simple'` → `'google'` |
| `searx/templates/simple/macros.html:5` | `url_for('static', filename='themes/simple/img/icons/' + favicon + '.png')` | `'themes/google/img/icons/…'` (favicon set path) |
| `searx/templates/simple/preferences/theme.html:19,21,24` | `id="pref_simple_style"`, `<select name="simple_style">`, `preferences.get_value('simple_style')` | optional: only if renaming the style pref |

Plus the dozens of intra-theme `{% extends "simple/base.html" %}`,
`{% include 'simple/…' %}`, `{% from 'simple/icons.html' import … %}`,
`{% from 'simple/macros.html' import … %}` references in **every** template under
`simple/` — these all use the `simple/` path prefix and must be rewritten to `google/`.
(They are template-internal cross-references; a bulk sed of `simple/` → `google/` across the
copied template dir handles them. Verify none are unrelated.)

### 7.4 Build config / package metadata (`client/simple/`)
| File | Token | Change |
|---|---|---|
| `client/simple/vite.config.ts` | `dist: resolve(ROOT, "searx/static/themes/simple/")` | → `…/themes/google/` |
| `client/simple/vite.config.ts` | `templates: resolve(ROOT, "searx/templates/simple/")` | → `…/templates/google/` (where `searxng-wordmark.min.svg` is emitted) |
| `client/simple/package.json` | `"name": "@searxng/theme-simple"` | → `@searxng/theme-google` (cosmetic) |
| (dir) `client/simple/` | the whole client dir name | → `client/google/` if you want a parallel build tree |

The TS source uses `settings.theme_static_path` (not a literal `simple`) for runtime asset
URLs (`client/simple/src/js/main/results.ts:18,42,46`,
`client/simple/src/js/toolkit.ts:19`), so once `theme_static_path` is fixed in
`webapp.py:377` the JS needs no string edits.

### 7.5 Result-templates fallback (free win)
`get_result_template` falls back to a **shared** `result_templates/<name>` dir if the themed
copy is absent (webapp.py:248-250). So a `google` theme can ship only the result templates it
restyles and inherit the rest — but note `results.html:65` passes the theme name explicitly,
so that include must still say `'google'` for the *themed* lookup to be attempted.

---

## 8. Quick checklist to fork `simple` → `google`

1. `cp -r searx/templates/simple searx/templates/google`; bulk-replace `simple/` → `google/`
   inside the copied templates (extends/include/from paths) and the two special spots:
   `base.html` `replace("simple/", …)` and `results.html` `get_result_template('simple', …)`.
2. `cp -r client/simple client/google`; in `vite.config.ts` repoint `PATH.dist` →
   `searx/static/themes/google/` and `PATH.templates` → `searx/templates/google/`. Build to
   produce `sxng-core.min.js`, `sxng-ltr.min.css`, `sxng-rtl.min.css`, `sxng-rss.min.css`,
   and the `img/*` assets in `searx/static/themes/google/`.
3. In `searx/webapp.py:377` set `theme_static_path` to `themes/google` (or make it dynamic).
4. In `macros.html` fix the favicon `img/icons` static path to `themes/google/...`.
5. (Optional) keep `simple_style` as the light/dark pref key to reuse the existing
   `theme-auto/light/dark/black` mechanism untouched, OR rename it in `base.html` +
   `preferences/theme.html` and add matching Less selectors `:root.theme-*`.
6. Restyle by editing the `--color-*` custom properties in `definitions.less` and the
   structural rules in `style.less` / `search.less` to the Google look — the **HTML markup,
   class names, ids, and grid areas above can stay identical**, which is the whole point:
   the new look maps onto the same server-rendered DOM.

---

### Appendix: result-template files (for per-type restyling)
`result_templates/`: `default.html` (web), `images.html`, `videos.html`, `torrent.html`,
`map.html`, `paper.html`, `packages.html`, `products.html`, `file.html`, `code.html`,
`keyvalue.html`. All except `images.html`, `keyvalue.html`, `map.html`(partial),
`packages.html` use `macros.html`'s `result_header/_sub_header/_sub_footer/_footer`. Matching
Less partials live in `client/simple/src/less/result_types/` (`code.less`, `file.less`,
`image.less`, `keyvalue.less`, `paper.less`) imported at the bottom of `style.less`.
