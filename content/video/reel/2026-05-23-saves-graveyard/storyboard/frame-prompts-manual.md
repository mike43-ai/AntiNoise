# Manual Frame Prompts — Variant A

**Where to run:** https://gemini.google.com (free, model: Nano Banana / 2.5 Flash Image) or https://aistudio.google.com
**Save to:** `/Users/huyai/Documents/Projects/Anti Noise/content/video/reel/2026-05-23-saves-graveyard/storyboard/`
**Aspect ratio:** 9:16 vertical for all (chọn vertical/portrait nếu Gemini hỏi)
**Output filename:** đặt đúng tên file dưới mỗi prompt để pipeline sau pick up đúng

---

## 1. Scene 1 START → save as `scene-1-1-start.png`

```
Brutalist anti-design poster, pure white background, oversized black Helvetica Bold text reading "YOUR SAVES FOLDER" filling top half of vertical frame, intentionally cramped layout, text slightly off-center to the left, no shadows, no gradients, no rounded corners, raw flat 2D composition, zine aesthetic, sharp typography, bottom half empty white space, 9:16 vertical aspect ratio. Negative: gradients, soft shadows, drop shadows, glow effects, photorealism, color outside black and white, rounded corners, ornament.
```

---

## 2. Scene 1 END → save as `scene-1-2-end.png`

```
Brutalist anti-design poster, pure white background, oversized black Helvetica Bold text reading "YOUR SAVES FOLDER" top half and "= GRAVEYARD" with a skull emoji bottom half, solid hot pink rectangle highlighter painted behind only the word "GRAVEYARD", subtle glitch displacement and chromatic-aberration jitter on the text edges of GRAVEYARD only, intentionally off-center layout, no shadows, no gradients, no rounded corners, 9:16 vertical aspect ratio. Negative: gradients, soft shadows, glow, multiple pink elements, photorealism, decorative serif, rounded corners.
```

---

## 3. Scene 2 START → save as `scene-2-1-start.png`

```
Flat brutalist illustration of an iPhone screen rendered as a tall thin black wireframe rectangle on pure white background, the screen content shows Safari Reading List with 47 unread article entries listed vertically, each entry is a single grey horizontal line with a placeholder rectangle, a top header reads "0 of 47 read" in solid hot pink Helvetica Bold, no phone bezels, no shadows, no gradients, flat 2D zine aesthetic, 9:16 vertical aspect ratio. Negative: realistic iPhone rendering, gradients, drop shadow, depth, photoreal, app icons in color, rounded corners on outer phone frame.
```

---

## 4. Scene 2 END → save as `scene-2-2-end.png`

```
Brutalist collage poster, pure white background, six flat black wireframe rectangles representing app screens labeled in small black text "Twitter Bookmarks", "YouTube Watch Later", "Instagram Saves", "Notes", "Pocket", "Notion", arranged in a chaotic overlapping stack tilted at slight random angles, hand-drawn marker-style red arrows pointing at each label with handwritten lowercase word "lol" beside every arrow, giant black Helvetica Bold text overlay "1,247 SAVED · 12 READ" diagonal across the middle, raw anti-design aesthetic, intentional cluttered composition, 9:16 vertical aspect ratio. Negative: clean alignment, gradients, soft shadows, realistic app screenshots, colored UI elements other than the red arrows, rounded corners.
```

---

## 5. Scene 3 START → save as `scene-3-1-start.png`

```
Flat brutalist illustration of an iPhone app screen as a tall black wireframe rectangle on pure white background, the in-app view shows one saved article entry with the title "Why memory is leaky — Atlantic 2025" in small black Helvetica, a thumbnail placeholder above it as a flat black rectangle outline, an oversized solid hot pink rectangular button at the bottom of the screen labeled "Feynman it" with an arrow glyph in pure black Helvetica Bold, no phone bezels, no shadows, no gradients, no rounded corners, flat 2D zine aesthetic, 9:16 vertical aspect ratio. Negative: realistic iOS rendering, gradients, glow, shadow, depth, soft pink, rounded button.
```

