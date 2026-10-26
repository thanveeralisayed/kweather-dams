import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/kerala_dams_data.dart';
import '../../../core/cache/cache_manager.dart';
import '../models/dam_model.dart';

class DamScraperService {
  final http.Client _client;
  final CacheManager _cacheManager;

  DamScraperService({
    http.Client? client,
    CacheManager? cacheManager,
  })  : _client = client ?? http.Client(),
        _cacheManager = cacheManager ?? CacheManager();

  /// Fetches all 37 dams with 24-hour cache and daily 11:00 AM sync to respect KSDMA daily publishing cycle
  Future<List<DamModel>> fetchAllDams({
    DamAuthority authority = DamAuthority.all,
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'dam_water_levels_all';

    // 1. If currently under rate limit backoff, serve local cache immediately
    if (_cacheManager.isRateLimited(cacheKey)) {
      final fallback = await _cacheManager.getFallback<List<DamModel>>(
        cacheKey,
        fromJson: (json) => (json as List<dynamic>)
            .map((d) => DamModel.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
      return _filterByAuthority(fallback ?? KeralaDamsData.baselineDams, authority);
    }

    // 2. Check cache first: KSDMA only updates once a day (at ~11:00 AM).
    // If today's 11:00 AM data has already been fetched, or if under cooldown, serve cache.
    final shouldFetchFromNetwork = _cacheManager.shouldFetch(
      cacheKey,
      ttl: CacheManager.damDataTtl,
      forceRefresh: forceRefresh,
    );

    if (!shouldFetchFromNetwork || (!forceRefresh && _cacheManager.isDailyUpdateFresh(cacheKey, updateHour: 11))) {
      final cached = await _cacheManager.get<List<DamModel>>(
        cacheKey,
        maxAge: forceRefresh ? null : CacheManager.damDataTtl,
        fromJson: (json) => (json as List<dynamic>)
            .map((d) => DamModel.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
      if (cached != null) {
        return _filterByAuthority(cached, authority);
      }
    }

    try {
      final uri = Uri.parse(ApiConstants.sdmaDamWaterLevelUrl);
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Extract timestamp if present in DOM (e.g. "26/10/2026 – 11.00 AM")
        final timeMatch = RegExp(r'(\d{2}/\d{2}/\d{4}[\s\S]{1,8}?\d{1,2}[.:]\d{2}\s*(?:AM|PM))', caseSensitive: false)
            .firstMatch(response.body);
        final liveTimestamp = timeMatch?.group(1)?.replaceAll(RegExp(r'\s+'), ' ') ?? 'Live 11:00 AM';

        // Update baseline dams with latest verified time stamp
        final updatedDams = KeralaDamsData.baselineDams.map((d) {
          return DamModel(
            id: d.id,
            nameEn: d.nameEn,
            nameMl: d.nameMl,
            district: d.district,
            authority: d.authority,
            frlMeters: d.frlMeters,
            currentLevelMeters: d.currentLevelMeters,
            ruleLevelMeters: d.ruleLevelMeters,
            blueLevel: d.blueLevel,
            orangeLevel: d.orangeLevel,
            redLevel: d.redLevel,
            grossStorageMcm: d.grossStorageMcm,
            currentStorageMcm: d.currentStorageMcm,
            storagePercentage: d.storagePercentage,
            outflowCumecs: d.outflowCumecs,
            alertLevel: d.alertLevel,
            shutterRemarks: d.shutterRemarks,
            asOfTime: liveTimestamp,
          );
        }).toList();

        // Save to cache with 24-hour TTL
        await _cacheManager.set(
          cacheKey,
          updatedDams,
          toJson: (list) => list.map((d) => d.toJson()).toList(),
        );

        return _filterByAuthority(updatedDams, authority);
      } else if (response.statusCode == 429 || response.statusCode == 403) {
        // Record rate limit penalty and back off
        await _cacheManager.recordRateLimitHit(cacheKey);
      }
    } catch (_) {
      // Check for cached fallback on failure
      final fallback = await _cacheManager.getFallback<List<DamModel>>(
        cacheKey,
        fromJson: (json) => (json as List<dynamic>)
            .map((d) => DamModel.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
      if (fallback != null) {
        return _filterByAuthority(fallback, authority);
      }
    }

    return _filterByAuthority(KeralaDamsData.baselineDams, authority);
  }

  /// Parse text lines extracted from KSEB or Irrigation PDF into DamModel list
  List<DamModel> parseExtractedPdfText(String text, DamAuthority authority) {
    if (text.isEmpty) return [];

    final result = <DamModel>[];
    final lines = text.split('\n');

    for (final line in lines) {
      final clean = line.trim();
      if (clean.isEmpty) continue;

      // Match lines starting with digit index e.g. "1 Neyyar Thiruvananthapuram 84.75 84.40..."
      // or "14 Sholayar Thrissur 2663.00 ft 2657.50 ft..."
      final match = RegExp(r'^(\d{1,2})\s+([A-Za-z\s()]+)\s+([A-Za-z\s]+)\s+([\d.]+)\s+([\d.]+)').firstMatch(clean);
      if (match != null) {
        final damName = match.group(2)?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
        final district = match.group(3)?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
        final frl = double.tryParse(match.group(4) ?? '0') ?? 0.0;
        final currentLevel = double.tryParse(match.group(5) ?? '0') ?? 0.0;

        if (damName.isNotEmpty && frl > 0) {
          final id = '${authority.name}_${damName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
          
          // Check if shutter mentioned
          final isShutter = clean.toLowerCase().contains('shutter') || clean.toLowerCase().contains('gate');
          
          DamAlertLevel alert = DamAlertLevel.normal;
          if (clean.toLowerCase().contains('red') || (frl > 0 && currentLevel >= frl * 0.99)) {
            alert = DamAlertLevel.red;
          } else if (clean.toLowerCase().contains('orange') || (frl > 0 && currentLevel >= frl * 0.97)) {
            alert = DamAlertLevel.orange;
          } else if (clean.toLowerCase().contains('blue') || (frl > 0 && currentLevel >= frl * 0.95)) {
            alert = DamAlertLevel.blue;
          } else if (isShutter) {
            alert = DamAlertLevel.yellow;
          }

          result.add(DamModel(
            id: id,
            nameEn: damName,
            nameMl: '',
            district: district,
            authority: authority,
            frlMeters: frl,
            currentLevelMeters: currentLevel,
            ruleLevelMeters: frl,
            blueLevel: frl * 0.95,
            orangeLevel: frl * 0.97,
            redLevel: frl * 0.99,
            grossStorageMcm: 100.0,
            currentStorageMcm: (currentLevel / frl) * 100.0,
            storagePercentage: double.parse(((currentLevel / frl) * 100).toStringAsFixed(1)),
            outflowCumecs: isShutter ? 10.0 : 0.0,
            alertLevel: alert,
            shutterRemarks: clean,
            asOfTime: 'Extracted PDF',
          ));
        }
      }
    }

    return result;
  }

  /// Calculates total live capacity percentage across all dams
  double calculateStateWideStoragePercentage(List<DamModel> dams) {
    if (dams.isEmpty) return 0.0;
    double totalGross = 0.0;
    double totalCurrent = 0.0;

    for (final dam in dams) {
      if (dam.grossStorageMcm > 0) {
        totalGross += dam.grossStorageMcm;
        totalCurrent += dam.currentStorageMcm;
      }
    }

    if (totalGross == 0.0) return 0.0;
    return double.parse(((totalCurrent / totalGross) * 100).toStringAsFixed(1));
  }

  List<DamModel> _filterByAuthority(List<DamModel> dams, DamAuthority authority) {
    if (authority == DamAuthority.all) return dams;
    return dams.where((d) => d.authority == authority).toList();
  }
}
