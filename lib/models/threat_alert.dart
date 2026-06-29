class ThreatAlert {
  final String id;
  final String title;
  final String description;
  final String severity; // Info, Caution, Danger, Critical
  final String type; // e.g. evil_twin, fake_hotspot, weak_encryption, etc.
  final DateTime timestamp;
  final String ssid;
  final String bssid;

  ThreatAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.type,
    required this.timestamp,
    required this.ssid,
    required this.bssid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'ssid': ssid,
      'bssid': bssid,
    };
  }

  factory ThreatAlert.fromMap(Map<String, dynamic> map) {
    return ThreatAlert(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      severity: map['severity'] ?? 'Info',
      type: map['type'] ?? 'unknown',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      ssid: map['ssid'] ?? '',
      bssid: map['bssid'] ?? '',
    );
  }
}
