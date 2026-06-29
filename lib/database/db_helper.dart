import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cybershield_wifi/models/scan_history.dart';
import 'package:cybershield_wifi/models/threat_alert.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cybershield.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Scan History Table
    await db.execute('''
      CREATE TABLE scan_history (
        id TEXT PRIMARY KEY,
        ssid TEXT NOT NULL,
        bssid TEXT NOT NULL,
        safetyScore INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        threatsCount INTEGER NOT NULL,
        status TEXT NOT NULL,
        encryption TEXT NOT NULL,
        gateway TEXT NOT NULL,
        dns TEXT NOT NULL
      )
    ''');

    // Threat Alerts Table
    await db.execute('''
      CREATE TABLE threat_alerts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        severity TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        ssid TEXT NOT NULL,
        bssid TEXT NOT NULL
      )
    ''');

    // Favorite/Trusted Networks Table
    await db.execute('''
      CREATE TABLE trusted_networks (
        bssid TEXT PRIMARY KEY,
        ssid TEXT NOT NULL,
        addedAt TEXT NOT NULL
      )
    ''');
  }

  // --- Scan History Operations ---

  Future<int> insertScanHistory(ScanHistory history) async {
    final db = await instance.database;
    return await db.insert(
      'scan_history',
      history.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScanHistory>> getAllScanHistory() async {
    final db = await instance.database;
    final maps = await db.query('scan_history', orderBy: 'timestamp DESC');

    return List.generate(maps.length, (i) => ScanHistory.fromMap(maps[i]));
  }

  Future<int> deleteScanHistory(String id) async {
    final db = await instance.database;
    return await db.delete('scan_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAllHistory() async {
    final db = await instance.database;
    await db.delete('threat_alerts');
    return await db.delete('scan_history');
  }

  // --- Threat Alerts Operations ---

  Future<int> insertThreatAlert(ThreatAlert alert) async {
    final db = await instance.database;
    return await db.insert(
      'threat_alerts',
      alert.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ThreatAlert>> getAllThreatAlerts() async {
    final db = await instance.database;
    final maps = await db.query('threat_alerts', orderBy: 'timestamp DESC');

    return List.generate(maps.length, (i) => ThreatAlert.fromMap(maps[i]));
  }

  Future<List<ThreatAlert>> getThreatsForNetwork(String bssid) async {
    final db = await instance.database;
    final maps = await db.query(
      'threat_alerts',
      where: 'bssid = ?',
      whereArgs: [bssid],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => ThreatAlert.fromMap(maps[i]));
  }

  // --- Trusted Networks Operations ---

  Future<int> addTrustedNetwork(String bssid, String ssid) async {
    final db = await instance.database;
    return await db.insert(
      'trusted_networks',
      {
        'bssid': bssid,
        'ssid': ssid,
        'addedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> removeTrustedNetwork(String bssid) async {
    final db = await instance.database;
    return await db.delete(
      'trusted_networks',
      where: 'bssid = ?',
      whereArgs: [bssid],
    );
  }

  Future<bool> isNetworkTrusted(String bssid) async {
    final db = await instance.database;
    final maps = await db.query(
      'trusted_networks',
      where: 'bssid = ?',
      whereArgs: [bssid],
    );
    return maps.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getTrustedNetworks() async {
    final db = await instance.database;
    return await db.query('trusted_networks', orderBy: 'addedAt DESC');
  }

  Future close() async {
    final db = instance._database;
    if (db != null) {
      await db.close();
    }
  }
}
