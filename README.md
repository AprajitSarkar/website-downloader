# ⚡ Website Downloader & Offline Browser for Android

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android" />
  <img src="https://img.shields.io/badge/Framework-Flutter%203.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Language-Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Architecture-100%25%20On--Device-10B981?style=for-the-badge&logo=speedtest&logoColor=white" alt="On-Device" />
  <img src="https://img.shields.io/badge/Google%20Play-Compliant-4285F4?style=for-the-badge&logo=googleplay&logoColor=white" alt="Google Play" />
  <img src="https://img.shields.io/badge/License-MIT-purple?style=for-the-badge" alt="License" />
</p>

---

## 🌟 Overview

**Website Downloader** is a modern, high-performance Android mobile application built with Flutter that allows you to scrape, package, bundle, and browse complete websites entirely offline. 

Unlike traditional web downloaders that depend on heavy external server backends or cloud scrapers, **Website Downloader runs 100% locally on your phone**. It parses HTML trees, downloads and rewrites linked CSS stylesheets, JavaScript files, images, and fonts, packages everything into portable `.zip` archives, and serves them locally using an embedded on-device localhost HTTP server.

---

## ✨ Key Features

- **⚡ 100% Standalone On-Device Engine**: No Node.js backend, cloud servers, or external proxies required. Everything runs inside the mobile app.
- **🌐 Embedded Localhost Web Server**: Serves downloaded websites over an internal `127.0.0.1` loopback server, bypassing `file://` CORS and font-rendering restrictions for a 1:1 original browsing experience.
- **🕒 Dynamic Download History**: Quick-access recent website history chips below the address input for rapid re-downloads and instant previews.
- **📦 ZIP Packaging & Scoped Storage**: Automatically extracts archives and organizes saved sites into the user's `Download/Website Downloader` directory with standard file manager access.
- **📜 Live Terminal Console**: Watch real-time scraping stages, network requests, byte streams, and ZIP compression metrics in a live hacker-style console.
- **💎 Ultra-Modern Liquid Glass UI**: Sleek glassmorphism theme designed with subtle gradients, responsive animations, and accessible typography.
- **🔒 Privacy First & Zero Telemetry**: Zero user tracking, zero data logging, and no analytics SDKs. All browsing data stays on your device.
- **🚀 Google Play Console Ready**: Follows latest Android scoped storage guidelines (API 33/34+ compliant), standard permission model, and included Privacy Policy.

---

## 📸 Screenshots & Architecture

```
                                [ Website Downloader Architecture ]
                                
    [ User Input URL ] 
            │
            ▼
    [ Native Dart Scraper ] ───► Fetches HTML & Parses DOM Tree
            │
            ├──────────────► Downloads Linked CSS, JS, Images, & Webfonts
            ├──────────────► Rewrites Relative & Absolute Resource URLs
            │
            ▼
    [ Archive & Compression Engine ] ───► Generates Clean .ZIP Bundle
            │
            ▼
    [ Scoped Storage / Device Vault ] ───► Stores in Download/Website Downloader
            │
            ▼
    [ Embedded Local Web Server (127.0.0.1) ]
            │
            ├──────────────► In-App Interactive WebView
            └──────────────► Launch in System Chrome / Firefox / Brave
```

---

## 🚀 Quick Start & Download APK

### 📲 Download Pre-Built APK
Get the latest stable release directly from GitHub:
👉 **[Download Latest APK from Releases](https://github.com/AprajitSarkar/website-downloader/releases)**

### 🛠️ Building from Source

```bash
# 1. Clone the repository
git clone https://github.com/AprajitSarkar/website-downloader.git
cd website-downloader/website_downloader_mobile

# 2. Fetch Flutter dependencies
flutter pub get

# 3. Run on connected Android device or emulator
flutter run

# 4. Build release APK
flutter build apk --release
```

The compiled APK will be located at:
`website_downloader_mobile/build/app/outputs/flutter-apk/app-release.apk`

---

## 🏷️ Google Play Console & Package Name Configuration

Website Downloader is designed to be easily branded or published under your existing Google Play Console app identifier.

To update the package name / application ID for your Play Store listing:
1. Open `website_downloader_mobile/android/app/build.gradle.kts`
2. Update the `applicationId` to match your registered Google Play Console package:
   ```kotlin
   defaultConfig {
       applicationId = "com.yourcompany.websitedownloader"
       minSdk = 24
       targetSdk = 34
       versionCode = 1
       versionName = "1.0.0"
   }
   ```
3. Build the signed Android App Bundle (AAB):
   ```bash
   flutter build appbundle --release
   ```

---

## 🔒 Privacy Policy

Website Downloader does not collect or transmit personal information. Read our full [Privacy Policy](PRIVACY_POLICY.md).

---

## 🙏 Credits & Acknowledgments

- **Original Inspiration:** The concept and desktop/Node.js web scraper architecture originated from [Website-downloader](https://github.com/AhmadIbrahiim/Website-downloader) by **Ahmad Ibrahiim** ([@AhmadIbrahiim](https://github.com/AhmadIbrahiim)).
- **Mobile Standalone Re-Architecture:** Created with Flutter, Dio, HTML parser, and shelf embedded web server by **Aprajit Sarkar**.

---

## 📬 Contact & Support

- **Email:** [workcozmo@gmail.com](mailto:workcozmo@gmail.com)
- **GitHub:** [https://github.com/AprajitSarkar/website-downloader](https://github.com/AprajitSarkar/website-downloader)
- **Issues & Pull Requests:** [Issue Tracker](https://github.com/AprajitSarkar/website-downloader/issues)

---

<p align="center">
  <sub>Made with ❤️ and Flutter for seamless offline web access anywhere.</sub>
</p>
