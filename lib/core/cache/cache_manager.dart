import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory and persistent caching layer designed to prevent triggering rate limiting
/// on IMD and KSDMA government servers.
class CacheManager {
  static CacheManager? _instance;
  SharedPreferences? _prefs;

  // In-memory cache for fast, zero-IO instant lookups
  final Map<String, _MemoryEntry> _memoryCache = {};

  CacheManager._({this._prefs});

  /// Factory constructor providing singleton or injected SharedPreferences (for testing)
  factory CacheManager({SharedPreferences? prefs}) {
    if (prefs != null) {
      return CacheManager._(prefs: prefs);
    }
    _instance ??= CacheManager._();
    return _instance!;
  }

  /// Initialize SharedPreferences if not already initialized
  Future<void> init() async {
    if (_prefs == null) {
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (_) {
        // Fallback to in-memory only in test or unsupported environments
      }
    }
  }

  /// Default Recommended TTLs (aligned with IMD & SDMA publication cycles):
  /// - Dams: 24 hours (KSDMA publishes once a day at 11:00 AM)
  /// - Weather Station Forecast: 12 hours (IMD forecasts update twice a day: 08:30 & 17:30 IST)
  /// - Bulletins (Ports, Sabarimala, QPF): 24 hours (Daily publication cycle)
  /// - Nowcast Thunderstorm Alerts: 3 hours (3-hr validity warnings)
  static const Duration damDataTtl = Duration(hours: 24);
  static const Duration weatherForecastTtl = Duration(hours: 12);
  static const Duration bulletinsTtl = Duration(hours: 24);
  static const Duration nowcastTtl = Duration(hours: 3);

  /// Minimum cooldown between live network hits for a specific key (prevents refresh hammering)
  static const Duration minRequestCooldown = Duration(minutes: 10);

  /// In-memory rate limiting backoff tracking
  final Map<String, DateTime> _rateLimitBackoffs = {};

  /// Check whether a network request should be executed or served from cache
  bool shouldFetch(String key, {Duration ttl = const Duration(hours: 12), bool forceRefresh = false}) {
    // 1. If currently under active rate limiting backoff, never fetch
    if (isRateLimited(key)) return false;

    final lastFetch = getLastFetchTime(key);
    if (lastFetch == null) return true;

    final age = DateTime.now().difference(lastFetch);

    // If forceRefresh requested, enforce minimum anti-hammering cooldown
    if (forceRefresh) {
      return age >= minRequestCooldown;
    }

    return age >= ttl;
  }

  /// Check if data that updates once a day (e.g., at 11:00 AM for Kerala Dams) is fresh.
  /// If today's 11:00 AM bulletin has already been fetched, no network calls are needed until tomorrow 11:00 AM.
  bool isDailyUpdateFresh(String key, {int updateHour = 11, int updateMinute = 0}) {
    if (isRateLimited(key)) return true;

    final lastFetch = getLastFetchTime(key);
    if (lastFetch == null) return false;

    final now = DateTime.now();
    DateTime lastPublishTime = DateTime(now.year, now.month, now.day, updateHour, updateMinute);
    if (now.isBefore(lastPublishTime)) {
      // Current time is before today's publishing window, so latest publication was yesterday
      lastPublishTime = lastPublishTime.subtract(const Duration(days: 1));
    }

    return lastFetch.isAfter(lastPublishTime);
  }

  /// Record a rate limiting event (HTTP 429 / 403) from a government server and trigger backoff
  Future<void> recordRateLimitHit(String key, {Duration backoffDuration = const Duration(hours: 2)}) async {
    final backoffExpiry = DateTime.now().add(backoffDuration);
    _rateLimitBackoffs[key] = backoffExpiry;
    await init();
    await _prefs?.setString('${key}_ratelimit_expiry', backoffExpiry.toIso8601String());
  }

