import 'daily_forecast.dart';

class NowcastAlert {
  final String stationName;
  final double latitude;
  final double longitude;
  final WarningSeverity severity;
  final String rainIntensity;
  final String windSpeed;
  final bool hasThunderstorm;
  final String timeOfIssue;
  final String validUpto;
  final String rawDescription;

  const NowcastAlert({
    required this.stationName,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.rainIntensity,
    required this.windSpeed,
    required this.hasThunderstorm,
    required this.timeOfIssue,
    required this.validUpto,
    required this.rawDescription,
  });

  factory NowcastAlert.fromMapJson(Map<String, dynamic> json) {
    final title = (json['title']?.toString() ?? 'Kerala Station').trim();
    final lat = double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0;
    final lon = double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0;
    final markerUrl = json['imageURL']?.toString().toLowerCase() ?? '';
    
    WarningSeverity severity = WarningSeverity.green;
    if (markerUrl.contains('red')) {
      severity = WarningSeverity.red;
    } else if (markerUrl.contains('orange')) {
      severity = WarningSeverity.orange;
    } else if (markerUrl.contains('yellow')) {
      severity = WarningSeverity.yellow;
    }

    final rawDesc = (json['description']?.toString() ?? '').replaceAll(RegExp(r'<[^>]+>'), ' ');
    final cleanDesc = rawDesc.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Extract rain intensity (e.g. "Moderate rain: 5-15 mm/hr" or "Light rain")
    String rainIntensity = 'No rain reported';
    final rainMatch = RegExp(r'(Light rain|Moderate rain:[^T]+|Heavy rain:[^T]+|Very heavy rain:[^T]+)', caseSensitive: false).firstMatch(cleanDesc);
    if (rainMatch != null) {
      rainIntensity = rainMatch.group(1)?.trim() ?? '';
    } else if (cleanDesc.toLowerCase().contains('light rain')) {
      rainIntensity = 'Light rain';
    }

    // Extract wind speed
    String windSpeed = 'Calm';
    final windMatch = RegExp(r'(wind speed [^M\n]+kmph|surface wind [^M\n]+kmph)', caseSensitive: false).firstMatch(cleanDesc);
    if (windMatch != null) {
      windSpeed = windMatch.group(1)?.trim() ?? '< 40 kmph';
    }

    // Extract thunderstorm flag
    final hasThunderstorm = cleanDesc.toLowerCase().contains('thunderstorm');

    // Extract Issue and Valid times
    String timeOfIssue = '';
    final issueMatch = RegExp(r'Time of issue:\s*([0-9-]+\s+[0-9]+(?:\s*Hrs)?)', caseSensitive: false).firstMatch(cleanDesc);
    if (issueMatch != null) {
      timeOfIssue = issueMatch.group(1)?.trim() ?? '';
    }

    String validUpto = '';
    final validMatch = RegExp(r'Valid upto:\s*([0-9]+(?:\s*Hrs)?)', caseSensitive: false).firstMatch(cleanDesc);
    if (validMatch != null) {
      validUpto = validMatch.group(1)?.trim() ?? '';
    }

    return NowcastAlert(
      stationName: title,
      latitude: lat,
      longitude: lon,
      severity: severity,
      rainIntensity: rainIntensity,
      windSpeed: windSpeed,
      hasThunderstorm: hasThunderstorm,
      timeOfIssue: timeOfIssue,
      validUpto: validUpto,
      rawDescription: cleanDesc,
    );
  }

  factory NowcastAlert.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('imageURL')) {
      return NowcastAlert.fromMapJson(json);
    }
    return NowcastAlert(
      stationName: json['stationName']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      severity: WarningSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => WarningSeverity.green,
      ),
      rainIntensity: json['rainIntensity']?.toString() ?? '',
      windSpeed: json['windSpeed']?.toString() ?? '',
      hasThunderstorm: json['hasThunderstorm'] == true,
      timeOfIssue: json['timeOfIssue']?.toString() ?? '',
      validUpto: json['validUpto']?.toString() ?? '',
      rawDescription: json['rawDescription']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stationName': stationName,
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity.name,
      'rainIntensity': rainIntensity,
      'windSpeed': windSpeed,
      'hasThunderstorm': hasThunderstorm,
      'timeOfIssue': timeOfIssue,
      'validUpto': validUpto,
      'rawDescription': rawDescription,
    };
  }
}
