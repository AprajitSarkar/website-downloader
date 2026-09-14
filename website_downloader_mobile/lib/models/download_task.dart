enum TaskStatus {
  idle,
  connecting,
  downloading,
  converting,
  syncing, // Transferring zip from server to phone
  completed,
  failed,
  cancelled,
}

class DownloadTask {
  final String token;
  final String url;
  final TaskStatus status;
  final int downloadedFilesCount;
  final String? activeFileName;
  final String? currentStatusDetails;
  final double? zipDownloadPercent;
  final String? zipDownloadBytesText;
  final List<String> logs;
  final String? zipFileName;
  final String? localZipPath;
  final String? localExtractedPath;
  final String? error;
  final DateTime startedAt;
  final DateTime? completedAt;

  DownloadTask({
    required this.token,
    required this.url,
    this.status = TaskStatus.idle,
    this.downloadedFilesCount = 0,
    this.activeFileName,
    this.currentStatusDetails,
    this.zipDownloadPercent,
    this.zipDownloadBytesText,
    List<String>? logs,
    this.zipFileName,
    this.localZipPath,
    this.localExtractedPath,
    this.error,
    DateTime? startedAt,
    this.completedAt,
  })  : logs = logs ?? [],
        startedAt = startedAt ?? DateTime.now();

  DownloadTask copyWith({
    TaskStatus? status,
    int? downloadedFilesCount,
    String? activeFileName,
    String? currentStatusDetails,
    double? zipDownloadPercent,
    String? zipDownloadBytesText,
    List<String>? logs,
    String? zipFileName,
    String? localZipPath,
    String? localExtractedPath,
    String? error,
    DateTime? completedAt,
  }) {
    return DownloadTask(
      token: token,
      url: url,
      status: status ?? this.status,
      downloadedFilesCount: downloadedFilesCount ?? this.downloadedFilesCount,
      activeFileName: activeFileName ?? this.activeFileName,
      currentStatusDetails: currentStatusDetails ?? this.currentStatusDetails,
      zipDownloadPercent: zipDownloadPercent ?? this.zipDownloadPercent,
      zipDownloadBytesText: zipDownloadBytesText ?? this.zipDownloadBytesText,
      logs: logs ?? List.from(this.logs),
      zipFileName: zipFileName ?? this.zipFileName,
      localZipPath: localZipPath ?? this.localZipPath,
      localExtractedPath: localExtractedPath ?? this.localExtractedPath,
      error: error ?? this.error,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  bool get isActive =>
      status == TaskStatus.connecting ||
      status == TaskStatus.downloading ||
      status == TaskStatus.converting ||
      status == TaskStatus.syncing;

  bool get isCompleted => status == TaskStatus.completed;
  bool get isFailed => status == TaskStatus.failed;
}
