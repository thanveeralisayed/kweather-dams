import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/kerala_stations_data.dart';
import '../models/weather_station.dart';
import '../models/station_weather.dart';
import '../models/nowcast_alert.dart';
import 'nowcast_parser.dart';

import '../../../core/cache/cache_manager.dart';

class WeatherApiService {
  final http.Client _client;
  final NowcastParser _nowcastParser;
  final CacheManager _cacheManager;

  WeatherApiService({
    http.Client? client,
    NowcastParser? nowcastParser,
    CacheManager? cacheManager,
  })  : _client = client ?? http.Client(),
        _nowcastParser = nowcastParser ?? const NowcastParser(),
        _cacheManager = cacheManager ?? CacheManager();

  /// Fetch full weather details (current + 7-day forecast) with multi-hour caching
  Future<StationWeather> fetchStationWeather(WeatherStation station, {bool forceRefresh = false}) async {
    final cacheKey = 'weather_station_${station.id}';

    // 1. If currently under rate limit backoff, serve local cache immediately
    if (_cacheManager.isRateLimited(cacheKey)) {
      final fallback = await _cacheManager.getFallback<StationWeather>(
        cacheKey,
        fromJson: (json) => StationWeather.fromJson(json as Map<String, dynamic>),
      );
      return fallback ?? _generateOfflineFallback(station, 'Rate limit backoff active');
    }

    // 2. Check cache first to avoid triggering IMD rate limiting
    final shouldFetchFromNetwork = _cacheManager.shouldFetch(
      cacheKey,
      ttl: CacheManager.weatherForecastTtl,
      forceRefresh: forceRefresh,
    );

    if (!shouldFetchFromNetwork) {
      final cached = await _cacheManager.get<StationWeather>(
        cacheKey,
        maxAge: forceRefresh ? null : CacheManager.weatherForecastTtl,
        fromJson: (json) => StationWeather.fromJson(json as Map<String, dynamic>),
      );
      if (cached != null) {
        return cached;
      }
    }

    final uri = Uri.parse(ApiConstants.imdFetchCityStatic);

    // Build multipart boundary for ID=<station_id>
    const boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
    final body = '--$boundary\r\nContent-Disposition: form-data; name="ID"\r\n\r\n${station.id}\r\n--$boundary--\r\n';

    final headers = Map<String, String>.from(ApiConstants.imdHeaders);
    headers['Content-Type'] = 'multipart/form-data; boundary=$boundary';

    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        Map<String, dynamic>? data;
        if (decoded is List && decoded.isNotEmpty) {
          data = decoded[0] as Map<String, dynamic>;
        } else if (decoded is Map<String, dynamic>) {
          data = decoded;
        }

        if (data != null) {
          final result = StationWeather.fromImdJson(
            station: station,
            json: data,
          );
          // Save to persistent cache (12-hour validity)
          await _cacheManager.set(
            cacheKey,
            result,
            toJson: (s) => s.toJson(),
          );
          return result;
        }
      } else if (response.statusCode == 429 || response.statusCode == 403) {
        await _cacheManager.recordRateLimitHit(cacheKey);
      }
      throw Exception('Server returned status code ${response.statusCode}');
    } catch (e) {
      // Check for cached fallback during network failure
      final fallback = await _cacheManager.getFallback<StationWeather>(
        cacheKey,
        fromJson: (json) => StationWeather.fromJson(json as Map<String, dynamic>),
      );
      if (fallback != null) {
        return fallback;
      }
      return _generateOfflineFallback(station, e.toString());
    }
  }

  /// Fetch real-time 3-hour nowcast severe weather alerts with caching
  Future<List<NowcastAlert>> fetchNowcastAlerts({bool forceRefresh = false}) async {
    const cacheKey = 'nowcast_alerts_list';

    // 1. If currently under rate limit backoff, return fallback
    if (_cacheManager.isRateLimited(cacheKey)) {
      final fallback = await _cacheManager.getFallback<List<NowcastAlert>>(
        cacheKey,
        fromJson: (json) => (json as List<dynamic>)
            .map((i) => NowcastAlert.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
      return fallback ?? [];
    }

    // 2. Check cache first
    final shouldFetchFromNetwork = _cacheManager.shouldFetch(
      cacheKey,
      ttl: CacheManager.nowcastTtl,
      forceRefresh: forceRefresh,
    );

    if (!shouldFetchFromNetwork) {
      final cached = await _cacheManager.get<List<NowcastAlert>>(
        cacheKey,
        maxAge: forceRefresh ? null : CacheManager.nowcastTtl,
        fromJson: (json) => (json as List<dynamic>)
            .map((i) => NowcastAlert.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
      if (cached != null) {
        return cached;
      }
    }

    final uri = Uri.parse(ApiConstants.imdNowcastUrl);

    try {
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final alerts = _nowcastParser.parseHtml(response.body);
        if (alerts.isNotEmpty) {
          await _cacheManager.set(
            cacheKey,
            alerts,
            toJson: (list) => list.map((a) => a.toJson()).toList(),
          );
        }
        return alerts;
      } else if (response.statusCode == 429 || response.statusCode == 403) {
        await _cacheManager.recordRateLimitHit(cacheKey);
      }
    } catch (_) {}

    // Fallback cache on failure
    final fallback = await _cacheManager.getFallback<List<NowcastAlert>>(
      cacheKey,
      fromJson: (json) => (json as List<dynamic>)
          .map((i) => NowcastAlert.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
    return fallback ?? [];
  }

  /// Search stations matching query string
  Future<List<WeatherStation>> searchStations(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) {
      return KeralaStationsData.defaultStations;
    }

    // First filter local catalog for instant response
    final localMatches = KeralaStationsData.defaultStations.where((s) {
      return s.nameEn.toLowerCase().contains(clean) ||
             s.nameMl.contains(clean) ||
             s.district.toLowerCase().contains(clean);
    }).toList();

    if (localMatches.isNotEmpty) {
      return localMatches;
    }

    // Query IMD search endpoint as fallback
    try {
      final uri = Uri.parse('${ApiConstants.imdSearchApi}?query=${Uri.encodeComponent(query)}');
      final response = await _client.get(uri, headers: ApiConstants.imdHeaders).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          final list = decoded['data'] as List;
          return list.map((item) {
            return WeatherStation(
              id: item['station_id']?.toString() ?? '',
              nameEn: item['station']?.toString() ?? '',
              nameMl: '',
              district: '',
              region: StationRegion.central,
              latitude: 10.0,
              longitude: 76.5,
            );
          }).toList();
        }
      }
    } catch (_) {}

    return localMatches;
  }

  StationWeather _generateOfflineFallback(WeatherStation station, String errorMsg) {
    final now = DateTime.now();
    return StationWeather.fromImdJson(
      station: station,
      json: {
        'station_id': station.id,
        'station': station.nameEn,
        'dat': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'updat': 'Offline Mode',
        'max': '30.0',
        'min': '24.0',
        'rainfall': '0.0',
        'rh0830': '80',
        'rh1730': '75',
        'forecast0': 'Cloudy with isolated showers (Cached)',
        'img0': '15',
        'wColor': ['green', 'green', 'green', 'green', 'green', 'green', 'green'],
        'wText': ['Offline mode: Check internet connection'],
      },
    );
  }
}
