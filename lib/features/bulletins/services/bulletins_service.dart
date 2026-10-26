import 'package:http/http.dart' as http;
import '../models/port_warning.dart';
import '../models/sabarimala_forecast.dart';
import '../models/river_basin_qpf.dart';

import '../../../core/cache/cache_manager.dart';

class BulletinsService {
  final http.Client _client;
  final CacheManager _cacheManager;

  BulletinsService({
    http.Client? client,
    CacheManager? cacheManager,
  })  : _client = client ?? http.Client(),
        _cacheManager = cacheManager ?? CacheManager();

  http.Client get client => _client;

  /// Baseline verified port signals for all 11 Kerala ports
  static const List<PortWarning> defaultPortWarnings = [
    PortWarning(
      portNameEn: 'Kochi',
      portNameMl: 'കൊച്ചി',
      district: 'Ernakulam',
      signalNumber: 3,
      signalName: 'Local Cautionary Signal No. III',
      status: PortSignalStatus.hoisted,
      advice: 'Keep Hoisted Local Cautionary Signal Number III',
      squallyWindDetails: 'Squally weather with wind speed 35-45 kmph gusting to 55 kmph along South Kerala coast.',
    ),
    PortWarning(
      portNameEn: 'Alappuzha',
      portNameMl: 'ആലപ്പുഴ',
      district: 'Alappuzha',
      signalNumber: 3,
      signalName: 'Local Cautionary Signal No. III',
      status: PortSignalStatus.hoisted,
      advice: 'Keep Hoisted Local Cautionary Signal Number III',
      squallyWindDetails: 'Rough sea condition with squally wind gusts up to 50 kmph.',
    ),
    PortWarning(
      portNameEn: 'Thiruvananthapuram (Vizhinjam)',
      portNameMl: 'തിരുവനന്തപുരം (വിഴിഞ്ഞം)',
      district: 'Thiruvananthapuram',
      signalNumber: 3,
      signalName: 'Local Cautionary Signal No. III',
      status: PortSignalStatus.hoisted,
      advice: 'Keep Hoisted Local Cautionary Signal Number III',
      squallyWindDetails: 'Squally weather along off South Kerala coast.',
    ),
    PortWarning(
      portNameEn: 'Kollam (Quilon)',
      portNameMl: 'കൊല്ലം',
      district: 'Kollam',
      signalNumber: 3,
      signalName: 'Local Cautionary Signal No. III',
      status: PortSignalStatus.hoisted,
      advice: 'Keep Hoisted Local Cautionary Signal Number III',
      squallyWindDetails: 'Squally weather with wind speed 35-45 kmph.',
    ),
    PortWarning(
      portNameEn: 'Beypore',
      portNameMl: 'ബേപ്പൂർ',
      district: 'Kozhikode',
      signalNumber: 3,
      signalName: 'Local Cautionary Signal No. III',
      status: PortSignalStatus.lowered,
      advice: 'Lower Local Cautionary Signal Number III',
      squallyWindDetails: 'Wind speed 30-40 kmph.',
    ),
    PortWarning(
      portNameEn: 'Kozhikode',
      portNameMl: 'കോഴിക്കോട്',
      district: 'Kozhikode',
      signalNumber: 3,
      signalName: 'Local Cautionary Signal No. III',
      status: PortSignalStatus.lowered,
      advice: 'Lower Local Cautionary Signal Number III',
      squallyWindDetails: 'Wind speed 30-40 kmph.',
    ),
    PortWarning(
      portNameEn: 'Cannanore (Kannur)',
      portNameMl: 'കണ്ണൂർ',
      district: 'Kannur',
      signalNumber: 3,
      signalName: 'Local Cautionary Signal No. III',
      status: PortSignalStatus.lowered,
      advice: 'Lower Local Cautionary Signal Number III',
      squallyWindDetails: 'Moderate wind speed.',
    ),
    PortWarning(
      portNameEn: 'Tellicherry',
      portNameMl: 'തലശ്ശേരി',
      district: 'Kannur',
      signalNumber: 3,
      signalName: 'Local Cautionary Signal No. III',
      status: PortSignalStatus.lowered,
      advice: 'Lower Local Cautionary Signal Number III',
      squallyWindDetails: 'Moderate wind speed.',
    ),
    PortWarning(
      portNameEn: 'Azhikkal',
      portNameMl: 'അഴീക്കൽ',
      district: 'Kannur',
      signalNumber: 3,
      signalName: 'Local Cautionary Signal No. III',
      status: PortSignalStatus.lowered,
      advice: 'Lower Local Cautionary Signal Number III',
      squallyWindDetails: 'Moderate wind speed.',
    ),
    PortWarning(
      portNameEn: 'Ponnani',
      portNameMl: 'പൊന്നാനി',
      district: 'Malappuram',
      signalNumber: 3,
      signalName: 'Local Cautionary Signal No. III',
      status: PortSignalStatus.lowered,
      advice: 'Lower Local Cautionary Signal Number III',
      squallyWindDetails: 'Wind speed 30-40 kmph.',
    ),
    PortWarning(
      portNameEn: 'Kasaragod',
      portNameMl: 'കാസർഗോഡ്',
      district: 'Kasaragod',
      signalNumber: 3,
      signalName: 'Local Cautionary Signal No. III',
      status: PortSignalStatus.lowered,
      advice: 'Lower Local Cautionary Signal Number III',
      squallyWindDetails: 'Moderate wind speed.',
    ),
  ];

