import 'package:flutter_test/flutter_test.dart';
import 'package:kweather/core/cache/cache_manager.dart';

void main() {
  group('CacheManager & Anti-Rate-Limiting Tests', () {
    late CacheManager cache;

    setUp(() {
      cache = CacheManager();
    });

    test('CacheManager sets and gets in-memory data within TTL', () async {
      await cache.set('test_key', {'temp': 29.5, 'station': 'Kochi'});

      final data = await cache.get<Map<String, dynamic>>(
        'test_key',
        maxAge: const Duration(hours: 4),
      );

      expect(data, isNotNull);
      expect(data!['temp'], 29.5);
      expect(data['station'], 'Kochi');
    });

    test('CacheManager expires data when maxAge is exceeded', () async {
      await cache.set('quick_key', 'value_1');
      await Future.delayed(const Duration(milliseconds: 5));

      // Query with 1 millisecond maxAge (expired)
      final expired = await cache.get<String>(
        'quick_key',
        maxAge: const Duration(milliseconds: 1),
      );

      expect(expired, isNull);

      // But getFallback still retrieves it to protect against network failures
      final fallback = await cache.getFallback<String>('quick_key');
      expect(fallback, 'value_1');
    });

    test('shouldFetch enforces minimum 10-minute cooldown against rapid spam', () async {
      await cache.set('freq_key', 'data');

      // Immediately after setting, shouldFetch is false
      expect(cache.shouldFetch('freq_key', ttl: const Duration(hours: 12)), isFalse);

      // Even if forceRefresh is requested, shouldFetch enforces minimum 10-minute cooldown
      expect(cache.shouldFetch('freq_key', ttl: const Duration(hours: 12), forceRefresh: true), isFalse);
    });

    test('shouldFetch returns true for un-cached keys', () {
      expect(cache.shouldFetch('never_cached_key'), isTrue);
    });

    test('Dam TTL is 24 hours and Weather Forecast TTL is 12 hours', () {
      expect(CacheManager.damDataTtl.inHours, 24);
      expect(CacheManager.weatherForecastTtl.inHours, 12);
      expect(CacheManager.bulletinsTtl.inHours, 24);
      expect(CacheManager.nowcastTtl.inHours, 3);
      expect(CacheManager.minRequestCooldown.inMinutes, 10);
    });

    test('Rate limiting backoff blocks shouldFetch and isRateLimited reports true', () async {
      const key = 'throttled_endpoint';
      expect(cache.isRateLimited(key), isFalse);

      // Trigger rate limit hit (e.g. HTTP 429 received from IMD)
      await cache.recordRateLimitHit(key, backoffDuration: const Duration(hours: 2));

      expect(cache.isRateLimited(key), isTrue);
      // shouldFetch must strictly return false under rate limiting backoff
      expect(cache.shouldFetch(key, forceRefresh: true), isFalse);
    });

    test('isDailyUpdateFresh correctly tracks daily publishing cycle', () async {
      const damKey = 'dam_water_levels_all';
      // Prior to setting, not fresh
      expect(cache.isDailyUpdateFresh(damKey, updateHour: 11), isFalse);

      await cache.set(damKey, 'fresh_dam_data');
      // After setting right now, it is fresh
      expect(cache.isDailyUpdateFresh(damKey, updateHour: 11), isTrue);
    });

    test('CacheManager clears specific key and all keys', () async {
      await cache.set('key_a', 'val_a');
      await cache.set('key_b', 'val_b');

      await cache.clear('key_a');
      expect(await cache.get<String>('key_a'), isNull);
      expect(await cache.get<String>('key_b'), 'val_b');

      await cache.clearAll();
      expect(await cache.get<String>('key_b'), isNull);
    });
  });
}
