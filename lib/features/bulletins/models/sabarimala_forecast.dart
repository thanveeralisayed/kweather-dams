class SabarimalaDayForecast {
  final String date;
  final String stationEn;
  final String stationMl;
  final String forecastEn;
  final String forecastMl;
  final String warningEn;
  final String warningMl;

  const SabarimalaDayForecast({
    required this.date,
    required this.stationEn,
    required this.stationMl,
    required this.forecastEn,
    required this.forecastMl,
    required this.warningEn,
    required this.warningMl,
  });

  String localizedStation(bool isMalayalam) => isMalayalam ? stationMl : stationEn;
  String localizedForecast(bool isMalayalam) => isMalayalam ? forecastMl : forecastEn;
  String localizedWarning(bool isMalayalam) => isMalayalam ? warningMl : warningEn;

  factory SabarimalaDayForecast.fromJson(Map<String, dynamic> json) {
    return SabarimalaDayForecast(
      date: json['date']?.toString() ?? '',
      stationEn: json['stationEn']?.toString() ?? '',
      stationMl: json['stationMl']?.toString() ?? '',
      forecastEn: json['forecastEn']?.toString() ?? 'Partly cloudy sky',
      forecastMl: json['forecastMl']?.toString() ?? 'ആകാശം ഭാഗികമായി മേഘാവൃതമായിരിക്കും',
      warningEn: json['warningEn']?.toString() ?? 'Nil',
      warningMl: json['warningMl']?.toString() ?? 'ഇല്ല',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'stationEn': stationEn,
      'stationMl': stationMl,
      'forecastEn': forecastEn,
      'forecastMl': forecastMl,
      'warningEn': warningEn,
      'warningMl': warningMl,
    };
  }
}
