import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/dams/models/dam_model.dart';
import '../../features/dams/providers/dam_providers.dart';
import '../../features/common/providers/app_settings_provider.dart';
import 'dam_shutter_alert_detail_sheet.dart';

class DamReservoirScreen extends ConsumerWidget {
  const DamReservoirScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final damsAsync = ref.watch(filteredDamsProvider);
    final selectedAuthority = ref.watch(selectedDamAuthorityProvider);
    final selectedAlert = ref.watch(selectedDamAlertLevelProvider);
    final sortOrder = ref.watch(damSortOrderProvider);
    final statewideStorage = ref.watch(stateWideDamStoragePercentageProvider);
    final isMalayalam = ref.watch(appSettingsProvider).isMalayalam;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceContainer,
      onRefresh: () async {
        ref.invalidate(allDamsFutureProvider);
        await ref.read(allDamsFutureProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Statewide Reservoir Storage Summary Banner
          _buildSummaryBanner(statewideStorage, isMalayalam),
          const SizedBox(height: 12),

          // 2. Authority Selector Tabs (All, KSEB, Irrigation)
          _buildAuthorityTabs(ref, selectedAuthority, isMalayalam),
          const SizedBox(height: 12),

          // 3. Filter and Sort Row
          _buildFilterRow(ref, selectedAlert, sortOrder, isMalayalam),
          const SizedBox(height: 12),

          // 4. Dam Cards List
          damsAsync.when(
            data: (dams) => _buildDamsList(context, dams, isMalayalam),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) => _buildErrorCard(ref, err.toString(), isMalayalam),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryBanner(double percentage, bool isMalayalam) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F3A5D),
            Color(0xFF092036),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1B5585), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMalayalam ? 'കേരള ഡാം സംഭരണ ശേഷി' : 'Statewide Reservoir Storage',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  isMalayalam ? '37 പ്രധാന അണക്കെട്ടുകൾ • KSDMA ലൈവ്' : '37 Major Dams (17 KSEB + 20 Irrigation)',
                  style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('11:00 AM Sync', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isMalayalam ? 'ജലസേചനം & കെ.എസ്.ഇ.ബി' : 'Live Telemetry Active',
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Circular gauge percentage
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: CircularProgressIndicator(
                  value: percentage / 100.0,
                  strokeWidth: 7,
                  backgroundColor: AppColors.surfaceContainerLowest,
                  color: percentage >= 85.0 ? AppColors.alertRed : (percentage >= 70 ? AppColors.primary : AppColors.alertGreen),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${percentage.round()}%',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                  ),
                  Text(
                    isMalayalam ? 'ശേഖരം' : 'Live',
                    style: const TextStyle(fontSize: 9, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorityTabs(WidgetRef ref, DamAuthority selected, bool isMalayalam) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildAuthorityTabItem(ref, DamAuthority.all, isMalayalam ? 'എല്ലാം (37)' : 'All Dams (37)', selected == DamAuthority.all),
          _buildAuthorityTabItem(ref, DamAuthority.kseb, isMalayalam ? 'കെ.എസ്.ഇ.ബി (17)' : 'KSEB Hydro (17)', selected == DamAuthority.kseb),
          _buildAuthorityTabItem(ref, DamAuthority.irrigation, isMalayalam ? 'ജലസേചനം (20)' : 'Irrigation (20)', selected == DamAuthority.irrigation),
        ],
      ),
    );
  }

