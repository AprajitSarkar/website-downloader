import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'download_screen.dart';
import 'saved_sites_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final StorageService _storageService = StorageService();
  final GlobalKey<SavedSitesScreenState> _vaultKey = GlobalKey<SavedSitesScreenState>();

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 1) {
      _vaultKey.currentState?.loadSites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DownloadScreen(
            storageService: _storageService,
            onGoToVault: () => _onTabSelected(1),
          ),
          SavedSitesScreen(
            key: _vaultKey,
            storageService: _storageService,
            onGoToDownloader: () => _onTabSelected(0),
          ),
          SettingsScreen(
            storageService: _storageService,
            onStorageCleared: () {
              _vaultKey.currentState?.loadSites();
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          border: Border(
            top: BorderSide(color: Color(0xFF334155), width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          backgroundColor: const Color(0xFF1E293B),
          indicatorColor: const Color(0xFF38BDF8).withAlpha(40),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.cloud_download_outlined, color: Color(0xFF94A3B8)),
              selectedIcon: Icon(Icons.cloud_download_rounded, color: Color(0xFF38BDF8)),
              label: 'Downloader',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_zip_outlined, color: Color(0xFF94A3B8)),
              selectedIcon: Icon(Icons.folder_zip_rounded, color: Color(0xFF38BDF8)),
              label: 'Offline Vault',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: Color(0xFF94A3B8)),
              selectedIcon: Icon(Icons.settings_rounded, color: Color(0xFF38BDF8)),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
