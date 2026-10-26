import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:kweather/features/dams/models/dam_model.dart';
import 'package:kweather/features/dams/services/dam_scraper_service.dart';
import 'package:kweather/core/constants/kerala_dams_data.dart';
import 'package:kweather/core/cache/cache_manager.dart';

void main() {
  setUp(() async {
    await CacheManager().clearAll();
  });

  group('Phase 2: DamModel Unit & Edge Case Tests', () {
    test('DamModel parses fromJson with string units (m, ft, %)', () {
      final json = {
        'id': 'irr_neyyar',
        'nameEn': 'Neyyar',
        'nameMl': 'നെയ്യാർ',
        'district': 'Thiruvananthapuram',
        'authority': 'irrigation',
        'frlMeters': '84.75 m',
        'currentLevelMeters': '84.40 m',
        'ruleLevelMeters': '84.75',
        'blueLevel': '83.25',
        'orangeLevel': '83.75',
        'redLevel': '84.40',
        'grossStorageMcm': '97.35',
        'currentStorageMcm': '94.31',
        'storagePercentage': '97%',
        'outflowCumecs': '46.05',
        'alertLevel': 'red',
        'shutterRemarks': '4/4 spillway shutter opened @ 20 cm each',
        'asOfTime': '26/10/2026 11:00 AM',
      };

      final dam = DamModel.fromJson(json);
      expect(dam.id, 'irr_neyyar');
      expect(dam.frlMeters, 84.75);
      expect(dam.currentLevelMeters, 84.40);
      expect(dam.storagePercentage, 97.0);
      expect(dam.outflowCumecs, 46.05);
      expect(dam.alertLevel, DamAlertLevel.red);
      expect(dam.isShutterOpen, isTrue);
      expect(dam.isNearCapacity, isTrue);
    });

    test('isShutterOpen returns false when all gates closed', () {
      const dam = DamModel(
        id: 'kseb_idukki',
        nameEn: 'Idukki',
        nameMl: 'ഇടുക്കി',
        district: 'Idukki',
        authority: DamAuthority.kseb,
        frlMeters: 732.43,
        currentLevelMeters: 724.80,
        ruleLevelMeters: 732.43,
        blueLevel: 728.50,
        orangeLevel: 729.50,
        redLevel: 730.50,
        grossStorageMcm: 1996.30,
        currentStorageMcm: 1612.40,
        storagePercentage: 80.77,
        outflowCumecs: 0.0,
        alertLevel: DamAlertLevel.normal,
        shutterRemarks: 'All spillway gates are in closed position.',
        asOfTime: '26/10/2026',
      );

      expect(dam.isShutterOpen, isFalse);
      expect(dam.isNearCapacity, isFalse);
    });

    test('isShutterOpen returns true for outflow or yellow warning', () {
      const dam = DamModel(
        id: 'irr_moolathara',
        nameEn: 'Moolathara',
        nameMl: 'മൂലത്തറ',
        district: 'Palakkad',
        authority: DamAuthority.irrigation,
        frlMeters: 184.7,
        currentLevelMeters: 183.0,
        ruleLevelMeters: 184.7,
        blueLevel: 183.5,
        orangeLevel: 184.0,
        redLevel: 184.5,
        grossStorageMcm: 1.0,
        currentStorageMcm: 0.8,
        storagePercentage: 80.0,
        outflowCumecs: 16.54,
        alertLevel: DamAlertLevel.yellow,
        shutterRemarks: '1/19 shutter opened @ 20 cm',
        asOfTime: '26/10/2026',
      );

      expect(dam.isShutterOpen, isTrue);
      expect(dam.alertBadgeLabel, 'Controlled Discharge');
    });

    test('localizedName returns Malayalam or English appropriately', () {
      const dam = DamModel(
        id: 'kseb_banasurasagar',
        nameEn: 'Banasurasagar',
        nameMl: 'ബാണാസുര സാഗർ',
        district: 'Wayanad',
        authority: DamAuthority.kseb,
        frlMeters: 775.6,
        currentLevelMeters: 771.9,
        ruleLevelMeters: 775.6,
        blueLevel: 774.1,
        orangeLevel: 774.6,
        redLevel: 775.1,
        grossStorageMcm: 201.0,
        currentStorageMcm: 156.35,
        storagePercentage: 77.79,
        outflowCumecs: 0.0,
        alertLevel: DamAlertLevel.normal,
        shutterRemarks: '',
        asOfTime: '',
      );

      expect(dam.localizedName(true), 'ബാണാസുര സാഗർ');
      expect(dam.localizedName(false), 'Banasurasagar');
    });
  });

  group('Phase 2: DamScraperService Unit Tests', () {
    test('fetchAllDams returns 37 baseline dams when authority is all', () async {
      final service = DamScraperService();
      final dams = await service.fetchAllDams(authority: DamAuthority.all);
      expect(dams.length, 37);
    });

    test('fetchAllDams filters correctly by KSEB (17) and Irrigation (20)', () async {
      final service = DamScraperService();
      final ksebDams = await service.fetchAllDams(authority: DamAuthority.kseb);
      expect(ksebDams.length, 17);
      expect(ksebDams.every((d) => d.authority == DamAuthority.kseb), isTrue);

      final irrDams = await service.fetchAllDams(authority: DamAuthority.irrigation);
      expect(irrDams.length, 20);
      expect(irrDams.every((d) => d.authority == DamAuthority.irrigation), isTrue);
    });

    test('calculateStateWideStoragePercentage calculates weighted ratio correctly', () {
      final service = DamScraperService();
      final sampleDams = [
        const DamModel(
          id: '1',
          nameEn: 'D1',
          nameMl: '',
          district: '',
          authority: DamAuthority.kseb,
          frlMeters: 100,
          currentLevelMeters: 90,
          ruleLevelMeters: 100,
          blueLevel: 90,
          orangeLevel: 95,
          redLevel: 98,
          grossStorageMcm: 1000.0,
          currentStorageMcm: 800.0,
          storagePercentage: 80.0,
          outflowCumecs: 0,
          alertLevel: DamAlertLevel.normal,
          shutterRemarks: '',
          asOfTime: '',
        ),
        const DamModel(
          id: '2',
          nameEn: 'D2',
          nameMl: '',
          district: '',
          authority: DamAuthority.irrigation,
          frlMeters: 50,
          currentLevelMeters: 45,
          ruleLevelMeters: 50,
          blueLevel: 40,
          orangeLevel: 45,
          redLevel: 48,
          grossStorageMcm: 1000.0,
          currentStorageMcm: 600.0,
          storagePercentage: 60.0,
          outflowCumecs: 0,
          alertLevel: DamAlertLevel.normal,
          shutterRemarks: '',
          asOfTime: '',
        ),
      ];

      // Total gross: 2000, Total current: 1400 -> 70.0%
      final pct = service.calculateStateWideStoragePercentage(sampleDams);
      expect(pct, 70.0);
    });

    test('calculateStateWideStoragePercentage handles empty list without divide by zero', () {
      final service = DamScraperService();
      expect(service.calculateStateWideStoragePercentage([]), 0.0);
    });

    test('parseExtractedPdfText extracts structured dams from OCR text lines', () {
      const sampleText = '''
      1 Neyyar Thiruvananthapuram 84.75 84.40 4/4 spillway shutter opened @ 20 cm each
      2 Kallada Kollam 115.82 107.33 Outflow for power generation
      3 Malampuzha Palakkad 115.06 110.37 Outflow for drinking water
      ''';

      final service = DamScraperService();
      final parsed = service.parseExtractedPdfText(sampleText, DamAuthority.irrigation);

      expect(parsed.length, 3);
      expect(parsed[0].nameEn, 'Neyyar');
      expect(parsed[0].district, 'Thiruvananthapuram');
      expect(parsed[0].frlMeters, 84.75);
      expect(parsed[0].currentLevelMeters, 84.40);
      expect(parsed[0].isShutterOpen, isTrue);

      expect(parsed[1].nameEn, 'Kallada');
      expect(parsed[1].district, 'Kollam');
      expect(parsed[1].frlMeters, 115.82);
    });

    test('Live HTTP scraping extracts timestamp when available', () async {
      final mockClient = MockClient((request) async {
        const mockHtml = '''
        <html>
        <body>
        <p>Daily Water Level Details of Major Dams 26/10/2026 – 11.00 AM</p>
        </body>
        </html>
        ''';
        return http.Response(
          mockHtml,
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });

      final service = DamScraperService(client: mockClient);
      final dams = await service.fetchAllDams(forceRefresh: true);
      expect(dams.length, 37);
      expect(dams.first.asOfTime, '26/10/2026 – 11.00 AM');
    });

    test('KeralaDamsData provides 37 baseline dams with valid identifiers', () {
      expect(KeralaDamsData.baselineDams.length, 37);
      expect(KeralaDamsData.baselineDams.where((d) => d.authority == DamAuthority.kseb).length, 17);
      expect(KeralaDamsData.baselineDams.where((d) => d.authority == DamAuthority.irrigation).length, 20);
    });

    test('DamScraperService handles HTTP 429 and triggers rate limit backoff', () async {
      await CacheManager().clearAll();
      int networkHits = 0;

      final mockClient = MockClient((request) async {
        networkHits++;
        return http.Response('Too Many Requests', 429);
      });

      final service = DamScraperService(client: mockClient);
      final dams = await service.fetchAllDams(forceRefresh: true);

      // Should return baseline dams safely without throwing
      expect(dams.length, 37);
      expect(networkHits, 1);

      // CacheManager should now report rate limited
      expect(CacheManager().isRateLimited('dam_water_levels_all'), isTrue);

      // Second call must NOT hit network at all because backoff is active
      final secondDams = await service.fetchAllDams(forceRefresh: true);
      expect(secondDams.length, 37);
      expect(networkHits, 1); // Still 1, 0 additional calls!
    });

    test('DamScraperService handles HTTP 403 and triggers rate limit backoff', () async {
      await CacheManager().clearAll();
      int networkHits = 0;

      final mockClient = MockClient((request) async {
        networkHits++;
        return http.Response('Forbidden', 403);
      });

      final service = DamScraperService(client: mockClient);
      final dams = await service.fetchAllDams(forceRefresh: true);

      expect(dams.length, 37);
      expect(networkHits, 1);
      expect(CacheManager().isRateLimited('dam_water_levels_all'), isTrue);
    });

    test('DamScraperService enforces 10-minute cooldown on forceRefresh', () async {
      await CacheManager().clearAll();
      int networkHits = 0;

      final mockClient = MockClient((request) async {
        networkHits++;
        return http.Response(
          '<html><body>Daily Water Level 26/10/2026 – 11.00 AM</body></html>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });

      final service = DamScraperService(client: mockClient);

      // First call: hits network and populates cache
      final call1 = await service.fetchAllDams(forceRefresh: true);
      expect(call1.length, 37);
      expect(networkHits, 1);

      // Immediate second call with forceRefresh: true (within 10-minute cooldown)
      final call2 = await service.fetchAllDams(forceRefresh: true);
      expect(call2.length, 37);
      expect(networkHits, 1); // Enforced cooldown: zero network hit!
    });
  });
}
