import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/kerala_stations_data.dart';
import '../models/weather_station.dart';
import '../models/station_weather.dart';
import '../models/nowcast_alert.dart';
import '../services/weather_api_service.dart';

final weatherApiServiceProvider = Provider<WeatherApiService>((ref) {
  return WeatherApiService();
});

/// Currently selected weather station (defaults to Thiruvananthapuram City)
final selectedStationProvider = StateProvider<WeatherStation>((ref) {
  return KeralaStationsData.defaultStations.first;
});

/// All known Kerala weather stations
final allStationsProvider = Provider<List<WeatherStation>>((ref) {
  return KeralaStationsData.defaultStations;
});

/// Search query string
final stationSearchQueryProvider = StateProvider<String>((ref) => '');

/// Selected region filter for station search
final selectedRegionFilterProvider = StateProvider<StationRegion?>((ref) => null);

/// Filtered stations list based on search and region
final filteredStationsProvider = Provider<List<WeatherStation>>((ref) {
  final query = ref.watch(stationSearchQueryProvider).trim().toLowerCase();
  final regionFilter = ref.watch(selectedRegionFilterProvider);
  final all = ref.watch(allStationsProvider);

  return all.where((s) {
    final matchesQuery = query.isEmpty ||
        s.nameEn.toLowerCase().contains(query) ||
        s.nameMl.contains(query) ||
        s.district.toLowerCase().contains(query);

    final matchesRegion = regionFilter == null || s.region == regionFilter;

    return matchesQuery && matchesRegion;
  }).toList();
});

/// Real-time 3-Hour Nowcast Alerts
final nowcastAlertsProvider = FutureProvider<List<NowcastAlert>>((ref) async {
  final service = ref.watch(weatherApiServiceProvider);
  return service.fetchNowcastAlerts();
});

/// Weather for the currently selected station
final stationWeatherProvider = FutureProvider<StationWeather>((ref) async {
  final station = ref.watch(selectedStationProvider);
  final service = ref.watch(weatherApiServiceProvider);
  
  // Optionally attach matching nowcast alert if any
  final nowcasts = await ref.watch(nowcastAlertsProvider.future).catchError((_) => <NowcastAlert>[]);
  final match = nowcasts.cast<NowcastAlert?>().firstWhere(
    (n) => n != null && (
      n.stationName.toLowerCase().contains(station.nameEn.toLowerCase()) ||
      station.nameEn.toLowerCase().contains(n.stationName.toLowerCase()) ||
      n.stationName.toLowerCase().contains(station.district.toLowerCase())
    ),
    orElse: () => null,
  );

  final weather = await service.fetchStationWeather(station);
  if (match != null) {
    return StationWeather(
      station: weather.station,
      current: weather.current,
      forecasts: weather.forecasts,
      nowcast: match,
      fetchedAt: weather.fetchedAt,
    );
  }
  return weather;
});
