class ScanHistory {
  final String id;
  final String ssid;
  final String bssid;
  final int safetyScore;
  final DateTime timestamp;
  final int threatsCount;
  final String status; // Safe, Mostly Safe, Caution, Danger, Critical
  final String encryption;
  final String gateway;
  final String dns;

  ScanHistory({
    required this.id,
    required this.ssid,
    required this.bssid,
    required this.safetyScore,
    required this.timestamp,
    required this.threatsCount,
    required this.status,
    required this.encryption,
    required this.gateway,
    required this.dns,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ssid': ssid,
      'bssid': bssid,
      'safetyScore': safetyScore,
      'timestamp': timestamp.toIso8601String(),
      'threatsCount': threatsCount,
      'status': status,
      'encryption': encryption,
      'gateway': gateway,
      'dns': dns,
    };
  }

  factory ScanHistory.fromMap(Map<String, dynamic> map) {
    return ScanHistory(
      id: map['id'] ?? '',
      ssid: map['ssid'] ?? '',
      bssid: map['bssid'] ?? '',
      safetyScore: map['safetyScore'] ?? 100,
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      threatsCount: map['threatsCount'] ?? 0,
      status: map['status'] ?? 'Safe',
      encryption: map['encryption'] ?? 'Unknown',
      gateway: map['gateway'] ?? '0.0.0.0',
      dns: map['dns'] ?? '0.0.0.0',
    );
  }
}
