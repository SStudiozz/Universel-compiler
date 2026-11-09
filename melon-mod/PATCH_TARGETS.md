# Patch targets (from dump.cs / script.json)

## Camera shake on hit
- `HumanController.DealDamage(DamageSource, float)` RVA `0x21D1164`
- `HumanController.add_OnTakeDamage` / event
- `ShakeCameraControl.SetShake(float, bool isForce=false)` RVA `0x2109528`
- Setting: `SettingsData.CameraShake` + `SettingsController.CameraShakeToggle`

## Settings
- `SettingsData` / `SettingsData.SaveObject`
- `SettingsController.InitializeUI` RVA `0x222A588`
- Prefer side-file for NEW settings to avoid breaking old SaveObject layout

## Particles / Gore
- `SettingsData.Gore`
- `HumanController.get_IsGoreOn` RVA `0x21CF134`
- `ParticleSystemHelper`, `ParticleEffect`, sub-emitters
- New independent `DisableNonBloodParticles` (side storage)

## FPS counter
- New lightweight overlay; no existing dependency required
- Toggle in settings side storage

## Resolution scale (2D)
- Main camera world render scale / RenderTexture path
- UI cameras/canvases stay native
- Runtime discovery of camera stack required on device

## Saves / Mods
- `SaveSystem`, `.melsave`
- `ModLoader`, `ModPacker`
- Export path: public Downloads via MediaStore
- Files sidebar: Android DocumentsProvider over game data dir
