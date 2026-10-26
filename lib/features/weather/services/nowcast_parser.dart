import 'dart:convert';
import '../models/nowcast_alert.dart';

class NowcastParser {
  const NowcastParser();

  /// Parse the list of nowcast station warnings from the IMD HTML page
  List<NowcastAlert> parseHtml(String html) {
    if (html.isEmpty) return [];

    final alerts = <NowcastAlert>[];

    // Primary strategy: Extract the JSON "images" array
    final imagesMatch = RegExp(r'"images"\s*:\s*(\[\s*\{[\s\S]*?\}\s*\])\s*[,;\}]').firstMatch(html);
    if (imagesMatch != null) {
      final jsonStr = imagesMatch.group(1);
      if (jsonStr != null) {
        try {
          final dynamic parsed = jsonDecode(jsonStr);
          if (parsed is List) {
            for (final item in parsed) {
              if (item is Map<String, dynamic>) {
                alerts.add(NowcastAlert.fromMapJson(item));
              }
            }
            if (alerts.isNotEmpty) {
              return alerts;
            }
          }
        } catch (_) {
          // If strict JSON decoding fails due to HTML escape issues, fallback to object regex
        }
      }
    }

    // Secondary fallback strategy: Regex match individual station objects
    final stationRegex = RegExp(
      r'\{\s*"imageURL"\s*:\s*"([^"]*)"[\s\S]*?"description"\s*:\s*"([^"]*)"[\s\S]*?"title"\s*:\s*"([^"]*)"[\s\S]*?"latitude"\s*:\s*"?([0-9.]+)"?[\s\S]*?"longitude"\s*:\s*"?([0-9.]+)"?',
      multiLine: true,
    );

    for (final match in stationRegex.allMatches(html)) {
      final imageURL = match.group(1) ?? '';
      final description = match.group(2) ?? '';
      final title = match.group(3) ?? '';
      final lat = match.group(4) ?? '0.0';
      final lon = match.group(5) ?? '0.0';

      alerts.add(NowcastAlert.fromMapJson({
        'imageURL': imageURL,
        'description': description,
        'title': title,
        'latitude': lat,
        'longitude': lon,
      }));
    }

    return alerts;
  }
}
