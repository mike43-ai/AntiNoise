# Anti Noise — Landing page

Static landing tại `antinoise.pages.dev` (Cloudflare Pages free). Single-page HTML, neo-brutalist genz style (paper + ink + signal orange + lime + violet pops, ticker marquee, bento grid, reveal-on-scroll), responsive.

## Cấu trúc

```
landing/
├── index.html          # Toàn bộ trang (single-file, inline CSS)
├── assets/
│   └── og-image.png    # OG share image (1200×630, từ social-assets)
└── README.md           # File này
```

## Local preview

Mở file trực tiếp:

```bash
open landing/index.html
```

Hoặc serve qua local server (cho test relative paths):

```bash
cd landing && python3 -m http.server 8080
# → http://localhost:8080
```

## Deploy to Cloudflare Pages

### Option A — Direct upload (recommended cho lean solo, 5 phút)

1. Login `dash.cloudflare.com` (free account)
2. Sidebar → **Workers & Pages** → **Create application** → **Pages** → **Upload assets**
3. Project name: `antinoise` → URL sẽ thành `antinoise.pages.dev`
4. Drag-drop cả folder `landing/` lên → Deploy
5. Done. Live trong ~30 giây.

Sửa landing? Drag-drop lại folder để deploy version mới (Cloudflare giữ history).

### Option B — Git-based auto-deploy

1. Tạo GitHub repo mới `anti-noise-landing` (public hoặc private đều OK)
2. Push folder `landing/` lên repo
3. Cloudflare Pages → **Connect to Git** → chọn repo
4. Build settings: framework = None, build command = (trống), output = `/`
5. Mỗi `git push` auto-deploy

Option A nhanh hơn cho MVP. Option B khi bắt đầu sửa thường xuyên.

## Wire Beehiiv waitlist (5 phút)

Form hiện tại là placeholder — capture email vào console, không gửi đâu.

1. Sign up `beehiiv.com` (free tier 2,500 subs)
2. Tạo publication tên **Anti Noise**
3. Settings → **Subscribe Forms** → **Embed** → copy embed code
4. Trong `index.html`, tìm comment block:
   ```html
   <!--
   ==================================
   BEEHIIV WAITLIST FORM — Sau khi sign up beehiiv.com:
   ...
   -->
   ```
5. **Option 1 (đơn giản nhất):** Replace cả `<form class="form" id="waitlist-form">...</form>` bằng `<iframe src="https://embeds.beehiiv.com/...">`. Mất styling brand nhưng work ngay.
6. **Option 2 (giữ brand):** Đổi `<form>` action sang Beehiiv POST URL + dùng JS submit. Beehiiv docs: `developers.beehiiv.com` → Subscriptions API.

Sau khi wire xong, form sẽ thật sự capture email vào Beehiiv subscriber list. Test bằng cách submit email của bạn → check Beehiiv dashboard.

## Update flow

```
Edit index.html → preview local → drag-drop folder lên Cloudflare Pages
```

Hot reload manual nhưng nhanh. Không cần build step.

## Custom domain (sau, $0-12/year)

Nếu sau này muốn `antinoise.app` thay vì `antinoise.pages.dev`:

1. Mua domain Namecheap / Porkbun (~$12/year)
2. Cloudflare Pages project → **Custom domains** → Add `antinoise.app` → CNAME setup
3. Auto HTTPS via Cloudflare

Đề xuất defer tới sau v1.0.1 launch nếu pages.dev subdomain hoạt động OK.

## SEO checklist

- [x] `<title>` có hook
- [x] `<meta description>` 155 chars
- [x] OG image 1200×630 + og:title / og:description
- [x] Twitter card large image
- [x] Favicon SVG inline (ANTi/NOISE wordmark)
- [x] Heading hierarchy h1 → h2 → h3 đúng
- [x] `prefers-reduced-motion` respected (ticker, sticker bob, blip, reveal)
- [ ] `sitemap.xml` (optional, low priority cho single-page)
- [ ] `robots.txt` (Cloudflare Pages serve default OK)
- [ ] llms.txt cho AI discovery (defer, post-v1.0.1)

## Brand tokens (CSS variables trong `index.html`)

```css
--ink:     #0a0a0a  (near-black)
--paper:   #f4f1ea  (cream)
--paper-2: #ebe7dd  (cream tint, stat strip bg)
--accent:  #ff5e1a  (signal orange — kept from origin)
--lime:    #c6ff3a  (genz pop, accents/highlights)
--violet:  #7b5cff  (genz pop, accents/cards)
--muted:   #5a5650  (body text secondary)
```

Fonts: Archivo (display, h1/h2 weight 800-900), Space Grotesk (logo), JetBrains Mono (eyebrows, ticker, meta).

Lưu ý: social assets trong `docs/social-assets/` vẫn dùng brand cream/dark/orange minimalist (pre-pivot 2026-05-21). Re-render nếu muốn đồng bộ.
