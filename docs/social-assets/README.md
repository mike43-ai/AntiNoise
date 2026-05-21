# Anti Noise — Social Assets

13 ready-to-use social-card templates cho 6-week X/Twitter content + launch. Tất cả standalone HTML, brand-matched neo-brutalist (paper #f4f1ea + ink #0a0a0a + signal orange #ff5e1a + lime #c6ff3a + violet #7b5cff), wordmark "ANTi/NOISE" Archivo 900.

## Quick start

```bash
chmod +x export-to-png.sh
./export-to-png.sh
```

Render tất cả HTML → PNG vào `./png/`. Cần Chrome cài sẵn (dùng `--headless=new`).

Hoặc manual: mở file HTML trong browser → DevTools (Cmd+Opt+I) → device toolbar (Cmd+Shift+M) → set exact size → 3-dot menu → Capture screenshot.

## Templates → X content mapping

| File | Size | Use in `x-content-6-weeks.md` |
|---|---|---|
| `og-image-1200x630.html` | 1200×630 | Landing OG share + bio link |
| `og-launch-v1-1200x630.html` | 1200×630 | Tuần 2 — v1.0 soft launch thread tweet 1/5 |
| `og-launch-v101-1200x630.html` | 1200×630 | Tuần 5 — v1.0.1 BIG launch pinned thread 1/5 |
| `quote-card-1080x1080.html` | 1080×1080 | Tuần 1 Day 9 — "Reading without testing is just hoarding" |
| `quote-graveyard-1080x1080.html` | 1080×1080 | Pinned intro thread 2/8 + Day 3 ("graveyard" idiom) |
| `quote-no-api-key-1080x1080.html` | 1080×1080 | Tuần 5 launch day quote — máy gốc cho hook |
| `quote-invisible-ux-1080x1080.html` | 1080×1080 | Tuần 3 Day 17 — migration silent purge post |
| `stats-card-1200x675.html` | 1200×675 | Tuần 2 Day +7 — week-1 retro |
| `stats-launch-day-1200x675.html` | 1200×675 | Tuần 5 Day +1 — PH end of day |
| `stats-launch-retro-1200x675.html` | 1200×675 | Tuần 6 Day +3 — full launch retro 5/5 |
| `comparison-tldr-vs-feynman-1200x675.html` | 1200×675 | Tuần 1 Day 9 thread 1/4 — Feynman vs TL;DR |
| `comparison-v1-vs-v101-1200x675.html` | 1200×675 | Tuần 3 Day 15 — refactor announcement |
| `feature-flow-1080x1080.html` | 1080×1080 | Pinned intro thread 3/8 (the flow) + any "what does it do" reply |

## Edit instructions

Tất cả số liệu trong cards là **placeholder draft** — sửa text thật trước khi export:

- `stats-card-1200x675.html` — 23 / 5 / 11 / 78% giả định, sửa thành số thật sau tuần 2
- `stats-launch-day-1200x675.html` — 187 / 312 / 47 / 8 giả định, sửa sau PH day 0
- `stats-launch-retro-1200x675.html` — funnel 580 → 142 → 89 → 67 → 40 giả định, sửa sau D+2

Mở file HTML trong text editor, search số → replace. Re-export.

## Brand tokens (consistent across all — matches `landing/index.html`)

| Token | Value | Use |
|---|---|---|
| `--paper` (light bg) | `#f4f1ea` | OG, light quote, light stats — default majority |
| `--paper-2` (light bg alt) | `#ebe7dd` | Stat box alt fill |
| `--ink` (dark bg, all borders, text) | `#0a0a0a` | Dark quote (graveyard, no-api-key), v1.0.1 launch OG, all 3px borders |
| `--accent` (signal orange) | `#ff5e1a` | Wordmark "NOISE", highlight blocks, accent shadows, badges |
| `--lime` (genz pop) | `#c6ff3a` | Badges, accent stat boxes, lime-tinted comparison column |
| `--violet` (genz pop) | `#7b5cff` | Stickers, occasional stat box, secondary highlight |
| `--muted` (light bg text) | `#5a5650` | Captions, mono labels on paper |
| Display / titles / wordmark | Archivo 900 -0.03em uppercase | "ANTi"/"NOISE", h1/h2 titles, stat numbers |
| Body | Archivo 500-700 | Body copy, takeaways |
| Mono | JetBrains Mono 500-700 | Eyebrows, dates, URLs, badges |
| Logo accent (optional) | Space Grotesk 700 | Step numbers in feature-flow |

### Neo-brutalist signatures
- 3px solid `--ink` borders on stat boxes, comparison columns, panels
- Hard offset shadows no blur: `5px 5px 0 var(--ink)` or `5px 5px 0 var(--accent)` for emphasis
- Bordered pill badges: `border:2px solid var(--ink); background:var(--lime|--accent|--violet); box-shadow:3px 3px 0 var(--ink)`
- Headline highlight `.hl::after` — rotated -1.5deg accent block behind one keyword
- Tilted stickers (rotate 6-8deg) in corners
- Decorative blur blobs sparingly (smaller, brighter, opacity 0.3-0.5) for soft depth on dark bg

## Adding new templates

Pattern theo các file hiện có:
1. Standalone HTML — không external CSS, chỉ Google Fonts qua `@import`
2. Body có dark `#2a2a2a` wrapper để preview
3. `.card` có size exact = filename (1200×630, 1200×675, hoặc 1080×1080)
4. Define `:root` với 7 CSS variables (--ink/--paper/--paper-2/--accent/--lime/--violet/--muted)
5. Wordmark dùng inline structure `<div class="anti">ANT<span class="lower">i</span></div><div class="noise">NOISE</div>` với Archivo 900 -0.03em uppercase
6. Highlight pattern: `<span class="hl">word</span>` + `.hl::after` rotated block
7. Save as `{type}-{topic}-{WxH}.html` kebab-case

## Capacity reality

Mỗi card chuẩn ~1-2 phút edit text + 5 giây export. Mỗi tuần BIP ~3-5 post → 3-5 cards.

Realistic: lúc cần image cho post X, mở file template gần nhất, sửa text, export, post. Không phải tạo từ đầu mỗi lần.
