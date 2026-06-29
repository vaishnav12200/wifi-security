import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cybershield_wifi/models/wifi_network.dart';
import 'package:cybershield_wifi/models/threat_alert.dart';
import 'package:cybershield_wifi/models/scan_history.dart';
import 'package:cybershield_wifi/services/network_service.dart';
import 'package:cybershield_wifi/services/threat_engine.dart';
import 'package:cybershield_wifi/database/db_helper.dart';
import 'package:cybershield_wifi/widgets/safety_meter.dart';
import 'package:cybershield_wifi/theme/app_theme.dart';
import 'package:cybershield_wifi/screens/threat_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToScanner;
  final VoidCallback onNavigateToHistory;

  const DashboardScreen({
    super.key,
    required this.onNavigateToScanner,
    required this.onNavigateToHistory,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final NetworkService _networkService = NetworkService();
  final ThreatEngine _threatEngine = ThreatEngine();
  
  bool _isAuditing = false;
  bool _continuousMonitoring = false;
  Timer? _monitoringTimer;

  // Active Network State
  late WifiNetwork _activeNetwork;
  int _safetyScore = 95;
  String _riskCategory = 'Mostly Safe';
  List<ThreatAlert> _alerts = [];
  bool _recommendVpn = false;
  String _vpnExplanation = '';
  
  // Diagnostic metrics
  String _localIp = '0.0.0.0';
  String _gatewayIp = '0.0.0.0';
  String _dnsServer = '8.8.8.8';
  int _latency = 22;
  double _internetSpeed = 48.2;
  
  // Real-time chart data points
  final List<FlSpot> _latencyPoints = [];
  int _chartTimeCounter = 0;

  @override
  void initState() {
    super.initState();
    _activeNetwork = WifiNetwork(
      ssid: 'Office_WiFi_Secure',
      bssid: '00:A0:C9:14:C8:29',
      rssi: -55,
      channel: 6,
      frequency: 2.4,
      securityType: 'WPA2',
      encryption: 'AES',
      vendor: 'Intel Corp',
      isOpen: false,
      isConnected: true,
    );
    
    // Seed initial chart data
    for (int i = 0; i < 7; i++) {
      _latencyPoints.add(FlSpot(i.toDouble(), 15.0 + (i % 3) * 5 + (i == 4 ? 12 : 0)));
      _chartTimeCounter = i;
    }

    _loadActiveConnectionDetails();
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveConnectionDetails() async {
    final ip = await _networkService.getLocalIpAddress();
    final gateway = await _networkService.getGatewayIp();
    final dns = await _networkService.getDnsServer();
    
    setState(() {
      _localIp = ip;
      _gatewayIp = gateway;
      _dnsServer = dns;
    });

    _runSecurityAudit(silent: true);
  }

  /// Runs full diagnostic scanner and writes logs to database
  Future<void> _runSecurityAudit({bool silent = false}) async {
    if (_isAuditing) return;

    if (!silent) {
      setState(() {
        _isAuditing = true;
      });
      // Visual feedback delay
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    final pingResult = await _networkService.runPingTest();
    double speedResult = 0.0;
    if (!silent) {
      speedResult = await _networkService.runSpeedTest();
    } else {
      speedResult = 35.0 + (10.0 * (0.5 - (0.5))); // Simulated standard speed
    }

    // Run AI/Heuristic Threat analysis
    final analysis = _threatEngine.analyzeNetwork(_activeNetwork);

    setState(() {
      _latency = pingResult['latency'] ?? 0;
      _internetSpeed = speedResult > 0 ? speedResult : _internetSpeed;
      _safetyScore = analysis['score'];
      _riskCategory = analysis['category'];
      _alerts = analysis['alerts'];
      _recommendVpn = analysis['recommendVpn'];
      _vpnExplanation = analysis['vpnExplanation'];
      _isAuditing = false;

      // Update Chart
      _chartTimeCounter++;
      if (_latencyPoints.length >= 10) {
        _latencyPoints.removeAt(0);
      }
      _latencyPoints.add(FlSpot(_chartTimeCounter.toDouble(), _latency.toDouble()));
    });

    // Save to Database
    final db = DbHelper.instance;
    final scanId = const Uuid().v4();
    
    final history = ScanHistory(
      id: scanId,
      ssid: _activeNetwork.ssid,
      bssid: _activeNetwork.bssid,
      safetyScore: _safetyScore,
      timestamp: DateTime.now(),
      threatsCount: _alerts.length,
      status: _riskCategory,
      encryption: _activeNetwork.securityType,
      gateway: _gatewayIp,
      dns: _dnsServer,
    );
    
    await db.insertScanHistory(history);
    for (var alert in _alerts) {
      await db.insertThreatAlert(alert);
    }

    if (!silent && _alerts.isNotEmpty && mounted) {
      _showThreatBanner(_alerts.first);
    }
  }

  void _showThreatBanner(ThreatAlert alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.cyberRed,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.gpp_maybe, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                cross: const CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${alert.title} DETECTED',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    alert.description,
                    style: const TextStyle(fontSize: 12, color: Colors.whiteEE),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'DETAILS',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ThreatDetailsScreen(alert: alert, activeNetwork: _activeNetwork),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Toggles continuous monitoring checks every 5 seconds
  void _toggleContinuousMonitoring(bool value) {
    setState(() {
      _continuousMonitoring = value;
    });

    if (_continuousMonitoring) {
      _monitoringTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        // Run light audits and simulate monitoring changes
        _runLightMonitoringCheck();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Continuous network security monitoring activated.'),
          backgroundColor: AppTheme.cyberGreen,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      _monitoringTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Monitoring deactivated.'),
          backgroundColor: AppTheme.darkCard,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _runLightMonitoringCheck() {
    // 1. Simulate minor connection fluctuations (chart updates)
    setState(() {
      _chartTimeCounter++;
      if (_latencyPoints.length >= 10) {
        _latencyPoints.removeAt(0);
      }
      
      // Random fluctuation
      final random = DateTime.now().millisecond;
      int baseVal = 18;
      if (random % 7 == 0) {
        baseVal = 85; // Simulated latency spike
      }
      _latency = baseVal + (random % 10);
      _latencyPoints.add(FlSpot(_chartTimeCounter.toDouble(), _latency.toDouble()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        cross: CrossAxisAlignment.stretch,
        children: [
          // Header Status Card
          _buildConnectedCard(),
          const SizedBox(height: 20),

          // Glowing Safety Score Gauge
          Center(
            child: SafetyMeter(
              score: _safetyScore,
              status: _riskCategory,
              onTap: () {
                if (_alerts.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ThreatDetailsScreen(
                        alert: _alerts.first,
                        activeNetwork: _activeNetwork,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          // Diagnostic quick specs grid
          _buildDiagnosticsGrid(),
          const SizedBox(height: 20),

          // Interactive monitoring chart
          _buildLiveChartSection(),
          const SizedBox(height: 20),

          // Network Parameters Card
          _buildParametersCard(),
          const SizedBox(height: 20),

          // Threat Alerts Overview
          if (_alerts.isNotEmpty) _buildAlertsLogSection(),
          if (_alerts.isNotEmpty) const SizedBox(height: 20),

          // VPN Recommendation Card
          if (_recommendVpn) _buildVpnRecommendationCard(),
        ],
      ),
    );
  }

  Widget _buildConnectedCard() {
    return Card(
      color: AppTheme.darkSurface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.cyberCyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi, color: AppTheme.cyberCyan, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activeNetwork.ssid,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Active connection secured via ${_activeNetwork.securityType}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            _isAuditing
                ? const SpinKitThreeBounce(color: AppTheme.cyberCyan, size: 18)
                : TextButton.icon(
                    onPressed: () => _runSecurityAudit(),
                    icon: const Icon(Icons.sync_problem, size: 16),
                    label: const Text('AUDIT', style: TextStyle(fontSize: 12)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Latency',
            value: '$_latency ms',
            subtitle: _latency == 0 ? 'Timeout' : (_latency < 50 ? 'Excellent' : 'Average'),
            icon: Icons.speed,
            color: _latency < 50 ? AppTheme.cyberGreen : AppTheme.cyberAmber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            title: 'Bandwidth',
            value: '${_internetSpeed.toStringAsFixed(1)} Mbps',
            subtitle: 'Download Speed',
            icon: Icons.download_for_offline_outlined,
            color: AppTheme.cyberCyan,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChartSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Security stability', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(
                    'Continuous monitoring data streams',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('MONITOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: _continuousMonitoring,
                      onChanged: _toggleContinuousMonitoring,
                      activeThumbColor: AppTheme.cyberCyan,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (val) {
                  return const FlLine(color: Color(0xFF1E293B), strokeWidth: 1);
                }),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: _latencyPoints.isNotEmpty ? _latencyPoints.first.x : 0,
                maxX: _latencyPoints.isNotEmpty ? _latencyPoints.last.x : 10,
                minY: 0,
                maxY: 120,
                lineBarsData: [
                  LineChartBarData(
                    spots: _latencyPoints,
                    isCurved: true,
                    color: AppTheme.cyberCyan,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.cyberCyan.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParametersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gateway Details',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildParameterRow('Local IPv4 IP', _localIp),
            _buildParameterRow('Router Gateway IP', _gatewayIp),
            _buildParameterRow('Primary DNS server', _dnsServer),
            _buildParameterRow('Hardware Vendor', _activeNetwork.vendor),
            _buildParameterRow('WiFi Frequency', '${_activeNetwork.frequency} GHz'),
            _buildParameterRow('Operating Channel', '${_activeNetwork.channel}'),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAlertsLogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security Alerts',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _alerts.length,
          itemBuilder: (context, index) {
            final alert = _alerts[index];
            final Color alertColor = alert.severity == 'Critical' || alert.severity == 'Danger' 
                ? AppTheme.cyberRed 
                : AppTheme.cyberAmber;
            
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: alertColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: alertColor.withOpacity(0.3), width: 1),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.warning_amber_rounded, color: alertColor),
                title: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(
                  alert.description,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ThreatDetailsScreen(
                        alert: alert,
                        activeNetwork: _activeNetwork,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVpnRecommendationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.cyberPurple.withOpacity(0.15),
            AppTheme.cyberCyan.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cyberPurple.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: AppTheme.cyberPurple, size: 24),
              const SizedBox(width: 8),
              Text(
                'VPN Protection Recommended',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.cyberPurple,
                  fontSize: 14,
                  shadows: [
                    Shadow(color: AppTheme.cyberPurple.withOpacity(0.5), blurRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _vpnExplanation,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildVpnLogo('Proton VPN'),
              const SizedBox(width: 8),
              _buildVpnLogo('Mullvad VPN'),
              const SizedBox(width: 8),
              _buildVpnLogo('Cloudflare WARP'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVpnLogo(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Text(
        name,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
      ),
    );
  }
}
