enum DamAuthority {
  kseb,
  irrigation,
  all,
}

enum DamAlertLevel {
  red,
  orange,
  blue,
  yellow,
  normal,
}

class DamModel {
  final String id;
  final String nameEn;
  final String nameMl;
  final String district;
  final DamAuthority authority;
  final double frlMeters;
  final double currentLevelMeters;
  final double ruleLevelMeters;
  final double blueLevel;
  final double orangeLevel;
  final double redLevel;
  final double grossStorageMcm;
  final double currentStorageMcm;
  final double storagePercentage;
  final double outflowCumecs;
  final DamAlertLevel alertLevel;
  final String shutterRemarks;
  final String asOfTime;

  const DamModel({
    required this.id,
    required this.nameEn,
    required this.nameMl,
    required this.district,
    required this.authority,
    required this.frlMeters,
    required this.currentLevelMeters,
    required this.ruleLevelMeters,
    required this.blueLevel,
    required this.orangeLevel,
    required this.redLevel,
    required this.grossStorageMcm,
    required this.currentStorageMcm,
    required this.storagePercentage,
    required this.outflowCumecs,
    required this.alertLevel,
    required this.shutterRemarks,
    required this.asOfTime,
  });

  bool get isShutterOpen {
    final lower = shutterRemarks.toLowerCase();
    return lower.contains('opened') || lower.contains('discharge') || outflowCumecs > 0.0 || alertLevel == DamAlertLevel.yellow;
  }

  bool get isNearCapacity => storagePercentage >= 85.0;

  String localizedName(bool isMalayalam) {
    if (isMalayalam && nameMl.isNotEmpty) return nameMl;
    return nameEn;
  }

  String get alertBadgeLabel {
    switch (alertLevel) {
      case DamAlertLevel.red:
        return 'Red Alert (Stage 3)';
      case DamAlertLevel.orange:
        return 'Orange Alert (Stage 2)';
      case DamAlertLevel.blue:
        return 'Blue Alert (Stage 1)';
      case DamAlertLevel.yellow:
        return 'Controlled Discharge';
      case DamAlertLevel.normal:
        return 'Normal Level';
    }
  }

  factory DamModel.fromJson(Map<String, dynamic> json) {
    return DamModel(
      id: json['id']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? '',
      nameMl: json['nameMl']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      authority: json['authority'] == 'kseb' ? DamAuthority.kseb : DamAuthority.irrigation,
      frlMeters: _parseDouble(json['frlMeters']),
      currentLevelMeters: _parseDouble(json['currentLevelMeters']),
      ruleLevelMeters: _parseDouble(json['ruleLevelMeters']),
      blueLevel: _parseDouble(json['blueLevel']),
      orangeLevel: _parseDouble(json['orangeLevel']),
      redLevel: _parseDouble(json['redLevel']),
      grossStorageMcm: _parseDouble(json['grossStorageMcm']),
      currentStorageMcm: _parseDouble(json['currentStorageMcm']),
      storagePercentage: _parseDouble(json['storagePercentage']),
      outflowCumecs: _parseDouble(json['outflowCumecs']),
      alertLevel: DamAlertLevel.values.firstWhere(
        (e) => e.name == json['alertLevel'],
        orElse: () => DamAlertLevel.normal,
      ),
      shutterRemarks: json['shutterRemarks']?.toString() ?? '',
      asOfTime: json['asOfTime']?.toString() ?? '',
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    final str = val.toString().trim().replaceAll('%', '').replaceAll('m', '').replaceAll('ft', '');
    if (str == 'NA' || str == '-' || str.isEmpty) return 0.0;
    return double.tryParse(str) ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameMl': nameMl,
      'district': district,
      'authority': authority.name,
      'frlMeters': frlMeters,
      'currentLevelMeters': currentLevelMeters,
      'ruleLevelMeters': ruleLevelMeters,
      'blueLevel': blueLevel,
      'orangeLevel': orangeLevel,
      'redLevel': redLevel,
      'grossStorageMcm': grossStorageMcm,
      'currentStorageMcm': currentStorageMcm,
      'storagePercentage': storagePercentage,
      'outflowCumecs': outflowCumecs,
      'alertLevel': alertLevel.name,
      'shutterRemarks': shutterRemarks,
      'asOfTime': asOfTime,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DamModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
