import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/bulletins/models/port_warning.dart';

class PortSignalDetailSheet extends StatelessWidget {
  final PortWarning port;
  final bool isMalayalam;

  const PortSignalDetailSheet({
    super.key,
    required this.port,
    required this.isMalayalam,
  });

  static Future<void> show(BuildContext context, PortWarning port, bool isMalayalam) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PortSignalDetailSheet(port: port, isMalayalam: isMalayalam),
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
                radius: 22,
                backgroundColor: AppColors.alertOrange.withValues(alpha: 0.15),
                child: const Icon(Icons.sailing_rounded, color: AppColors.alertOrange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      port.localizedPortName(isMalayalam),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                    ),
                    Text(
                      '${port.district} District • ${port.signalName}',
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: port.isCautionActive
                      ? AppColors.alertOrange.withValues(alpha: 0.2)
                      : AppColors.alertGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: port.isCautionActive ? AppColors.alertOrange : AppColors.alertGreen),
                ),
                child: Text(
                  port.isCautionActive ? 'SIGNAL III HOISTED' : 'SIGNAL LOWERED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: port.isCautionActive ? AppColors.alertOrange : AppColors.alertGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Signal Meaning Explanation Card
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
                Text(
                  isMalayalam ? 'ലോക്കൽ കോഷനറി സിഗ്നൽ നമ്പർ III ൻ്റെ അർത്ഥം' : 'Local Cautionary Signal No. III Meaning',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  isMalayalam
                      ? 'തുറമുഖത്ത് സ്ക്വാളി കാലാവസ്ഥയും കാറ്റിൻ്റെ വേഗത 40-50 കി.മീ/മണിക്കൂർ വരെ ഉയരാൻ സാധ്യതയുണ്ട്. മത്സ്യത്തൊഴിലാളികൾ കടലിൽ പോകരുതെന്നും ആഴക്കടലിലുള്ളവർ ഉടൻ തിരിച്ചെത്തണമെന്നും നിർദ്ദേശം.'
                      : 'The port may experience bad/squally weather with wind gusts reaching 40-50 kmph. Fishermen are strictly advised not to venture into sea areas.',
                  style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.onSurface),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Advice banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.alertRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.alertRed.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.crisis_alert_rounded, color: AppColors.alertRed, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    port.advice,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.alertRed),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Squally wind info
          Text(
            isMalayalam ? 'കാറ്റിൻ്റെ മുന്നറിയിപ്പ് വിവരങ്ങൾ' : 'Wind Warning Specifics',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            port.squallyWindDetails,
            style: const TextStyle(fontSize: 12, color: AppColors.onSurface, height: 1.3),
          ),
        ],
      ),
    );
  }
}
