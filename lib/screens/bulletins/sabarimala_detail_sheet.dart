import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/bulletins/models/sabarimala_forecast.dart';

class SabarimalaDetailSheet extends StatelessWidget {
  final List<SabarimalaDayForecast> forecasts;
  final bool isMalayalam;

  const SabarimalaDetailSheet({
    super.key,
    required this.forecasts,
    required this.isMalayalam,
  });

  static Future<void> show(BuildContext context, List<SabarimalaDayForecast> forecasts, bool isMalayalam) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SabarimalaDetailSheet(forecasts: forecasts, isMalayalam: isMalayalam),
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
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.alertYellow.withValues(alpha: 0.15),
                child: const Icon(Icons.temple_hindu_rounded, color: AppColors.alertYellow, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMalayalam ? 'ശബരിമല തീർത്ഥാടന കാലാവസ്ഥ' : 'Sabarimala Pilgrimage Micro-Weather',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                    ),
                    Text(
                      isMalayalam ? 'സന്നിധാനം • പമ്പ • നിലയ്ക്കൽ' : 'Sannidhanam • Pamba Base Camp • Nilakkal',
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Forecast cards for each station
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: forecasts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final f = forecasts[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1E2D44)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            f.localizedStation(isMalayalam),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              f.date,
                              style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        f.localizedForecast(isMalayalam),
                        style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 12, color: AppColors.alertYellow),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${isMalayalam ? "മുന്നറിയിപ്പ്" : "Warning"}: ${f.localizedWarning(isMalayalam)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.alertYellow),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Advisory banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.hiking_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isMalayalam
                        ? 'മലയോര പാതകളിൽ മണ്ണിടിച്ചിൽ സാധ്യതയുള്ളതിനാൽ വനംവകുപ്പിന്റെയും ദുരന്തനിവാരണ അതോറിറ്റിയുടെയും നിർദ്ദേശങ്ങൾ പാലിക്കുക.'
                        : 'Devotees trekking on high-range forest paths are advised to stay alert for sudden flash downpours and lightning.',
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurface, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
