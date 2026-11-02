#!/usr/bin/env python3
import argparse
import os
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path

APP_PACKAGE = "com.example.universalcompiler"


def detect_project_type(project_dir: Path):
    files = []
    for path in project_dir.rglob('*'):
        if path.is_file():
            files.append(path)

    if (project_dir / "Cargo.toml").exists():
        return "rust"
    if (project_dir / "CMakeLists.txt").exists() or any(p.suffix.lower() in {".cpp", ".cc", ".cxx", ".c", ".h", ".hpp"} for p in files):
        return "cpp"
    if any(p.suffix.lower() == ".html" for p in files):
        return "html"
    if (project_dir / "build.gradle").exists() or (project_dir / "settings.gradle").exists():
        return "android"
    return "generic"


def find_entry_html(project_dir: Path):
    candidates = sorted(project_dir.rglob("*.html"))
    if not candidates:
        return "index.html"
    for c in candidates:
        if c.name.lower() == "index.html":
            return c.relative_to(project_dir).as_posix()
    return candidates[0].relative_to(project_dir).as_posix()


def write_text(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def copy_project_tree(source: Path, dest: Path):
    if source.exists():
        for item in source.iterdir():
            target = dest / item.name
            if item.is_dir():
                shutil.copytree(item, target, dirs_exist_ok=True)
            else:
                shutil.copy2(item, target)


def create_android_project(project_root: Path, project_name: str, project_type: str, entry_html: str):
    app_dir = project_root / "android"
    asset_dir = app_dir / "app" / "src" / "main" / "assets"
    code_dir = app_dir / "app" / "src" / "main" / "java" / "com" / "example" / "universalcompiler"
    res_dir = app_dir / "app" / "src" / "main" / "res" / "values"
    asset_dir.mkdir(parents=True, exist_ok=True)
    code_dir.mkdir(parents=True, exist_ok=True)
    res_dir.mkdir(parents=True, exist_ok=True)

    imported_dir = project_root / "imported"
    copy_project_tree(imported_dir, asset_dir)

    if entry_html and (imported_dir / entry_html).exists():
        source = imported_dir / entry_html
        if not (asset_dir / "index.html").exists():
            shutil.copy2(source, asset_dir / "index.html")
    if not (asset_dir / "index.html").exists():
        write_text(asset_dir / "index.html", "<!doctype html><html><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"></head><body style=\"margin:0;background:#111;color:#fff;display:flex;align-items:center;justify-content:center;height:100vh;font-family:sans-serif;\">Universal Compiler placeholder</body></html>\n")

    write_text(app_dir / "settings.gradle", f"pluginManagement {{ repositories {{ google(); mavenCentral(); gradlePluginPortal() }} }}\nrootProject.name = \"{project_name}\"\ninclude(':app')\n")
    write_text(app_dir / "build.gradle", "buildscript { repositories { google(); mavenCentral(); gradlePluginPortal() } dependencies { classpath 'com.android.tools.build:gradle:8.5.2' } }\nallprojects { repositories { google(); mavenCentral() } }\n")
    write_text(app_dir / "gradle.properties", "org.gradle.jvmargs=-Xmx2048m\nandroid.useAndroidX=true\nandroid.enableJetifier=true\n")
    write_text(app_dir / "app" / "build.gradle", '''
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android' version '1.9.24'
}

android {
    namespace 'com.example.universalcompiler'
    compileSdk 34

    defaultConfig {
        applicationId "com.example.universalcompiler"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = '17'
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.13.1'
    implementation 'androidx.appcompat:appcompat:1.7.0'
    implementation 'androidx.webkit:webkit:1.11.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
}
''')
    write_text(app_dir / "app" / "proguard-rules.pro", "")

    manifest = '''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:allowBackup="true"
        android:label="UniversalCompiler"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar"
        android:hardwareAccelerated="true">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="sensorLandscape"
            android:configChanges="orientation|screenSize|keyboardHidden"
            android:hardwareAccelerated="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
'''
    write_text(app_dir / "app" / "src" / "main" / "AndroidManifest.xml", manifest)

    write_text(res_dir / "colors.xml", '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="black">#000000</color>
</resources>
''')

    main_activity = '''package com.example.universalcompiler

import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_FULLSCREEN or
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        )
        window.statusBarColor = Color.BLACK
        window.navigationBarColor = Color.BLACK

        val webView = WebView(this)
        setContentView(webView)
        webView.setBackgroundColor(Color.BLACK)
        webView.setLayerType(View.LAYER_TYPE_HARDWARE, null)
        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true
        webView.settings.databaseEnabled = true
        webView.settings.allowFileAccess = true
        webView.settings.allowContentAccess = true
        webView.settings.builtInZoomControls = false
        webView.settings.loadWithOverviewMode = true
        webView.settings.useWideViewPort = true
        webView.settings.setRenderPriority(WebSettings.RenderPriority.HIGH)
        webView.webViewClient = WebViewClient()
        webView.loadUrl("file:///android_asset/index.html")
    }
}
'''
    write_text(code_dir / "MainActivity.kt", main_activity)

    readme = f'''# {project_name}

