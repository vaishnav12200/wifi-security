import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cybershield_wifi/database/db_helper.dart';
import 'package:cybershield_wifi/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoScan = true;
  double _aiSensitivity = 0.7; // default
  bool _soundAlerts = true;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PREFERENCES'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section: General Scanner
          _buildSectionHeader('SCANNER METRICS'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Auto Scan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Perform background threat monitoring every 5 seconds.', style: TextStyle(fontSize: 10)),
                  value: _autoScan,
                  onChanged: (val) {
                    setState(() => _autoScan = val);
                  },
                  activeThumbColor: AppTheme.cyberCyan,
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Scan Interval', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('5 Seconds', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cyberCyan)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: AI Risk Engine
          _buildSectionHeader('AI SAFETY ENGINE'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'AI Engine Sensitivity',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(_aiSensitivity * 100).toInt()}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cyberPurple),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _aiSensitivity,
                    onChanged: (val) {
                      setState(() => _aiSensitivity = val);
                    },
                    activeColor: AppTheme.cyberPurple,
                    inactiveColor: const Color(0xFF1E293B),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Higher sensitivity increases threat flags for low-grade encryption standards or slight SSID naming variations.',
                    style: TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section: Alerts & Audio
          _buildSectionHeader('NOTIFICATIONS & ALERTS'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Audible Alarms', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Trigger cyber alert chime on detecting critical threats.', style: TextStyle(fontSize: 10)),
                  value: _soundAlerts,
                  onChanged: (val) {
                    setState(() => _soundAlerts = val);
                  },
                  activeThumbColor: AppTheme.cyberCyan,
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Active Language', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Adjust threat explanation dictionary.', style: TextStyle(fontSize: 10)),
                  trailing: DropdownButton<String>(
                    dropdownColor: AppTheme.darkSurface,
                    underline: const SizedBox(),
                    value: _selectedLanguage,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedLanguage = val);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'English', child: Text('English', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Spanish', child: Text('Español', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Hindi', child: Text('हिन्दी', style: TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Database management
          _buildSectionHeader('SYSTEM INTEGRATION'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cleaning_services_rounded, color: AppTheme.cyberRed),
              title: const Text('Wipe Database Storage', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.cyberRed)),
              subtitle: const Text('Delete all network settings, scanned devices, and trusted logs.', style: TextStyle(fontSize: 10)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Wipe Database?'),
                    content: const Text('This action will permanently erase all settings, scanned networks, threat logs, and logs in the local sqflite storage. This cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: AppTheme.cyberRed),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('WIPE DATA'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await DbHelper.instance.clearAllHistory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All local database storage cleared.'), backgroundColor: AppTheme.cyberRed),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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
}