---

## 6. Scene 3 END → save as `scene-3-2-end.png`

```
Flat brutalist illustration of an iPhone app screen as a tall black wireframe rectangle on pure white background, the in-app view shows a 5-part Feynman summary as five vertically stacked text cards each labeled "1. Simple", "2. Analogy", "3. Gaps", "4. Examples", "5. Questions" in black Helvetica with solid hot pink square number badges, below them a row of three flashcards as black wireframe outlines with a large question mark on each, a tiny handwritten lowercase word "auto" with a curved marker-style arrow points at the flashcard row, a small solid hot pink badge in the top right corner reads "30s", pure white outside the phone wireframe, flat 2D zine aesthetic, 9:16 vertical aspect ratio. Negative: gradients, soft shadows, glow, realistic UI, depth, drop shadows, soft pink, rounded corners on cards.
```

---

## 7. Scene 4 START → save as `scene-4-1-start.png`

```
Brutalist anti-design poster, pure white background, oversized black Helvetica Bold text reading "JOIN THE WAITLIST" centered in a 9:16 vertical frame, a solid hot pink rectangle highlighter painted behind only the word "WAITLIST", intentionally cramped layout, no shadows, no gradients, no rounded corners, raw zine aesthetic, 9:16 vertical aspect ratio. Negative: gradients, glow, drop shadow, soft pink, multiple accent colors, rounded corners, photorealism.
```

---

## 8. Scene 4 END → save as `scene-4-2-end.png`

```
Brutalist anti-design poster, pure white background, oversized black Helvetica Bold text "JOIN THE WAITLIST" centered, solid hot pink rectangle highlighter behind the word "WAITLIST", small black monospace text "antinoise.pages.dev" at the bottom of the frame, a hand-drawn marker-style red arrow points diagonally up from the URL toward the upper right corner with a handwritten lowercase label "link in bio" beside it, small "0:16 / 0:16" timecode in the bottom-right corner mirroring the opening hook, 9:16 vertical aspect ratio. Negative: gradients, glow, drop shadow, additional pink areas, photoreal arrow, rounded corners, decorative typography.
```

---

# Validation Checklist (apply to mỗi frame trước khi accept)

- [ ] Pure white BG (không xám, không gradient)
- [ ] Text "YOUR SAVES FOLDER" / "GRAVEYARD" / "JOIN THE WAITLIST" KHÔNG bị typo
- [ ] Hot pink CHỈ ở vị trí đã chỉ định (1 nơi/frame, không loang ra elsewhere)
- [ ] Không có rounded corner ở UI wireframes
- [ ] Composition 9:16 (cao gấp ~1.78× rộng), không bị letterbox
- [ ] Helvetica Bold, không phải serif khác

Nếu fail → regenerate trong cùng prompt (Gemini Chat cho phép) hoặc thêm tag mạnh hơn vào negative.

---

# Sau khi có đủ 8 frame

1. Move/save tất cả vào folder `storyboard/` này với đúng tên file
2. Reply mình "8 frame xong" → mình sẽ:
   - Verify từng file (kích thước, aspect, OK)
   - Build storyboard.json để track
   - Đợi billing → render Veo motion clips (4 clip × ~$0.50)

# Tip nhanh

- Trong Gemini Chat UI, nếu nó không cho chọn 9:16, gõ thêm cuối prompt: `"render as 1080x1920 vertical TikTok format, do not crop to square"`
- Nếu kết quả ra serif hoặc rounded → regenerate + thêm `"flat sans-serif Helvetica Bold only, no decorative typography, hard sharp corners on all shapes"` vào prompt
- Nếu hot pink ra hồng nhạt → thay từ `"hot pink"` bằng `"vivid magenta-pink, fluorescent, high saturation"`
