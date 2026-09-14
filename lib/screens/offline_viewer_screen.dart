import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../models/saved_site.dart';
import '../services/local_web_server.dart';

class OfflineViewerScreen extends StatefulWidget {
  final SavedSite site;

  const OfflineViewerScreen({
    super.key,
    required this.site,
  });

  @override
  State<OfflineViewerScreen> createState() => _OfflineViewerScreenState();
}

class _OfflineViewerScreenState extends State<OfflineViewerScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  String _pageTitle = '';
  String _currentLocalUrl = '';
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _fileNotFound = false;
  bool _isDesktopMode = false;

  @override
  void initState() {
    super.initState();
    _pageTitle = widget.site.hostname;
    _initWebView();
  }

  Future<void> _initWebView() async {
    final file = File(widget.site.entryHtmlPath);
    if (!file.existsSync()) {
      setState(() {
        _fileNotFound = true;
      });
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
              });
            }
          },
          onPageStarted: (url) {
            _updateNavState();
          },
          onPageFinished: (url) async {
            final title = await _controller.getTitle();
            if (mounted) {
              setState(() {
                _loadingProgress = 100;
                if (title != null && title.isNotEmpty) {
                  _pageTitle = title;
                }
              });
            }
            _updateNavState();
          },
          onWebResourceError: (error) {
            debugPrint('Offline WebView resource error: ${error.description}');
          },
        ),
      );

    if (_controller.platform is AndroidWebViewController) {
      final androidController = _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    try {
      final localUrl = await LocalWebServer.instance.serveDirectory(widget.site.extractedPath);
      _currentLocalUrl = localUrl;
      await _controller.loadRequest(Uri.parse(localUrl));
    } catch (_) {
      _currentLocalUrl = widget.site.entryHtmlPath;
      await _controller.loadFile(widget.site.entryHtmlPath);
    }
  }

  Future<void> _updateNavState() async {
    final back = await _controller.canGoBack();
    final forward = await _controller.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = back;
        _canGoForward = forward;
      });
    }
  }

  Future<void> _openInSystemBrowser() async {
    try {
      if (_currentLocalUrl.isNotEmpty) {
        final uri = Uri.parse(_currentLocalUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open external browser: $e')),
        );
      }
    }
  }

  void _toggleDesktopMode() {
    setState(() {
      _isDesktopMode = !_isDesktopMode;
    });

    final ua = _isDesktopMode
        ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        : '';
    _controller.setUserAgent(ua);
    _controller.reload();
  }

  void _showSiteInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8)),
                const SizedBox(width: 8),
                Text(
                  'Offline Website Info',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow('Domain', widget.site.hostname),
            _infoRow('Original URL', widget.site.originalUrl),
            _infoRow('Archive Size', widget.site.formattedSize),
            _infoRow('Files Downloaded', '${widget.site.fileCount} items'),
            _infoRow('Downloaded On', widget.site.formattedDate),
            _infoRow('Offline Address', _currentLocalUrl),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openInSystemBrowser();
                    },
                    icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                    label: const Text('Open in Chrome'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_fileNotFound) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.site.hostname),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 60, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                Text(
                  'Offline Files Missing',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'The downloaded HTML entrypoint could not be found in local storage.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _pageTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Offline Local Server • ${widget.site.hostname}',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Open in external Chrome/System Browser
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded, color: Color(0xFF38BDF8)),
            tooltip: 'Open in Chrome / Browser',
            onPressed: _openInSystemBrowser,
          ),
          IconButton(
            icon: Icon(
              _isDesktopMode ? Icons.desktop_windows_rounded : Icons.phone_android_rounded,
              color: _isDesktopMode ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
            ),
            tooltip: _isDesktopMode ? 'Desktop Mode ON' : 'Mobile Mode',
            onPressed: _toggleDesktopMode,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF94A3B8)),
            tooltip: 'Site Info',
            onPressed: _showSiteInfo,
          ),
        ],
        bottom: _loadingProgress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: _canGoBack ? Colors.white : const Color(0xFF475569),
              ),
              onPressed: _canGoBack ? () => _controller.goBack() : null,
            ),
            IconButton(
              icon: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 20,
                color: _canGoForward ? Colors.white : const Color(0xFF475569),
              ),
              onPressed: _canGoForward ? () => _controller.goForward() : null,
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 22, color: Colors.white),
              onPressed: () => _controller.reload(),
            ),
            IconButton(
              icon: const Icon(Icons.home_rounded, size: 22, color: Colors.white),
              onPressed: () => _controller.loadRequest(Uri.parse(_currentLocalUrl)),
            ),
            IconButton(
              icon: const Icon(Icons.chrome_reader_mode_rounded, size: 22, color: Color(0xFF38BDF8)),
              tooltip: 'Open in Chrome',
              onPressed: _openInSystemBrowser,
            ),
          ],
        ),
      ),
    );
  }
}
