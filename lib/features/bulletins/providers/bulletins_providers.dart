import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/port_warning.dart';
import '../models/sabarimala_forecast.dart';
import '../models/river_basin_qpf.dart';
import '../services/bulletins_service.dart';

final bulletinsServiceProvider = Provider<BulletinsService>((ref) {
  return BulletinsService();
});

/// Port Warnings provider
final portWarningsProvider = FutureProvider<List<PortWarning>>((ref) async {
  final service = ref.watch(bulletinsServiceProvider);
  return service.fetchPortWarnings();
});

/// Sabarimala Pilgrimage micro-weather provider
final sabarimalaForecastProvider = FutureProvider<List<SabarimalaDayForecast>>((ref) async {
  final service = ref.watch(bulletinsServiceProvider);
  return service.fetchSabarimalaForecast();
});

/// River Basin QPF flood risk provider
final riverBasinQpfProvider = FutureProvider<List<RiverBasinQPF>>((ref) async {
  final service = ref.watch(bulletinsServiceProvider);
  return service.fetchRiverBasinQpf();
});

/// Count of ports with Signal III hoisted
final hoistedPortsCountProvider = Provider<int>((ref) {
  final portsAsync = ref.watch(portWarningsProvider);
  return portsAsync.maybeWhen(
    data: (ports) => ports.where((p) => p.isCautionActive).length,
    orElse: () => 4,
  );
});