  Widget _buildAuthorityTabItem(WidgetRef ref, DamAuthority authority, String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(selectedDamAuthorityProvider.notifier).state = authority;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? const [BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(WidgetRef ref, DamAlertLevel? selectedAlert, DamSortOrder sortOrder, bool isMalayalam) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Filter by Alert
          FilterChip(
            selected: selectedAlert == null,
            label: Text(isMalayalam ? 'എല്ലാ ലെവലും' : 'All Levels'),
            onSelected: (_) => ref.read(selectedDamAlertLevelProvider.notifier).state = null,
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: selectedAlert == DamAlertLevel.red,
            label: Text(isMalayalam ? 'റെഡ് അലർട്ട്' : 'Red Alert'),
            selectedColor: AppColors.alertRed.withValues(alpha: 0.3),
            onSelected: (_) => ref.read(selectedDamAlertLevelProvider.notifier).state =
                selectedAlert == DamAlertLevel.red ? null : DamAlertLevel.red,
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: selectedAlert == DamAlertLevel.orange,
            label: Text(isMalayalam ? 'ഓറഞ്ച്' : 'Orange'),
            selectedColor: AppColors.alertOrange.withValues(alpha: 0.3),
            onSelected: (_) => ref.read(selectedDamAlertLevelProvider.notifier).state =
                selectedAlert == DamAlertLevel.orange ? null : DamAlertLevel.orange,
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: selectedAlert == DamAlertLevel.yellow,
            label: Text(isMalayalam ? 'ഷട്ടർ തുറന്നവ' : 'Controlled Discharge'),
            selectedColor: AppColors.alertYellow.withValues(alpha: 0.3),
            onSelected: (_) => ref.read(selectedDamAlertLevelProvider.notifier).state =
                selectedAlert == DamAlertLevel.yellow ? null : DamAlertLevel.yellow,
          ),
          const SizedBox(width: 12),

          // Sort Button
          ActionChip(
            avatar: const Icon(Icons.sort_rounded, size: 16, color: AppColors.primary),
            label: Text(
              sortOrder == DamSortOrder.storageDesc
                  ? (isMalayalam ? 'ശേഖരം % (കൂടിയത്)' : 'Capacity % (High)')
                  : (isMalayalam ? 'അക്ഷരമാല' : 'Name A-Z'),
              style: const TextStyle(fontSize: 11),
            ),
            onPressed: () {
              ref.read(damSortOrderProvider.notifier).state =
                  sortOrder == DamSortOrder.storageDesc ? DamSortOrder.nameAsc : DamSortOrder.storageDesc;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDamsList(BuildContext context, List<DamModel> dams, bool isMalayalam) {
    if (dams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.water_damage_outlined, size: 48, color: AppColors.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(
                isMalayalam ? 'അണക്കെട്ടുകൾ കണ്ടെത്തിയില്ല' : 'No Dams Match Filters',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dams.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final dam = dams[index];
        return _buildDamCard(context, dam, isMalayalam);
      },
    );
  }

  Widget _buildDamCard(BuildContext context, DamModel dam, bool isMalayalam) {
    final alertColor = _getAlertColor(dam.alertLevel);

    return InkWell(
      onTap: () {
        DamShutterAlertDetailSheet.show(context, dam, isMalayalam);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dam.alertLevel != DamAlertLevel.normal ? alertColor.withValues(alpha: 0.5) : const Color(0xFF1E2D44),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dam Title, Authority Tag & Alert Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dam.localizedName(isMalayalam),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: dam.authority == DamAuthority.kseb
                                  ? AppColors.primaryContainer.withValues(alpha: 0.3)
                                  : AppColors.secondaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              dam.authority == DamAuthority.kseb ? 'KSEB' : 'Irrigation',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: dam.authority == DamAuthority.kseb ? AppColors.primary : AppColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(dam.district, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Alert Level Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: alertColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: alertColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    dam.alertBadgeLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: alertColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar and Level numbers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${isMalayalam ? "ജലനിരപ്പ്" : "Water Level"}: ${dam.currentLevelMeters.toStringAsFixed(1)} m / ${dam.frlMeters.toStringAsFixed(1)} m (FRL)',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                ),
                Text(
                  '${dam.storagePercentage.round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: dam.isNearCapacity ? AppColors.alertRed : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (dam.storagePercentage / 100.0).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.surfaceContainerLowest,
                color: dam.isNearCapacity ? AppColors.alertRed : (dam.storagePercentage >= 75 ? AppColors.primary : AppColors.alertGreen),
              ),
            ),
            const SizedBox(height: 10),

            // Shutter Status Footer
            Row(
              children: [
                Icon(
                  dam.isShutterOpen ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                  size: 14,
                  color: dam.isShutterOpen ? AppColors.alertOrange : AppColors.alertGreen,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    dam.shutterRemarks.isNotEmpty ? dam.shutterRemarks : 'All gates closed. Operating normally.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: dam.isShutterOpen ? AppColors.alertOrange : AppColors.onSurfaceVariant,
                      fontWeight: dam.isShutterOpen ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getAlertColor(DamAlertLevel level) {
    switch (level) {
      case DamAlertLevel.red:
        return AppColors.alertRed;
      case DamAlertLevel.orange:
        return AppColors.alertOrange;
      case DamAlertLevel.blue:
        return AppColors.alertBlue;
      case DamAlertLevel.yellow:
        return AppColors.alertYellow;
      case DamAlertLevel.normal:
        return AppColors.alertGreen;
    }
  }

  Widget _buildErrorCard(WidgetRef ref, String error, bool isMalayalam) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.alertRed),
          const SizedBox(height: 8),
          Text(isMalayalam ? 'ഡാം വിവരങ്ങൾ ലഭ്യമാക്കാൻ കഴിഞ്ഞില്ല' : 'Error loading dam data', style: const TextStyle(color: AppColors.onSurface)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => ref.invalidate(allDamsFutureProvider),
            child: Text(isMalayalam ? 'വീണ്ടും ശ്രമിക്കുക' : 'Retry'),
          ),
        ],
      ),
    );
  }
}
