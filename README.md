# Universal Compiler

This repo now includes a quick ZIP-to-Android build helper.

## What it does
- accepts a ZIP file containing HTML, Rust, C++, or generic app content
- detects the project type automatically
- generates an Android project that targets Android 5+ (`minSdk 21`)
- uses full screen mode and hardware acceleration for smoother performance
- packages the imported project into an APK-ready Android project structure

## Quick commands

### Detect a ZIP project type
```bash
python3 universal_compiler.py detect my_project.zip
```

### Build Android packaging from a ZIP
```bash
python3 universal_compiler.py build my_project.zip --output build
```

### Create a starter project
```bash
python3 universal_compiler.py init --type html --name my_app --output build
```

### Launch generated Android build
```bash
cd build/my_app/android
./gradlew assembleDebug
```

## Notes
- HTML apps are wrapped into a fullscreen Android WebView.
- Rust and C++ projects are detected and scaffolded for Android packaging, but actual native Android toolchains still need Android NDK/SDK installed.
- This is a fast prototype for ZIP import and APK-ready project generation.

## Example flow
```bash
python3 universal_compiler.py build my_zip.zip --output build
cd build/my_zip/android
./gradlew assembleDebug
```
