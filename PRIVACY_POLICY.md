# Privacy Policy for Website Downloader

**Effective Date:** September 14, 2026  
**Last Updated:** September 14, 2026  
**Developer Contact:** workcozmo@gmail.com  
**Application:** Website Downloader (Standalone Android App)

---

## 1. Overview
Website Downloader is committed to protecting your privacy. This Privacy Policy describes our practices regarding information collected through the Website Downloader mobile application on Android.

---

## 2. 100% On-Device Processing
- **No External Servers:** Website Downloader operates entirely on your local Android device.
- **Local Scraping & Archiving:** All HTML parsing, asset fetching (CSS, JS, images, fonts), ZIP bundling, and offline rendering take place locally on your device without sending any data through external third-party proxies, telemetry backends, or cloud processors.

---

## 3. Zero Data Collection & Zero Telemetry
- **No Personal Information:** We do NOT collect, transmit, store, sell, or rent your personal information (including your name, email, device ID, IP address, or location).
- **No Browsing History Stored Remotely:** The URLs you download and the websites you view offline remain exclusively in your device's local storage.
- **No Third-Party Trackers or Analytics:** There are no analytics SDKs, advertising SDKs, or user tracking services included in the application.

---

## 4. Permissions Used & Why

Website Downloader requests only the minimum permissions necessary to deliver offline web archiving features:

| Permission | Purpose |
| :--- | :--- |
| `android.permission.INTERNET` | Required to fetch and download the user-specified webpage assets from the internet onto the local device. |
| `android.permission.ACCESS_NETWORK_STATE` | Used to verify network connectivity before initiating download tasks. |
| `android.permission.READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` *(API ≤ 32)* | Used to store downloaded ZIP archives and extracted website folders in the user's `Download/Website Downloader` directory so users can access their files. |

> **Scoped Storage & Modern Android:** On Android 13+ (API 33+), the app utilizes Scoped App Storage and standard media access. No sensitive all-files access permissions (`MANAGE_EXTERNAL_STORAGE`) are requested.

---

## 5. Offline Web Viewing & Embedded Local Server
- When viewing a downloaded website, an embedded lightweight HTTP server is temporarily started on `127.0.0.1` (localhost) strictly within your device's loopback interface.
- This localhost server is NOT exposed to external networks and is used exclusively to serve local HTML/CSS/JS files to the in-app WebView or system browser without `file://` security restrictions.

---

## 6. User Control & Data Deletion
You have complete control over your offline data at all times:
- You can delete individual saved websites at any time from the **Offline Vault** screen.
- You can clear all offline archives, temporary files, and downloaded sites instantly from **Settings > Clear All Downloaded Data**.
- Uninstalling the app completely removes all application data.

---

## 7. Compliance with Google Play Policies
Website Downloader is designed in full compliance with the Google Play Developer Program Policies, including the User Data Policy, Permissions Policy, and Family Policies.

---

## 8. Changes to This Privacy Policy
We may update our Privacy Policy periodically. Any changes will be posted within the application and in this repository.

---

## 9. Contact Us
If you have any questions, feedback, or privacy inquiries, please contact us at:

**Email:** [workcozmo@gmail.com](mailto:workcozmo@gmail.com)  
**GitHub Repository:** [https://github.com/AprajitSarkar/website-downloader](https://github.com/AprajitSarkar/website-downloader)
