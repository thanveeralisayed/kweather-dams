enum WarningSeverity {
  green,
  yellow,
  orange,
  red,
  none,
}

class DailyForecast {
  final int dayIndex;
  final String date;
  final String dayName;
  final String summary;
  final double maxTemp;
  final double minTemp;
  final String iconCode;
  final WarningSeverity warningSeverity;
  final String warningText;
  final int humidityMorning;
  final int humidityEvening;

  const DailyForecast({
    required this.dayIndex,
    required this.date,
    required this.dayName,
    required this.summary,
    required this.maxTemp,
    required this.minTemp,
    required this.iconCode,
    required this.warningSeverity,
    required this.warningText,
    required this.humidityMorning,
    required this.humidityEvening,
  });

  factory DailyForecast.fromImdIndex(Map<String, dynamic> json, int index, DateTime baseDate) {
    final forecastDate = baseDate.add(Duration(days: index));
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = index == 0 ? 'Today' : (index == 1 ? 'Tomorrow' : dayNames[forecastDate.weekday - 1]);
    
    final summary = json['forecast$index']?.toString() ?? 
                    (json['ffc'] is List && (json['ffc'] as List).length > index ? (json['ffc'] as List)[index]?.toString() : '') ?? 
                    'Partly cloudy sky';

    final max = _parseDouble(json['max$index'] ?? 
                (json['fmax'] is List && (json['fmax'] as List).length > index ? (json['fmax'] as List)[index] : '30.0'));
    
    final min = _parseDouble(json['min$index'] ?? 
                (json['fmin'] is List && (json['fmin'] as List).length > index ? (json['fmin'] as List)[index] : '24.0'));

    final icon = json['img$index']?.toString() ?? 
                 (json['fimg'] is List && (json['fimg'] as List).length > index ? (json['fimg'] as List)[index]?.toString() : '15') ?? 
                 '15';

    final rawColor = (json['wColor'] is List && (json['wColor'] as List).length > index 
                      ? (json['wColor'] as List)[index]?.toString().toLowerCase() 
                      : json['color$index']?.toString().toLowerCase()) ?? 'green';

    final severity = _parseWarningSeverity(rawColor);

    final rawWarning = (json['wText'] is List && (json['wText'] as List).length > index 
                        ? (json['wText'] as List)[index]?.toString() 
                        : json['warning$index']?.toString()) ?? 'No Warning';

    final rhMorning = _parseInt(json['rh0830d$index'] ?? 
                      (json['rh0830d'] is List && (json['rh0830d'] as List).length > index ? (json['rh0830d'] as List)[index] : '85'));

    final rhEvening = _parseInt(json['rh1730d$index'] ?? 
                      (json['rh1730d'] is List && (json['rh1730d'] as List).length > index ? (json['rh1730d'] as List)[index] : '80'));

    return DailyForecast(
      dayIndex: index,
      date: '${forecastDate.day} ${_monthName(forecastDate.month)}',
      dayName: dayName,
      summary: summary,
      maxTemp: max,
      minTemp: min,
      iconCode: icon,
      warningSeverity: severity,
      warningText: rawWarning,
      humidityMorning: rhMorning,
      humidityEvening: rhEvening,
    );
  }

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      dayIndex: json['dayIndex'] is int ? json['dayIndex'] : int.tryParse(json['dayIndex']?.toString() ?? '0') ?? 0,
      date: json['date']?.toString() ?? '',
      dayName: json['dayName']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      maxTemp: _parseDouble(json['maxTemp']),
      minTemp: _parseDouble(json['minTemp']),
      iconCode: json['iconCode']?.toString() ?? '15',
      warningSeverity: WarningSeverity.values.firstWhere(
        (e) => e.name == json['warningSeverity'],
        orElse: () => WarningSeverity.green,
      ),
      warningText: json['warningText']?.toString() ?? '',
      humidityMorning: _parseInt(json['humidityMorning']),
      humidityEvening: _parseInt(json['humidityEvening']),
    );
  }

  static WarningSeverity _parseWarningSeverity(String? color) {
    if (color == null) return WarningSeverity.none;
    final c = color.toLowerCase();
    if (c.contains('red') || c == '3') return WarningSeverity.red;
    if (c.contains('orange') || c == '2') return WarningSeverity.orange;
    if (c.contains('yellow') || c == '1') return WarningSeverity.yellow;
    if (c.contains('green') || c == '0') return WarningSeverity.green;
    return WarningSeverity.none;
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    final str = val.toString().trim();
    if (str == 'NA' || str == 'null' || str.isEmpty) return 0.0;
    return double.tryParse(str) ?? 0.0;
  }

  static int _parseInt(dynamic val) {
    if (val == null) return 0;
    final str = val.toString().trim();
    return int.tryParse(str) ?? (double.tryParse(str)?.round() ?? 0);
  }

  static String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Map<String, dynamic> toJson() {
    return {
      'dayIndex': dayIndex,
      'date': date,
      'dayName': dayName,
      'summary': summary,
      'maxTemp': maxTemp,
      'minTemp': minTemp,
      'iconCode': iconCode,
      'warningSeverity': warningSeverity.name,
      'warningText': warningText,
      'humidityMorning': humidityMorning,
      'humidityEvening': humidityEvening,
    };
  }
}
