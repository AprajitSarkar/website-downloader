import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/download_task.dart';
import '../models/saved_site.dart';
import '../services/native_downloader_service.dart';
import '../services/storage_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/progress_card.dart';
import '../widgets/terminal_log_view.dart';
import 'offline_viewer_screen.dart';

class DownloadScreen extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback onGoToVault;

  const DownloadScreen({
    super.key,
    required this.storageService,
    required this.onGoToVault,
  });

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final TextEditingController _urlController = TextEditingController();
  final NativeDownloaderService _nativeDownloader = NativeDownloaderService();
  DownloadTask? _currentTask;
  SavedSite? _lastSavedSite;
  bool _isProcessing = false;
  List<SavedSite> _recentSites = [];

  @override
  void initState() {
    super.initState();
    // Request permissions and load recent download history
    widget.storageService.requestStoragePermissions();
    _loadRecentHistory();
  }

  Future<void> _loadRecentHistory() async {
    final sites = await widget.storageService.getSavedSites();
    if (mounted) {
      setState(() {
        _recentSites = sites;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      setState(() {
        _urlController.text = data.text!.trim();
      });
    }
  }

  Future<void> _startDownload() async {
    final target = _urlController.text.trim();
    if (target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid website URL')),
      );
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Ensure permissions
    await widget.storageService.requestStoragePermissions();

    setState(() {
      _isProcessing = true;
      _lastSavedSite = null;
    });

    final savedSite = await _nativeDownloader.downloadWebsite(
      targetUrl: target,
      onTaskUpdate: (task) {
        if (mounted) {
          setState(() {
            _currentTask = task;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFEF4444),
              content: Text(error),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
    );

    if (savedSite != null && mounted) {
      setState(() {
        _lastSavedSite = savedSite;
        _isProcessing = false;
      });

      // Reload recent history
      _loadRecentHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text('Downloaded & packaged ${savedSite.hostname} (${savedSite.formattedSize})!'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'PREVIEW',
            textColor: Colors.black,
            onPressed: () => _openOfflineSite(savedSite),
          ),
        ),
      );
    } else if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _cancelDownload() {
    _nativeDownloader.cancel();
    setState(() {
      _isProcessing = false;
      _currentTask = _currentTask?.copyWith(
        status: TaskStatus.cancelled,
        currentStatusDetails: 'Download cancelled by user',
      );
    });
  }

  void _openOfflineSite(SavedSite site) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfflineViewerScreen(site: site),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // App Title & Tagline with Liquid Glass Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF38BDF8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withAlpha(80),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.cloud_download_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Website Downloader',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Native Engine • 100% On-Device',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF38BDF8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // URL Input Liquid Glass Card
                  GlassCard(
                    borderColor: const Color(0xFF38BDF8).withAlpha(90),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.link_rounded, color: Color(0xFF38BDF8), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Target Website Address',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _urlController,
                          keyboardType: TextInputType.url,
                          style: GoogleFonts.firaCode(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'https://example.com',
                            hintStyle: const TextStyle(color: Color(0xFF64748B)),
                            prefixIcon: const Icon(Icons.language_rounded, color: Color(0xFF38BDF8), size: 20),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_urlController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                                    onPressed: () {
                                      _urlController.clear();
                                      setState(() {});
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.content_paste_rounded, color: Color(0xFF38BDF8), size: 18),
                                  tooltip: 'Paste',
                                  onPressed: _pasteFromClipboard,
                                ),
                              ],
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0F172A).withAlpha(200),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Recently Downloaded Sites / History Chips
                        if (_recentSites.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.history_rounded, size: 14, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 4),
                              Text(
                                'Recently Downloaded History:',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _recentSites.take(8).map((site) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ActionChip(
                                    avatar: const Icon(
                                      Icons.language_rounded,
                                      size: 14,
                                      color: Color(0xFF38BDF8),
                                    ),
                                    label: Text(site.hostname),
                                    labelStyle: GoogleFonts.firaCode(
                                      fontSize: 10.5,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    backgroundColor: const Color(0xFF0F172A),
                                    side: const BorderSide(color: Color(0xFF334155)),
                                    onPressed: () {
                                      setState(() {
                                        _urlController.text = site.originalUrl;
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Enter any website URL to scrape, bundle, and view offline.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Download Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF38BDF8),
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: const Color(0xFF334155),
                              disabledForegroundColor: const Color(0xFF64748B),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isProcessing ? null : _startDownload,
                            child: _isProcessing
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Scraping & Archiving Website...',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.download_rounded, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Download Complete Website',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_currentTask != null) ...[
                    const SizedBox(height: 16),
                    ProgressCard(
                      task: _currentTask!,
                      onCancel: _cancelDownload,
                      onOpenOffline: _lastSavedSite != null
                          ? () => _openOfflineSite(_lastSavedSite!)
                          : null,
                      onViewInVault: widget.onGoToVault,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Realtime Terminal Logs Header
                  Row(
                    children: [
                      const Icon(Icons.terminal_rounded, size: 16, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text(
                        'Live Download Console',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFCBD5E1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 250,
                    child: TerminalLogView(
                      logs: _currentTask?.logs ?? [],
                      isRunning: _currentTask?.isActive ?? false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
