import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback onStorageCleared;

  const SettingsScreen({
    super.key,
    required this.storageService,
    required this.onStorageCleared,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _storageUsedBytes = 0;
  String _storagePath = 'Loading...';
  int _savedSitesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final used = await widget.storageService.getTotalStorageUsed();
    final path = await widget.storageService.getDisplayStoragePath();
    final sites = await widget.storageService.getSavedSites();
    if (mounted) {
      setState(() {
        _storageUsedBytes = used;
        _storagePath = path;
        _savedSitesCount = sites.length;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $url')),
        );
      }
    }
  }

  Future<void> _sendEmail() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'workcozmo@gmail.com',
      queryParameters: {
        'subject': 'Website Downloader Feedback & Support',
      },
    );
    try {
      await launchUrl(emailUri);
    } catch (_) {
      _launchUrl('mailto:workcozmo@gmail.com');
    }
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Privacy Policy & Play Compliance',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '1. 100% On-Device Processing\n'
                'Website Downloader runs completely locally on your phone. All website scraping, asset bundling, CSS parsing, and ZIP creation are performed on-device without any intermediary servers.\n\n'
                '2. Zero Telemetry & Data Collection\n'
                'We do not collect, track, or share your browsing history, downloaded URLs, or offline archives. Your data never leaves your device.\n\n'
                '3. Permissions\n'
                'Storage and Internet permissions are solely used to fetch requested web pages and save offline ZIP archives to your device storage.\n\n'
                '4. Google Play Console Compliance\n'
                'This application complies with Google Play policies regarding user privacy, data safety, and scoped storage.\n\n'
                '5. Contact\n'
                'For questions or privacy concerns, contact: workcozmo@gmail.com',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1), height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('I Understand', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear All Downloaded Sites?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Text(
          'This will permanently delete all $_savedSitesCount saved website archives and unextracted folders from your device storage.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.storageService.clearAllData();
              await _loadSettings();
              widget.onStorageCleared();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF10B981),
                    content: Text('All downloaded website data cleared!'),
                  ),
                );
              }
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Color(0xFF38BDF8), size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Settings & Info',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Storage & Directory Glass Card
            GlassCard(
              borderColor: const Color(0xFF38BDF8).withAlpha(80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.folder_special_rounded, color: Color(0xFF38BDF8), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Offline Storage Location',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Website Downloader folder on phone',
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Directory path box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withAlpha(180),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Folder Path:',
                          style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _storagePath,
                          style: GoogleFonts.firaCode(fontSize: 11.5, color: const Color(0xFF38BDF8)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Vault Size:',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                      ),
                      Text(
                        '$_savedSitesCount sites • ${_formatBytes(_storageUsedBytes)}',
                        style: GoogleFonts.firaCode(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  if (_storageUsedBytes > 0) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onPressed: _confirmClearAll,
                        icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                        label: const Text('Clear All Downloaded Data'),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Open Source & GitHub Glass Card
            GlassCard(
              borderColor: const Color(0xFF6366F1).withAlpha(80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.code_rounded, color: Color(0xFF818CF8), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Open Source Project',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Website Downloader is an open source utility allowing anyone to mirror, bundle, and view complete web applications without internet access.',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1), height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _launchUrl('https://github.com/AprajitSarkar/website-downloader'),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('View GitHub Repository', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Original repository credit
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withAlpha(150),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Original Concept & Credits:',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Based on and inspired by Website-downloader by Ahmad Ibrahiim.',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFCBD5E1)),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _launchUrl('https://github.com/AhmadIbrahiim/Website-downloader'),
                          child: Text(
                            'github.com/AhmadIbrahiim/Website-downloader ↗',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF38BDF8), decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contact & Developer Glass Card
            GlassCard(
              borderColor: const Color(0xFF10B981).withAlpha(80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.email_outlined, color: Color(0xFF34D399), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Developer & Support',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'workcozmo@gmail.com',
                              style: GoogleFonts.firaCode(fontSize: 11, color: const Color(0xFF34D399)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF34D399),
                        side: const BorderSide(color: Color(0xFF34D399)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _sendEmail,
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Contact: workcozmo@gmail.com', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Privacy Policy & Version
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    onTap: _showPrivacyPolicy,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.privacy_tip_outlined, size: 16, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        Text(
                          'Privacy Policy',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFCBD5E1)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 6),
                        Text(
                          'v1.0.0 Native',
                          style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF38BDF8)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
