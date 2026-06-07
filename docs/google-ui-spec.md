# Google Search UI — Implementation-Ready Visual Spec (2024–2026)

A precise, CSS-ready description of how Google Search *looks* (desktop-first, with mobile
notes), in **light and dark mode**, so an engineer can recreate the look **without copying
Google's trademarked assets** (logo, Product Sans, favicons, icon glyphs).

> **Method / confidence.** The hard values below were captured two ways and cross-checked:
> 1. **Live inspection** of `google.com` and a live results page via `getComputedStyle()` on
>    the real DOM, in **both** light and dark mode (the inspected account rendered the results
>    page in light mode and the homepage in dark mode, giving direct measurements of both).
> 2. **Live CSS source** — Google's own shipped stylesheet was scraped and grepped for the
>    color tokens, confirming which hex values actually exist in the product.
> 3. **Web sources** (color/brand references, dev teardowns, Material docs) — at least 2–3 per
>    major color claim. See **Sources** at the end.
>
> Where Google ships *both* a legacy and a current value (it is mid-migration from the
> `#202124 / #5f6368 / #dadce0` "Material 2" greys to a flatter `#1f1f1f / #4d5156` set, and
> from a blue active-tab underline to a dark-gray one), **both are listed and the current one
> is marked ✅**. Class names like `.RNNXgb`, `.VwiC3b`, `.VuuXrf` are Google's obfuscated,
> frequently-changing internal names — given only for traceability; **do not depend on them**.

---

## 0. Quick-reference color token table (BOTH modes)

CSS-variable-style tokens you can paste into `:root` / `[data-theme="dark"]`. Values marked
✅ are what the live product currently renders; legacy values are kept as comments.

```css
:root {
  /* ---------- LIGHT MODE ---------- */
  --g-bg:            #ffffff;  /* page background (verified live) */
  --g-surface:       #f8f9fa;  /* button / chip / raised surface bg */
  --g-surface-2:     #f1f3f4;  /* secondary fill (hover wells, pills) */
  --g-text:          #1f1f1f;  /* ✅ primary text: titles snippets site-name (legacy #202124) */
  --g-text-secondary:#4d5156;  /* ✅ URL / breadcrumb / meta (legacy #5f6368 / #70757a) */
  --g-text-tertiary: #5f6368;  /* muted labels, icons */
  --g-link:          #1a0dab;  /* ✅ result TITLE link (classic, still live) */
  --g-link-alt:      #1558d6;  /* alt title blue Google A/B-tests in some locales */
  --g-link-visited:  #681da8;  /* ✅ visited title link (legacy #660599) */
  --g-url:           #4d5156;  /* URL/breadcrumb path text */
  --g-url-sitename:  #1f1f1f;  /* site-name (bold-ish) in the URL row */
  --g-border:        #dadce0;  /* dividers, card borders, header search border */
  --g-border-home:   #dfe1e5;  /* homepage search-box border (slightly cooler) */
  --g-accent:        #1a73e8;  /* ACTION blue: buttons, tab underline (legacy), toggles, focus */
  --g-brand-blue:    #4285f4;  /* brand "Google blue" (logo G) */
  --g-brand-red:     #ea4335;
  --g-brand-yellow:  #fbbc05;  /* (logo uses #f9ab00 / #fbbc04 variants) */
  --g-brand-green:   #34a853;
  --g-tab-active:    #1f1f1f;  /* ✅ active category-tab text + underline (current) */
  --g-tab-active-legacy:#1a73e8;/* old blue tab underline */
  --g-tab-inactive:  #5f6368;  /* inactive tab label */
  --g-btn-bg:        #f8f9fa;  /* homepage Search / Lucky button bg */
  --g-btn-text:      #3c4043;  /* homepage button text */
  --g-btn-border:    #f8f9fa;  /* button border (same as bg until hover) */
  --g-btn-border-hover:#dadce0;
  --g-focus-shadow:  rgba(64,60,67,.16);

  /* ---------- DARK MODE (override) ---------- */
}

[data-theme="dark"], .dark {
  --g-bg:            #1f1f1f;  /* ✅ canonical dark bg (#202124 legacy; some surfaces #22242a) */
  --g-surface:       #303134;  /* raised surface: search-box focus, menus, cards */
  --g-surface-2:     #28292a;  /* chips / subtle fills */
  --g-text:          #e8e8e8;  /* ✅ primary text (legacy #e8eaed / #bdc1c6) */
  --g-text-secondary:#bdc1c6;  /* URL / secondary */
  --g-text-tertiary: #9aa0a6;  /* muted labels, icons */
  --g-link:          #99c3ff;  /* ✅ result TITLE link (live; classic #8ab4f8) */
  --g-link-alt:      #8ab4f8;  /* widely-used dark title blue (still in CSS) */
  --g-link-visited:  #c58af9;  /* visited title link */
  --g-url:           #bdc1c6;
  --g-url-sitename:  #e8e8e8;
  --g-border:        #3c4043;  /* dividers / card borders */
  --g-accent:        #8ab4f8;  /* dark action blue (buttons/toggles) */
  --g-accent-strong: #a8c7fa;  /* Material-You dark primary, heavily used for icons/accents */
  --g-tab-active:    #e8e8e8;  /* active tab text + underline */
  --g-tab-inactive:  #9aa0a6;
  --g-btn-bg:        #303134;  /* dark homepage button bg (#3c4043 alt) */
  --g-btn-text:      #e8eaed;
  --g-btn-border:    #303134;
  --g-search-bg:     #4d5156;  /* dark search-box resting bg */
  --g-search-bg-focus:#303134; /* dark search-box hover/focus/open bg */
  --g-focus-shadow:  rgba(23,23,23,.9);
}
```

