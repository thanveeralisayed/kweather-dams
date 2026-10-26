import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/weather/models/daily_forecast.dart';
import '../../features/weather/models/station_weather.dart';
import '../../features/weather/providers/weather_providers.dart';
import '../../features/common/providers/app_settings_provider.dart';

class WeatherDashboardScreen extends ConsumerWidget {
  final VoidCallback onNavigateToRadar;
  final VoidCallback onNavigateToDams;
  final VoidCallback onNavigateToBulletins;

  const WeatherDashboardScreen({
    super.key,
    required this.onNavigateToRadar,
    required this.onNavigateToDams,
    required this.onNavigateToBulletins,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(stationWeatherProvider);
    final selectedStation = ref.watch(selectedStationProvider);
    final allStations = ref.watch(allStationsProvider);
    final isMalayalam = ref.watch(appSettingsProvider).isMalayalam;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceContainer,
      onRefresh: () async {
        ref.invalidate(stationWeatherProvider);
        ref.invalidate(nowcastAlertsProvider);
        await ref.read(stationWeatherProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Station Observation Ribbon
          _buildStationRibbon(ref, allStations, selectedStation.id, isMalayalam),
          const SizedBox(height: 12),

          // Weather Content based on state
          weatherAsync.when(
            data: (weather) => _buildWeatherContent(context, weather, isMalayalam),
            loading: () => _buildLoadingSkeleton(),
            error: (err, _) => _buildErrorCard(context, ref, err.toString(), isMalayalam),
          ),
          const SizedBox(height: 16),

          // 4. Quick Surveillance Modules Grid
          _buildSurveillanceGrid(context, isMalayalam),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStationRibbon(WidgetRef ref, List<dynamic> stations, String currentId, bool isMalayalam) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stations.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final s = stations[index];
          final isSelected = s.id == currentId;

          return GestureDetector(
            onTap: () {
              ref.read(selectedStationProvider.notifier).state = s;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  Text(
                    s.localizedName(isMalayalam),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.onSurface : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherContent(BuildContext context, StationWeather weather, bool isMalayalam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2. Severe Nowcast Alert Card (if any alert active)
        if (weather.nowcast != null && weather.nowcast!.severity != WarningSeverity.green)
          _buildNowcastCard(weather.nowcast!, isMalayalam),

        // 3. Live AWS Hero Weather Card
        _buildHeroWeatherCard(weather, isMalayalam),
        const SizedBox(height: 16),

        // 4. 7-Day Synoptic Outlook Horizontal Slider
        _build7DayForecastSection(weather.forecasts, isMalayalam),
      ],
    );
  }

  Widget _buildNowcastCard(dynamic nowcast, bool isMalayalam) {
    final Color badgeColor = nowcast.severity == WarningSeverity.red
        ? AppColors.alertRed
        : (nowcast.severity == WarningSeverity.orange ? AppColors.alertOrange : AppColors.alertYellow);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isMalayalam ? '3-മണിക്കൂർ മുന്നറിയിപ്പ്' : 'NOWCAST ALERT',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              const Spacer(),
              if (nowcast.validUpto.isNotEmpty)
                Text(
                  '${isMalayalam ? "സാധുത" : "Valid till"}: ${nowcast.validUpto}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.bolt_rounded, color: badgeColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nowcast.rawDescription.isNotEmpty
                      ? nowcast.rawDescription
                      : '${nowcast.rainIntensity} • Wind ${nowcast.windSpeed}',
                  style: const TextStyle(fontSize: 13, height: 1.3, color: AppColors.onSurface),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroWeatherCard(StationWeather weather, bool isMalayalam) {
    final cur = weather.current;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF132A4A),
            Color(0xFF0F1E33),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1F3B66), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x66030E20), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station & Update time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        weather.station.localizedName(isMalayalam),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${weather.station.district} • Station ID: ${weather.station.id}',
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cur.updatedAt.contains('Offline') ? 'Offline Cache' : 'Live AWS',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Big Temp and Condition
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cur.maxTemp > 0 ? cur.maxTemp.toStringAsFixed(1) : '29.4',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                          color: AppColors.onSurface,
                          height: 1.0,
                        ),
                      ),
                      const Text(
                        '°C',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cur.conditionSummary,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  ),
                  if (cur.maxTempDeviation != null)
                    Text(
                      'Departure: ${cur.maxTempDeviation! >= 0 ? '+' : ''}${cur.maxTempDeviation}°C from normal',
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                ],
              ),
              // Weather Icon Illustration
              const Icon(
                Icons.thunderstorm_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Metric Badges Grid (Rainfall, Humidity, Min/Max)
          Row(
            children: [
              _buildMetricPill(
                Icons.water_drop_rounded,
                isMalayalam ? '24മ മണിക്കൂർ മഴ' : '24h Rainfall',
                '${cur.rainfall24h} mm',
                AppColors.primary,
              ),
              const SizedBox(width: 8),
              _buildMetricPill(
                Icons.water_rounded,
                isMalayalam ? 'ആർദ്രത (രാവിലെ)' : 'Humidity (AM)',
                '${cur.humidityMorning}%',
                AppColors.secondary,
              ),
              const SizedBox(width: 8),
              _buildMetricPill(
                Icons.thermostat_rounded,
                isMalayalam ? 'കുറഞ്ഞ താപം' : 'Min Temp',
                '${cur.minTemp}°C',
                AppColors.alertYellow,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Astro Grid (Sunrise, Sunset, Moonrise, Moonset)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAstroItem(Icons.wb_sunny_rounded, isMalayalam ? 'സൂര്യോദയം' : 'Sunrise', cur.sunrise),
                _buildAstroItem(Icons.nights_stay_rounded, isMalayalam ? 'സൂര്യാസ്തമയം' : 'Sunset', cur.sunset),
                _buildAstroItem(Icons.brightness_3_rounded, isMalayalam ? 'ചന്ദ്രോദയം' : 'Moonrise', cur.moonrise),
                _buildAstroItem(Icons.bedtime_rounded, isMalayalam ? 'ചന്ദ്രാസ്തമയം' : 'Moonset', cur.moonset),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(IconData icon, String label, String value, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: accent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAstroItem(IconData icon, String label, String time) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(height: 2),
        Text(time, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _build7DayForecastSection(List<DailyForecast> forecasts, bool isMalayalam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isMalayalam ? '7-ദിവസ കാലാവസ്ഥ പ്രവചനം' : '7-Day Synoptic Outlook',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
            ),
            const Text(
              'IMD NWP Model',
              style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 165,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: forecasts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final f = forecasts[index];
              return _buildForecastCard(f, isMalayalam);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForecastCard(DailyForecast f, bool isMalayalam) {
    Color badgeColor = AppColors.alertGreen;
    String badgeText = isMalayalam ? 'മുന്നറിയിപ്പില്ല' : 'No Warning';

    if (f.warningSeverity == WarningSeverity.red) {
      badgeColor = AppColors.alertRed;
      badgeText = isMalayalam ? 'റെഡ് അലർട്ട്' : 'Red Alert';
    } else if (f.warningSeverity == WarningSeverity.orange) {
      badgeColor = AppColors.alertOrange;
      badgeText = isMalayalam ? 'ഓറഞ്ച് അലർട്ട്' : 'Orange Alert';
    } else if (f.warningSeverity == WarningSeverity.yellow) {
      badgeColor = AppColors.alertYellow;
      badgeText = isMalayalam ? 'യെല്ലോ വാച്ച്' : 'Yellow Watch';
    }

    return Container(
      width: 125,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: f.warningSeverity != WarningSeverity.green ? badgeColor.withValues(alpha: 0.5) : const Color(0xFF1E2D44),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(f.dayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
          Text(f.date, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
          const Spacer(),
          const Icon(Icons.cloud_queue_rounded, size: 28, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            '${f.maxTemp.round()}° / ${f.minTemp.round()}°',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveillanceGrid(BuildContext context, bool isMalayalam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isMalayalam ? 'ദ്രുത നിരീക്ഷണ മൊഡ്യൂളുകൾ' : 'Active Surveillance Modules',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildModuleTile(
                icon: Icons.radar_rounded,
                title: isMalayalam ? 'ഡോപ്ലർ റഡാർ' : 'Doppler Radar',
                subtitle: 'Kochi 250km Loop',
                accent: AppColors.primary,
                onTap: onNavigateToRadar,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildModuleTile(
                icon: Icons.waves_rounded,
                title: isMalayalam ? 'ഡാം ജലനിരപ്പ്' : 'Dam Reserves',
                subtitle: '37 Reservoirs Live',
                accent: AppColors.secondary,
                onTap: onNavigateToDams,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildModuleTile(
                icon: Icons.sailing_rounded,
                title: isMalayalam ? 'തീരദേശ & പോർട്ട്' : 'Port Signals',
                subtitle: '11 Kerala Ports',
                accent: AppColors.alertOrange,
                onTap: onNavigateToBulletins,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildModuleTile(
                icon: Icons.temple_hindu_rounded,
                title: isMalayalam ? 'ശബരിമല പ്രവചനം' : 'Sabarimala',
                subtitle: 'Pilgrimage Weather',
                accent: AppColors.alertYellow,
                onTap: onNavigateToBulletins,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModuleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E2D44), width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: accent.withValues(alpha: 0.15),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      height: 260,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, WidgetRef ref, String error, bool isMalayalam) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.alertRed.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.alertRed),
          const SizedBox(height: 8),
          Text(
            isMalayalam ? 'ഡാറ്റ ലഭ്യമാക്കാൻ കഴിഞ്ഞില്ല' : 'Weather Sync Interrupted',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () {
              ref.invalidate(stationWeatherProvider);
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(isMalayalam ? 'വീണ്ടും ശ്രമിക്കുക' : 'Retry'),
          ),
        ],
      ),
    );
  }
}
