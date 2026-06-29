import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cybershield_wifi/models/threat_alert.dart';
import 'package:cybershield_wifi/models/wifi_network.dart';
import 'package:cybershield_wifi/theme/app_theme.dart';

class ThreatDetailsScreen extends StatelessWidget {
  final ThreatAlert alert;
  final WifiNetwork activeNetwork;

  const ThreatDetailsScreen({
    Key? key,
    required this.alert,
    required this.activeNetwork,
  }) : super(key: key);

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'danger':
        return AppTheme.cyberRed;
      case 'caution':
        return AppTheme.cyberAmber;
      default:
        return AppTheme.cyberCyan;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'evil_twin':
        return Icons.copy_outlined;
      case 'fake_hotspot':
        return Icons.spellcheck;
      case 'arp_spoofing':
        return Icons.leak_add_rounded;
      case 'dns_manipulation':
        return Icons.dns_outlined;
      case 'captive_portal':
        return Icons.login_outlined;
      case 'rogue_dhcp':
        return Icons.router_outlined;
      default:
        return Icons.security;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(alert.severity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('THREAT PROFILE'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Alert Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: severityColor.withOpacity(0.4), width: 1.5),
            ),
            child: Column(
              children: [
                Icon(
                  _getIconForType(alert.type),
                  color: severityColor,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  alert.title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    alert.severity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: severityColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Explain Risks in Plain English
          Text(
            'What is happening?',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            alert.description,
            style: const TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 24),

          // Cyber Threat Analysis Explanation
          Text(
            'Under the hood',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildUnderTheHoodSection(alert.type),
          const SizedBox(height: 24),

          // Technical specifications
          Card(
            color: AppTheme.darkSurface,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Technical Details',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 20),
                  _buildTechnicalRow('Target SSID', alert.ssid),
                  _buildTechnicalRow('Reported BSSID', alert.bssid),
                  _buildTechnicalRow('Attack Vector', alert.type),
                  _buildTechnicalRow('Timestamp', alert.timestamp.toString().substring(0, 19)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Recommendation Checklist
          Text(
            'Defensive Checklist',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildActionItem('1', 'Disconnect from "${alert.ssid}" immediately.', true),
          _buildActionItem('2', 'Activate your VPN client (Mullvad, Proton VPN) to secure current packet tunnels.', true),
          _buildActionItem('3', 'Never type sensitive passwords or bank credentials on this connection.', true),
          _buildActionItem('4', 'Report this access point configuration details to the network administrator.', false),
          const SizedBox(height: 24),

          // Disconnect button
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Simulating connection shutdown... Safe actions deployed!'),
                  backgroundColor: AppTheme.cyberGreen,
                ),
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.link_off_rounded),
            label: const Text('DISCONNECT SAFELY'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: AppTheme.cyberRed, width: 1.2),
              foregroundColor: AppTheme.cyberRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildActionItem(String num, String text, bool critical) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: critical ? AppTheme.cyberRed.withOpacity(0.1) : AppTheme.cyberCyan.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              num,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: critical ? AppTheme.cyberRed : AppTheme.cyberCyan,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnderTheHoodSection(String type) {
    String techExplain = '';
    switch (type) {
      case 'evil_twin':
        techExplain = 'Evil Twin attacks occur when a rogue transmitter clones a legitimate Wi-Fi access point\'s name (SSID) and MAC address (BSSID). A victim\'s device automatically connects to the stronger rogue signal. The hacker then uses passive sniffing tools to capture plaintext passwords, DNS requests, and unencrypted web tokens.';
        break;
      case 'fake_hotspot':
        techExplain = 'Attackers create typosquatted hotspots (e.g. CoffeeShop_Wi-Fi_Guest) near high-traffic locations. They count on users choosing the misspelled or slightly different SSID name thinking it is the official free network. Once connected, all data packets flow through the attacker\'s router.';
        break;
      case 'arp_spoofing':
        techExplain = 'ARP spoofing (Address Resolution Protocol poison) allows local devices to map their MAC address to the router\'s gateway IP. Other computers on the local network will send their internet traffic straight to the hacker instead of the physical router. This enables packet manipulation and credential theft.';
        break;
      case 'dns_manipulation':
        techExplain = 'DNS hijacking redirects your requests for domain names (like google.com) to a custom IP address. A rogue DNS server serves spoofed IP mappings, sending your browser to a malicious replica website designed to steal your passwords or install malware.';
        break;
      case 'captive_portal':
        techExplain = 'Captive portals intercept standard HTTP port traffic and redirect to local registration portals. While standard practice in commercial zones, spoofed portals can mimic login credentials forms for Facebook, Google, or email addresses to harvest login passwords.';
        break;
      case 'rogue_dhcp':
        techExplain = 'A rogue DHCP server operates on the same local network segment as the official DHCP router. It answers clients faster with configured options pointing default routes and DNS addresses to an attacker-controlled gateway node.';
        break;
      default:
        techExplain = 'Unsecured connections transmit data in plaintext. Any network card placed in Promiscuous Mode can sniff nearby packets and extract session cookies, tokens, and insecure request headers.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B), width: 1),
      ),
      child: Text(
        techExplain,
        style: const TextStyle(fontSize: 11, height: 1.5, color: AppTheme.textSecondary),
      ),
    );
  }
}
