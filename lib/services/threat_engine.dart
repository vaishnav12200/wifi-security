import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:cybershield_wifi/models/wifi_network.dart';
import 'package:cybershield_wifi/models/threat_alert.dart';

class ThreatEngine {
  static final List<String> _legitimateBrands = [
    'Starbucks WiFi',
    'McDonalds Free WiFi',
    'CoffeeShop_Guest',
    'Airport_Free_WiFi',
    'Transit_WiFi',
    'Hotel_Lobby_Guest',
    'University_Secure_WiFi',
  ];

  /// Calculates a Levenshtein distance between two strings to detect typosquatting
  int calculateLevenshtein(String s, String t) {
    s = s.toLowerCase();
    t = t.toLowerCase();
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = _min3(v1[j] + 1, v0[j + 1] + 1, v0[j] + cost);
      }
      v0 = List<int>.from(v1);
    }
    return v0[t.length];
  }

  int _min3(int a, int b, int c) {
    int m = a < b ? a : b;
    return m < c ? m : c;
  }

  /// Checks if a SSID is a suspicious imitation of a legitimate network name
  double getSSIDSimilarityScore(String ssid) {
    if (ssid.isEmpty) return 0.0;
    
    // Exact match is not a fake typo
    if (_legitimateBrands.contains(ssid)) return 0.0;

    double maxSimilarity = 0.0;

    for (var brand in _legitimateBrands) {
      int distance = calculateLevenshtein(ssid, brand);
      int maxLength = max(ssid.length, brand.length);
      
      if (maxLength == 0) continue;
      
      // Convert distance to similarity ratio (0.0 to 1.0)
      double similarity = 1.0 - (distance / maxLength);
      
      // If the strings are highly similar but not identical, flag it
      if (similarity > 0.65 && similarity < 1.0) {
        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
        }
      }
    }
    return maxSimilarity;
  }

  /// Main entry point to run threat analysis on the current network or scanned networks
  Map<String, dynamic> analyzeNetwork(WifiNetwork network, {
    bool simulatedArpSpoofing = false,
    bool simulatedDnsHijack = false,
    bool simulatedCaptivePortal = false,
    bool simulatedRogueDhcp = false,
    List<WifiNetwork> otherScannedNetworks = const [],
  }) {
    List<ThreatAlert> alerts = [];
    int baseScore = 100;
    final uuid = const Uuid();

    // 1. Encryption Analysis
    if (network.isOpen || network.securityType.toUpperCase() == 'OPEN') {
      baseScore -= 30;
      alerts.add(ThreatAlert(
        id: uuid.v4(),
        title: 'Unsecured Network (Open WiFi)',
        description: 'This network does not use encryption. Anyone nearby can intercept your internet traffic, passwords, and personal details.',
        severity: 'Danger',
        type: 'weak_encryption',
        timestamp: DateTime.now(),
        ssid: network.ssid,
        bssid: network.bssid,
      ));
    } else if (network.securityType.toUpperCase().contains('WEP')) {
      baseScore -= 25;
      alerts.add(ThreatAlert(
        id: uuid.v4(),
        title: 'Deprecated WEP Encryption',
        description: 'This network uses WEP encryption, which is obsolete and can be cracked in seconds using basic hacking tools.',
        severity: 'Danger',
        type: 'weak_encryption',
        timestamp: DateTime.now(),
        ssid: network.ssid,
        bssid: network.bssid,
      ));
    } else if (network.securityType.toUpperCase().contains('WPA') && !network.securityType.toUpperCase().contains('WPA2') && !network.securityType.toUpperCase().contains('WPA3')) {
      baseScore -= 10;
      alerts.add(ThreatAlert(
        id: uuid.v4(),
        title: 'Weak Cipher (WPA1)',
        description: 'The network is using the original WPA standard which contains known vulnerabilities. Upgrade to WPA2/WPA3 is recommended.',
        severity: 'Caution',
        type: 'weak_encryption',
        timestamp: DateTime.now(),
        ssid: network.ssid,
        bssid: network.bssid,
      ));
    }

    // 2. Fake Hotspot Detection (SSID typosquatting)
    double similarity = getSSIDSimilarityScore(network.ssid);
    if (similarity > 0.70) {
      baseScore -= 20;
      alerts.add(ThreatAlert(
        id: uuid.v4(),
        title: 'Suspicious Hotspot Name (Typosquatting)',
        description: 'This network name ("${network.ssid}") is extremely similar to known public hotspots. Attackers set up similar-sounding names to trick users into connecting (e.g., "Starbucks_WiFi_Free" instead of "Starbucks WiFi").',
        severity: 'Danger',
        type: 'fake_hotspot',
        timestamp: DateTime.now(),
        ssid: network.ssid,
        bssid: network.bssid,
      ));
    }

    // 3. Evil Twin Detection (Duplicate SSID, different BSSID)
    if (otherScannedNetworks.isNotEmpty) {
      final duplicates = otherScannedNetworks.where((n) => 
        n.ssid == network.ssid && n.bssid != network.bssid
      ).toList();

      if (duplicates.isNotEmpty) {
        // Find if they have different vendors or channels/encryption
        bool hasSuspiciousDifference = false;
        String reason = '';

        for (var duplicate in duplicates) {
          if (duplicate.securityType != network.securityType) {
            hasSuspiciousDifference = true;
            reason = 'different security configurations';
            break;
          }
          if (duplicate.vendor != 'Unknown' && network.vendor != 'Unknown' && duplicate.vendor != network.vendor) {
            hasSuspiciousDifference = true;
            reason = 'different router hardware vendors (${network.vendor} vs ${duplicate.vendor})';
            break;
          }
        }

        if (hasSuspiciousDifference) {
          baseScore -= 35;
          alerts.add(ThreatAlert(
            id: uuid.v4(),
            title: 'Potential Evil Twin Attack',
            description: 'We detected multiple transmitters broadcasting the network "${network.ssid}" using $reason. A hacker may be mimicking the legitimate network to intercept your connection.',
            severity: 'Critical',
            type: 'evil_twin',
            timestamp: DateTime.now(),
            ssid: network.ssid,
            bssid: network.bssid,
          ));
        } else if (duplicates.length > 2) {
          // Simply too many APs claiming the same network name in close range
          baseScore -= 10;
          alerts.add(ThreatAlert(
            id: uuid.v4(),
            title: 'Multiple APs with same SSID',
            description: 'There are ${duplicates.length + 1} access points broadcasting the name "${network.ssid}". While common in enterprise mesh networks, it is sometimes used to mask rogue access points.',
            severity: 'Caution',
            type: 'evil_twin',
            timestamp: DateTime.now(),
            ssid: network.ssid,
            bssid: network.bssid,
          ));
        }
      }
    }

    // 4. Simulated ARP Spoofing / MITM
    if (simulatedArpSpoofing) {
      baseScore -= 40;
      alerts.add(ThreatAlert(
        id: uuid.v4(),
        title: 'ARP Spoofing / MITM Attack',
        description: 'Man-in-the-Middle (MITM) activity detected. Another device on the network is claiming the identity of the router (Gateway MAC cloning), routing all your web traffic through their computer.',
        severity: 'Critical',
        type: 'arp_spoofing',
        timestamp: DateTime.now(),
        ssid: network.ssid,
        bssid: network.bssid,
      ));
    }

    // 5. Simulated DNS Manipulation
    if (simulatedDnsHijack) {
      baseScore -= 30;
      alerts.add(ThreatAlert(
        id: uuid.v4(),
        title: 'DNS Manipulation Detected',
        description: 'Your DNS queries are being modified or routed to an unverified private resolver. This allows attackers to redirect your requests for legitimate websites (e.g. google.com) to malicious phishing copies.',
        severity: 'Danger',
        type: 'dns_manipulation',
        timestamp: DateTime.now(),
        ssid: network.ssid,
        bssid: network.bssid,
      ));
    }

    // 6. Simulated Captive Portal
    if (simulatedCaptivePortal) {
      baseScore -= 5;
      alerts.add(ThreatAlert(
        id: uuid.v4(),
        title: 'Captive Portal Interception',
        description: 'This network redirects internet traffic to a login/advertisement page. While common in hotels/airports, be careful: credentials typed into captive portals are frequently unencrypted.',
        severity: 'Caution',
        type: 'captive_portal',
        timestamp: DateTime.now(),
        ssid: network.ssid,
        bssid: network.bssid,
      ));
    }

    // 7. Simulated Rogue DHCP Server
    if (simulatedRogueDhcp) {
      baseScore -= 25;
      alerts.add(ThreatAlert(
        id: uuid.v4(),
        title: 'Rogue DHCP Server Detected',
        description: 'An unauthorized DHCP server was found distributing network configurations. A rogue DHCP server can assign malicious DNS and Gateway settings to automatically route your data to a hacker.',
        severity: 'Danger',
        type: 'rogue_dhcp',
        timestamp: DateTime.now(),
        ssid: network.ssid,
        bssid: network.bssid,
      ));
    }

    // Bound safety score between 0 and 100
    int finalScore = max(0, min(100, baseScore));
    String category = 'Safe';

    if (finalScore >= 90) {
      category = 'Safe';
    } else if (finalScore >= 75) {
      category = 'Mostly Safe';
    } else if (finalScore >= 50) {
      category = 'Caution';
    } else if (finalScore >= 30) {
      category = 'Danger';
    } else {
      category = 'Critical';
    }

    // Recommendation logic
    bool recommendVpn = finalScore < 85; 
    String vpnExplanation = '';
    if (recommendVpn) {
      if (finalScore < 50) {
        vpnExplanation = 'Highly Recommended. The network has critical security alerts. Enabling a VPN (Mullvad, Proton VPN) is mandatory to encrypt your data before it leaves your device, preventing eavesdropping.';
      } else {
        vpnExplanation = 'Recommended. Public or open networks expose your metadata. A VPN wraps your web traffic in a secure tunnel, keeping your browsing activity private from other devices on this network.';
      }
    }

    return {
      'score': finalScore,
      'category': category,
      'alerts': alerts,
      'recommendVpn': recommendVpn,
      'vpnExplanation': vpnExplanation,
    };
  }
}
