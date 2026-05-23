# Anti Noise — Product Roadmap

> Locked 2026-05-23 brainstorm session. v1.0 đang Apple review round 3.

## Roadmap summary

| Version | Theme | Effort | Status |
|---|---|---|---|
| v1.0 | MVP | — | In Apple review (Build 6) |
| v1.0.1 | Server proxy + Gemini Flash migration | 3-5 ngày | Scoped — see [v1.0.1 spec](v1-0-1-server-proxy-spec.md) |
| v1.1 | Daily Knowledge (articles + layered cards) | ~2 tuần | Scoped — see [v1.1 spec](v1-1-daily-knowledge-spec.md) |
| v1.2 | Widgets + Chrome Ext + Android port | TBD | Candidates only |

## v1.2 candidates (defer until v1.1 data)

- **iOS Widgets**: Daily 3 articles widget, streak/due cards widget, quick capture widget
- **Chrome Extension**: Capture URL from browser → push to iOS app, reading-time text selection capture. Cần backend endpoint mới.
- **Google Play Store (Android)**: Major scope. Options:
  - React Native rewrite (shared codebase future)
  - Flutter rewrite
  - Kotlin/Compose parallel app (2 codebase maintain)
  - Effort: 4-8 tuần
  - Backend (v1.0.1 server proxy) ready, không cần rebuild

## Locked architecture decisions (2026-05-23)

1. **§2 unlocked**: Original plan locked "GPT-4o vision only" — unlocked 2026-05-23, switching all AI to **Gemini 2.0 Flash** starting v1.0.1.
2. **AI vendor consolidation**: Single provider Gemini cho rank + summary + flashcard. Lý do: cheaper, VI tốt hơn (Google data), free tier overlap, native multimodal.
3. **Content source**: Reddit API only (free, OAuth). Skip Twitter (API quá đắt từ 2023), skip HN/Dev.to.
4. **Card mechanic**: Layered 15 cards (Recognize → Recall → Apply) replacing 5-card lessons. Per Bloom's taxonomy.
5. **Server-shared API key**: Kill BYOK entirely. All AI calls qua server proxy với operator's Gemini key.

## Cost projection 1000 active users/month

- Reddit API: $0
- Gemini Flash rank + summary + flashcard: ~$25/mo total
- Cloudflare Workers + Firestore: $0 (free tier)
- **Total infra**: ~$25/mo
- Revenue $9.99 × 5% conv = $500/mo → **95% gross margin**

## Launch strategy

Per [growth-playbook.md](growth-playbook.md) Path C, updated 2026-05-23:

- **v1.0**: Soft launch only. KHÔNG burn PH/HN.
- **v1.0.1**: Quiet foundation update. Kill BYOK + Gemini migration.
- **v1.1**: **Big launch moment**. ProductHunt + HackerNews + Reddit. Hook = Daily Knowledge feature drop.

## Cross-references

- [v1.0.1 server proxy spec](v1-0-1-server-proxy-spec.md)
- [v1.1 daily knowledge spec](v1-1-daily-knowledge-spec.md)
- [Growth playbook](growth-playbook.md)
