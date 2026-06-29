import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cybershield_wifi/models/wifi_network.dart';
import 'package:cybershield_wifi/models/threat_alert.dart';

class PdfService {
  /// Generates a PDF network security report and returns the file path
  Future<String> generateSecurityReport({
    required WifiNetwork network,
    required int safetyScore,
    required String riskCategory,
    required List<ThreatAlert> alerts,
    required bool recommendVpn,
    required String vpnExplanation,
    required String gateway,
    required String dns,
    required int latency,
    required double uploadSpeed,
  }) async {
    final pdf = pw.Document();

    // Define colors
    final primaryColor = PdfColor.fromHex('#0F172A'); // Slate 900
    final accentColor = PdfColor.fromHex('#3B82F6');  // Blue 500
    final successColor = PdfColor.fromHex('#10B981'); // Emerald 500
    final warningColor = PdfColor.fromHex('#F59E0B'); // Amber 500
    final dangerColor = PdfColor.fromHex('#EF4444');  // Red 500
    
    // Choose status color
    PdfColor statusColor = successColor;
    if (riskCategory == 'Danger' || riskCategory == 'Critical') {
      statusColor = dangerColor;
    } else if (riskCategory == 'Caution') {
      statusColor = warningColor;
    } else if (riskCategory == 'Mostly Safe') {
      statusColor = accentColor;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CyberShield WiFi',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      pw.Text(
                        'Network Security Audit Report',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    DateTime.now().toString().substring(0, 16),
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 16),

              // Summary Box (Score)
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                padding: const pw.EdgeInsets.all(16),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SSID: ${network.ssid}',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'BSSID: ${network.bssid}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey400,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Hardware Vendor: ${network.vendor}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey400,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          '$safetyScore%',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        pw.Text(
                          'Category: $riskCategory',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Network Properties
              pw.Text(
                'Network Diagnostics',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  _buildTableRow('Security Standard', network.securityType),
                  _buildTableRow('Encryption Cipher', network.encryption),
                  _buildTableRow('Operating Channel', '${network.channel} (${network.frequency} GHz)'),
                  _buildTableRow('Signal Strength (RSSI)', '${network.rssi} dBm'),
                  _buildTableRow('Gateway IP Address', gateway),
                  _buildTableRow('DNS Server Resolver', dns),
                  _buildTableRow('Connection Latency', '$latency ms'),
                  _buildTableRow('Estimated Speed', '$uploadSpeed Mbps'),
                ],
              ),

              pw.SizedBox(height: 20),

              // Security Threat Log
              pw.Text(
                'Vulnerability Log (${alerts.length} Detected)',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),

              alerts.isEmpty
                  ? pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.green50,
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Text(
                        'Perfect Score. No vulnerabilities, anomalous packets, or configuration issues were detected on this network.',
                        style: const pw.TextStyle(color: PdfColors.green800, fontSize: 10),
                      ),
                    )
                  : pw.ListView.builder(
                      itemCount: alerts.length,
                      itemBuilder: (pw.Context context, int index) {
                        final alert = alerts[index];
                        PdfColor itemColor = warningColor;
                        if (alert.severity == 'Danger' || alert.severity == 'Critical') {
                          itemColor = dangerColor;
                        }
                        
                        return pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 8),
                          padding: const pw.EdgeInsets.all(10),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                            border: pw.Border(left: pw.BorderSide(color: PdfColors.grey400, width: 4)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    alert.title,
                                    style: pw.TextStyle(
                                      fontSize: 11,
                                      fontWeight: pw.FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  pw.Text(
                                    alert.severity.toUpperCase(),
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                      color: itemColor,
                                    ),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                alert.description,
                                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              pw.SizedBox(height: 8),

              // Recommendations Footer
              pw.Text(
                'Security Recommendations:',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor),
              ),
              pw.SizedBox(height: 4),
              pw.Bullet(
                text: recommendVpn 
                    ? vpnExplanation 
                    : 'Your network looks secure. Use a VPN to encrypt traffic if you start handling highly confidential data.',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
              ),
              pw.Bullet(
                text: 'Always disable auto-join/auto-connect for public hotspots on your devices.',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
              ),
              pw.Bullet(
                text: 'Disclaimer: This report is advisory. Defensive metrics represent heuristics and may not guarantee detection of all advanced custom hardware attacks.',
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic),
              ),
            ],
          );
        },
      ),
    );

    // Save the file
    final outputDir = await getTemporaryDirectory();
    final file = File('${outputDir.path}/cybershield_report_${network.ssid.replaceAll(" ", "_")}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
  }

  pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }
}
