import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class OfflineFallbackSheet extends StatelessWidget {
  final bool isMalayalam;

  const OfflineFallbackSheet({
    super.key,
    required this.isMalayalam,
  });

  static Future<void> show(BuildContext context, {required bool isMalayalam}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => OfflineFallbackSheet(isMalayalam: isMalayalam),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.alertYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.alertYellow.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 14, color: AppColors.alertYellow),
                        const SizedBox(width: 6),
                        Text(
                          isMalayalam ? 'ഓഫ്‌ലൈൻ കാഷെ മോഡ്' : 'Offline Cache Mode',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.alertYellow),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Last Updated Title
          Text(
            isMalayalam ? 'അവസാനം പുതുക്കിയത്: 3 മണിക്കൂർ മുമ്പ് (08:30 IST)' : 'Last Updated: 3 hours ago (08:30 IST)',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            isMalayalam
                ? 'IMD & KSDMA സെർവറുകളുമായി കണക്റ്റുചെയ്യാനാകുന്നില്ല. ഉപകരണത്തിൽ മുൻകൂട്ടി സൂക്ഷിച്ച ലോക്കൽ ഡാറ്റ (Hive Local Storage) കാണിക്കുന്നു.'
                : 'Unable to reach IMD & KSDMA live endpoints. Rendering verified local snapshot from on-device storage.',
            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 16),

          // CTA Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isMalayalam ? 'ഡാറ്റ പുതുക്കാൻ ശ്രമിക്കുന്നു...' : 'Re-checking IMD & SDMA endpoints...'),
                        backgroundColor: AppColors.surfaceContainerHigh,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: Text(isMalayalam ? 'വീണ്ടും ശ്രമിക്കുക (Retry)' : 'Retry Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.storage_rounded, size: 16, color: AppColors.secondary),
                label: const Text('Hive DB (14 MB)', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1E2D44)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Diagnostic Panel
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E2D44)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isMalayalam ? 'നെറ്റ്‌വർക്ക് ഡയഗ്നോസ്റ്റിക്സ്' : 'Network Stream Diagnostics',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.alertYellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('3 Fallbacks Active', style: TextStyle(fontSize: 10, color: AppColors.alertYellow, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStreamItem('IMD AWS City Weather API', 'Timeout 5000ms • Using snapshot', 'Hive Cache', AppColors.alertYellow),
                const SizedBox(height: 8),
                _buildStreamItem('KSDMA Dam Water Portal', 'Connection refused • Sync 11:00 AM', 'Daily PDF', AppColors.alertYellow),
                const SizedBox(height: 8),
                _buildStreamItem('Doppler Radar Stream', 'High-bandwidth stream paused', 'Paused', AppColors.alertRed),
                const SizedBox(height: 8),
                _buildStreamItem('Emergency Alert System', 'Cell broadcast active via tower', 'SMS Fallback', AppColors.alertBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamItem(String title, String subtitle, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
