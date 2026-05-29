---
phase: 1
title: "Design System Foundation (Kinetic Command)"
status: pending
priority: P1
effort: "3d"
dependencies: []
---

# Phase 1: Design System Foundation (Kinetic Command)

## Overview
Retune design tokens + components sang **Kinetic Command** (Soft Stone + Vibrant Orange + Space Grotesk + modular cards + glassmorphic dock). Foundation cho Phase 2 redesign màn.

## Requirements
- Functional: token + component reusable phản ánh DESIGN.md; Space Grotesk load được; glassmorphic floating dock.
- Non-functional: tận dụng DesignSystem sẵn có (`Core/DesignSystem/Tokens` + `Components`).

## Architecture
- DesignSystem đã có: `Tokens/AppColor.swift`, `AppFont.swift`, `AppSpacing.swift`, `AppRadius.swift`, `AppMotion.swift`; `Components/AppCard`, `PrimaryButton`, `SecondaryButton`, `GhostButton`, `Chip`, `BottomTabBar`, `AppTextField`, `AppEmptyState`, `AppLoadingIndicator`.
- Nguồn giá trị: `kinetic_command/DESIGN.md` + 3 mockup code.html.

## Design tokens (từ DESIGN.md)
- **Colors**: surface `#fff8f2`, surface-container `#f3ede7`, on-surface `#1d1b18`, on-surface-variant `#5c4037`, outline `#916f65`, primary `#a93100`, primary-container `#d34000`, on-primary `#ffffff`, inverse-surface `#33302c` (dark cards), error `#ba1a1a`.
- **Typography**: Space Grotesk — display 48/700/-0.02em, headline-lg 32/600, headline-md 24/600, body 16-18/400, label-sm 12/500 UPPERCASE 0.08em.
- **Spacing**: base 4px — xs4/sm8/md16/lg24/xl48, container-padding 32. **Radius**: sm4/8/md12/lg16/xl24/full.
- **Elevation**: card = white + 1px border `#E5E0DA` + soft shadow (Nero 15%, 20px blur, 4px Y). Overlay = glass blur(12px) 80%.

## Related Code Files
- Create: `AntiNoise/Resources/Fonts/SpaceGrotesk-*.ttf` (Regular/Medium/SemiBold/Bold) + register `UIAppFonts` trong `project.yml`
- **Modify: `AntiNoise/Resources/Assets.xcassets/*.colorset/Contents.json`** (giá trị màu THẬT ở đây, KHÔNG ở AppColor.swift)
- Modify: `AntiNoise/Core/DesignSystem/Tokens/AppFont.swift` (thêm `Font.custom("SpaceGrotesk-…")` + fallback SF + Dynamic Type)
- Modify: `AntiNoise/Core/DesignSystem/Tokens/AppSpacing.swift`, `AppRadius.swift`
- Modify: `Components/AppCard.swift`, `PrimaryButton.swift`, `SecondaryButton.swift` (dark), `GhostButton.swift`, `Chip.swift`
- Modify: `Components/BottomTabBar.swift` (glassmorphic floating dock + center "+" + active orange dot)
- Fix call-site hardcode `.font(.system(size:))` (vd `Chip.swift:16`, `BottomTabBar.swift:71`)

## Implementation Steps
1. Add Space Grotesk fonts + `project.yml` UIAppFonts; xcodegen generate; verify load.
2. **Edit `.colorset` JSON** trong Assets.xcassets cho từng semantic color (KHÔNG sửa AppColor.swift — nó chỉ là asset-key resolver `Color(rawValue, bundle:)`).
3. AppFont: `ScaledAppFont` dùng `Font.custom` cho Space Grotesk + fallback SF; label-sm uppercase helper; verify Dynamic Type scaling.
4. AppSpacing/AppRadius theo DESIGN.md.
5. AppCard + buttons + chip: border/shadow/radius/fill; SecondaryButton dark (Nero) như "Process & Save".
6. BottomTabBar → glassmorphic dock (`.ultraThinMaterial`, floating, center "+", active dot). Giữ tab hiện tại (rename defer — đụng v1.2).
7. Grep hardcoded color/`.system(size:)` call-site → chuyển token. DesignSystemPreview review; compile.

## Success Criteria
- [ ] Space Grotesk render đúng toàn app (verify trên device, không chỉ code)
- [ ] Đổi `.colorset` → màn hiện có tự đổi màu (semantic token giữ tên)
- [ ] Card/button/chip/dock khớp mockup (border, shadow, glass, orange)
- [ ] Không còn `.font(.system(size:))` hardcode ở call-site chính
- [ ] DesignSystemPreview + build pass

## Risk Assessment
- **[High] No-op risk**: màu ở `.xcassets` không phải AppColor.swift; font cần `Font.custom` không phải `.system`. Sửa sai chỗ = vô hiệu. Đã chỉ đúng file ở trên.
- Đổi token global → màn cũ vỡ chỗ hardcode → grep + migrate.
- Font Space Grotesk OFL (free) — confirm bundling.
- Glassmorphism GPU máy cũ → material gọn, test device cũ.
