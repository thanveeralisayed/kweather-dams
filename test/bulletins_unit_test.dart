import 'package:flutter_test/flutter_test.dart';
import 'package:kweather/features/bulletins/models/port_warning.dart';
import 'package:kweather/features/bulletins/models/sabarimala_forecast.dart';
import 'package:kweather/features/bulletins/models/river_basin_qpf.dart';
import 'package:kweather/features/bulletins/services/bulletins_service.dart';
import 'package:kweather/core/cache/cache_manager.dart';

void main() {
  setUp(() async {
    await CacheManager().clearAll();
  });

  group('Phase 3: PortWarning Unit Tests', () {
    test('PortWarning parses json and status correctly', () {
      final json = {
        'portNameEn': 'Kochi',
        'portNameMl': 'കൊച്ചി',
        'district': 'Ernakulam',
        'signalNumber': '3',
        'signalName': 'Signal III',
        'advice': 'Keep Hoisted Local Cautionary Signal Number III',
        'squallyWindDetails': 'Wind 35-45 kmph',
      };

      final port = PortWarning.fromJson(json);
      expect(port.portNameEn, 'Kochi');
      expect(port.portNameMl, 'കൊച്ചി');
      expect(port.status, PortSignalStatus.hoisted);
      expect(port.isCautionActive, isTrue);
      expect(port.localizedPortName(true), 'കൊച്ചി');
      expect(port.localizedPortName(false), 'Kochi');
    });

    test('PortWarning recognizes lowered signal status', () {
      final json = {
        'portNameEn': 'Kasaragod',
        'advice': 'Lower Local Cautionary Signal Number III',
      };
      final port = PortWarning.fromJson(json);
      expect(port.status, PortSignalStatus.lowered);
      expect(port.isCautionActive, isFalse);
    });
  });

  group('Phase 3: Sabarimala & RiverBasinQPF Unit Tests', () {
    test('SabarimalaDayForecast parses bilingual fields', () {
      final json = {
        'date': 'Day 1',
        'stationEn': 'Sannidhanam',
        'stationMl': 'സന്നിധാനം',
        'forecastEn': 'Rain',
        'forecastMl': 'മഴ',
        'warningEn': 'Watch',
        'warningMl': 'ജാഗ്രത',
      };

      final forecast = SabarimalaDayForecast.fromJson(json);
      expect(forecast.localizedStation(true), 'സന്നിധാനം');
      expect(forecast.localizedStation(false), 'Sannidhanam');
      expect(forecast.localizedForecast(true), 'മഴ');
      expect(forecast.localizedWarning(true), 'ജാഗ്രത');
    });

    test('RiverBasinQPF detects flood risk correctly', () {
      const safeBasin = RiverBasinQPF(
        slNo: 1,
        basinName: 'Achankoil',
        subBasinName: 'Achankoil',
        dayQpfValues: ['11-25', '11-25', '0.1-10', '0.1-10', '0.1-10', '0.1-10', '0.1-10'],
      );
      expect(safeBasin.hasHighFloodRisk, isFalse);

      const highRiskBasin = RiverBasinQPF(
        slNo: 2,
        basinName: 'Periyar',
        subBasinName: 'Idamalayar',
        dayQpfValues: ['26-37', '51-75', '0.1-10', '0.1-10', '0.1-10', '0.1-10', '0.1-10'],
      );
      expect(highRiskBasin.hasHighFloodRisk, isTrue);
    });
  });

  group('Phase 3: BulletinsService Unit Tests', () {
    test('BulletinsService has all 11 Kerala ports', () async {
      final service = BulletinsService();
      final ports = await service.fetchPortWarnings();
      expect(ports.length, 11);
      final hoisted = ports.where((p) => p.isCautionActive).toList();
      expect(hoisted.isNotEmpty, isTrue);
    });

    test('BulletinsService has 11 River Basins QPF', () async {
      final service = BulletinsService();
      final basins = await service.fetchRiverBasinQpf();
      expect(basins.length, 11);
    });

    test('parsePortText parses OCR lines from bulletin', () {
      const text = '''
      1. KOCHI Keep Hoisted Local Cautionary signal number III
      2. BEYPORE Lower Local Cautionary signal number III
      ''';

      final service = BulletinsService();
      final parsed = service.parsePortText(text);

      final kochi = parsed.firstWhere((p) => p.portNameEn == 'Kochi');
      expect(kochi.status, PortSignalStatus.hoisted);

      final beypore = parsed.firstWhere((p) => p.portNameEn == 'Beypore');
      expect(beypore.status, PortSignalStatus.lowered);
    });

    test('BulletinsService enforces 10-minute cooldown on repeated forceRefresh', () async {
      await CacheManager().clearAll();
      final service = BulletinsService();

      final p1 = await service.fetchPortWarnings(forceRefresh: true);
      expect(p1.length, 11);

      // Within 10 minutes, shouldFetch returns false
      expect(CacheManager().shouldFetch('port_warnings_bulletin', forceRefresh: true), isFalse);

      final p2 = await service.fetchPortWarnings(forceRefresh: true);
      expect(p2.length, 11);

      final s1 = await service.fetchSabarimalaForecast(forceRefresh: true);
      expect(s1.isNotEmpty, isTrue);
      expect(CacheManager().shouldFetch('sabarimala_forecast_bulletin', forceRefresh: true), isFalse);

      final q1 = await service.fetchRiverBasinQpf(forceRefresh: true);
      expect(q1.length, 11);
      expect(CacheManager().shouldFetch('river_basin_qpf_bulletin', forceRefresh: true), isFalse);
    });
  });
}
