import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/saved_site.dart';
import '../services/storage_service.dart';
import '../widgets/site_card.dart';
import 'offline_viewer_screen.dart';

class SavedSitesScreen extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback onGoToDownloader;

  const SavedSitesScreen({
    super.key,
    required this.storageService,
    required this.onGoToDownloader,
  });

  @override
  State<SavedSitesScreen> createState() => SavedSitesScreenState();
}

class SavedSitesScreenState extends State<SavedSitesScreen> {
  List<SavedSite> _sites = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadSites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadSites() async {
    setState(() => _isLoading = true);
    final sites = await widget.storageService.getSavedSites();
    if (mounted) {
      setState(() {
        _sites = sites;
        _isLoading = false;
      });
    }
  }

  List<SavedSite> get _filteredSites {
    if (_searchQuery.trim().isEmpty) return _sites;
    final query = _searchQuery.toLowerCase();
    return _sites.where((s) {
      return s.hostname.toLowerCase().contains(query) ||
          s.originalUrl.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _deleteSite(SavedSite site) async {
    await widget.storageService.deleteSite(site.id);
    await loadSites();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${site.hostname}"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openSite(SavedSite site) {
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
            // Search & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Offline Vault',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Text(
                          '${_sites.length} ${_sites.length == 1 ? 'Site' : 'Sites'}',
                          style: GoogleFonts.firaCode(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search saved websites...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                      ),
                    )
                  : _filteredSites.isEmpty
                      ? RefreshIndicator(
                          onRefresh: loadSites,
                          color: const Color(0xFF38BDF8),
                          child: ListView(
                            padding: const EdgeInsets.all(32),
                            children: [
                              const SizedBox(height: 60),
                              Center(
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF334155)),
                                  ),
                                  child: const Icon(
                                    Icons.folder_off_outlined,
                                    size: 40,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No matching websites found'
                                    : 'No Offline Websites Yet',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Try checking for typos or searching by domain.'
                                    : 'Websites downloaded will appear here for instant offline browsing.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 24),
                                Center(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF38BDF8),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: widget.onGoToDownloader,
                                    icon: const Icon(Icons.download_rounded, size: 18),
                                    label: const Text(
                                      'Download a Website',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: loadSites,
                          color: const Color(0xFF38BDF8),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredSites.length,
                            itemBuilder: (context, index) {
                              final site = _filteredSites[index];
                              return SiteCard(
                                site: site,
                                onOpen: () => _openSite(site),
                                onDelete: () => _deleteSite(site),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
