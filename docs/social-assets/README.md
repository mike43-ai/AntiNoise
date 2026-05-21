# Anti Noise — Social Assets

13 ready-to-use social-card templates cho 6-week X/Twitter content + launch. Tất cả standalone HTML, brand-matched (cream + warm dark + orange #FF4F00), wordmark "ANTi/NOISE" thật.

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

## Brand tokens (consistent across all)

| Token | Value | Use |
|---|---|---|
| Bg primary (light) | `#F4F1EE` | OG, light quote, light stats |
| Bg primary (dark) | `#1A1916` | Dark quote, v1.0.1 launch OG, dark stats |
| Text primary (light bg) | `#1D1B18` | |
| Text primary (dark bg) | `#F6F0EA` | |
| Accent orange | `#FF4F00` | All emphasis, wordmark "NOISE", buttons, badges |
| Wordmark font | Inter 900 -0.04em | "ANTi" / "NOISE" 2-line |
| Display serif | Instrument Serif | Headlines, quotes, stats numbers |
| Body sans | Inter 500-700 | Labels, tags |
| Mono | JetBrains Mono | Badges, URLs, dates, code |

## Adding new templates

Pattern theo các file hiện có:
1. Standalone HTML — không external CSS
2. Body có dark `#2a2a2a` wrapper để preview
3. `.card` có size exact = filename
4. Wordmark dùng inline structure `<div class="anti">ANT<span class="lower">i</span></div><div class="noise">NOISE</div>`
5. Decorative circle accent: `position: absolute; opacity: 0.08-0.18; background: #FF4F00; border-radius: 50%`
6. Save as `{type}-{topic}-{WxH}.html` kebab-case

## Capacity reality

Mỗi card chuẩn ~1-2 phút edit text + 5 giây export. Mỗi tuần BIP ~3-5 post → 3-5 cards.

Realistic: lúc cần image cho post X, mở file template gần nhất, sửa text, export, post. Không phải tạo từ đầu mỗi lần.
