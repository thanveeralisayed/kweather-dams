import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../features/common/providers/app_settings_provider.dart';
import 'weather/weather_dashboard_screen.dart';
import 'dams/dam_reservoir_screen.dart';
import 'radar/radar_map_screen.dart';
import 'bulletins/bulletins_screen.dart';
import 'search/station_search_modal.dart';
import '../core/widgets/kweather_monochrome_icon.dart';
import '../features/weather/providers/weather_providers.dart';
import '../features/dams/providers/dam_providers.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isMalayalam = settings.isMalayalam;

    final pages = [
      WeatherDashboardScreen(
        onNavigateToRadar: () => _onTabSelected(2),
        onNavigateToDams: () => _onTabSelected(1),
        onNavigateToBulletins: () => _onTabSelected(3),
      ),
      const DamReservoirScreen(),
      const RadarMapScreen(),
      const BulletinsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Material monochrome app logo badge
            const KWeatherMonochromeIcon(
              size: 20,
              withBackground: true,
            ),
            const SizedBox(width: 8),
            const Text(
              'K-Weather & Dams',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 5),
            // Live dot
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.alertGreen,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        actions: [
          // Refresh Button
          IconButton(
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: const EdgeInsets.all(7),
            icon: const Icon(Icons.sync_rounded, color: AppColors.onSurfaceVariant, size: 20),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(stationWeatherProvider);
              ref.invalidate(nowcastAlertsProvider);
              ref.invalidate(allDamsFutureProvider);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4), width: 1.2),
                  ),
                  backgroundColor: const Color(0xFF0C1D33),
                  duration: const Duration(seconds: 2),
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isMalayalam ? 'വിവരങ്ങൾ പുതുക്കുന്നു...' : 'Updating latest data...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 2),

          // Language Toggle Chip
          GestureDetector(
            onTap: () {
              ref.read(appSettingsProvider.notifier).toggleLanguage();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outline),
              ),
              child: Text(
                isMalayalam ? 'English' : 'മലയാളം',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 2),

          // Station Search Button
          IconButton(
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: const EdgeInsets.all(7),
            icon: const Icon(Icons.search_rounded, color: AppColors.onSurfaceVariant, size: 20),
            tooltip: 'Search Stations',
            onPressed: () {
              StationSearchModal.show(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.air_rounded),
            activeIcon: const Icon(Icons.air_rounded, color: AppColors.primary),
            label: isMalayalam ? 'കാലാവസ്ഥ' : 'Weather',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.waves_rounded),
            activeIcon: const Icon(Icons.waves_rounded, color: AppColors.primary),
            label: isMalayalam ? 'ഡാമുകൾ' : 'Dams',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.radar_rounded),
            activeIcon: const Icon(Icons.radar_rounded, color: AppColors.primary),
            label: isMalayalam ? 'റഡാർ' : 'Radar & Map',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shield_outlined),
            activeIcon: const Icon(Icons.shield_rounded, color: AppColors.primary),
            label: isMalayalam ? 'മുന്നറിയിപ്പ്' : 'Bulletins',
          ),
        ],
      ),
    );
  }
}
