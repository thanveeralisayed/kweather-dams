class RiverBasinQPF {
  final int slNo;
  final String basinName;
  final String subBasinName;
  final List<String> dayQpfValues; // 7 days of mm range e.g. ["26-37", "11-25", "0.1-10", ...]

  const RiverBasinQPF({
    required this.slNo,
    required this.basinName,
    required this.subBasinName,
    required this.dayQpfValues,
  });

  bool get hasHighFloodRisk {
    return dayQpfValues.any((v) {
      final clean = v.trim();
      return clean.contains('51-75') || clean.contains('76-100') || clean.contains('>100');
    });
  }

  factory RiverBasinQPF.fromJson(Map<String, dynamic> json) {
    return RiverBasinQPF(
      slNo: json['slNo'] is int ? json['slNo'] : int.tryParse(json['slNo']?.toString() ?? '1') ?? 1,
      basinName: json['basinName']?.toString() ?? '',
      subBasinName: json['subBasinName']?.toString() ?? '',
      dayQpfValues: (json['dayQpfValues'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slNo': slNo,
      'basinName': basinName,
      'subBasinName': subBasinName,
      'dayQpfValues': dayQpfValues,
    };
  }
}
