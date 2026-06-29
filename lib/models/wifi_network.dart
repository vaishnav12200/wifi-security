class WifiNetwork {
  final String ssid;
  final String bssid;
  final int rssi; // Signal Strength in dBm
  final int channel;
  final double frequency; // in GHz, e.g., 2.4 or 5.0
  final String securityType; // e.g., WPA3, WPA2, WEP, Open
  final String encryption; // e.g., AES, TKIP, None
  final String vendor;
  final bool isHidden;
  final bool isOpen;
  final bool isConnected;

  WifiNetwork({
    required this.ssid,
    required this.bssid,
    required this.rssi,
    required this.channel,
    required this.frequency,
    required this.securityType,
    required this.encryption,
    required this.vendor,
    this.isHidden = false,
    this.isOpen = false,
    this.isConnected = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'ssid': ssid,
      'bssid': bssid,
      'rssi': rssi,
      'channel': channel,
      'frequency': frequency,
      'securityType': securityType,
      'encryption': encryption,
      'vendor': vendor,
      'isHidden': isHidden ? 1 : 0,
      'isOpen': isOpen ? 1 : 0,
      'isConnected': isConnected ? 1 : 0,
    };
  }

  factory WifiNetwork.fromMap(Map<String, dynamic> map) {
    return WifiNetwork(
      ssid: map['ssid'] ?? '',
      bssid: map['bssid'] ?? '',
      rssi: map['rssi'] ?? 0,
      channel: map['channel'] ?? 0,
      frequency: map['frequency'] ?? 2.4,
      securityType: map['securityType'] ?? 'Open',
      encryption: map['encryption'] ?? 'None',
      vendor: map['vendor'] ?? 'Unknown',
      isHidden: (map['isHidden'] ?? 0) == 1,
      isOpen: (map['isOpen'] ?? 0) == 1,
      isConnected: (map['isConnected'] ?? 0) == 1,
    );
  }
}
