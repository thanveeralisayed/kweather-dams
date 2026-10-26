import 'weather_station.dart';
import 'current_observation.dart';
import 'daily_forecast.dart';
import 'nowcast_alert.dart';

class StationWeather {
  final WeatherStation station;
  final CurrentObservation current;
  final List<DailyForecast> forecasts;
  final NowcastAlert? nowcast;
  final DateTime fetchedAt;

  const StationWeather({
    required this.station,
    required this.current,
    required this.forecasts,
    this.nowcast,
    required this.fetchedAt,
  });

  factory StationWeather.fromImdJson({
    required WeatherStation station,
    required Map<String, dynamic> json,
    NowcastAlert? nowcast,
    DateTime? fetchedAt,
  }) {
    final now = fetchedAt ?? DateTime.now();
    final current = CurrentObservation.fromImdJson(json);
    
    final forecasts = List.generate(7, (index) {
      return DailyForecast.fromImdIndex(json, index, now);
    });

    return StationWeather(
      station: station,
      current: current,
      forecasts: forecasts,
      nowcast: nowcast,
      fetchedAt: now,
    );
  }

  factory StationWeather.fromJson(Map<String, dynamic> json) {
    return StationWeather(
      station: WeatherStation.fromJson(json['station'] as Map<String, dynamic>),
      current: CurrentObservation.fromJson(json['current'] as Map<String, dynamic>),
      forecasts: (json['forecasts'] as List<dynamic>)
          .map((f) => DailyForecast.fromJson(f as Map<String, dynamic>))
          .toList(),
      nowcast: json['nowcast'] != null
          ? NowcastAlert.fromJson(json['nowcast'] as Map<String, dynamic>)
          : null,
      fetchedAt: DateTime.tryParse(json['fetchedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station': station.toJson(),
      'current': current.toJson(),
      'forecasts': forecasts.map((f) => f.toJson()).toList(),
      'nowcast': nowcast?.toJson(),
      'fetchedAt': fetchedAt.toIso8601String(),
    };
  }
}