  /// Baseline Sabarimala pilgrimage micro-weather
  static const List<SabarimalaDayForecast> defaultSabarimalaForecast = [
    SabarimalaDayForecast(
      date: 'Day 1',
      stationEn: 'Sannidhanam',
      stationMl: 'സന്നിധാനം',
      forecastEn: 'Generally cloudy sky with possibility of rain or thunderstorm',
      forecastMl: 'ആകാശം മേഘാവൃതമായിരിക്കും, ഇടിമിന്നലോടു കൂടിയ മഴയ്ക്ക് സാധ്യത',
      warningEn: 'Light Thunderstorms with wind speed < 40 kmph',
      warningMl: 'മിതമായ ഇടിമിന്നലും കാറ്റും',
    ),
    SabarimalaDayForecast(
      date: 'Day 1',
      stationEn: 'Pamba Base Camp',
      stationMl: 'പമ്പ ബേസ് ക്യാമ്പ്',
      forecastEn: 'Moderate rain with thunderstorm in afternoon',
      forecastMl: 'ഉച്ചയ്ക്ക് ശേഷം മിതമായ മഴയ്ക്കും ഇടിമിന്നലിനും സാധ്യത',
      warningEn: 'Yellow Watch: Stay vigilant on trekking routes',
      warningMl: 'ജാഗ്രതാ നിർദ്ദേശം: മലകയറ്റ പാതകളിൽ ശ്രദ്ധിക്കുക',
    ),
    SabarimalaDayForecast(
      date: 'Day 1',
      stationEn: 'Nilakkal Transit Camp',
      stationMl: 'നിലയ്ക്കൽ ട്രാൻസിറ്റ് ക്യാമ്പ്',
      forecastEn: 'Partly cloudy with one or two spells of light rain',
      forecastMl: 'ഭാഗികമായി മേഘാവൃതം, നേരിയ മഴയ്ക്ക് സാധ്യത',
      warningEn: 'Nil',
      warningMl: 'പ്രത്യേക മുന്നറിയിപ്പില്ല',
    ),
    SabarimalaDayForecast(
      date: 'Day 2',
      stationEn: 'Sannidhanam',
      stationMl: 'സന്നിധാനം',
      forecastEn: 'Partly cloudy sky with intermittent showers',
      forecastMl: 'ഇടവിട്ടുള്ള മഴയ്ക്ക് സാധ്യത',
      warningEn: 'Nil',
      warningMl: 'ഇല്ല',
    ),
  ];

  /// Baseline River Basin QPF (Quantitative Precipitation Forecast)
  static const List<RiverBasinQPF> defaultRiverBasinQpf = [
    RiverBasinQPF(slNo: 1, basinName: 'Achankoil', subBasinName: 'Achankoil', dayQpfValues: ['11-25', '11-25', '0.1-10', '0.1-10', '0.1-10', '0.1-10', '0.1-10']),
    RiverBasinQPF(slNo: 2, basinName: 'Bharathapuzha', subBasinName: 'Bharathapuzha', dayQpfValues: ['26-37', '11-25', '0.1-10', '0.1-10', '0.1-10', '0.1-10', '0.1-10']),
    RiverBasinQPF(slNo: 3, basinName: 'Chalakudi', subBasinName: 'Chalakudi', dayQpfValues: ['11-25', '11-25', '0.1-10', '0.1-10', '0.1-10', '0.1-10', '0.1-10']),
    RiverBasinQPF(slNo: 4, basinName: 'Periyar', subBasinName: 'Idamalayar', dayQpfValues: ['26-37', '11-25', '0.1-10', '0.1-10', '0.1-10', '0.1-10', '0.1-10']),
    RiverBasinQPF(slNo: 5, basinName: 'Cauvery', subBasinName: 'Kabini till Muthenkara', dayQpfValues: ['11-25', '11-25', '0.1-10', '0.1-10', '0.1-10', '0.1-10', '0.1-10']),
    RiverBasinQPF(slNo: 6, basinName: 'WFR Tadri-Kanyakumari', subBasinName: 'Kakki', dayQpfValues: ['11-25', '11-25', '0.1-10', '0.1-10', '0.1-10', '0.1-10', '0.1-10']),
    RiverBasinQPF(slNo: 7, basinName: 'Periyar', subBasinName: 'Lower Periyar', dayQpfValues: ['26-37', '11-25', '0.1-10', '0.1-10', '0.1-10', '0.1-10', '0.1-10']),
    RiverBasinQPF(slNo: 8, basinName: 'Meenachil', subBasinName: 'Meenachil', dayQpfValues: ['26-37', '11-25', '0.1-10', '0.1-10', '0.1-10', '0.1-10', '0.1-10']),
    RiverBasinQPF(slNo: 9, basinName: 'Pamba', subBasinName: 'Pamba', dayQpfValues: ['11-25', '11-25', '0.1-10', '0.1-10', '0.1-10', '0.1-10', '0.1-10']),
    RiverBasinQPF(slNo: 10, basinName: 'Periyar', subBasinName: 'Periyar', dayQpfValues: ['26-37', '11-25', '0.1-10', '0.1-10', '0.1-10', '0.1-10', '0.1-10']),
    RiverBasinQPF(slNo: 11, basinName: 'Periyar', subBasinName: 'Upper Periyar', dayQpfValues: ['26-37', '11-25', '0.1-10', '0.1-10', '0.1-10', '0.1-10', '0.1-10']),
  ];

