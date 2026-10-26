import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

import 'package:kweather/features/weather/models/weather_station.dart';
import 'package:kweather/features/weather/models/current_observation.dart';
import 'package:kweather/features/weather/models/daily_forecast.dart';
import 'package:kweather/features/weather/models/nowcast_alert.dart';
import 'package:kweather/features/weather/models/station_weather.dart';
import 'package:kweather/features/weather/services/nowcast_parser.dart';
import 'package:kweather/features/weather/services/weather_api_service.dart';
import 'package:kweather/core/constants/kerala_stations_data.dart';
import 'package:kweather/core/cache/cache_manager.dart';

void main() {
  setUp(() async {
    await CacheManager().clearAll();
  });

  group('Phase 1: Weather Station Model Tests', () {
    test('WeatherStation parses fromJson correctly with aliases', () {
      final json = {
        'station_id': '43371',
        'station': 'Thiruvananthapuram-City',
        'district': 'Thiruvananthapuram',
        'region': 'south',
        'lat': '8.48',
        'lon': '76.95',
      };
      final station = WeatherStation.fromJson(json);
      expect(station.id, '43371');
      expect(station.nameEn, 'Thiruvananthapuram-City');
      expect(station.district, 'Thiruvananthapuram');
      expect(station.region, StationRegion.south);
      expect(station.latitude, 8.48);
      expect(station.longitude, 76.95);
    });

    test('WeatherStation localizedName returns Malayalam when enabled', () {
      const station = WeatherStation(
        id: '43353',
        nameEn: 'Kochi',
        nameMl: 'കൊച്ചി',
        district: 'Ernakulam',
        region: StationRegion.central,
        latitude: 9.94,
        longitude: 76.27,
      );

      expect(station.localizedName(true), 'കൊച്ചി');
      expect(station.localizedName(false), 'Kochi');
    });

    test('WeatherStation equality based on ID', () {
      const s1 = WeatherStation(
        id: '43371',
        nameEn: 'City 1',
        nameMl: '1',
        district: 'D',
        region: StationRegion.south,
        latitude: 0,
        longitude: 0,
      );
      const s2 = WeatherStation(
        id: '43371',
        nameEn: 'City 2',
        nameMl: '2',
        district: 'D',
        region: StationRegion.north,
        latitude: 1,
        longitude: 1,
      );
      expect(s1, equals(s2));
    });
  });

  group('Phase 1: CurrentObservation Model Edge Cases', () {
    test('Parses complete IMD JSON payload', () {
      final json = {
        'dat': '2026-10-26',
        'updat': '2026-10-26 13:54:31',
        'max': '32.0',
        'min': '24.6',
        'maxdep': '0.8',
        'mindep': '-1.2',
        'rainfall': '26.00',
        'rh0830': '96',
        'rh1730': '75',
        'sunrise': '06:10',
        'sunset': '18:02',
        'moonrise': '18:07',
        'moonset': '06:00',
        'forecast0': 'Generally cloudy sky',
        'img0': '15',
      };

      final obs = CurrentObservation.fromImdJson(json);
      expect(obs.maxTemp, 32.0);
      expect(obs.minTemp, 24.6);
      expect(obs.maxTempDeviation, 0.8);
      expect(obs.minTempDeviation, -1.2);
      expect(obs.rainfall24h, 26.0);
      expect(obs.humidityMorning, 96);
      expect(obs.humidityEvening, 75);
      expect(obs.sunrise, '06:10');
      expect(obs.sunset, '18:02');
      expect(obs.conditionSummary, 'Generally cloudy sky');
    });

    test('Handles missing, null, and NA edge cases safely', () {
      final json = {
        'dat': null,
        'max': 'NA',
        'min': null,
        'maxdep': 'NA',
        'mindep': '',
        'rainfall': null,
        'rh0830': 'NA',
        'rh1730': null,
      };

      final obs = CurrentObservation.fromImdJson(json);
      expect(obs.maxTemp, 28.0); // fallback default
      expect(obs.minTemp, 23.0); // fallback default
      expect(obs.maxTempDeviation, isNull);
      expect(obs.minTempDeviation, isNull);
      expect(obs.rainfall24h, 0.0);
      expect(obs.humidityMorning, 0);
      expect(obs.humidityEvening, 0);
      expect(obs.sunrise, '--:--');
    });
  });

  group('Phase 1: DailyForecast Model Edge Cases', () {
    test('Parses warning severity levels correctly', () {
      final date = DateTime(2026, 10, 26);
      
      final redJson = {'color0': 'red', 'warning0': 'Extremely Heavy Rain', 'max0': '30', 'min0': '23'};
      final fRed = DailyForecast.fromImdIndex(redJson, 0, date);
      expect(fRed.warningSeverity, WarningSeverity.red);

      final orangeJson = {'color0': 'orange', 'warning0': 'Very Heavy Rain', 'max0': '30', 'min0': '23'};
      final fOrange = DailyForecast.fromImdIndex(orangeJson, 0, date);
      expect(fOrange.warningSeverity, WarningSeverity.orange);

      final yellowJson = {'color0': 'yellow', 'warning0': 'Heavy Rain', 'max0': '30', 'min0': '23'};
      final fYellow = DailyForecast.fromImdIndex(yellowJson, 0, date);
      expect(fYellow.warningSeverity, WarningSeverity.yellow);

      final greenJson = {'color0': 'green', 'warning0': 'No Warning', 'max0': '30', 'min0': '23'};
      final fGreen = DailyForecast.fromImdIndex(greenJson, 0, date);
      expect(fGreen.warningSeverity, WarningSeverity.green);
    });

    test('Parses array format (fmax, fmin, wColor, wText)', () {
      final date = DateTime(2026, 10, 26);
      final json = {
        'fmax': ['32.0', '31.0', '30.0'],
        'fmin': ['23.0', '24.0', '24.0'],
        'ffc': ['Rain spells', 'Thunderstorm', 'Partly cloudy'],
        'fimg': ['15', '14', '13'],
        'wColor': ['yellow', 'green', 'green'],
        'wText': ['Heavy Rain Alert', 'No warning', 'No warning'],
      };

      final f0 = DailyForecast.fromImdIndex(json, 0, date);
      expect(f0.dayName, 'Today');
      expect(f0.maxTemp, 32.0);
      expect(f0.summary, 'Rain spells');
      expect(f0.warningSeverity, WarningSeverity.yellow);

      final f1 = DailyForecast.fromImdIndex(json, 1, date);
      expect(f1.dayName, 'Tomorrow');
      expect(f1.maxTemp, 31.0);
      expect(f1.warningSeverity, WarningSeverity.green);
    });
  });

  group('Phase 1: Nowcast Alert & Parser Edge Cases', () {
    test('NowcastAlert parses rain, wind, and thunderstorm correctly', () {
      final json = {
        'title': 'Kochi',
        'latitude': '9.9312',
        'longitude': '76.2673',
        'imageURL': 'nowcast_marker/map-marker-icon-png-yellow.png',
        'description': '<p>Light Thunderstorms with maximum surface wind speed less than 40 kmph </br>Moderate rain: 5-15 mm/hr</br> Time of issue: 2026-10-26 2200 Hrs</br> Valid upto: 0100 Hrs </p>',
      };

      final alert = NowcastAlert.fromMapJson(json);
      expect(alert.stationName, 'Kochi');
      expect(alert.latitude, 9.9312);
      expect(alert.longitude, 76.2673);
      expect(alert.severity, WarningSeverity.yellow);
      expect(alert.hasThunderstorm, isTrue);
      expect(alert.rainIntensity.contains('Moderate rain'), isTrue);
      expect(alert.timeOfIssue.contains('2200 Hrs'), isTrue);
      expect(alert.validUpto.contains('0100 Hrs'), isTrue);
    });

    test('NowcastParser extracts items from HTML script tag', () {
      const html = '''
      <html><body><script>
      var countrydataprovider = {
        "images": [
          {
            "imageURL": "nowcast_marker/map-marker-icon-png-yellow.png",
            "title": "Alappuzha",
            "latitude": "9.498067",
            "longitude": "76.338848",
            "description": "Moderate rain: 5-15 mm/hr Time of issue: 2026-10-26 2200 Hrs Valid upto: 0100 Hrs"
          },
          {
            "imageURL": "nowcast_marker/map-marker-icon-png-green.png",
            "title": "Thrissur",
            "latitude": "10.527642",
            "longitude": "76.214435",
            "description": "No Warning Time of issue: 2026-10-26 2200 Hrs Valid upto: 0100 Hrs"
          }
        ]
      };
      </script></body></html>
      ''';

      final parser = NowcastParser();
      final alerts = parser.parseHtml(html);
      expect(alerts.length, 2);
      expect(alerts[0].stationName, 'Alappuzha');
      expect(alerts[0].severity, WarningSeverity.yellow);
      expect(alerts[1].stationName, 'Thrissur');
      expect(alerts[1].severity, WarningSeverity.green);
    });

    test('NowcastParser handles empty, malformed, or missing script gracefully', () {
      final parser = NowcastParser();
      expect(parser.parseHtml(''), isEmpty);
      expect(parser.parseHtml('<html><body>No data here</body></html>'), isEmpty);
    });
  });

  group('Phase 1: WeatherApiService with Mock Client', () {
    test('fetchStationWeather parses response on 200 OK', () async {
      final mockClient = MockClient((request) async {
        final mockResponse = [
          {
            'station_id': '43371',
            'station': 'Thiruvananthapuram-City',
            'dat': '2026-10-26',
            'updat': '2026-10-26 13:54:31',
            'max': '32.0',
            'min': '24.6',
            'rainfall': '26.00',
            'rh0830': '96',
            'rh1730': '75',
            'sunrise': '06:10',
            'sunset': '18:02',
            'moonrise': '18:07',
            'moonset': '06:00',
            'forecast0': 'Generally cloudy sky',
            'max0': '32.0',
            'min0': '23.0',
            'img0': '15',
            'color0': '1',
            'warning0': 'Heavy Rain',
          }
        ];
        return http.Response(jsonEncode(mockResponse), 200, headers: {'content-type': 'application/json'});
      });

      final service = WeatherApiService(client: mockClient);
      final station = KeralaStationsData.defaultStations.first;
      final result = await service.fetchStationWeather(station);

      expect(result.station.id, '43371');
      expect(result.current.maxTemp, 32.0);
      expect(result.current.rainfall24h, 26.0);
      expect(result.forecasts.length, 7);
      expect(result.forecasts[0].warningSeverity, WarningSeverity.yellow);
    });

    test('fetchStationWeather handles error with offline fallback without throwing', () async {
      await CacheManager().clearAll();
      final mockClient = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final service = WeatherApiService(client: mockClient);
      final station = KeralaStationsData.defaultStations.first;
      final StationWeather result = await service.fetchStationWeather(station, forceRefresh: true);

      expect(result.station.id, '43371');
      expect(result.current.updatedAt, 'Offline Mode');
      expect(result.forecasts.length, 7);
    });

    test('searchStations filters local list instantly', () async {
      final service = WeatherApiService();
      final results = await service.searchStations('Munnar');
      expect(results.length, 1);
      expect(results.first.nameEn, 'Munnar');
    });

    test('searchStations supports Malayalam search', () async {
      final service = WeatherApiService();
      final results = await service.searchStations('കൊച്ചി');
      expect(results.length, 1);
      expect(results.first.nameEn, 'Kochi');
    });

    test('fetchStationWeather handles HTTP 429 and triggers rate limit backoff', () async {
      await CacheManager().clearAll();
      int networkHits = 0;
      final station = KeralaStationsData.defaultStations.first;

      final mockClient = MockClient((request) async {
        networkHits++;
        return http.Response('Too Many Requests', 429);
      });

      final service = WeatherApiService(client: mockClient);
      final result = await service.fetchStationWeather(station, forceRefresh: true);

      // Must return fallback safely without throwing
      expect(result.station.id, station.id);
      expect(networkHits, 1);
      expect(CacheManager().isRateLimited('weather_station_${station.id}'), isTrue);

      // Subsequent call while rate limited must bypass network completely
      final secondResult = await service.fetchStationWeather(station, forceRefresh: true);
      expect(secondResult.station.id, station.id);
      expect(networkHits, 1); // 0 additional network calls
    });

    test('fetchStationWeather enforces 10-minute cooldown on repeated forceRefresh', () async {
      await CacheManager().clearAll();
      int networkHits = 0;
      final station = KeralaStationsData.defaultStations.first;

      final mockClient = MockClient((request) async {
        networkHits++;
        return http.Response(jsonEncode([{
          'station_id': station.id,
          'station': station.nameEn,
          'dat': '2026-10-26',
          'updat': '2026-10-26 13:54:31',
          'max': '31.0',
          'min': '23.0',
          'rainfall': '0.0',
          'rh0830': '80',
          'rh1730': '70',
          'forecast0': 'Partly cloudy',
          'img0': '15',
          'wColor': ['green'],
          'wText': ['Normal'],
        }]), 200, headers: {'content-type': 'application/json'});
      });

      final service = WeatherApiService(client: mockClient);

      // Call 1: fresh fetch hits network
      final r1 = await service.fetchStationWeather(station, forceRefresh: true);
      expect(r1.station.id, station.id);
      expect(networkHits, 1);

      // Call 2: repeated forceRefresh within 10-minute cooldown window
      final r2 = await service.fetchStationWeather(station, forceRefresh: true);
      expect(r2.station.id, station.id);
      expect(networkHits, 1); // Strict cooldown: 0 network hit!
    });

    test('fetchNowcastAlerts handles HTTP 429 and triggers rate limit backoff', () async {
      await CacheManager().clearAll();
      int networkHits = 0;

      final mockClient = MockClient((request) async {
        networkHits++;
        return http.Response('Too Many Requests', 429);
      });

      final service = WeatherApiService(client: mockClient);
      final alerts = await service.fetchNowcastAlerts(forceRefresh: true);

      expect(alerts, isEmpty);
      expect(networkHits, 1);
      expect(CacheManager().isRateLimited('nowcast_alerts_list'), isTrue);

      // Second call during backoff
      final secondAlerts = await service.fetchNowcastAlerts(forceRefresh: true);
      expect(secondAlerts, isEmpty);
      expect(networkHits, 1); // No new network call
    });

    test('fetchNowcastAlerts enforces 10-minute cooldown on forceRefresh', () async {
      await CacheManager().clearAll();
      int networkHits = 0;

      final mockClient = MockClient((request) async {
        networkHits++;
        const sampleHtml = '''
        <html><body><script>
        var countrydataprovider = {
          "images": [
            {
              "imageURL": "nowcast_marker/map-marker-icon-png-yellow.png",
              "title": "Kollam",
              "latitude": "8.8932",
              "longitude": "76.6141",
              "description": "Light rain Time of issue: 2026-10-26 2200 Hrs Valid upto: 0100 Hrs"
            }
          ]
        };
        </script></body></html>
        ''';
        return http.Response(sampleHtml, 200, headers: {'content-type': 'text/html'});
      });

      final service = WeatherApiService(client: mockClient);

      final a1 = await service.fetchNowcastAlerts(forceRefresh: true);
      expect(a1.length, 1);
      expect(networkHits, 1);

      // Immediate forceRefresh within 10 min
      final a2 = await service.fetchNowcastAlerts(forceRefresh: true);
      expect(a2.length, 1);
      expect(networkHits, 1); // Cooldown preserved
    });
  });
}
