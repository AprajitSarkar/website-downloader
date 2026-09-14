import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

class LocalWebServer {
  static LocalWebServer? _instance;
  static LocalWebServer get instance => _instance ??= LocalWebServer._();

  LocalWebServer._();

  HttpServer? _server;
  String? _servingPath;
  int? _port;

  int? get port => _port;
  String? get servingPath => _servingPath;
  bool get isRunning => _server != null;

  Future<String> serveDirectory(String directoryPath) async {
    // If already serving the exact same directory and server is alive
    if (_server != null && _servingPath == directoryPath && _port != null) {
      return 'http://127.0.0.1:$_port/index.html';
    }

    await stop();

    _servingPath = directoryPath;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;

    debugPrint('LocalWebServer started on http://127.0.0.1:$_port for $directoryPath');

    _server!.listen((HttpRequest request) async {
      try {
        var reqPath = request.uri.path;
        if (reqPath == '/' || reqPath.isEmpty) {
          reqPath = '/index.html';
        }

        // Clean up leading slash
        if (reqPath.startsWith('/')) {
          reqPath = reqPath.substring(1);
        }

        final targetFile = File(p.join(directoryPath, reqPath));
        if (await targetFile.exists()) {
          final mimeType = lookupMimeType(targetFile.path) ?? 'application/octet-stream';
          request.response.headers.contentType = ContentType.parse(mimeType);
          request.response.headers.set('Access-Control-Allow-Origin', '*');
          await request.response.addStream(targetFile.openRead());
        } else {
          // Check for index.html in subdirectories if requested
          final fallbackIndex = File(p.join(directoryPath, 'index.html'));
          if (await fallbackIndex.exists()) {
            request.response.headers.contentType = ContentType.html;
            await request.response.addStream(fallbackIndex.openRead());
          } else {
            request.response.statusCode = HttpStatus.notFound;
            request.response.write('File not found: $reqPath');
          }
        }
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Server Error: $e');
      } finally {
        await request.response.close();
      }
    });

    return 'http://127.0.0.1:$_port/index.html';
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _port = null;
      _servingPath = null;
    }
  }
}
