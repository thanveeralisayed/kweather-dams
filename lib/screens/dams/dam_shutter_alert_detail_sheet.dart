import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/dams/models/dam_model.dart';

class DamShutterAlertDetailSheet extends StatelessWidget {
  final DamModel dam;
  final bool isMalayalam;

  const DamShutterAlertDetailSheet({
    super.key,
    required this.dam,
    required this.isMalayalam,
  });

  static Future<void> show(BuildContext context, DamModel dam, bool isMalayalam) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DamShutterAlertDetailSheet(dam: dam, isMalayalam: isMalayalam),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertColor = _getAlertColor(dam.alertLevel);

    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 32),
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dam.localizedName(isMalayalam),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '${dam.district} • ${dam.authority == DamAuthority.kseb ? "KSEB" : "Irrigation Dept"} • ${dam.asOfTime}',
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: alertColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: alertColor),
                ),
                child: Text(
                  dam.alertBadgeLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: alertColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Shutter alert banner if open
          if (dam.isShutterOpen)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.alertOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.alertOrange.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.alertOrange, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMalayalam ? 'ഷട്ടർ തുറന്നിരിക്കുന്നു / ജലസ്രോതസ്സ്' : 'Active Shutter Discharge Alert',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.alertOrange),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dam.shutterRemarks,
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurface, height: 1.3),
                        ),
                        if (dam.outflowCumecs > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${isMalayalam ? "പുറന്തള്ളുന്ന ജലം" : "Spillway Outflow"}: ${dam.outflowCumecs} cumecs (m³/sec)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Water Level Metrics Grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricCol(
                      isMalayalam ? 'ഇപ്പോഴത്തെ ജലനിരപ്പ്' : 'Current Water Level',
                      '${dam.currentLevelMeters.toStringAsFixed(2)} m',
                      AppColors.primary,
                    ),
                    _buildMetricCol(
                      isMalayalam ? 'പരമാവധി ജലനിരപ്പ്' : 'Full Reservoir Level (FRL)',
                      '${dam.frlMeters.toStringAsFixed(2)} m',
                      AppColors.onSurface,
                    ),
                    _buildMetricCol(
                      isMalayalam ? 'സംഭരണ ശതമാനം' : 'Capacity Storage',
                      '${dam.storagePercentage}%',
                      dam.isNearCapacity ? AppColors.alertRed : AppColors.alertGreen,
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF26354D), height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricCol(
                      isMalayalam ? 'നിലവിലെ ജലശേഖരം' : 'Today Storage',
                      '${dam.currentStorageMcm.toStringAsFixed(2)} MCM',
                      AppColors.onSurface,
                    ),
                    _buildMetricCol(
                      isMalayalam ? 'ആകെ സംഭരണശേഷി' : 'Gross Storage',
                      '${dam.grossStorageMcm.toStringAsFixed(2)} MCM',
                      AppColors.onSurface,
                    ),
                    _buildMetricCol(
                      isMalayalam ? 'റൂൾ ലെവൽ' : 'Rule Level',
                      '${dam.ruleLevelMeters.toStringAsFixed(2)} m',
                      AppColors.alertYellow,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Alert Thresholds Reference
          Text(
            isMalayalam ? 'അലർട്ട് ലെവലുകൾ (റഫറൻസ്)' : 'Safety Thresholds (Meters)',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildAlertBadge('Blue Level', '${dam.blueLevel.toStringAsFixed(2)}m', AppColors.alertBlue),
              const SizedBox(width: 8),
              _buildAlertBadge('Orange Level', '${dam.orangeLevel.toStringAsFixed(2)}m', AppColors.alertOrange),
              const SizedBox(width: 8),
              _buildAlertBadge('Red Level', '${dam.redLevel.toStringAsFixed(2)}m', AppColors.alertRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildAlertBadge(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
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
}
