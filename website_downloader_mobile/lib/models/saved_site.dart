import 'dart:convert';
import 'package:intl/intl.dart';

class SavedSite {
  final String id;
  final String title;
  final String hostname;
  final String originalUrl;
  final String zipPath;
  final String extractedPath;
  final String entryHtmlPath;
  final int sizeBytes;
  final int fileCount;
  final DateTime downloadedAt;

  SavedSite({
    required this.id,
    required this.title,
    required this.hostname,
    required this.originalUrl,
    required this.zipPath,
    required this.extractedPath,
    required this.entryHtmlPath,
    required this.sizeBytes,
    required this.fileCount,
    required this.downloadedAt,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(downloadedAt);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'hostname': hostname,
      'originalUrl': originalUrl,
      'zipPath': zipPath,
      'extractedPath': extractedPath,
      'entryHtmlPath': entryHtmlPath,
      'sizeBytes': sizeBytes,
      'fileCount': fileCount,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }

  factory SavedSite.fromMap(Map<String, dynamic> map) {
    return SavedSite(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      hostname: map['hostname'] ?? '',
      originalUrl: map['originalUrl'] ?? '',
      zipPath: map['zipPath'] ?? '',
      extractedPath: map['extractedPath'] ?? '',
      entryHtmlPath: map['entryHtmlPath'] ?? '',
      sizeBytes: map['sizeBytes'] ?? 0,
      fileCount: map['fileCount'] ?? 0,
      downloadedAt: DateTime.tryParse(map['downloadedAt'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory SavedSite.fromJson(String source) =>
      SavedSite.fromMap(json.decode(source));
}
