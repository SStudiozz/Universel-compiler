# Melon Playground — Files sidebar (DocumentsProvider)

## Goal
Appear in Android Files app sidebar like Termux / PojavLauncher, with browse access to Melon saves/mods data.

## Mechanism
Register `android.content.action.DOCUMENTS_PROVIDER` for package `com.studio27.MelonPlayground`.

Authority: `com.studio27.MelonPlayground.documents`

Root directory preference order:
1. `context.getExternalFilesDir(null)` — `Android/data/com.studio27.MelonPlayground/files`
2. Fallback: `context.getFilesDir()`

Expose recursively: saves (`.melsave`), mods, exported ZIPs, user content.

## Manifest snippet
```xml
<provider
    android:name="com.studio27.melonmod.MelonDocumentsProvider"
    android:authorities="com.studio27.MelonPlayground.documents"
    android:exported="true"
    android:grantUriPermissions="true"
    android:permission="android.permission.MANAGE_DOCUMENTS">
    <intent-filter>
        <action android:name="android.content.action.DOCUMENTS_PROVIDER" />
    </intent-filter>
</provider>
```

## Build
Use workflow `melon-documents-provider.yml` on GitHub Actions (local Unity APK decode is too heavy for the sandbox).

## Current artifact
- Ad-kill APK (38 patches, clean libunity): build locally as `melon-adkill-v2.apk`
- SHA-256: `61e0bc6bf657ad82612afc0bb8bf13a8222fdbe228f1ac85b71f087bc5fa7090`
