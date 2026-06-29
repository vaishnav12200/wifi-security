import 'package:flutter/material.dart';
import 'package:cybershield_wifi/theme/app_theme.dart';
import 'package:cybershield_wifi/screens/dashboard_screen.dart';
import 'package:cybershield_wifi/screens/scanner_screen.dart';
import 'package:cybershield_wifi/screens/history_screen.dart';
import 'package:cybershield_wifi/screens/settings_screen.dart';
import 'package:cybershield_wifi/screens/about_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CyberShieldApp());
}

class CyberShieldApp extends StatelessWidget {
  const CyberShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CyberShield WiFi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, color: AppTheme.cyberCyan, size: 22),
            const SizedBox(width: 8),
            Text(
              'CYBERSHIELD WiFi',
              style: TextStyle(
                fontFamily: 'Outfit',
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: AppTheme.cyberCyan.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(
            onNavigateToScanner: () => setState(() => _currentIndex = 1),
            onNavigateToHistory: () => setState(() => _currentIndex = 2),
          ),
          const ScannerScreen(),
          const HistoryScreen(),
          const SettingsScreen(),
          const AboutScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.darkSurface,
        selectedItemColor: AppTheme.cyberCyan,
        unselectedItemColor: AppTheme.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard, color: AppTheme.cyberCyan),
            label: 'DASHBOARD',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wifi_find_outlined),
            activeIcon: Icon(Icons.wifi_find, color: AppTheme.cyberCyan),
            label: 'SCANNER',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history, color: AppTheme.cyberCyan),
            label: 'HISTORY',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune_outlined),
            activeIcon: Icon(Icons.tune, color: AppTheme.cyberCyan),
            label: 'SETTINGS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            activeIcon: Icon(Icons.info, color: AppTheme.cyberCyan),
            label: 'ABOUT',
          ),
        ],
      ),
    );
  }
}
