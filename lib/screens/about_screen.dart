import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cybershield_wifi/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ABOUT SYSTEM'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // App Header Logo
          Center(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.cyberCyan.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.cyberCyan.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppTheme.cyberCyan,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'CyberShield WiFi',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Text(
                  'Version 1.0.0 (Stable Release)',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Project Objectives Card
          _buildSectionTitle('DEFENSIVE CYBERSECURITY TOOL'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CyberShield WiFi is an intelligent public wireless security analyzer designed to evaluate risk factors before users engage in network communication.',
                    style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Developed as an engineering project, the application runs entirely client-side using robust heuristic weights, fuzzy SSID naming similarity checks, and synthetic threat injection to demonstrate offensive/defensive scenarios in wireless security.',
                    style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textSecondary),
                  ),
                  const Divider(height: 24),
                  _buildObjectiveBullet(Icons.check_circle_outline, '100% Passive Sniffing Heuristics'),
                  _buildObjectiveBullet(Icons.check_circle_outline, 'No root permissions or illegal packet injection'),
                  _buildObjectiveBullet(Icons.check_circle_outline, 'Educational threat lab simulation'),
                  _buildObjectiveBullet(Icons.check_circle_outline, 'Instant PDF audit reports generator'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Technical Architecture info
          _buildSectionTitle('SYSTEM ARCHITECTURE'),
          Card(
            color: AppTheme.darkSurface,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTechSpec('Frontend', 'Flutter 3.x (Material 3 Dark Theme)'),
                  _buildTechSpec('Database', 'SQLite via Sqflite ORM'),
                  _buildTechSpec('Charts', 'Fl Chart Engine (Line Graphs)'),
                  _buildTechSpec('Report Exporter', 'PDF Vector Engine & Share API'),
                  _buildTechSpec('Similarity Engine', 'Levenshtein Distance Algorithm'),
                  _buildTechSpec('Threading', 'Continuous background checks via timer loops'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Security Disclaimer
          _buildSectionTitle('REGULATORY COMPLIANCE'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cyberAmber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cyberAmber.withOpacity(0.3), width: 1),
            ),
            child: const Text(
              'DISCLAIMER: This application is a defensive network security tool and does not conduct unauthorized attacks or packet cracking. Network scanning diagnostics represent mathematical approximations of risk and may not identify all custom hardware attacks.',
              style: TextStyle(fontSize: 10, height: 1.4, color: AppTheme.cyberAmber, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),
        ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: AppTheme.cyberCyan,
        ),
      ),
    );
  }

  Widget _buildObjectiveBullet(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.cyberCyan, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTechSpec(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
