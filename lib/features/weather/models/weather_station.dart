enum StationRegion {
  south,
  central,
  north,
  highRange,
  pilgrimage,
  lakshadweep,
}

class WeatherStation {
  final String id;
  final String nameEn;
  final String nameMl;
  final String district;
  final StationRegion region;
  final double latitude;
  final double longitude;
  final bool isPrimary;

  const WeatherStation({
    required this.id,
    required this.nameEn,
    required this.nameMl,
    required this.district,
    required this.region,
    required this.latitude,
    required this.longitude,
    this.isPrimary = false,
  });

  factory WeatherStation.fromJson(Map<String, dynamic> json) {
    return WeatherStation(
      id: json['station_id']?.toString() ?? json['id']?.toString() ?? '',
      nameEn: json['station']?.toString() ?? json['nameEn']?.toString() ?? '',
      nameMl: json['nameMl']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      region: StationRegion.values.firstWhere(
        (r) => r.name == json['region'],
        orElse: () => StationRegion.central,
      ),
      latitude: double.tryParse(json['lat']?.toString() ?? json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['lon']?.toString() ?? json['longitude']?.toString() ?? '0') ?? 0.0,
      isPrimary: json['isPrimary'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameMl': nameMl,
      'district': district,
      'region': region.name,
      'latitude': latitude,
      'longitude': longitude,
      'isPrimary': isPrimary,
    };
  }

  String localizedName(bool isMalayalam) {
    if (isMalayalam && nameMl.isNotEmpty) return nameMl;
    return nameEn;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherStation && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
