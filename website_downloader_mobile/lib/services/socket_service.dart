import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/download_task.dart';

class SocketService {
  io.Socket? _socket;
  String? _connectedUrl;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  static String generateToken([int length = 20]) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  void connect({
    required String serverUrl,
    VoidCallback? onConnect,
    VoidCallback? onDisconnect,
    ValueChanged<dynamic>? onError,
  }) {
    if (_socket != null && _connectedUrl == serverUrl && _socket!.connected) {
      return;
    }

    _socket?.disconnect();
    _socket?.dispose();

    _connectedUrl = serverUrl;

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setReconnectionAttempts(3)
          .setTimeout(10000)
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('Socket connected to $serverUrl');
      onConnect?.call();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('Socket disconnected from $serverUrl');
      onDisconnect?.call();
    });

    _socket!.onConnectError((err) {
      _isConnected = false;
      debugPrint('Socket connect error: $err');
      onError?.call(err);
    });

    _socket!.connect();
  }

  void startDownload({
    required String serverUrl,
    required String targetUrl,
    required ValueChanged<DownloadTask> onTaskUpdate,
    required void Function(String zipFileName, int fileCount) onCompleted,
    required void Function(String error) onError,
  }) {
    final token = generateToken(20);
    int fileCount = 0;
    List<String> logs = [];
    String? currentActiveFile;
    String? currentDetails;

    DownloadTask currentTask = DownloadTask(
      token: token,
      url: targetUrl,
      status: TaskStatus.connecting,
      currentStatusDetails: 'Connecting to server...',
      startedAt: DateTime.now(),
    );

    onTaskUpdate(currentTask);

    connect(
      serverUrl: serverUrl,
      onConnect: () {
        currentTask = currentTask.copyWith(
          status: TaskStatus.downloading,
          currentStatusDetails: 'Initiating recursive mirroring...',
        );
        onTaskUpdate(currentTask);

        // Listen for updates on the token channel
        _socket!.on(token, (data) {
          if (data is Map) {
            final error = data['error'];
            final progress = data['progress'];
            final file = data['file'];

            if (error != null) {
              currentTask = currentTask.copyWith(
                status: TaskStatus.failed,
                error: error.toString(),
                currentStatusDetails: 'Failed: ${error.toString()}',
                completedAt: DateTime.now(),
              );
              onTaskUpdate(currentTask);
              onError(error.toString());
              _socket?.off(token);
              return;
            }

            if (progress != null) {
              final progressStr = progress.toString();
              logs.add(progressStr);
              if (logs.length > 200) {
                logs.removeAt(0);
              }

              // Parse active file and details from wget lines
              final parsedInfo = _parseWgetLine(progressStr);
              if (parsedInfo.activeFile != null) {
                currentActiveFile = parsedInfo.activeFile;
              }
              if (parsedInfo.statusDetails != null) {
                currentDetails = parsedInfo.statusDetails;
              }

              if (progressStr.contains('200 OK') || progressStr.contains('Saving to:')) {
                fileCount++;
              }

              if (progressStr == 'Converting') {
                currentTask = currentTask.copyWith(
                  status: TaskStatus.converting,
                  downloadedFilesCount: fileCount,
                  currentStatusDetails: 'Compressing site assets into ZIP archive...',
                  activeFileName: 'All assets gathered',
                  logs: List.from(logs),
                );
                onTaskUpdate(currentTask);
              } else if (progressStr == 'Completed') {
                final zipName = file?.toString() ?? '';
                currentTask = currentTask.copyWith(
                  status: TaskStatus.syncing,
                  downloadedFilesCount: fileCount,
                  zipFileName: zipName,
                  currentStatusDetails: 'Server compression finished. Syncing to device...',
                  logs: List.from(logs),
                );
                onTaskUpdate(currentTask);
                _socket?.off(token);
                onCompleted(zipName, fileCount);
              } else {
                currentTask = currentTask.copyWith(
                  status: TaskStatus.downloading,
                  downloadedFilesCount: fileCount,
                  activeFileName: currentActiveFile,
                  currentStatusDetails: currentDetails ?? 'Mirroring website assets...',
                  logs: List.from(logs),
                );
                onTaskUpdate(currentTask);
              }
            }
          }
        });

        // Send request payload
        _socket!.emit('request', {
          'token': token,
          'website': targetUrl,
        });
      },
      onError: (err) {
        currentTask = currentTask.copyWith(
          status: TaskStatus.failed,
          error: 'Could not connect to server at $serverUrl. Make sure the backend is running.',
          completedAt: DateTime.now(),
        );
        onTaskUpdate(currentTask);
        onError('Could not connect to server: $err');
      },
    );
  }

  ({String? activeFile, String? statusDetails}) _parseWgetLine(String line) {
    String? file;
    String? details;

    final trimmed = line.trim();

    // Saving to: 'example.com/assets/style.css'
    final savingMatch = RegExp(r"Saving to:\s*['"'"'"]([^'"'"'"]+)['"'"'"]").firstMatch(trimmed);
    if (savingMatch != null) {
      file = savingMatch.group(1);
      details = 'Saving $file';
    } else if (trimmed.contains('-->')) {
      final parts = trimmed.split('-->');
      if (parts.length > 1) {
        file = parts.last.replaceAll(RegExp(r"['"'"'"]"), '').trim();
        details = 'Downloaded $file';
      }
    } else if (trimmed.startsWith('Connecting to')) {
      details = trimmed;
    } else if (trimmed.startsWith('Resolving')) {
      details = trimmed;
    } else if (trimmed.contains('200 OK')) {
      details = '200 OK — Resource received';
    } else if (trimmed.startsWith('Length:')) {
      details = trimmed;
    }

    return (activeFile: file, statusDetails: details);
  }

  void cancelDownload(String token) {
    _socket?.off(token);
    _socket?.disconnect();
    _isConnected = false;
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
