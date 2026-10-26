import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dam_model.dart';
import '../services/dam_scraper_service.dart';

enum DamSortOrder {
  storageDesc,
  storageAsc,
  nameAsc,
  outflowDesc,
}

final damScraperServiceProvider = Provider<DamScraperService>((ref) {
  return DamScraperService();
});

/// All dams fetched from SDMA
final allDamsFutureProvider = FutureProvider<List<DamModel>>((ref) async {
  final service = ref.watch(damScraperServiceProvider);
  return service.fetchAllDams(authority: DamAuthority.all);
});

/// Filter by DamAuthority (all, kseb, irrigation)
final selectedDamAuthorityProvider = StateProvider<DamAuthority>((ref) => DamAuthority.all);

/// Filter by district (null = all districts)
final selectedDamDistrictProvider = StateProvider<String?>((ref) => null);

/// Filter by alert level (null = all levels)
final selectedDamAlertLevelProvider = StateProvider<DamAlertLevel?>((ref) => null);

/// Sorting order
final damSortOrderProvider = StateProvider<DamSortOrder>((ref) => DamSortOrder.storageDesc);

/// Filtered and sorted dams list
final filteredDamsProvider = Provider<AsyncValue<List<DamModel>>>((ref) {
  final damsAsync = ref.watch(allDamsFutureProvider);
  final authority = ref.watch(selectedDamAuthorityProvider);
  final district = ref.watch(selectedDamDistrictProvider);
  final alertLevel = ref.watch(selectedDamAlertLevelProvider);
  final sortOrder = ref.watch(damSortOrderProvider);

  return damsAsync.whenData((dams) {
    var result = dams.where((dam) {
      final matchesAuthority = authority == DamAuthority.all || dam.authority == authority;
      final matchesDistrict = district == null || dam.district.toLowerCase() == district.toLowerCase();
      final matchesAlert = alertLevel == null || dam.alertLevel == alertLevel;
      return matchesAuthority && matchesDistrict && matchesAlert;
    }).toList();

    switch (sortOrder) {
      case DamSortOrder.storageDesc:
        result.sort((a, b) => b.storagePercentage.compareTo(a.storagePercentage));
        break;
      case DamSortOrder.storageAsc:
        result.sort((a, b) => a.storagePercentage.compareTo(b.storagePercentage));
        break;
      case DamSortOrder.nameAsc:
        result.sort((a, b) => a.nameEn.compareTo(b.nameEn));
        break;
      case DamSortOrder.outflowDesc:
        result.sort((a, b) => b.outflowCumecs.compareTo(a.outflowCumecs));
        break;
    }

    return result;
  });
});

/// Statewide average storage % across all reservoirs
final stateWideDamStoragePercentageProvider = Provider<double>((ref) {
  final damsAsync = ref.watch(allDamsFutureProvider);
  final service = ref.watch(damScraperServiceProvider);

  return damsAsync.when(
    data: (dams) => service.calculateStateWideStoragePercentage(dams),
    loading: () => 74.5,
    error: (_, stackTrace) => 74.5,
  );
});

/// List of dams with open shutters or controlled release
final damsWithOpenShuttersProvider = Provider<List<DamModel>>((ref) {
  final damsAsync = ref.watch(allDamsFutureProvider);
  return damsAsync.maybeWhen(
    data: (dams) => dams.where((d) => d.isShutterOpen).toList(),
    orElse: () => [],
  );
});

/// Selected dam for modal view
final selectedDamIdProvider = StateProvider<String?>((ref) => null);
