import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cybershield_wifi/models/scan_history.dart';
import 'package:cybershield_wifi/models/wifi_network.dart';
import 'package:cybershield_wifi/database/db_helper.dart';
import 'package:cybershield_wifi/services/pdf_service.dart';
import 'package:cybershield_wifi/theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DbHelper _dbHelper = DbHelper.instance;
  final PdfService _pdfService = PdfService();

  List<ScanHistory> _historyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final list = await _dbHelper.getAllScanHistory();
    setState(() {
      _historyList = list;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs?'),
        content: const Text('This will permanently delete all local WiFi safety scans and threat logs from your database.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.cyberRed),
            onPressed: () async {
              await _dbHelper.clearAllHistory();
              Navigator.pop(context);
              _loadHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Database cleared.'), backgroundColor: AppTheme.darkCard),
              );
            },
            child: const Text('CLEAR ALL'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return AppTheme.cyberGreen;
      case 'mostly safe':
        return AppTheme.cyberCyan;
      case 'caution':
        return AppTheme.cyberAmber;
      default:
        return AppTheme.cyberRed;
    }
  }

  Future<void> _exportPdfReport(ScanHistory history) async {
    // 1. Fetch threat details from DB associated with this scanned BSSID
    final alerts = await _dbHelper.getThreatsForNetwork(history.bssid);
    
    // Create an instance of WifiNetwork representation for the PDF generator
    final mockNetwork = WifiNetwork(
      ssid: history.ssid,
      bssid: history.bssid,
      rssi: -60, // approximate/placeholder
      channel: 6,
      frequency: 2.4,
      securityType: history.encryption,
      encryption: 'AES',
      vendor: 'Unknown (Logged)',
      isConnected: false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyberCyan),
            ),
            SizedBox(width: 12),
            Text('Generating PDF security report...'),
          ],
        ),
        backgroundColor: AppTheme.darkCard,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final path = await _pdfService.generateSecurityReport(
        network: mockNetwork,
        safetyScore: history.safetyScore,
        riskCategory: history.status,
        alerts: alerts,
        recommendVpn: history.safetyScore < 85,
        vpnExplanation: history.safetyScore < 50 
            ? 'Mandatory: Critical threats detected.' 
            : 'Recommended: Free public WiFi exposes browsing footprint.',
        gateway: history.gateway,
        dns: history.dns,
        latency: 18,
        uploadSpeed: 42.0,
      );

      // Share/open PDF file
      await Share.shareXFiles([XFile(path)], text: 'CyberShield Security Audit: ${history.ssid}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PDF: $e'), backgroundColor: AppTheme.cyberRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SCAN ARCHIVE'),
        actions: [
          if (_historyList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyList.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _historyList.length,
                  itemBuilder: (context, index) {
                    final hist = _historyList[index];
                    final color = _getStatusColor(hist.status);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    hist.ssid,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${hist.safetyScore}%',
                                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'MAC Address: ${hist.bssid}',
                              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontFamily: 'monospace'),
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            
                            // Specs block
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSpecLabel('GATEWAY', hist.gateway),
                                _buildSpecLabel('DNS SERVER', hist.dns),
                                _buildSpecLabel('SECURITY', hist.encryption),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  hist.timestamp.toString().substring(0, 16),
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    backgroundColor: AppTheme.darkSurface,
                                    foregroundColor: AppTheme.cyberCyan,
                                    side: const BorderSide(color: Color(0xFF334155)),
                                  ),
                                  onPressed: () => _exportPdfReport(hist),
                                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                                  label: const Text('PDF REPORT', style: TextStyle(fontSize: 10)),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildSpecLabel(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 8, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, color: AppTheme.textSecondary.withOpacity(0.3), size: 64),
          const SizedBox(height: 16),
          const Text(
            'No history logs found.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Run connection audits or connect tests to save records.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
