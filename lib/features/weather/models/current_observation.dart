class CurrentObservation {
  final String date;
  final String updatedAt;
  final double currentTemp;
  final double maxTemp;
  final double minTemp;
  final double? maxTempDeviation;
  final double? minTempDeviation;
  final double rainfall24h;
  final int humidityMorning;
  final int humidityEvening;
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;
  final String conditionSummary;
  final String iconCode;

  const CurrentObservation({
    required this.date,
    required this.updatedAt,
    required this.currentTemp,
    required this.maxTemp,
    required this.minTemp,
    this.maxTempDeviation,
    this.minTempDeviation,
    required this.rainfall24h,
    required this.humidityMorning,
    required this.humidityEvening,
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.conditionSummary,
    required this.iconCode,
  });

  factory CurrentObservation.fromImdJson(Map<String, dynamic> json) {
    // Current temp is estimated from max/forecast0 or direct max/min
    final max = _parseDouble(json['max'] ?? json['max0'], 28.0);
    final min = _parseDouble(json['min'] ?? json['min0'], 23.0);
    
    // Estimate sensible current ambient temp based on time or average
    final current = double.tryParse(json['current_temp']?.toString() ?? '') ?? 
        ((max + min) / 2.0);

    return CurrentObservation(
      date: json['dat']?.toString() ?? json['max_date']?.toString() ?? '',
      updatedAt: json['updat']?.toString() ?? '',
      currentTemp: double.parse(current.toStringAsFixed(1)),
      maxTemp: max,
      minTemp: min,
      maxTempDeviation: _parseDoubleOrNull(json['maxdep']),
      minTempDeviation: _parseDoubleOrNull(json['mindep']),
      rainfall24h: _parseDouble(json['rainfall']),
      humidityMorning: _parseInt(json['rh0830']),
      humidityEvening: _parseInt(json['rh1730']),
      sunrise: json['sunrise']?.toString() ?? '--:--',
      sunset: json['sunset']?.toString() ?? '--:--',
      moonrise: json['moonrise']?.toString() ?? '--:--',
      moonset: json['moonset']?.toString() ?? '--:--',
      conditionSummary: json['forecast0']?.toString() ?? 'Partly cloudy sky',
      iconCode: json['img0']?.toString() ?? '15',
    );
  }

  factory CurrentObservation.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('max0') || json.containsKey('updat')) {
      return CurrentObservation.fromImdJson(json);
    }
    return CurrentObservation(
      date: json['date']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      currentTemp: _parseDouble(json['currentTemp'], 28.0),
      maxTemp: _parseDouble(json['maxTemp'], 30.0),
      minTemp: _parseDouble(json['minTemp'], 23.0),
      maxTempDeviation: _parseDoubleOrNull(json['maxTempDeviation']),
      minTempDeviation: _parseDoubleOrNull(json['minTempDeviation']),
      rainfall24h: _parseDouble(json['rainfall24h']),
      humidityMorning: _parseInt(json['humidityMorning']),
      humidityEvening: _parseInt(json['humidityEvening']),
      sunrise: json['sunrise']?.toString() ?? '--:--',
      sunset: json['sunset']?.toString() ?? '--:--',
      moonrise: json['moonrise']?.toString() ?? '--:--',
      moonset: json['moonset']?.toString() ?? '--:--',
      conditionSummary: json['conditionSummary']?.toString() ?? 'Partly cloudy sky',
      iconCode: json['iconCode']?.toString() ?? '15',
    );
  }

  static double _parseDouble(dynamic val, [double defaultValue = 0.0]) {
    if (val == null) return defaultValue;
    final str = val.toString().trim();
    if (str == 'NA' || str == 'null' || str.isEmpty) return defaultValue;
    return double.tryParse(str) ?? defaultValue;
  }

  static double? _parseDoubleOrNull(dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim();
    if (str == 'NA' || str == 'null' || str.isEmpty) return null;
    return double.tryParse(str);
  }

  static int _parseInt(dynamic val, [int defaultValue = 0]) {
    if (val == null) return defaultValue;
    final str = val.toString().trim();
    if (str == 'NA' || str == 'null' || str.isEmpty) return defaultValue;
    return int.tryParse(str) ?? (double.tryParse(str)?.round() ?? defaultValue);
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'updatedAt': updatedAt,
      'currentTemp': currentTemp,
      'maxTemp': maxTemp,
      'minTemp': minTemp,
      'maxTempDeviation': maxTempDeviation,
      'minTempDeviation': minTempDeviation,
      'rainfall24h': rainfall24h,
      'humidityMorning': humidityMorning,
      'humidityEvening': humidityEvening,
      'sunrise': sunrise,
      'sunset': sunset,
      'moonrise': moonrise,
      'moonset': moonset,
      'conditionSummary': conditionSummary,
      'iconCode': iconCode,
    };
  }
}
