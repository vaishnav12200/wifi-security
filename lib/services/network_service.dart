import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:math';
import 'package:cybershield_wifi/models/wifi_network.dart';

class NetworkService {
  /// Fetches the local IP address from system network interfaces
  Future<String> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          if (!address.isLoopback) {
            return address.address;
          }
        }
      }
      return '192.168.1.104'; // Default fallback
    } catch (_) {
      return '192.168.1.104';
    }
  }

  /// Estimates active DNS server IP
  Future<String> getDnsServer() async {
    // In real mobile environment, we'd query android.net.LinkProperties
    // For standalone Dart, we'll return common public or local resolvers
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      if (interfaces.isNotEmpty) {
        final ip = interfaces.first.addresses.first.address;
        final segments = ip.split('.');
        if (segments.length == 4) {
          return '${segments[0]}.${segments[1]}.${segments[2]}.1'; // Typically router gateway / DNS
        }
      }
      return '8.8.8.8'; // Public fallback
    } catch (_) {
      return '8.8.8.8';
    }
  }

  /// Estimates the gateway IP
  Future<String> getGatewayIp() async {
    try {
      final ip = await getLocalIpAddress();
      final segments = ip.split('.');
      if (segments.length == 4) {
        return '${segments[0]}.${segments[1]}.${segments[2]}.1';
      }
      return '192.168.1.1';
    } catch (_) {
      return '192.168.1.1';
    }
  }

  /// Pings a public server (e.g. google.com) via Socket connection to measure latency
  Future<Map<String, dynamic>> runPingTest() async {
    final stopwatch = Stopwatch()..start();
    try {
      // Connect to Google DNS port 53 (very fast/reliable)
      final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 3));
      stopwatch.stop();
      await socket.close();
      
      int latency = stopwatch.elapsedMilliseconds;
      double packetLoss = 0.0;
      String stability = 'Excellent';
      if (latency > 150) {
        stability = 'Poor';
      } else if (latency > 75) {
        stability = 'Average';
      }

      return {
        'latency': latency,
        'packetLoss': packetLoss,
        'stability': stability,
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'latency': 0,
        'packetLoss': 100.0,
        'stability': 'No Connection',
      };
    }
  }

  /// Downloads a tiny asset to estimate download speed in Mbps
  Future<double> runSpeedTest() async {
    final stopwatch = Stopwatch()..start();
    try {
      // Download a small 100KB file from public CDN
      final response = await http.get(
        Uri.parse('https://images.unsplash.com/photo-1541701494587-cb58502866ab?q=80&w=1000'),
      ).timeout(const Duration(seconds: 5));

      stopwatch.stop();
      if (response.statusCode == 200) {
        int bytes = response.bodyBytes.length;
        double durationInSeconds = stopwatch.elapsedMilliseconds / 1000.0;
        if (durationInSeconds == 0) return 10.0;
        
        // bytes / duration = bytes per second
        // (bytes_per_second * 8) / 1,000,000 = Mbps
        double mbps = (bytes * 8) / (durationInSeconds * 1000000.0);
        return double.parse(mbps.toStringAsFixed(2));
      }
      return 0.0;
    } catch (_) {
      stopwatch.stop();
      return 0.0;
    }
  }

  /// Generates a realistic mock scan of nearby WiFi networks
  List<WifiNetwork> generateMockNearbyNetworks() {
    final random = Random();
    return [
      // 1. Safe secure home network
      WifiNetwork(
        ssid: 'Home_WiFi_Secure',
        bssid: 'E4:95:6E:40:9A:12',
        rssi: -45,
        channel: 6,
        frequency: 2.4,
        securityType: 'WPA3',
        encryption: 'AES',
        vendor: 'TP-Link',
        isConnected: false,
      ),
      // 2. Legitimate brand public network
      WifiNetwork(
        ssid: 'Starbucks WiFi',
        bssid: '00:1C:F2:C1:B4:98',
        rssi: -62,
        channel: 11,
        frequency: 2.4,
        securityType: 'Open',
        encryption: 'None',
        vendor: 'Cisco Systems',
        isOpen: true,
        isConnected: false,
      ),
      // 3. Fake Hotspot (SSID similarity attack on Starbucks WiFi)
      WifiNetwork(
        ssid: 'Starbucks_WiFi_Free',
        bssid: 'A4:2B:B0:11:22:33',
        rssi: -58,
        channel: 1,
        frequency: 2.4,
        securityType: 'Open',
        encryption: 'None',
        vendor: 'Rogue AP',
        isOpen: true,
        isConnected: false,
      ),
      // 4. Evil Twin network (broadcasts same SSID as Starbucks WiFi, different BSSID & vendor)
      WifiNetwork(
        ssid: 'Starbucks WiFi',
        bssid: '90:3A:4C:D8:EF:12',
        rssi: -50,
        channel: 6,
        frequency: 2.4,
        securityType: 'WEP', // Suspicious different security type!
        encryption: 'TKIP',
        vendor: 'Netgear (Unverified)',
        isOpen: true,
        isConnected: false,
      ),
      // 5. Weak Encryption network
      WifiNetwork(
        ssid: 'Legacy_Office_Guest',
        bssid: 'C0:56:27:E3:FA:90',
        rssi: -78,
        channel: 36,
        frequency: 5.0,
        securityType: 'WEP',
        encryption: 'WEP',
        vendor: 'D-Link',
        isOpen: false,
        isConnected: false,
      ),
      // 6. Generic safe neighborhood networks
      WifiNetwork(
        ssid: 'Netgear-5G',
        bssid: '2C:30:33:4B:9A:8C',
        rssi: -82,
        channel: 149,
        frequency: 5.0,
        securityType: 'WPA2',
        encryption: 'AES',
        vendor: 'Netgear',
        isConnected: false,
      ),
      WifiNetwork(
        ssid: 'Linksys_Wireless',
        bssid: '00:25:9C:1A:BC:DF',
        rssi: -88,
        channel: 11,
        frequency: 2.4,
        securityType: 'WPA2',
        encryption: 'AES',
        vendor: 'Linksys',
        isConnected: false,
      ),
      // 7. Hidden network
      WifiNetwork(
        ssid: '<Hidden Network>',
        bssid: 'AA:BB:CC:DD:EE:FF',
        rssi: -72,
        channel: 6,
        frequency: 2.4,
        securityType: 'WPA2',
        encryption: 'AES',
        vendor: 'Unknown',
        isHidden: true,
        isConnected: false,
      ),
    ];
  }
}
