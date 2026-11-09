# Melon Playground 22.0.5 — Mod Scope (LOCKED)

## In scope
1. APK patch pipeline (rebuild + sign)
2. Hit camera shake (confirmed damage only)
3. Non-blood particle disable setting
4. Settings persistence for new options
5. FPS counter (small, top-left, toggleable)
6. GORE polish (existing systems, keep Gore toggle)
7. Internal 2D resolution slider
8. Save & Mod Manager (import/export/ZIP)
9. Export to Downloads
10. Melon in Android Files sidebar (DocumentsProvider)

## Out of scope (for now)
- Slow-motion improvement (deferred — heavy Time.timeScale / Physics2D coupling)
- Full Minecraft-style code mod API
- Root / permission bypasses

## Known blockers
- Source APK has unreadable `lib/arm64-v8a/libunity.so` (non-standard deflate). Pipeline removes or replaces it for signing.
- Il2CppDumper gives signatures/RVAs, not method bodies. Patches use hooks or binary edits at known RVAs.

## Package
- `com.studio27.MelonPlayground`
- versionName `22.0.5` / versionCode `114`
- ABIs: arm64-v8a, armeabi-v7a
- SHA-256 of base APK: `9d71ab33e2849bca17c8d37e77b299d3b62c13e10f94ebd7537c281449e034f5`
