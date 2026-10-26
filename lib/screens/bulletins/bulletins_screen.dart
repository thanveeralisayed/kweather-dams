import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/bulletins/models/port_warning.dart';
import '../../features/bulletins/models/sabarimala_forecast.dart';
import '../../features/bulletins/models/river_basin_qpf.dart';
import '../../features/bulletins/providers/bulletins_providers.dart';
import '../../features/common/providers/app_settings_provider.dart';
import 'port_signal_detail_sheet.dart';
import 'sabarimala_detail_sheet.dart';

class BulletinsScreen extends ConsumerWidget {
  const BulletinsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portsAsync = ref.watch(portWarningsProvider);
    final sabarimalaAsync = ref.watch(sabarimalaForecastProvider);
    final riverBasinAsync = ref.watch(riverBasinQpfProvider);
    final isMalayalam = ref.watch(appSettingsProvider).isMalayalam;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceContainer,
      onRefresh: () async {
        ref.invalidate(portWarningsProvider);
        ref.invalidate(sabarimalaForecastProvider);
        ref.invalidate(riverBasinQpfProvider);
        await Future.wait([
          ref.read(portWarningsProvider.future),
          ref.read(sabarimalaForecastProvider.future),
          ref.read(riverBasinQpfProvider.future),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Marine & Coastal Warning Banner
          _buildMarineHeaderBanner(isMalayalam),
          const SizedBox(height: 16),

          // 2. 11 Kerala Ports Section
          _buildPortsSection(context, portsAsync, isMalayalam),
          const SizedBox(height: 16),

          // 3. Sabarimala Pilgrimage Micro-weather Section
          _buildSabarimalaSection(context, sabarimalaAsync, isMalayalam),
          const SizedBox(height: 16),

          // 4. River Basin QPF Flood Forecast Section
          _buildRiverBasinSection(context, riverBasinAsync, isMalayalam),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMarineHeaderBanner(bool isMalayalam) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5A2A18),
            Color(0xFF2E150C),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.alertOrange.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.alertOrange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('PORT WARNING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
              const SizedBox(width: 8),
              Text(
                isMalayalam ? 'മത്സ്യത്തൊഴിലാളി മുന്നറിയിപ്പ്' : 'Fishermen Marine Advisory',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isMalayalam
                ? 'തെക്കൻ കേരള തീരത്ത് മണിക്കൂറിൽ 35 മുതൽ 45 കി.മീ വേഗതയിലും ചില അവസരങ്ങളിൽ 55 കി.മീ വേഗതയിലും ശക്തമായ കാറ്റിന് സാധ്യത. മത്സ്യത്തൊഴിലാളികൾ കടലിൽ പോകരുത്.'
                : 'Squally weather with wind speed 35-45 kmph gusting to 55 kmph likely along South Kerala coast. Fishermen are strictly advised not to venture into sea areas.',
            style: const TextStyle(fontSize: 12, color: AppColors.onSurface, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildPortsSection(BuildContext context, AsyncValue<List<PortWarning>> portsAsync, bool isMalayalam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isMalayalam ? 'കേരള തുറമുഖ സിഗ്നലുകൾ (11 എണ്ണം)' : 'Kerala Coastal Ports (11 Ports)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface),
            ),
            const Text('IMD Port Signal III', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 10),
        portsAsync.when(
          data: (ports) => ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ports.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final port = ports[index];
              return _buildPortItem(context, port, isMalayalam);
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Text(e.toString()),
        ),
      ],
    );
  }

  Widget _buildPortItem(BuildContext context, PortWarning port, bool isMalayalam) {
    final isHoisted = port.isCautionActive;

    return InkWell(
      onTap: () => PortSignalDetailSheet.show(context, port, isMalayalam),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHoisted ? AppColors.alertOrange.withValues(alpha: 0.5) : const Color(0xFF1E2D44),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.sailing_rounded,
              size: 20,
              color: isHoisted ? AppColors.alertOrange : AppColors.alertGreen,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    port.localizedPortName(isMalayalam),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                  ),
                  Text(
                    '${port.district} • ${port.signalName}',
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isHoisted ? AppColors.alertOrange.withValues(alpha: 0.15) : AppColors.alertGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isHoisted ? AppColors.alertOrange.withValues(alpha: 0.4) : AppColors.alertGreen.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                isHoisted ? 'SIGNAL III' : 'LOWERED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isHoisted ? AppColors.alertOrange : AppColors.alertGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSabarimalaSection(BuildContext context, AsyncValue<List<SabarimalaDayForecast>> sabarimalaAsync, bool isMalayalam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isMalayalam ? 'ശബരിമല തീർത്ഥാടന കാലാവസ്ഥ' : 'Sabarimala Pilgrimage Micro-Weather',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface),
            ),
            const Text('3-Day Special', style: TextStyle(fontSize: 11, color: AppColors.alertYellow, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 10),
        sabarimalaAsync.when(
          data: (forecasts) => InkWell(
            onTap: () => SabarimalaDetailSheet.show(context, forecasts, isMalayalam),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E2D44)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.alertYellow.withValues(alpha: 0.15),
                        child: const Icon(Icons.temple_hindu_rounded, size: 20, color: AppColors.alertYellow),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMalayalam ? 'സന്നിധാനം • പമ്പ • നിലയ്ക്കൽ' : 'Sannidhanam, Pamba Base Camp & Nilakkal',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                            ),
                            Text(
                              isMalayalam ? 'ഉച്ചയ്ക്ക് ശേഷം ഇടിമിന്നലോടു കൂടിയ മഴ സാധ്യത' : 'Moderate afternoon rain & thunderstorm alerts',
                              style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.onSurfaceVariant),
                    ],
                  ),
                ],
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Text(e.toString()),
        ),
      ],
    );
  }

  Widget _buildRiverBasinSection(BuildContext context, AsyncValue<List<RiverBasinQPF>> basinsAsync, bool isMalayalam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isMalayalam ? 'നദീതട പ്രളയ സാധ്യത (QPF)' : 'River Basin Flood Forecast (QPF)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface),
            ),
            const Text('7-Day Rainfall mm', style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 10),
        basinsAsync.when(
          data: (basins) => ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: basins.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final b = basins[index];
              final day1Val = b.dayQpfValues.isNotEmpty ? b.dayQpfValues[0] : '0.1-10';
              final day2Val = b.dayQpfValues.length > 1 ? b.dayQpfValues[1] : '0.1-10';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E2D44)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      child: Text('${b.slNo}', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.basinName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                          Text(b.subBasinName, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Day 1: $day1Val mm', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Text('Day 2: $day2Val mm', style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Text(e.toString()),
        ),
      ],
    );
  }
}
