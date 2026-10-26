import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/weather/models/weather_station.dart';
import '../../features/weather/providers/weather_providers.dart';
import '../../features/common/providers/app_settings_provider.dart';

class StationSearchModal extends ConsumerWidget {
  const StationSearchModal({super.key});

  static Future<WeatherStation?> show(BuildContext context) {
    return showModalBottomSheet<WeatherStation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const StationSearchModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(stationSearchQueryProvider);
    final selectedRegion = ref.watch(selectedRegionFilterProvider);
    final filteredStations = ref.watch(filteredStationsProvider);
    final isMalayalam = ref.watch(appSettingsProvider).isMalayalam;

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title & Close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isMalayalam ? 'സ്റ്റേഷൻ തിരഞ്ഞെടുക്കുക' : 'Select Weather Station',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            autofocus: false,
            style: const TextStyle(color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: isMalayalam ? 'നഗരം അല്ലെങ്കിൽ ജില്ല തിരയുക...' : 'Search city or district...',
              hintStyle: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.onSurfaceVariant, size: 20),
                      onPressed: () => ref.read(stationSearchQueryProvider.notifier).state = '',
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceContainerHigh,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              ref.read(stationSearchQueryProvider.notifier).state = val;
            },
          ),
          const SizedBox(height: 12),

          // Region filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRegionChip(ref, null, isMalayalam ? 'എല്ലാം' : 'All', selectedRegion == null),
                const SizedBox(width: 8),
                _buildRegionChip(ref, StationRegion.south, isMalayalam ? 'തെക്കൻ' : 'South', selectedRegion == StationRegion.south),
                const SizedBox(width: 8),
                _buildRegionChip(ref, StationRegion.central, isMalayalam ? 'മധ്യ' : 'Central', selectedRegion == StationRegion.central),
                const SizedBox(width: 8),
                _buildRegionChip(ref, StationRegion.north, isMalayalam ? 'വടക്കൻ' : 'North', selectedRegion == StationRegion.north),
                const SizedBox(width: 8),
                _buildRegionChip(ref, StationRegion.highRange, isMalayalam ? 'ഹൈറേഞ്ച്' : 'High Range', selectedRegion == StationRegion.highRange),
                const SizedBox(width: 8),
                _buildRegionChip(ref, StationRegion.pilgrimage, isMalayalam ? 'തീർത്ഥാടനം' : 'Pilgrimage', selectedRegion == StationRegion.pilgrimage),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Station results list or Empty State
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: filteredStations.isEmpty
                ? _buildEmptyState(isMalayalam, query)
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredStations.length,
                    separatorBuilder: (context, index) => const Divider(color: Color(0xFF1E2D44), height: 1),
                    itemBuilder: (context, index) {
                      final station = filteredStations[index];
                      final isSelected = ref.watch(selectedStationProvider).id == station.id;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerHighest,
                          child: Icon(
                            isSelected ? Icons.check_rounded : Icons.location_on_outlined,
                            size: 18,
                            color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          station.localizedName(isMalayalam),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? AppColors.primary : AppColors.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '${station.district} • ID: ${station.id}',
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                        trailing: station.isPrimary
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'SYNOP',
                                  style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              )
                            : null,
                        onTap: () {
                          ref.read(selectedStationProvider.notifier).state = station;
                          Navigator.pop(context, station);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionChip(WidgetRef ref, StationRegion? region, String label, bool isSelected) {
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
        ref.read(selectedRegionFilterProvider.notifier).state = region;
      },
    );
  }

  Widget _buildEmptyState(bool isMalayalam, String query) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.location_off_rounded, size: 48, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              isMalayalam ? 'സ്റ്റേഷനുകൾ കണ്ടെത്തിയില്ല' : 'No Stations Found',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              isMalayalam ? '"$query" ന് അനുയോജ്യമായ ഫലങ്ങളില്ല' : 'No results matching "$query"',
              style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