This project was generated by Universal Compiler.

Detected type: {project_type}
Entry file: {entry_html or 'index.html'}

Quick build:

cd android
gradle wrapper --gradle-version 8.7
./gradlew assembleDebug
'''
    write_text(app_dir / "README.md", readme)


def build_zip_project(zip_path: Path, output_dir: Path):
    if not zip_path.exists():
        raise FileNotFoundError(f"ZIP file not found: {zip_path}")

    project_name = zip_path.stem.replace(" ", "_")
    temp_dir = Path(tempfile.mkdtemp(prefix="uc_"))
    extract_dir = temp_dir / "input"
    extract_dir.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(zip_path, 'r') as zf:
        zf.extractall(extract_dir)

    project_root = output_dir / project_name
    project_root.mkdir(parents=True, exist_ok=True)
    imported_dir = project_root / "imported"
    imported_dir.mkdir(parents=True, exist_ok=True)
    copy_project_tree(extract_dir, imported_dir)

    project_type = detect_project_type(imported_dir)
    entry_html = find_entry_html(imported_dir)
    create_android_project(project_root, project_name, project_type, entry_html)

    summary = project_root / "summary.txt"
    summary.write_text(
        f"project_name={project_name}\nproject_type={project_type}\nentry_html={entry_html}\nandroid_dir={project_root / 'android'}\n",
        encoding="utf-8",
    )

    print(f"project_name={project_name}")
    print(f"project_type={project_type}")
    print(f"entry_html={entry_html}")
    print(f"android_dir={project_root / 'android'}")
    shutil.rmtree(temp_dir, ignore_errors=True)


def run_detect(zip_path: Path):
    temp_dir = Path(tempfile.mkdtemp(prefix="uc_detect_"))
    extract_dir = temp_dir / "input"
    extract_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_path, 'r') as zf:
        zf.extractall(extract_dir)
    project_type = detect_project_type(extract_dir)
    entry = find_entry_html(extract_dir)
    print(f"project_type={project_type}")
    print(f"entry_html={entry}")
    shutil.rmtree(temp_dir, ignore_errors=True)


def main():
    parser = argparse.ArgumentParser(description="Universal Compiler ZIP importer")
    subparsers = parser.add_subparsers(dest="command", required=True)

    detect_parser = subparsers.add_parser("detect", help="detect project type")
    detect_parser.add_argument("zip_path")

    build_parser = subparsers.add_parser("build", help="import zip and create Android project")
    build_parser.add_argument("zip_path")
    build_parser.add_argument("--output", default="build")

    init_parser = subparsers.add_parser("init", help="make starter project")
    init_parser.add_argument("--type", choices=["html", "cpp", "rust", "generic"], default="html")
    init_parser.add_argument("--name", default="starter_app")
    init_parser.add_argument("--output", default="build")

    args = parser.parse_args()

    if args.command == "detect":
        run_detect(Path(args.zip_path))
        return 0

    if args.command == "init":
        target = Path(args.output) / args.name
        target.mkdir(parents=True, exist_ok=True)
        if args.type == "html":
            (target / "index.html").write_text("<!doctype html><html><body><h1>Universal Compiler Starter</h1></body></html>\n", encoding="utf-8")
        elif args.type == "cpp":
            (target / "main.cpp").write_text("#include <iostream>\nint main(){ std::cout << \"Hello from C++\" << std::endl; }\n", encoding="utf-8")
        elif args.type == "rust":
            (target / "Cargo.toml").write_text("[package]\nname = \"starter\"\nversion = \"0.1.0\"\nedition = \"2021\"\n", encoding="utf-8")
            (target / "src").mkdir(exist_ok=True)
            (target / "src" / "main.rs").write_text("fn main(){ println!(\"Hello from Rust\"); }\n", encoding="utf-8")
        else:
            (target / "README.md").write_text("Generic app placeholder\n", encoding="utf-8")

        create_android_project(target, args.name, args.type, "index.html" if args.type == "html" else "")
        print(f"starter_project={target}")
        return 0

    if args.command == "build":
        out = Path(args.output)
        out.mkdir(parents=True, exist_ok=True)
        build_zip_project(Path(args.zip_path), out)
        return 0

    parser.print_help()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
