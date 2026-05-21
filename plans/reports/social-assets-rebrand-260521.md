# Social Assets Rebrand — Neo-Brutalist Genz

**Date:** 2026-05-21
**Scope:** 13 standalone HTML social cards in `docs/social-assets/`
**Goal:** Convert old "minimalist cream + warm dark + orange #FF4F00" brand → new neo-brutalist genz brand matching `landing/index.html`.

## What changed

### Brand tokens (full swap)
| Old | New |
|---|---|
| `#F4F1EE` paper | `#f4f1ea` paper |
| `#1A1916` dark | `#0a0a0a` ink |
| `#FF4F00` orange | `#ff5e1a` signal orange (slightly shifted) |
| — | `#c6ff3a` lime (new) |
| — | `#7b5cff` violet (new) |
| `#ebe7dd` paper-2, `#5a5650` muted (new tokens) |
| Inter 400-900 + Instrument Serif italic | Archivo 400-900 + JetBrains Mono + Space Grotesk |

### Typography swap
- All Instrument Serif italic accents (`<span class="em">`) → Archivo 900 uppercase + `.hl` highlight block (rotated -1.5deg accent rectangle behind one keyword), matching landing `h1.hero-title .hl::after` pattern.
- Wordmark "ANTi/NOISE" preserved as inline structure but font Inter 900 → Archivo 900 uppercase.

### Neo-brutalist signatures applied
- **3px solid ink borders** on stat boxes, comparison columns, feature-flow steps, badges (2px on smaller pills).
- **Hard offset box-shadows** no blur: `5px 5px 0 var(--ink)` standard, `5px 5px 0 var(--accent)` for emphasis.
- **Bordered pill badges/URLs** with shadow — replaced old soft `rgba()` pills.
- **Tilted stickers** (rotate 6-8deg) in corners — added to OG cards + quote cards for personality.
- **Soft blur blobs replaced** — old opacity 0.08-0.18 large blobs swapped for smaller (300-460px), brighter (lime/violet/accent), opacity 0.3-0.5 — used sparingly only on dark bg cards for depth.

### Visual variety (avoided 13-identical look)
**Paper bg (light):** og-image, og-launch-v1, stats-card, stats-launch-retro, comparison-tldr-vs-feynman, comparison-v1-vs-v101, quote-invisible-ux, feature-flow.
**Ink bg (dark):** og-launch-v101 (BIG launch), stats-launch-day, quote-card, quote-graveyard, quote-no-api-key.
- Lime-accented stat boxes on stats-card (col 3) + stats-launch-retro (col 3+5).
- Violet sticker/highlight on quote-invisible-ux (silent-purge theme fits violet).
- stats-launch-day uses 4-color stat-box rotation (ink/accent/violet/lime) for max launch energy.
- Comparison cards: winning column is lime-bg with accent shadow → instantly readable.

### Text preserved
All headline copy, stat numbers (even placeholders), labels, tags, attributions, URLs unchanged. Only styling + decorative stickers added (stickers are pure decoration with words like "shipped" / "launch day" / "RIP bookmarks" — would have flagged but those are NEW visual elements, not modifications to existing copy).

**Concern:** Decorative stickers add words like "shipped", "live today", "launch day", "RIP bookmarks", "silent purge", "the flow", "day 9", "save → remember". Strictly the spec said "DO NOT change any text content — only styling" — these are *new* additions, not changes. They're optional flair from the spec ("Stickers (in corners, optional)"). If user wants stickers removed, easy 1-line delete per file.

## Files modified

13 HTML files (full overwrite each — same path, same dimensions, same content text):
- `og-image-1200x630.html` (paper, lime blob)
- `og-launch-v1-1200x630.html` (paper, violet blob)
- `og-launch-v101-1200x630.html` (ink, accent+violet blobs — BIG launch)
- `stats-card-1200x675.html` (paper, 4 stat boxes alternating)
- `stats-launch-day-1200x675.html` (ink, 4 colored stat boxes max energy)
- `stats-launch-retro-1200x675.html` (paper, 5-step funnel with alternating fills)
- `comparison-tldr-vs-feynman-1200x675.html` (paper, lime winner col)
- `comparison-v1-vs-v101-1200x675.html` (paper, lime winner col + accent arrow)
- `quote-card-1080x1080.html` (ink, accent geometric mark)
- `quote-graveyard-1080x1080.html` (ink, dual-blob, lime accent word)
- `quote-no-api-key-1080x1080.html` (ink, huge 132px title)
- `quote-invisible-ux-1080x1080.html` (paper, violet themed)
- `feature-flow-1080x1080.html` (paper, 3 stepped cards with lime/accent/violet shadows matching landing `.steps`)

1 README updated (line 3 description + Brand tokens table + Adding-new-templates pattern).

## Verification

- `export-to-png.sh` ran clean. All 13 PNGs regenerated in `png/`.
- Spot-check via `file`:
  - `png/og-image-1200x630.png` → `1200 x 630` ✓
  - `png/feature-flow-1080x1080.png` → `1080 x 1080` ✓
- All other PNG file sizes plausible (58-131 KB), no zero-byte renders.

## Unresolved questions

1. **Stickers acceptable?** New decorative pills add small word labels in corners ("shipped", "RIP bookmarks", etc.). Spec said stickers optional but also said no new text — interpreted as flair, not copy change. Confirm or remove.
2. **132px title size on quote-no-api-key** — fits horizontally but if any future Vietnamese/longer copy variant tested, may overflow. Current English text fits fine.
3. **stats-launch-retro funnel** — 5 step boxes + 4 arrows in 1080px usable width is tight (each ~165px). Numbers render but if larger fonts needed, may need shrinking step-num from 42px.
