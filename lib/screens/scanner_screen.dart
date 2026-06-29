import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cybershield_wifi/models/wifi_network.dart';
import 'package:cybershield_wifi/models/threat_alert.dart';
import 'package:cybershield_wifi/services/network_service.dart';
import 'package:cybershield_wifi/services/threat_engine.dart';
import 'package:cybershield_wifi/database/db_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:cybershield_wifi/models/scan_history.dart';
import 'package:cybershield_wifi/theme/app_theme.dart';
import 'package:cybershield_wifi/screens/threat_details_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  final NetworkService _networkService = NetworkService();
  final ThreatEngine _threatEngine = ThreatEngine();
  final DbHelper _dbHelper = DbHelper.instance;

  bool _isScanning = false;
  List<WifiNetwork> _networks = [];
  Map<String, bool> _trustedMap = {};

  // Attack Simulators State
  bool _simulatedArp = false;
  bool _simulatedDns = false;
  bool _simulatedRogueDhcp = false;

  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _loadTrustedNetworks();
    _startScan();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _loadTrustedNetworks() async {
    final list = await _dbHelper.getTrustedNetworks();
    final Map<String, bool> newMap = {};
    for (var net in list) {
      if (net['bssid'] != null) {
        newMap[net['bssid']] = true;
      }
    }
    setState(() {
      _trustedMap = newMap;
    });
  }

  Future<void> _startScan() async {
    if (_isScanning) return;
    
    setState(() {
      _isScanning = true;
    });
    _radarController.repeat();

    // Visual scanning effect
    await Future.delayed(const Duration(seconds: 2));

    final rawList = _networkService.generateMockNearbyNetworks();
    
    // Inject active simulated modifications if any
    List<WifiNetwork> updatedList = List.from(rawList);
    
    if (_simulatedArp) {
      // Simulate ARP vulnerability warning on the first home net
      final idx = updatedList.indexWhere((n) => n.ssid.contains('Home'));
      if (idx != -1) {
        updatedList[idx] = WifiNetwork(
          ssid: updatedList[idx].ssid,
          bssid: updatedList[idx].bssid,
          rssi: updatedList[idx].rssi,
          channel: updatedList[idx].channel,
          frequency: updatedList[idx].frequency,
          securityType: updatedList[idx].securityType,
          encryption: updatedList[idx].encryption,
          vendor: '${updatedList[idx].vendor} (ARP Poisoned)',
          isConnected: updatedList[idx].isConnected,
        );
      }
    }

    if (mounted) {
      setState(() {
        _networks = updatedList;
        _isScanning = false;
      });
      _radarController.stop();
    }
  }

  void _toggleTrust(WifiNetwork network) async {
    final isTrusted = _trustedMap[network.bssid] ?? false;
    if (isTrusted) {
      await _dbHelper.removeTrustedNetwork(network.bssid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed ${network.ssid} from trusted list.'), backgroundColor: AppTheme.darkCard),
      );
    } else {
      await _dbHelper.addTrustedNetwork(network.bssid, network.ssid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked ${network.ssid} as trusted network.'), backgroundColor: AppTheme.cyberGreen),
      );
    }
    _loadTrustedNetworks();
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppTheme.cyberGreen;
    if (score >= 75) return AppTheme.cyberCyan;
    if (score >= 50) return AppTheme.cyberAmber;
    return AppTheme.cyberRed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEARBY SIGNALS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startScan,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Radar Sweep Area
          if (_isScanning) _buildRadarArea() else _buildSimulationHeader(),

          // List of networks
          Expanded(
            child: _networks.isEmpty
                ? const Center(child: Text('No nearby WiFi signals detected.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _networks.length,
                    itemBuilder: (context, index) {
                      final net = _networks[index];
                      final isTrusted = _trustedMap[net.bssid] ?? false;

                      // Run diagnostics rules for this network
                      // Inject simulated parameters
                      final analysis = _threatEngine.analyzeNetwork(
                        net,
                        simulatedArpSpoofing: _simulatedArp && net.ssid.contains('Home'),
                        simulatedDnsHijack: _simulatedDns && net.ssid.contains('Starbucks'),
                        simulatedRogueDhcp: _simulatedRogueDhcp && net.ssid.contains('Legacy'),
                        otherScannedNetworks: _networks,
                      );

                      int finalScore = isTrusted ? 100 : analysis['score'];
                      String category = isTrusted ? 'Trusted' : analysis['category'];
                      List<ThreatAlert> networkAlerts = isTrusted ? [] : List<ThreatAlert>.from(analysis['alerts']);
                      
                      return _buildWifiNetworkTile(net, finalScore, category, networkAlerts, isTrusted);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarArea() {
    return Container(
      height: 120,
      color: AppTheme.darkSurface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SpinKitDoubleBounce(
              color: AppTheme.cyberCyan,
              size: 50.0,
            ),
            const SizedBox(height: 12),
            Text(
              'Scanning 2.4 / 5.0 GHz wireless bands...',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.cyberCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.darkSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DEFENSIVE CYBER LAB (SIMULATIONS)',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (_simulatedArp || _simulatedDns || _simulatedRogueDhcp)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _simulatedArp = false;
                      _simulatedDns = false;
                      _simulatedRogueDhcp = false;
                    });
                    _startScan();
                  },
                  child: const Text(
                    'RESET LAB',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.cyberRed,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSimChip(
                  label: 'MITM (ARP)',
                  isActive: _simulatedArp,
                  onSelected: (val) {
                    setState(() => _simulatedArp = val);
                    _startScan();
                  },
                ),
                const SizedBox(width: 8),
                _buildSimChip(
                  label: 'DNS Spoof',
                  isActive: _simulatedDns,
                  onSelected: (val) {
                    setState(() => _simulatedDns = val);
                    _startScan();
                  },
                ),
                const SizedBox(width: 8),
                _buildSimChip(
                  label: 'Rogue DHCP',
                  isActive: _simulatedRogueDhcp,
                  onSelected: (val) {
                    setState(() => _simulatedRogueDhcp = val);
                    _startScan();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimChip({
    required String label,
    required bool isActive,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      selected: isActive,
      onSelected: onSelected,
      selectedColor: AppTheme.cyberPurple.withOpacity(0.2),
      checkmarkColor: AppTheme.cyberPurple,
      backgroundColor: AppTheme.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isActive ? AppTheme.cyberPurple : const Color(0xFF334155),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildWifiNetworkTile(
    WifiNetwork network,
    int score,
    String category,
    List<ThreatAlert> alerts,
    bool isTrusted,
  ) {
    final scoreColor = isTrusted ? AppTheme.cyberGreen : _getScoreColor(score);
    final signalIcon = network.rssi > -60 
        ? Icons.signal_wifi_4_bar_rounded 
        : (network.rssi > -80 ? Icons.signal_wifi_bad : Icons.signal_wifi_0_bar);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        leading: Icon(signalIcon, color: scoreColor),
        title: Row(
          children: [
            Expanded(
              child: Text(
                network.ssid,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isTrusted)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.cyberGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TRUSTED',
                  style: TextStyle(color: AppTheme.cyberGreen, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${network.vendor} • Ch ${network.channel} (${network.frequency}GHz)',
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: scoreColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isTrusted ? '100%' : '$score%',
            style: TextStyle(
              color: scoreColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoLine('BSSID', network.bssid),
                _buildInfoLine('Security standard', network.securityType),
                _buildInfoLine('Signal strength', '${network.rssi} dBm'),
                _buildInfoLine('Confidence rating', isTrusted ? 'Verified Trusted' : '$score/100'),
                const SizedBox(height: 12),
                
                // Threat Warnings
                if (alerts.isNotEmpty) ...[
                  const Text(
                    'SECURITY THREATS FOUND:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.cyberRed),
                  ),
                  const SizedBox(height: 6),
                  ...alerts.map((alert) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.cyberRed.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cyberRed.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppTheme.cyberRed, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                alert.title,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(40, 20),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ThreatDetailsScreen(
                                      alert: alert,
                                      activeNetwork: network,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('READ', style: TextStyle(fontSize: 10, color: AppTheme.cyberRed)),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                ],

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _toggleTrust(network),
                      icon: Icon(isTrusted ? Icons.verified : Icons.verified_user_outlined, size: 14),
                      label: Text(isTrusted ? 'UNTRUST' : 'TRUST NET', style: const TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: () async {
                        // Simulating connecting and running diagnostics logs to DB
                        setState(() {
                          _isScanning = true;
                        });
                        await Future.delayed(const Duration(seconds: 1));
                        
                        final scanId = const Uuid().v4();
                        final history = ScanHistory(
                          id: scanId,
                          ssid: network.ssid,
                          bssid: network.bssid,
                          safetyScore: score,
                          timestamp: DateTime.now(),
                          threatsCount: alerts.length,
                          status: category,
                          encryption: network.securityType,
                          gateway: '192.168.1.1',
                          dns: '8.8.8.8',
                        );
                        
                        await _dbHelper.insertScanHistory(history);
                        for (var alert in alerts) {
                          await _dbHelper.insertThreatAlert(alert);
                        }

                        if (mounted) {
                          setState(() {
                            _isScanning = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Successfully connection-tested "${network.ssid}" and logged report.'),
                              backgroundColor: score >= 75 ? AppTheme.cyberGreen : AppTheme.cyberRed,
                            ),
                          );
                        }
                      },
                      child: const Text('CONNECT TEST', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
