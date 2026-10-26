import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../features/common/providers/app_settings_provider.dart';
import 'weather/weather_dashboard_screen.dart';
import 'dams/dam_reservoir_screen.dart';
import 'radar/radar_map_screen.dart';
import 'bulletins/bulletins_screen.dart';
import 'search/station_search_modal.dart';
import 'common/offline_fallback_sheet.dart';
import '../core/widgets/kweather_monochrome_icon.dart';

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
        titleSpacing: 16,
        title: Row(
          children: [
            // Material monochrome app logo badge
            const KWeatherMonochromeIcon(
              size: 22,
              withBackground: true,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'K-Weather & Dams',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                      ),
                      const SizedBox(width: 6),
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
                  Text(
                    isMalayalam ? 'കേരള കാലാവസ്ഥ & അണക്കെട്ടുകൾ' : 'IMD • KSDMA Verified Live',
                    style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Sync / Offline Diagnostics Button
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppColors.onSurfaceVariant),
            tooltip: 'Sync & Offline Diagnostics',
            onPressed: () {
              OfflineFallbackSheet.show(context, isMalayalam: isMalayalam);
            },
          ),

          // Language Toggle Chip
          GestureDetector(
            onTap: () {
              ref.read(appSettingsProvider.notifier).toggleLanguage();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline),
              ),
              child: Text(
                isMalayalam ? 'English' : 'മലയാളം',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Station Search Button
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.onSurfaceVariant),
            tooltip: 'Search Stations',
            onPressed: () {
              StationSearchModal.show(context);
            },
          ),
          const SizedBox(width: 4),
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
