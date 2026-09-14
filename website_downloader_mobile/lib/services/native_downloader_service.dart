import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;
import '../models/download_task.dart';
import '../models/saved_site.dart';
import 'storage_service.dart';

class NativeDownloaderService {
  final StorageService _storageService;
  final Dio _dio;
  bool _isCancelled = false;

  NativeDownloaderService({
    StorageService? storageService,
    Dio? dio,
  })  : _storageService = storageService ?? StorageService(),
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
                  'Accept':
                      'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
                },
              ),
            );

  void cancel() {
    _isCancelled = true;
  }

  Future<SavedSite?> downloadWebsite({
    required String targetUrl,
    required void Function(DownloadTask task) onTaskUpdate,
    required void Function(String error) onError,
  }) async {
    _isCancelled = false;
    final token = DateTime.now().millisecondsSinceEpoch.toString();
    final List<String> logs = [];
    int downloadedCount = 0;

    void log(String message) {
      logs.add(message);
      if (logs.length > 250) logs.removeAt(0);
    }

    Uri? targetUri;
    try {
      var raw = targetUrl.trim();
      if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
        raw = 'https://$raw';
      }
      targetUri = Uri.parse(raw);
      if (targetUri.host.isEmpty) {
        throw const FormatException('Invalid hostname');
      }
    } catch (e) {
      onError('Invalid website address. Please enter a valid URL like https://example.com');
      return null;
    }

    final siteId = DateTime.now().millisecondsSinceEpoch.toString();
    final hostname = targetUri.host;

    var currentTask = DownloadTask(
      token: token,
      url: targetUri.toString(),
      status: TaskStatus.connecting,
      currentStatusDetails: 'Connecting to $hostname...',
      startedAt: DateTime.now(),
      logs: logs,
    );
    onTaskUpdate(currentTask);

    log('==> Starting Native In-App Web Downloader');
    log('==> Resolving host $hostname...');
    log('==> Requesting ${targetUri.toString()}');

    final sitesDir = await _storageService.getSitesDir();
    final siteFolder = Directory(p.join(sitesDir.path, siteId));
    await siteFolder.create(recursive: true);

    final assetsFolder = Directory(p.join(siteFolder.path, 'assets'));
    await assetsFolder.create(recursive: true);

    String? htmlContent;
    try {
      final response = await _dio.get<String>(
        targetUri.toString(),
        options: Options(responseType: ResponseType.plain),
      );
      htmlContent = response.data;
      log('[200 OK] Received main HTML document (${htmlContent?.length ?? 0} bytes)');
      downloadedCount++;
    } catch (e) {
      currentTask = currentTask.copyWith(
        status: TaskStatus.failed,
        error: 'Failed to reach website: $e',
        completedAt: DateTime.now(),
      );
      onTaskUpdate(currentTask);
      onError('Failed to reach $hostname: $e');
      return null;
    }

    if (htmlContent == null || htmlContent.isEmpty) {
      currentTask = currentTask.copyWith(
        status: TaskStatus.failed,
        error: 'Received empty response from website.',
        completedAt: DateTime.now(),
      );
      onTaskUpdate(currentTask);
      onError('Received empty response from website.');
      return null;
    }

    currentTask = currentTask.copyWith(
      status: TaskStatus.downloading,
      downloadedFilesCount: downloadedCount,
      currentStatusDetails: 'Parsing HTML document and discovering assets...',
      logs: List.from(logs),
    );
    onTaskUpdate(currentTask);

    // Parse HTML
    final document = html_parser.parse(htmlContent);

    // Collect all asset URLs
    final Map<String, String> urlToLocalRelative = {};
    final Set<String> assetUrls = {};

    void addAsset(String? rawUrl) {
      if (rawUrl == null || rawUrl.trim().isEmpty) return;
      final trimmed = rawUrl.trim();
      if (trimmed.startsWith('data:') || trimmed.startsWith('javascript:') || trimmed.startsWith('mailto:') || trimmed.startsWith('#')) {
        return;
      }
      try {
        final resolved = targetUri!.resolve(trimmed).toString();
        assetUrls.add(resolved);
      } catch (_) {}
    }

    // Stylesheets & Icons
    for (final el in document.querySelectorAll('link[href]')) {
      final href = el.attributes['href'];
      final rel = el.attributes['rel']?.toLowerCase() ?? '';
      if (rel.contains('stylesheet') || rel.contains('icon') || rel.contains('preload') || rel.contains('image')) {
        addAsset(href);
      }
    }

    // Scripts
    for (final el in document.querySelectorAll('script[src]')) {
      addAsset(el.attributes['src']);
    }

    // Images & Picture sources
    for (final el in document.querySelectorAll('img, source')) {
      addAsset(el.attributes['src']);
      addAsset(el.attributes['data-src']);
      final srcset = el.attributes['srcset'];
      if (srcset != null) {
        for (final part in srcset.split(',')) {
          final candidate = part.trim().split(' ').first;
          addAsset(candidate);
        }
      }
    }

    // Audio & Video
    for (final el in document.querySelectorAll('audio[src], video[src]')) {
      addAsset(el.attributes['src']);
    }

    log('==> Discovered ${assetUrls.length} external assets (CSS, JS, Images, Fonts)');

    // Download each asset concurrently with rate limit
    int assetIndex = 0;
    for (final assetUrl in assetUrls) {
      if (_isCancelled) {
        log('==> Download cancelled by user.');
        currentTask = currentTask.copyWith(
          status: TaskStatus.cancelled,
          completedAt: DateTime.now(),
        );
        onTaskUpdate(currentTask);
        return null;
      }

      assetIndex++;
      final uri = Uri.parse(assetUrl);
      var filename = p.basename(uri.path);
      if (filename.isEmpty || !filename.contains('.')) {
        filename = 'res_$assetIndex${_guessExtension(assetUrl)}';
      } else {
        // Sanitize filename
        filename = filename.replaceAll(RegExp(r'[^\w\.\-]'), '_');
        filename = '${assetIndex}_$filename';
      }

      final localRelative = 'assets/$filename';
      final localFile = File(p.join(siteFolder.path, localRelative));

      log('[$assetIndex/${assetUrls.length}] Fetching $assetUrl');

      currentTask = currentTask.copyWith(
        downloadedFilesCount: downloadedCount,
        activeFileName: filename,
        currentStatusDetails: 'Downloading asset $assetIndex/${assetUrls.length}: $filename',
        logs: List.from(logs),
      );
      onTaskUpdate(currentTask);

      try {
        final res = await _dio.get<List<int>>(
          assetUrl,
          options: Options(responseType: ResponseType.bytes),
        );

        if (res.data != null && res.data!.isNotEmpty) {
          await localFile.writeAsBytes(res.data!);
          urlToLocalRelative[assetUrl] = localRelative;
          downloadedCount++;
          log('[200 OK] Saved $localRelative (${res.data!.length} bytes)');

          // If this is a CSS file, parse for url(...) fonts/background images
          if (filename.toLowerCase().endsWith('.css') || res.headers.value('content-type')?.contains('css') == true) {
            final cssString = utf8.decode(res.data!, allowMalformed: true);
            await _processCssAssets(
              cssString: cssString,
              cssBaseUri: uri,
              cssFile: localFile,
              siteFolder: siteFolder,
              log: log,
            );
          }
        }
      } catch (e) {
        log('[Warning] Could not fetch $assetUrl: ${e.toString().split('\n').first}');
      }
    }

    // Rewrite HTML asset references to local relative files
    log('==> Rewriting HTML asset paths for offline viewing...');

    for (final el in document.querySelectorAll('link[href]')) {
      final raw = el.attributes['href'];
      if (raw != null) {
        final resolved = _resolveOrNull(targetUri, raw);
        if (resolved != null && urlToLocalRelative.containsKey(resolved)) {
          el.attributes['href'] = urlToLocalRelative[resolved]!;
        }
      }
    }

    for (final el in document.querySelectorAll('script[src]')) {
      final raw = el.attributes['src'];
      if (raw != null) {
        final resolved = _resolveOrNull(targetUri, raw);
        if (resolved != null && urlToLocalRelative.containsKey(resolved)) {
          el.attributes['src'] = urlToLocalRelative[resolved]!;
        }
      }
    }

    for (final el in document.querySelectorAll('img[src], source[src]')) {
      final raw = el.attributes['src'];
      if (raw != null) {
        final resolved = _resolveOrNull(targetUri, raw);
        if (resolved != null && urlToLocalRelative.containsKey(resolved)) {
          el.attributes['src'] = urlToLocalRelative[resolved]!;
        }
      }
    }

    // Save rewritten index.html
    final indexFile = File(p.join(siteFolder.path, 'index.html'));
    await indexFile.writeAsString(document.outerHtml);
    log('==> Rewritten index.html created successfully.');

    // Step 3: Create ZIP Archive locally
    currentTask = currentTask.copyWith(
      status: TaskStatus.converting,
      downloadedFilesCount: downloadedCount,
      activeFileName: 'Creating ZIP archive...',
      currentStatusDetails: 'Compressing all offline assets into ZIP archive...',
      logs: List.from(logs),
    );
    onTaskUpdate(currentTask);

    log('==> Packaging website into ZIP archive...');
    final zipName = '${hostname.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}-$siteId.zip';
    final archivesDir = await _storageService.getArchivesDir();
    final zipFile = File(p.join(archivesDir.path, zipName));

    final archive = Archive();
    final allFiles = siteFolder.listSync(recursive: true);
    for (final entity in allFiles) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: siteFolder.path);
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      }
    }

    final zipBytes = ZipEncoder().encode(archive);
    await zipFile.writeAsBytes(zipBytes);
    log('[Completed] ZIP Archive created (${(zipBytes.length / 1024).toStringAsFixed(1)} KB)');

    final totalSize = await zipFile.exists() ? await zipFile.length() : await _calculateFolderSize(siteFolder);

    final savedSite = SavedSite(
      id: siteId,
      title: hostname,
      hostname: hostname,
      originalUrl: targetUri.toString(),
      zipPath: zipFile.path,
      extractedPath: siteFolder.path,
      entryHtmlPath: indexFile.path,
      sizeBytes: totalSize,
      fileCount: downloadedCount,
      downloadedAt: DateTime.now(),
    );

    await _storageService.saveSite(savedSite);

    currentTask = currentTask.copyWith(
      status: TaskStatus.completed,
      downloadedFilesCount: downloadedCount,
      zipFileName: zipName,
      localZipPath: zipFile.path,
      localExtractedPath: siteFolder.path,
      currentStatusDetails: 'All assets saved & ready for offline preview!',
      completedAt: DateTime.now(),
      logs: List.from(logs),
    );
    onTaskUpdate(currentTask);

    return savedSite;
  }

  Future<void> _processCssAssets({
    required String cssString,
    required Uri cssBaseUri,
    required File cssFile,
    required Directory siteFolder,
    required void Function(String msg) log,
  }) async {
    var modifiedCss = cssString;
    final urlRegex = RegExp(r'''url\(\s*['"]?([^'")]+)['"]?\s*\)''', caseSensitive: false);

    for (final match in urlRegex.allMatches(cssString)) {
      final rawAsset = match.group(1)?.trim();
      if (rawAsset == null || rawAsset.startsWith('data:') || rawAsset.startsWith('#')) continue;

      try {
        final assetUri = cssBaseUri.resolve(rawAsset);
        final filename = 'font_${p.basename(assetUri.path).replaceAll(RegExp(r'[^\w\.\-]'), '_')}';
        final localRel = 'assets/$filename';
        final destFile = File(p.join(siteFolder.path, localRel));

        if (!await destFile.exists()) {
          final res = await _dio.get<List<int>>(
            assetUri.toString(),
            options: Options(responseType: ResponseType.bytes),
          );
          if (res.data != null && res.data!.isNotEmpty) {
            await destFile.writeAsBytes(res.data!);
            log('  ↳ [CSS Font/Image] Saved $localRel (${res.data!.length} bytes)');
          }
        }

        // In CSS file inside assets/, relative path to assets/filename is just filename
        modifiedCss = modifiedCss.replaceAll(match.group(0)!, "url('$filename')");
      } catch (_) {}
    }

    await cssFile.writeAsString(modifiedCss);
  }

  String? _resolveOrNull(Uri base, String relative) {
    try {
      return base.resolve(relative.trim()).toString();
    } catch (_) {
      return null;
    }
  }

  String _guessExtension(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.css')) return '.css';
    if (lower.contains('.js')) return '.js';
    if (lower.contains('.png')) return '.png';
    if (lower.contains('.jpg') || lower.contains('.jpeg')) return '.jpg';
    if (lower.contains('.svg')) return '.svg';
    if (lower.contains('.webp')) return '.webp';
    if (lower.contains('.woff2')) return '.woff2';
    if (lower.contains('.woff')) return '.woff';
    if (lower.contains('.ttf')) return '.ttf';
    return '.dat';
  }

  Future<int> _calculateFolderSize(Directory dir) async {
    int size = 0;
    try {
      for (final f in dir.listSync(recursive: true)) {
        if (f is File) size += await f.length();
      }
    } catch (_) {}
    return size;
  }
}
