import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../models/saved_site.dart';
import 'storage_service.dart';

class DownloadService {
  final StorageService _storageService;
  final Dio _dio;

  DownloadService({
    StorageService? storageService,
    Dio? dio,
  })  : _storageService = storageService ?? StorageService(),
        _dio = dio ?? Dio();

  Future<SavedSite> fetchAndExtractSite({
    required String serverBaseUrl,
    required String zipFileName,
    required String originalUrl,
    required int fileCount,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    final cleanBaseUrl = serverBaseUrl.endsWith('/')
        ? serverBaseUrl.substring(0, serverBaseUrl.length - 1)
        : serverBaseUrl;

    final fileWithExtension = zipFileName.endsWith('.zip')
        ? zipFileName
        : '$zipFileName.zip';

    final downloadUrl = '$cleanBaseUrl/sites/$fileWithExtension';
    final archivesDir = await _storageService.getArchivesDir();
    final localZipFile = File(p.join(archivesDir.path, fileWithExtension));

    // Download ZIP file from server
    await _dio.download(
      downloadUrl,
      localZipFile.path,
      onReceiveProgress: onReceiveProgress,
    );

    final siteId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Extract archive
    final extractedPath = await _storageService.extractZipArchive(
      zipFilePath: localZipFile.path,
      siteId: siteId,
    );

    // Find entrypoint HTML file
    final entryHtml = await _storageService.findEntryHtml(extractedPath) ??
        p.join(extractedPath, 'index.html');

    final uri = Uri.tryParse(originalUrl);
    final hostname = uri?.host.isNotEmpty == true
        ? uri!.host
        : originalUrl.replaceAll(RegExp(r'https?://'), '').split('/').first;

    final zipSize = await localZipFile.length();

    final savedSite = SavedSite(
      id: siteId,
      title: hostname,
      hostname: hostname,
      originalUrl: originalUrl,
      zipPath: localZipFile.path,
      extractedPath: extractedPath,
      entryHtmlPath: entryHtml,
      sizeBytes: zipSize,
      fileCount: fileCount,
      downloadedAt: DateTime.now(),
    );

    await _storageService.saveSite(savedSite);
    return savedSite;
  }
}
