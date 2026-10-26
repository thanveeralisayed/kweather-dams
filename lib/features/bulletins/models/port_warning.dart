enum PortSignalStatus {
  hoisted,
  lowered,
  informationOnly,
}

class PortWarning {
  final String portNameEn;
  final String portNameMl;
  final String district;
  final int signalNumber;
  final String signalName;
  final PortSignalStatus status;
  final String advice;
  final String squallyWindDetails;

  const PortWarning({
    required this.portNameEn,
    required this.portNameMl,
    required this.district,
    required this.signalNumber,
    required this.signalName,
    required this.status,
    required this.advice,
    required this.squallyWindDetails,
  });

  bool get isCautionActive => status == PortSignalStatus.hoisted;

  String localizedPortName(bool isMalayalam) {
    if (isMalayalam && portNameMl.isNotEmpty) return portNameMl;
    return portNameEn;
  }

  factory PortWarning.fromJson(Map<String, dynamic> json) {
    PortSignalStatus status = PortSignalStatus.hoisted;
    final adviceStr = json['advice']?.toString().toLowerCase() ?? '';
    if (adviceStr.contains('lower')) {
      status = PortSignalStatus.lowered;
    } else if (adviceStr.contains('information')) {
      status = PortSignalStatus.informationOnly;
    }

    return PortWarning(
      portNameEn: json['portNameEn']?.toString() ?? '',
      portNameMl: json['portNameMl']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      signalNumber: int.tryParse(json['signalNumber']?.toString() ?? '3') ?? 3,
      signalName: json['signalName']?.toString() ?? 'Local Cautionary Signal No. III',
      status: status,
      advice: json['advice']?.toString() ?? '',
      squallyWindDetails: json['squallyWindDetails']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'portNameEn': portNameEn,
      'portNameMl': portNameMl,
      'district': district,
      'signalNumber': signalNumber,
      'signalName': signalName,
      'status': status.name,
      'advice': advice,
      'squallyWindDetails': squallyWindDetails,
    };
  }
}