**Token usage cheat-sheet (where each goes):**

| Token | Used on |
|---|---|
| `--g-link` (#1a0dab / #99c3ff) | **only the clickable result H3 title** |
| `--g-accent` (#1a73e8 / #8ab4f8) | buttons, links inside snippets/PAA, tab underline (legacy), focus rings, toggles, "More results" |
| `--g-text` (#1f1f1f / #e8e8e8) | titles' fallback, **snippet body**, site name, active-tab text |
| `--g-text-secondary` (#4d5156 / #bdc1c6) | URL path, "About this result", timestamps |
| `--g-tab-active` (#1f1f1f / #e8e8e8) | the *current* active-category underline + label (NOT blue anymore) |

> ⚠️ **Important nuance most clones get wrong:** in the current UI the **snippet body text is
> NOT a light gray — it's the same near-black `#1f1f1f` as the title fallback** (measured live).
> The only gray text in a result block is the **URL/breadcrumb row** (`#4d5156`). Older specs
> that say "gray #70757a snippet" describe the pre-2023 look.

---

## 1. Color palette — LIGHT mode

| Element | Hex | Notes (verified) |
|---|---|---|
| Page background | `#ffffff` | live `body { background:#fff }` |
| Raised surface (buttons, chips) | `#f8f9fa` | in Google CSS ×6; rgb(248,249,250) |
| Secondary fill / hover well | `#f1f3f4` | |
| **Primary text** (titles, snippet, site name) | **`#1f1f1f`** ✅ | live; rgb(31,31,31). Legacy `#202124` still in CSS ×10 |
| **Secondary text** (URL, meta) | **`#4d5156`** ✅ | live `cite`/breadcrumb color; legacy `#5f6368` (×4 in CSS), older `#70757a` |
| Tertiary / icon gray | `#5f6368` / `#474747` | `#474747` appeared ×104 live for some UI chrome |
| **Result TITLE link** | **`#1a0dab`** ✅ | live H3 color; rgb(26,13,171). This is the *classic* blue — **still the live default** |
| Title link (A/B alt) | `#1558d6` | tested in some locales; not the default |
| **Visited title link** | **`#681da8`** ✅ | live; rgb(104,29,168). Legacy `#660599` |
| URL / breadcrumb path | `#4d5156` | the greenish-gray of old (`#006621`) is **gone**; path is neutral gray now |
| URL site-name (left of path) | `#1f1f1f` | site name renders in primary text color, ~14px |
| Borders / dividers | `#dadce0` ✅ | live header search border; rgb(218,220,224). Cards also `#ebebeb` in places |
| Homepage search border | `#dfe1e5` | cooler gray, homepage-only (web-sourced) |
| **Action/accent blue** | **`#1a73e8`** ✅ | rgb(26,115,232). Buttons, links-in-snippets, focus, toggles, (legacy) tab underline |
| Brand blue (logo G) | `#4285f4` | rgb(66,133,244) |
| Homepage button bg | `#f8f9fa` | text `#3c4043`, border same as bg |
| Homepage button text | `#3c4043` | rgb(60,64,67) |

**Which blue goes WHERE (light):**
- **Result title** → `#1a0dab` (deep indigo-blue, *not* the bright UI blue).
- **Everything interactive that isn't a title** (buttons, "People also ask" links, "More
  results", filter chips text, focus ring) → `#1a73e8`.
- **Logo / brand mark** → `#4285f4` + the four brand colors.

**Hover states (light):**
- Result title link: gains `text-decoration: underline` on hover (color unchanged).
- Header search box: `box-shadow: 0 1px 6px rgba(32,33,36,.28); border-color: transparent;`
  (loses the gray border, gains a soft shadow). Resting shadow on results header is
  `rgba(31,31,31,.08) 0 3px 10px` (measured live).
- Homepage buttons: bg stays `#f8f9fa`, border becomes `#dadce0`, subtle shadow
  `0 1px 1px rgba(0,0,0,.1)`, text darkens toward `#202124`.

---

## 2. Color palette — DARK mode

| Element | Hex | Notes (verified live in dark) |
|---|---|---|
| Page background | `#1f1f1f` ✅ | canonical. Inspected account rendered `#22242a` (a warm near-black variant); legacy `#202124`. Some teardowns cite `#0e0e0e`/`#171717` for OLED variants |
| Raised surface | `#303134` ✅ | search-box focus/open bg, menus, cards |
| Chip / subtle fill | `#28292a` | live chip bg |
| **Primary text** | **`#e8e8e8`** ✅ | live (×1124 on page). Legacy `#e8eaed`, dimmer `#bdc1c6` |
| **Secondary text** (URL) | **`#bdc1c6`** ✅ | live `cite` color |
| Tertiary / icon gray | `#9aa0a6` ✅ | live ×32 |
| **Result TITLE link** | **`#99c3ff`** ✅ | live H3 color (×276). Classic `#8ab4f8` still shipped in CSS (×6) |
| Title accent (Material-You) | `#a8c7fa` | in CSS ×34 — dark primary/accent for icons & some links |
| **Visited title link** | **`#c58af9`** ✅ | live; rgb(197,138,249) |
| URL / breadcrumb path | `#bdc1c6` | |
| URL site-name | `#e8e8e8` | |
| Borders / dividers | `#3c4043` ✅ | |
| Action/accent blue | `#8ab4f8` ✅ | buttons, toggles, snippet links |
| Dark search-box bg (resting) | `#4d5156` ✅ | live `.RNNXgb { background: rgb(77,81,86) }` |
| Dark search-box bg (hover/focus/open) | `#303134` ✅ | live `.RNNXgb:hover { background: rgb(48,49,52) }` |
| Dark button bg | `#303134` / `#3c4043` ✅ | text `#e8eaed`, border `#303134` |

**Which blue goes WHERE (dark):** title → `#99c3ff` (or `#8ab4f8`); UI/accent → `#8ab4f8`;
icons & Material-You accents → `#a8c7fa`; visited → `#c58af9`.

**Hover (dark):** search box bg shifts `#4d5156 → #303134` with shadow
`rgba(23,23,23,.9) 0 4px 12px`; title gains underline.

---

## 3. Typography

**Google's real stack (do not ship Product Sans / Google Sans — proprietary):**
- Logo + large display/branding: **Product Sans** (logo) / **Google Sans** (display).
- Result titles: `"Google Sans", Arial, sans-serif` (measured live on the H3).
- Body / snippet / URL / UI: `Arial, sans-serif` (measured live on `body` and snippet).
- Internally Google also uses `Roboto` and `"Google Sans Text"`; on most desktop pages the
  body actually computes to **plain `Arial, sans-serif`**.

**Recommended open-source / web-safe replacement stacks:**

```css
/* Body / snippet / URL / general UI — closest to Google's Arial rendering */
--g-font-body: Arial, "Helvetica Neue", Helvetica, sans-serif;
/* or a slightly more modern but neutral grotesque: */
--g-font-body-alt: Inter, Roboto, Arial, sans-serif;

/* Display / titles / "Product-Sans-like" geometric — free Google Fonts that read similarly: */
--g-font-display: "Google Sans", "Product Sans",
                  "Google Sans Text",          /* if licensed/available */
                  "Inter", "Manrope", "Poppins", Arial, sans-serif;
/* Best single FOSS substitute for Product Sans's friendly geometric look: */
/*   • Google Sans alternative → "Manrope" or "Inter" (UI), "Poppins"/"Nunito Sans" (logo-ish) */
```

> Product Sans is a geometric humanist sans with a circular `o` and single-story `a`. The
> closest free approximations are **Poppins** (very circular) or **Manrope**/**Inter** (more
> neutral, better for UI). For body text, **Arial** *is* what Google actually renders, so
> using `arial, sans-serif` is the most faithful (and license-clean) choice.

**Sizes & weights (measured live):**

| Element | font-size | line-height | weight | family |
|---|---|---|---|---|
| Result **title** (H3) | **20px** (renders **22px** in some wide layouts) | 26px (28px when 22px) | **400** | `"Google Sans", Arial, sans-serif` |
| **Snippet** body | **14px** | **~20–22px** (≈1.5–1.58) | 400 | `Arial, sans-serif` |
| URL site-name | **14px** | 20px | 400 (visually slightly heavier) | Arial |
| URL / breadcrumb (`cite`) | **12px** (older specs: 14px) | 18px | 400 | Arial |
| Search input text | **16px** | — | 400 | Arial |
| Category tab labels | **14px** | — | 400 (active reads heavier) | Arial |
| Filter / related chips | **14px** | — | 400 | Arial |
| Footer links | **13px** | — | 400 | Arial |
| Body default | 14px | normal | 400 | `Arial, sans-serif` |

---

## 4. Homepage

**Layout:** single column, **vertically + horizontally centered**. Top bar with right-aligned
links; logo centered above the search box; two buttons below; footer pinned to the bottom.

```
┌───────────────────────────────────────── top bar (h ~60px) ─────────────┐
│                                  Gmail   Images   ▦(apps)   ◉(Sign in)   │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│                         [ G o o g l e   logo ]   ~272×92px                  │
│                                                                            │
│        🔍  ┌──────────────── search box ─────────────────┐  🎤 📷         │
│           │  width 584px · height ~44–52px · radius 24px  │                │
│           └───────────────────────────────────────────────┘                │
│                                                                            │
│              [ Google Search ]   [ I'm Feeling Lucky ]                      │
│                                                                            │
├───────────────────────────────── footer (bg #f2f2f2) ────────────────────┤
│  Country/region                                                            │
│  About  Advertising  Business  How Search works   │   Privacy  Terms  ⚙   │
└──────────────────────────────────────────────────────────────────────────┘
```

**Logo:** Google wordmark, approx **272 × 92px** desktop (scales down on mobile to ~`min()`
based widths). Centered, sits ~`30vh` from top in the centered stack. **Use your own
wordmark** — do not reproduce Google's.

**Search box** (the `.RNNXgb` pill — measured live):
- `width: 584px;` (`max-width` ~`min(584px, calc(100% - 40px))`); full-width on mobile.
- `min-height: 50px;` historically **44px**, currently renders ~**46–52px**.
- `border-radius: 24px;` (live computed **26px** in the current build → `height/2`).
- Light: `border: 1px solid #dfe1e5; background:#fff; box-shadow:none;`
- Light **hover/focus**: `border-color: transparent; box-shadow: 0 1px 6px rgba(32,33,36,.28);`
- Dark: `background:#4d5156; border:1px solid transparent;` → hover/focus
  `background:#303134; box-shadow: rgba(23,23,23,.9) 0 4px 12px;`
- **Autocomplete open** (`.emcav`): bottom corners go square (`border-bottom-*-radius:0`),
  dropdown attaches flush, box shadow appears.
- **Left:** search/magnifier icon (~20px, color `#9aa0a6` dark / `#5f6368` light), ~`13px`
  left padding.
- **Right:** microphone icon + **Google Lens** (camera) icon, ~20–24px each, ~`16px` gap.
  (Use your own/neutral icons; Lens & mic glyphs are Google assets.)
- Input: `font-size:16px;` text color `#1f1f1f` light / `#e8eaed` dark.

**Buttons** ("Google Search" / "I'm Feeling Lucky" — measured live):
- `height: 36px;` padding `0 16px`; `font: 14px/… "Google Sans", Arial; font-weight: 500;`
- `border-radius: 4px;` (**classic**; the current build renders **8px** — use 8px for the
  modern look, 4px for the retro look).
- Light: `background:#f8f9fa; color:#3c4043; border:1px solid #f8f9fa;`
  hover → `border-color:#dadce0; box-shadow:0 1px 1px rgba(0,0,0,.1); color:#202124;`
- Dark: `background:#303134; color:#e8eaed; border:1px solid #303134;`
- Gap between the two buttons ~`8–11px`; centered as a group.

**Top-right links** (measured live, dark): `Gmail`, `Images` as text links at **13px**
(`#3c4043` light / `#e3e3e3` dark), then the **apps grid** (3×3 dots, ~24px icon), then a
**Sign in** pill button (filled `#1a73e8` light / light-blue with `#001d35` text dark,
radius ~`4px`, `14px`, padding `~9px 23px`).

**Footer** (web-sourced + live):
- Light: `background:#f2f2f2; border-top:1px solid #dadce0;` Dark: blends into page bg
  (`#22242a`), border-top `#3c4043`.
- Links: **13px**, color `#3c4043`/`#70757a` light, `#e3e3e3` dark; padding `~15px 27px`.
- Two rows: region line on top; About/Advertising/Business/How-Search-works on the left,
  Privacy/Terms/Settings(⚙) on the right.

---

## 5. Results page

### 5.1 Top header
- **Small logo** top-left (~`92–120px` wide, vertically centered in a ~`56–60px` bar),
  left margin aligns with the results column (~`x:170–180px` content start, logo sits left of it).
- **Search box** left-aligned **next to the logo** (same `.RNNXgb` pill): live **height 52px**,
  `border-radius:26px`, light `border:1px solid #dadce0; background:#fff;`
  `box-shadow: rgba(31,31,31,.08) 0 3px 10px;` It is **wider** than homepage (stretches with
  the header, ~`692px` measured), with the search icon on the left and a clear-(✕)/voice/Lens
  cluster on the right.
- Right side: profile avatar / **Sign in**, an **apps grid**, and a **Settings** (gear) entry.

### 5.2 Category / tab bar (All · Images · Videos · News · Maps · More)
- A horizontal nav directly under the header, left-aligned to the results column.
- Tab label font **14px**.
- **Active tab (CURRENT design):** text **`#1f1f1f`** with a **3px** bottom underline in
  **`#1f1f1f`** (measured live — *the underline is dark gray, not blue, in the 2024+ UI*).
- **Active tab (LEGACY):** **`#1a73e8`** text + **3px `#1a73e8`** underline. Support both via
  `--g-tab-active`.
- **Inactive tabs:** `#5f6368` (light) / `#9aa0a6` (dark), no underline; hover adds a faint
  underline / text darken.
- The bar has a hairline `1px #dadce0` (light) / `#3c4043` (dark) bottom divider that the
  active underline overlaps.

### 5.3 Results column geometry (measured live, 1440px viewport)
- **`#center_col` width: 652px`** ✅ (the famous ~652px measure — confirmed exactly).
- **Left offset: `x ≈ 170px`** ✅ (left margin ~170–180px from viewport edge; older specs say
  180px). There is no right-side content column on plain web results by default; knowledge
  panels (when present) sit further right.
- The column hosts: tab bar → (optional AI overview / ads) → `#search`/`#rso` results list
  → People-also-ask → related searches → pagination, all at the same 652px width.

### 5.4 A single ORGANIC RESULT block (top → bottom, measured live)

```
┌─ result block (width 652px, ~30px vertical gap to next) ─────────────────┐
│  (●)  Site Name                                            ⋮ (About icon)  │  ← row 1
│       https://example.com › path › subpath                                 │  ← URL row
│  Blue Clickable Title Goes Here In 20px Google-Sans         ← row 2 (H3)    │
│  Snippet description text in 14px near-black, two or three lines clamped,   │  ← row 3
│  ending with an ellipsis…                                                   │
└────────────────────────────────────────────────────────────────────────────┘
```

1. **Favicon + site row:**
   - Favicon image **18×18px** (measured live) sitting inside a **~26px** circular/rounded
     container with `border-radius: 50%` (light wells the favicon on a faint
     `#f1f3f4`/`#303134` circle). *Use your own favicons / a neutral placeholder.*
   - **Site name** at 14px, color `#1f1f1f` / `#e8e8e8`, ~8px right of the favicon.
   - **URL / breadcrumb** beneath (or inline on one line): `cite` at **12px**, color
     **`#4d5156`** / `#bdc1c6`, segments joined by a `›` separator. (No more green URLs.)
   - A small **⋮ / "About this result"** affordance at the row's right edge.
2. **Title (H3 link):** **20px / 26px**, weight **400**, `"Google Sans", Arial`,
   color **`#1a0dab`** (light) / **`#99c3ff`** (dark), `text-decoration:none` → underline on
   hover. Top margin from URL row ~`3–5px`.
3. **Snippet:** **14px / ~20–22px**, weight 400, color **`#1f1f1f`** / `#e8e8e8` (near-black,
   *not* gray), `Arial`. Usually clamped to 2–3 lines (`-webkit-line-clamp`). Top margin ~`3px`.
4. **Spacing between results:** **~26–30px** gap (measured **30px** live). Each block has no
   visible border/card on plain web results (cards appear for some rich result types).

### 5.5 "People also ask" (PAA) accordion
- A bordered card containing stacked question rows.
- Card: `border:1px solid #dadce0` (light) / `#3c4043` (dark), `border-radius:8px`, white /
  `#1f1f1f`-ish surface, full 652px width.
- Each question row: ~`48–54px` tall, question text 16px `#1f1f1f`/`#e8e8e8`, with a
  chevron/expand (▾) icon on the right; rows separated by 1px dividers.
- Expanding reveals an answer snippet (14px) + a source result block + a `▴` to collapse.

### 5.6 Related searches chips (measured live)
- Grid of pill chips (2 columns on desktop).
- Chip: `background:#f7f8f9` (light, measured) / `#28292a` (dark), `border-radius:8px`,
  `min-height:52px` (measured; a roomy pill), `font-size:14px`, text `#1f1f1f`/`#e8e8e8`,
  often with a small magnifier icon at left; hover lightens the fill.
- Some related-search variants use **rounded outline chips** (`border:1px solid #dadce0`,
  `border-radius:16–18px`, height ~`32px`) — Google ships both styles.

### 5.7 Pagination footer
- Classic numbered pager ("Goooogle" / page numbers) OR the newer **"More results"** button.
- Current page number: color `#1f1f1f` / `#e8e8e8`, weight 400 (no longer bold-orange).
- Other page links + **Next ›**: color **`#1a0dab`** (measured live — uses the *title* blue,
  not the action blue) / `#99c3ff` dark.
- Newer "More results" is a pill/button using the accent blue `#1a73e8` / `#8ab4f8`.

---

## 6. Images results

- **Dense, gap-tight grid** of thumbnails — rows of **justified** images (variable widths,
  uniform row height ~`180px` desktop), not a fixed masonry; Google sizes each row so images
  fill the row width edge-to-edge (à la a "justified gallery").
- **Gaps:** very small, roughly **`4px`** between tiles (both axes) — the look is intentionally
  dense. On mobile it collapses to 2–3 columns.
- **Tile:** image with `border-radius:8px`; below it a compact **label** line:
  - Title/alt text at **~14px**, color `#1f1f1f` / `#e8e8e8`, single line, ellipsis.
  - Source/site at **~12px**, color `#4d5156` / `#bdc1c6`, sometimes with a tiny favicon.
- **Hover:** the tile lifts slightly (subtle `box-shadow`), shows a faint overlay and the
  label; cursor pointer. Selecting a tile opens a **side/overlay preview panel** (right side
  on desktop) with the enlarged image, title, source, related images, and action buttons —
  the grid stays behind it.
- Background: same `#fff` / `#1f1f1f` as web results; the grid has the same ~`170px` left
  offset but a **wider content area** than the 652px text column (images use most of the
  viewport width).

---

## 7. Dark-mode structural specifics (what differs beyond colors)

Dark mode is **almost entirely a color/token swap** — geometry, spacing, font sizes, the
652px column, the 30px gaps, tab underline thickness, etc. are **identical**. Differences:

1. **Search box is filled, not outlined.** Light: white with a 1px gray border. Dark: a
   **filled** pill `#4d5156` with a *transparent* border; on hover/focus/open it deepens to
   `#303134` and gains a heavy shadow `rgba(23,23,23,.9) 0 4px 12px` (vs light's soft
   `rgba(32,33,36,.28)`).
2. **Surfaces are elevated by lightening, not shadowing.** Cards/menus/PAA go to `#303134`
   (lighter than the `#1f1f1f`/`#22242a` page) instead of relying on drop shadows.
3. **Two-tier accent blue.** Dark uses `#8ab4f8`/`#99c3ff` for links and a *separate*
   `#a8c7fa` (Material-You) for icon/accent fills — light mostly collapses to `#1a73e8`.
4. **Borders are `#3c4043`** (low-contrast) rather than `#dadce0`.
5. **Footer/top-bar** lose their distinct fill and blend into the page background (with a
   `#3c4043` hairline) instead of the light `#f2f2f2` footer band.
6. Brand/logo colors are unchanged across modes (the four brand hues stay vivid).

---

## 8. Putting it together — minimal faithful CSS skeleton

```css
body{ background:var(--g-bg); color:var(--g-text);
      font:14px/1.5 Arial, "Helvetica Neue", sans-serif; }

/* results column */
.g-results{ width:652px; margin-left:170px; }

/* one result */
.g-result{ margin-bottom:30px; }
.g-result__url{ display:flex; align-items:center; gap:8px; }
.g-result__favicon{ width:26px; height:26px; border-radius:50%;
                    display:grid; place-items:center; background:var(--g-surface); }
.g-result__site{ font-size:14px; color:var(--g-url-sitename); }
.g-result__cite{ font-size:12px; color:var(--g-url); }
.g-result__title{ font:400 20px/1.3 "Inter", Arial, sans-serif;  /* Google Sans subst. */
                  color:var(--g-link); text-decoration:none; margin-top:4px; display:block; }
.g-result__title:visited{ color:var(--g-link-visited); }
.g-result__title:hover{ text-decoration:underline; }
.g-result__snippet{ font-size:14px; line-height:1.58; color:var(--g-text); margin-top:3px; }

/* tab bar */
.g-tabs__item{ font-size:14px; color:var(--g-tab-inactive); padding:0 12px 12px;
               border-bottom:3px solid transparent; }
.g-tabs__item--active{ color:var(--g-tab-active); border-bottom-color:var(--g-tab-active); }

/* search pill */
.g-search{ width:584px; max-width:calc(100% - 40px); height:46px; border-radius:24px;
           background:var(--g-bg); border:1px solid var(--g-border-home);
           display:flex; align-items:center; padding:0 16px; }
.g-search:hover, .g-search:focus-within{
           border-color:transparent; box-shadow:0 1px 6px rgba(32,33,36,.28); }
[data-theme="dark"] .g-search{ background:var(--g-search-bg); border-color:transparent; }
[data-theme="dark"] .g-search:hover{ background:var(--g-search-bg-focus);
           box-shadow:var(--g-focus-shadow) 0 4px 12px; }

/* homepage buttons */
.g-btn{ height:36px; padding:0 16px; border-radius:8px;       /* 4px for classic look */
        font:500 14px "Inter", Arial, sans-serif;
        background:var(--g-btn-bg); color:var(--g-btn-text);
        border:1px solid var(--g-btn-border); }
.g-btn:hover{ border-color:var(--g-btn-border-hover); box-shadow:0 1px 1px rgba(0,0,0,.1); }

/* related-search chips */
.g-chip{ min-height:52px; border-radius:8px; padding:0 16px; font-size:14px;
         background:var(--g-surface); color:var(--g-text); display:flex; align-items:center; }
```

---

## 9. Don't-copy checklist (trademark/IP safety)

- ❌ Google wordmark / "G" logo / favicon → ship your own brand mark.
- ❌ Product Sans / Google Sans → use Arial (body) + Inter/Manrope/Poppins (display).
- ❌ Google's icon glyphs (mic, Lens, apps-grid, etc.) → use an open icon set
  (Material Symbols *open-source*, Lucide, Heroicons).
- ✅ Layout metrics, spacing, and **functional color roles** (these are not protectable as
  trademark) — reproduced via the tokens above.

---

## Sources

Live inspection of `https://www.google.com/` and a live results page
(`https://www.google.com/search?q=…`) via `getComputedStyle()` and direct CSS-source scraping
in **both light and dark mode** (primary, authoritative source for all measured px/hex values).
Cross-checked against:

- Google brand colors (4285f4 / EA4335 / FBBC05 / 34A853): https://colorcode.tools/brands/google
- Google color codes & action blue 1a73e8: https://brandpalettes.com/google-colors/
- #1a73e8 action blue vs #4285f4 brand blue history: https://encycolorpedia.com/1a73e8
- Classic title link #1a0dab (rgb 26,13,171) + A/B link-color tests: https://goodui.org/leaks/google-has-been-a-b-testing-link-colors-again-and-this-light-blue-didnt-pass/
- Google Search results color references: https://brandpalettes.com/google-search-results-colors/ , https://www.schemecolor.com/google-search-results-colors.php
- Google dark theme color references: https://www.schemecolor.com/google-dark-theme.php , https://blog.shahednasser.com/google-in-dark-mode/
- Material Design dark theme baseline (#121212 surface guidance): https://m2.material.io/design/color/dark-theme.html
- Material Design color system: https://m2.material.io/design/color/the-color-system.html
- Google Sans / Product Sans proprietary + font-stack guidance: https://www.dozro.com/fonts/google-sans-and-roboto-as-default-system-font , https://www.ideastoreach.com/blog/font-used-by-google
- Styling a Google-like search box (border #dfe1e5, radius=height/2, focus shadow): https://medium.com/100-days-in-kyoto-to-create-a-web-app-with-google/day-17-styling-a-search-box-like-googles-e17dd9074abe
- Google results column width history (~600–652px): https://www.searchlaboratory.com/2016/06/google-extends-results-column-width-test-changes/
- Google Search visual elements & PAA / related-searches structure: https://developers.google.com/search/docs/appearance/visual-elements-gallery , https://developers.google.com/search/docs/appearance/title-link
- Google dark theme on desktop (rollout context): https://www.xda-developers.com/google-search-desktop-finally-dark-theme/

> *Captured June 2026. Google A/B-tests these constantly and is mid-migration between two grey
> ramps and two active-tab styles; treat ✅ values as "current as inspected" and keep the
> legacy values as documented fallbacks.*