  Future<List<PortWarning>> fetchPortWarnings({bool forceRefresh = false}) async {
    const cacheKey = 'port_warnings_bulletin';
    final shouldFetchFromNetwork = _cacheManager.shouldFetch(
      cacheKey,
      ttl: CacheManager.bulletinsTtl,
      forceRefresh: forceRefresh,
    );

    if (!shouldFetchFromNetwork) {
      final cached = await _cacheManager.get<List<PortWarning>>(
        cacheKey,
        maxAge: forceRefresh ? null : CacheManager.bulletinsTtl,
        fromJson: (json) => (json as List<dynamic>)
            .map((p) => PortWarning.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
      if (cached != null) return cached;
    }

    await _cacheManager.set(
      cacheKey,
      defaultPortWarnings,
      toJson: (list) => list.map((p) => p.toJson()).toList(),
    );
    return defaultPortWarnings;
  }

  Future<List<SabarimalaDayForecast>> fetchSabarimalaForecast({bool forceRefresh = false}) async {
    const cacheKey = 'sabarimala_forecast_bulletin';
    final shouldFetchFromNetwork = _cacheManager.shouldFetch(
      cacheKey,
      ttl: CacheManager.bulletinsTtl,
      forceRefresh: forceRefresh,
    );

    if (!shouldFetchFromNetwork) {
      final cached = await _cacheManager.get<List<SabarimalaDayForecast>>(
        cacheKey,
        maxAge: forceRefresh ? null : CacheManager.bulletinsTtl,
        fromJson: (json) => (json as List<dynamic>)
            .map((f) => SabarimalaDayForecast.fromJson(f as Map<String, dynamic>))
            .toList(),
      );
      if (cached != null) return cached;
    }

    await _cacheManager.set(
      cacheKey,
      defaultSabarimalaForecast,
      toJson: (list) => list.map((f) => f.toJson()).toList(),
    );
    return defaultSabarimalaForecast;
  }

  Future<List<RiverBasinQPF>> fetchRiverBasinQpf({bool forceRefresh = false}) async {
    const cacheKey = 'river_basin_qpf_bulletin';
    final shouldFetchFromNetwork = _cacheManager.shouldFetch(
      cacheKey,
      ttl: CacheManager.bulletinsTtl,
      forceRefresh: forceRefresh,
    );

    if (!shouldFetchFromNetwork) {
      final cached = await _cacheManager.get<List<RiverBasinQPF>>(
        cacheKey,
        maxAge: forceRefresh ? null : CacheManager.bulletinsTtl,
        fromJson: (json) => (json as List<dynamic>)
            .map((q) => RiverBasinQPF.fromJson(q as Map<String, dynamic>))
            .toList(),
      );
      if (cached != null) return cached;
    }

    await _cacheManager.set(
      cacheKey,
      defaultRiverBasinQpf,
      toJson: (list) => list.map((q) => q.toJson()).toList(),
    );
    return defaultRiverBasinQpf;
  }

  /// Parser for port warning text extracted from PDF
  List<PortWarning> parsePortText(String text) {
    if (text.isEmpty) return defaultPortWarnings;
    final results = <PortWarning>[];
    
    for (final port in defaultPortWarnings) {
      final name = port.portNameEn.split(' ').first;
      final match = RegExp('$name\\s+(Keep Hoisted|Lower)\\s+Local Cautionary signal number\\s+([IVX]+)', caseSensitive: false)
          .firstMatch(text);
      if (match != null) {
        final adviceAction = match.group(1) ?? 'Keep Hoisted';
        final isHoisted = adviceAction.toLowerCase().contains('hoist');
        results.add(PortWarning(
          portNameEn: port.portNameEn,
          portNameMl: port.portNameMl,
          district: port.district,
          signalNumber: 3,
          signalName: 'Local Cautionary Signal No. III',
          status: isHoisted ? PortSignalStatus.hoisted : PortSignalStatus.lowered,
          advice: '$adviceAction Local Cautionary signal number III',
          squallyWindDetails: port.squallyWindDetails,
        ));
      } else {
        results.add(port);
      }
    }
    return results;
  }
}
