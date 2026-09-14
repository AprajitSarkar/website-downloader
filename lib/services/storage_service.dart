import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_site.dart';

class StorageService {
  static const String _sitesKey = 'saved_offline_sites';

  Future<bool> requestStoragePermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted) return true;
      final status = await Permission.storage.request();
      if (status.isGranted) return true;

      // On Android 13+ (SDK 33+)
      final photos = await Permission.photos.request();
      return photos.isGranted;
    }
    return true;
  }

  Future<Directory> getBaseAppDirectory() async {
    if (Platform.isAndroid) {
      // Try to use public Download/Website Downloader folder so user can easily see files
      final downloadDir = Directory('/storage/emulated/0/Download/Website Downloader');
      try {
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir;
      } catch (_) {}

      // Fallback to external storage directory
      try {
        final ext = await getExternalStorageDirectory();
        if (ext != null) {
          final dir = Directory(p.join(ext.path, 'Website Downloader'));
          if (!await dir.exists()) await dir.create(recursive: true);
          return dir;
        }
      } catch (_) {}
    }

    // Default to app documents directory
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docDir.path, 'Website Downloader'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> getArchivesDir() async {
    final base = await getBaseAppDirectory();
    final dir = Directory(p.join(base.path, 'Archives'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> getSitesDir() async {
    final base = await getBaseAppDirectory();
    final dir = Directory(p.join(base.path, 'Sites'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> getDisplayStoragePath() async {
    final base = await getBaseAppDirectory();
    return base.path;
  }

  Future<List<SavedSite>> getSavedSites() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_sitesKey) ?? [];
    return rawList.map((item) => SavedSite.fromJson(item)).toList();
  }

  Future<void> saveSite(SavedSite site) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = await getSavedSites();
    currentList.removeWhere((s) => s.id == site.id);
    currentList.insert(0, site);
    final jsonList = currentList.map((s) => s.toJson()).toList();
    await prefs.setStringList(_sitesKey, jsonList);
  }

  Future<void> deleteSite(String id) async {
    final sites = await getSavedSites();
    final targetIndex = sites.indexWhere((s) => s.id == id);
    if (targetIndex != -1) {
      final site = sites[targetIndex];
      try {
        final zipFile = File(site.zipPath);
        if (await zipFile.exists()) {
          await zipFile.delete();
        }
        final extractDir = Directory(site.extractedPath);
        if (await extractDir.exists()) {
          await extractDir.delete(recursive: true);
        }
      } catch (e) {
        // Ignored
      }
      sites.removeAt(targetIndex);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _sitesKey,
        sites.map((s) => s.toJson()).toList(),
      );
    }
  }

  Future<String> extractZipArchive({
    required String zipFilePath,
    required String siteId,
  }) async {
    final sitesRoot = await getSitesDir();
    final destinationDir = Directory(p.join(sitesRoot.path, siteId));
    if (await destinationDir.exists()) {
      await destinationDir.delete(recursive: true);
    }
    await destinationDir.create(recursive: true);

    final bytes = await File(zipFilePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final filename = file.name;
      final outPath = p.normalize(p.join(destinationDir.path, filename));

      // Guard against zip slip
      if (!outPath.startsWith(p.normalize(destinationDir.path))) {
        continue;
      }

      if (file.isFile) {
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        final data = file.content as List<int>;
        await outFile.writeAsBytes(data);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }

    return destinationDir.path;
  }

  Future<String?> findEntryHtml(String extractedDirPath) async {
    final dir = Directory(extractedDirPath);
    if (!await dir.exists()) return null;

    final directIndex = File(p.join(extractedDirPath, 'index.html'));
    if (await directIndex.exists()) return directIndex.path;

    final directIndexHtm = File(p.join(extractedDirPath, 'index.htm'));
    if (await directIndexHtm.exists()) return directIndexHtm.path;

    final entities = dir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File && p.basename(entity.path).toLowerCase() == 'index.html') {
        return entity.path;
      }
    }

    for (final entity in entities) {
      if (entity is File && p.extension(entity.path).toLowerCase() == '.html') {
        return entity.path;
      }
    }

    return null;
  }

  Future<List<String>> listHtmlPages(String extractedDirPath) async {
    final dir = Directory(extractedDirPath);
    if (!await dir.exists()) return [];
    final List<String> pages = [];
    try {
      final entities = dir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File &&
            (entity.path.endsWith('.html') || entity.path.endsWith('.htm'))) {
          pages.add(entity.path);
        }
      }
    } catch (_) {}
    return pages;
  }

  Future<int> getTotalStorageUsed() async {
    int total = 0;
    try {
      final archives = await getArchivesDir();
      if (await archives.exists()) {
        for (final f in archives.listSync(recursive: true)) {
          if (f is File) total += await f.length();
        }
      }
      final sites = await getSitesDir();
      if (await sites.exists()) {
        for (final f in sites.listSync(recursive: true)) {
          if (f is File) total += await f.length();
        }
      }
    } catch (_) {}
    return total;
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sitesKey);
    final archives = await getArchivesDir();
    if (await archives.exists()) {
      await archives.delete(recursive: true);
    }
    final sites = await getSitesDir();
    if (await sites.exists()) {
      await sites.delete(recursive: true);
    }
  }
}