  /// Check if a key is currently under rate limiting backoff
  bool isRateLimited(String key) {
    final now = DateTime.now();
    if (_rateLimitBackoffs.containsKey(key)) {
      if (now.isBefore(_rateLimitBackoffs[key]!)) {
        return true;
      } else {
        _rateLimitBackoffs.remove(key);
      }
    }
    final storedExpiry = _prefs?.getString('${key}_ratelimit_expiry');
    if (storedExpiry != null) {
      final expiry = DateTime.tryParse(storedExpiry);
      if (expiry != null && now.isBefore(expiry)) {
        return true;
      }
    }
    return false;
  }

  /// Get last fetch timestamp for a given key
  DateTime? getLastFetchTime(String key) {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key]!.timestamp;
    }
    final storedTime = _prefs?.getString('${key}_timestamp');
    if (storedTime != null) {
      return DateTime.tryParse(storedTime);
    }
    return null;
  }

  /// Retrieve cached data if valid and within maxAge
  Future<T?> get<T>(
    String key, {
    Duration? maxAge,
    T Function(dynamic json)? fromJson,
  }) async {
    final now = DateTime.now();

    // 1. Check in-memory cache first
    if (_memoryCache.containsKey(key)) {
      final entry = _memoryCache[key]!;
      if (maxAge == null || now.difference(entry.timestamp) <= maxAge) {
        if (entry.data is T) return entry.data as T;
        if (fromJson != null) {
          try {
            return fromJson(entry.data);
          } catch (_) {}
        }
      }
    }

    // 2. Check persistent SharedPreferences
    await init();
    final jsonStr = _prefs?.getString('${key}_data');
    final timeStr = _prefs?.getString('${key}_timestamp');

    if (jsonStr != null && timeStr != null) {
      final timestamp = DateTime.tryParse(timeStr) ?? now;
      if (maxAge == null || now.difference(timestamp) <= maxAge) {
        try {
          final decoded = jsonDecode(jsonStr);
          // Populate in-memory cache
          _memoryCache[key] = _MemoryEntry(data: decoded, timestamp: timestamp);

          if (fromJson != null) {
            return fromJson(decoded);
          }
          if (decoded is T) return decoded;
        } catch (_) {}
      }
    }

    return null;
  }

  /// Retrieve latest cached data regardless of expiration (for offline fallback during network errors)
  Future<T?> getFallback<T>(
    String key, {
    T Function(dynamic json)? fromJson,
  }) async {
    return get<T>(key, maxAge: null, fromJson: fromJson);
  }

  /// Save data to both in-memory cache and persistent disk
  Future<void> set<T>(
    String key,
    T value, {
    dynamic Function(T value)? toJson,
  }) async {
    final now = DateTime.now();
    final dynamic serialized = toJson != null ? toJson(value) : value;

    // 1. Save to in-memory
    _memoryCache[key] = _MemoryEntry(data: serialized, timestamp: now);

    // 2. Save to persistent SharedPreferences
    await init();
    if (_prefs != null) {
      try {
        final jsonString = jsonEncode(serialized);
        await _prefs!.setString('${key}_data', jsonString);
        await _prefs!.setString('${key}_timestamp', now.toIso8601String());
      } catch (_) {
        // Safe to ignore disk serialize failures in constrained environments
      }
    }
  }

  /// Clear specific cache key
  Future<void> clear(String key) async {
    _memoryCache.remove(key);
    _rateLimitBackoffs.remove(key);
    await init();
    await _prefs?.remove('${key}_data');
    await _prefs?.remove('${key}_timestamp');
    await _prefs?.remove('${key}_ratelimit_expiry');
  }

  /// Clear all cache
  Future<void> clearAll() async {
    _memoryCache.clear();
    _rateLimitBackoffs.clear();
    await init();
    await _prefs?.clear();
  }
}

class _MemoryEntry {
  final dynamic data;
  final DateTime timestamp;

  _MemoryEntry({required this.data, required this.timestamp});
}
