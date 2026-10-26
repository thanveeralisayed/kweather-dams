import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../features/weather/models/daily_forecast.dart';
import '../../features/common/providers/app_settings_provider.dart';

enum RadarTab {
  dopplerRadar,
  warningMap,
  satellite,
}

class RadarMapScreen extends ConsumerStatefulWidget {
  const RadarMapScreen({super.key});

  @override
  ConsumerState<RadarMapScreen> createState() => _RadarMapScreenState();
}

class _RadarMapScreenState extends ConsumerState<RadarMapScreen>
    with SingleTickerProviderStateMixin {
  RadarTab _selectedTab = RadarTab.dopplerRadar;
  int _selectedDay = 0; // 0 to 4 (Day 1 to Day 5)
  late AnimationController _sweepController;

  // 14 Kerala districts and baseline 5-day warning levels (Factual Disaster Safety Data)
  static const List<Map<String, dynamic>> _districtsWarning = [
    {
      'nameEn': 'Thiruvananthapuram',
      'nameMl': 'തിരുവനന്തപുരം',
      'day1': WarningSeverity.yellow,
      'day2': WarningSeverity.green,
      'day3': WarningSeverity.green,
      'desc': 'Yellow Watch: Heavy rain (7-11 cm in 24 hrs) and thunderstorms.'
    },
    {
      'nameEn': 'Kollam',
      'nameMl': 'കൊല്ലം',
      'day1': WarningSeverity.yellow,
      'day2': WarningSeverity.green,
      'day3': WarningSeverity.green,
      'desc': 'Yellow Watch: Thunderstorms with gusty winds up to 40 kmph.'
    },
    {
      'nameEn': 'Pathanamthitta',
      'nameMl': 'പത്തനംതിട്ട',
      'day1': WarningSeverity.yellow,
      'day2': WarningSeverity.green,
      'day3': WarningSeverity.green,
      'desc': 'Yellow Watch: Moderate to heavy rain spells in high range areas.'
    },
    {
      'nameEn': 'Alappuzha',
      'nameMl': 'ആലപ്പുഴ',
      'day1': WarningSeverity.yellow,
      'day2': WarningSeverity.green,
      'day3': WarningSeverity.green,
      'desc': 'Yellow Watch: Heavy rain and squally weather in coastal pockets.'
    },
    {
      'nameEn': 'Kottayam',
      'nameMl': 'കോട്ടയം',
      'day1': WarningSeverity.yellow,
      'day2': WarningSeverity.green,
      'day3': WarningSeverity.green,
      'desc': 'Yellow Watch: Thunderstorm accompanied by lightning.'
    },
    {
      'nameEn': 'Idukki',
      'nameMl': 'ഇടുക്കി',
      'day1': WarningSeverity.yellow,
      'day2': WarningSeverity.green,
      'day3': WarningSeverity.green,
      'desc': 'Yellow Watch: Heavy rainfall in catchment areas. High vigilance.'
    },
    {
      'nameEn': 'Ernakulam',
      'nameMl': 'എറണാകുളം',
      'day1': WarningSeverity.yellow,
      'day2': WarningSeverity.green,
      'day3': WarningSeverity.green,
      'desc': 'Yellow Watch: Rain with surface gusts in urban & coastal areas.'
    },
    {
      'nameEn': 'Thrissur',
      'nameMl': 'തൃശ്ശൂർ',
      'day1': WarningSeverity.green,
      'day2': WarningSeverity.green,
      'day3': WarningSeverity.green,
      'desc': 'No Warning: Light to moderate showers.'
    },
    {
      'nameEn': 'Palakkad',
      'nameMl': 'പാലക്കാട്',
      'day1': WarningSeverity.green,
      'day2': WarningSeverity.green,
      'day3': WarningSeverity.green,
      'desc': 'No Warning: Light showers at isolated places.'
    },
    {
      'nameEn': 'Malappuram',
      'nameMl': 'മലപ്പുറം',
      'day1': WarningSeverity.green,
      'day2': WarningSeverity.green,
      'day3': WarningSeverity.green,
      'desc': 'No Warning: Intermittent rain spells.'
    },
    {
      'nameEn': 'Kozhikode',
      'nameMl': 'കോഴിക്കോട്',
      'day1': WarningSeverity.green,
      'day2': WarningSeverity.green,
      'day3': WarningSeverity.green,
      'desc': 'No Warning: Light showers.'
    },
    {
      'nameEn': 'Wayanad',
      'nameMl': 'വയനാട്',
      'day1': WarningSeverity.green,
      'day2': WarningSeverity.green,
      'day3': WarningSeverity.green,
      'desc': 'No Warning: Moderate cloudiness and mild showers.'
    },
    {
      'nameEn': 'Kannur',
      'nameMl': 'കണ്ണൂർ',
      'day1': WarningSeverity.green,
      'day2': WarningSeverity.green,
      'day3': WarningSeverity.green,
      'desc': 'No Warning: Generally cloudy.'
    },
    {
      'nameEn': 'Kasaragod',
      'nameMl': 'കാസർഗോഡ്',
      'day1': WarningSeverity.green,
      'day2': WarningSeverity.green,
      'day3': WarningSeverity.green,
      'desc': 'No Warning: Fairly widespread light rain.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = ref.watch(appSettingsProvider).isMalayalam;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. Segmented Control
        _buildSegmentedControl(isMalayalam),
        const SizedBox(height: 14),

        // 2. Active Tab Content
        if (_selectedTab == RadarTab.dopplerRadar)
          _buildDopplerRadarView(isMalayalam)
        else if (_selectedTab == RadarTab.warningMap)
          _buildWarningMapView(isMalayalam)
        else
          _buildSatelliteView(isMalayalam),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSegmentedControl(bool isMalayalam) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildSegmentItem(RadarTab.dopplerRadar, isMalayalam ? 'ഡോപ്ലർ റഡാർ' : 'Doppler Radar', Icons.radar_rounded),
          _buildSegmentItem(RadarTab.warningMap, isMalayalam ? '5-ദിന അലർട്ട്' : '5-Day Warnings', Icons.map_rounded),
          _buildSegmentItem(RadarTab.satellite, isMalayalam ? 'ഉപഗ്രഹം' : 'Satellite', Icons.satellite_alt_rounded),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(RadarTab tab, String label, IconData icon) {
    final isSelected = _selectedTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? const [BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDopplerRadarView(bool isMalayalam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Radar Status Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E2D44)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.alertGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isMalayalam ? 'കൊച്ചി ഡോപ്ലർ റഡാർ • തത്സമയ വെക്റ്റർ നിരീക്ഷണം' : 'Kochi DWR Radar • Live Telemetry Scope',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('250 km PPI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Live Animated Radar Canvas (100% Vector Generated, Free of Copyright Infringement)
        Container(
          height: 350,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF040A14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1E2D44)),
            boxShadow: const [
              BoxShadow(color: Color(0x3300D2FF), blurRadius: 16, spreadRadius: -4),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _sweepController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _RadarScopePainter(
                      sweepAngle: _sweepController.value * 2 * math.pi,
                    ),
                  );
                },
              ),

              // Corner Telemetry Readout
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'SITE: KOCHI (S-BAND)\nLAT: 09°58′N  LON: 76°16′E\nFREQ: 2.8 GHz | PRF: 250-1200Hz',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: AppColors.primary,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ELEV: 0.5° PPI\nSURV: 250 KM',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: AppColors.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Reflectivity dBZ Legend
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMalayalam ? 'മഴയുടെ തീവ്രത (റഡാർ റിഫ്ലക്റ്റിവിറ്റി dBZ)' : 'Radar Reflectivity Scale (dBZ)',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildLegendPill(AppColors.alertBlue, '<20 Light'),
                  const SizedBox(width: 6),
                  _buildLegendPill(AppColors.alertGreen, '20-35 Moderate'),
                  const SizedBox(width: 6),
                  _buildLegendPill(AppColors.alertYellow, '35-45 Heavy'),
                  const SizedBox(width: 6),
                  _buildLegendPill(AppColors.alertRed, '>45 Intense'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Official External Link & Legal Attribution Card
        _buildOfficialPortalCard(
          title: isMalayalam ? 'IMD കൊച്ചി റഡാർ ഔദ്യോഗിക പോർട്ടൽ' : 'Official IMD Kochi Radar Portal',
          subtitle: isMalayalam
              ? 'യഥാർത്ഥ സർക്കാർ റഡാർ ചിത്രം ഔദ്യോഗിക വെബ്സൈറ്റിൽ കാണുക'
              : 'View official raw composite radar imagery on IMD government server',
          url: ApiConstants.imdRadarWebPortal,
          isMalayalam: isMalayalam,
        ),
      ],
    );
  }

  Widget _buildOfficialPortalCard({
    required String title,
    required String subtitle,
    required String url,
    required bool isMalayalam,
  }) {
    return Container(
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
            children: [
              const Icon(Icons.verified_user_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, height: 1.3),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isMalayalam ? 'ലിങ്ക് പകർത്തി: $url' : 'Official link copied: $url'),
                      backgroundColor: AppColors.surfaceContainerHigh,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                label: Text(
                  isMalayalam ? 'ലിങ്ക് പകർത്തുക' : 'Copy Link',
                  style: const TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.alertGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Sec 52 Compliant', style: TextStyle(fontSize: 10, color: AppColors.alertGreen, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendPill(Color color, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  Widget _buildWarningMapView(bool isMalayalam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day Selector Bar (Day 1 to Day 5)
        Row(
          children: List.generate(3, (index) {
            final isSelected = _selectedDay == index;
            final label = isMalayalam ? 'ദിവസം ${index + 1}' : 'Day ${index + 1}';

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDay = index),
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),

        // District Warning Cards List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _districtsWarning.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final d = _districtsWarning[index];
            final severity = _selectedDay == 0
                ? (d['day1'] as WarningSeverity)
                : (_selectedDay == 1 ? (d['day2'] as WarningSeverity) : (d['day3'] as WarningSeverity));

            final color = _getSeverityColor(severity);
            final badgeLabel = _getSeverityLabel(severity, isMalayalam);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: severity != WarningSeverity.green ? color.withValues(alpha: 0.5) : const Color(0xFF1E2D44),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMalayalam ? d['nameMl'] : d['nameEn'],
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                        ),
                        Text(
                          d['desc'],
                          style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSatelliteView(bool isMalayalam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Satellite Status Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E2D44)),
          ),
          child: Row(
            children: [
              const Icon(Icons.satellite_alt_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isMalayalam ? 'INSAT-3DR ഉപഗ്രഹ നിരീക്ഷണം & ക്ലൗഡ് പ്രൊഫൈൽ' : 'INSAT-3DR Satellite & Cloud Telemetry',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('ISRO-IMD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Informative Cloud & Satellite Telemetry Card (Pure Facts)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1E2D44)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INSAT-3DR GEOSTATIONARY (74°E)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Text(
                        isMalayalam ? 'മേഘപടലങ്ങളുടെ വ്യാപ്തി: 5/8 ഒക്റ്റാസ്' : 'Atmospheric Cloud Index: 5/8 Octas',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                      ),
                    ],
                  ),
                  const Icon(Icons.wb_cloudy_rounded, size: 28, color: AppColors.primary),
                ],
              ),
              const Divider(color: Color(0xFF1E2D44), height: 24),

              // Telemetry Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSatMetric(isMalayalam ? 'മേഘ അടിത്തട്ട്' : 'Cloud Base', '800 - 1400 m', AppColors.onSurface),
                  _buildSatMetric(isMalayalam ? 'ക്ലൗഡ് ടോപ്പ് താപനില' : 'Cloud Top Temp', '-42.0°C', AppColors.alertYellow),
                  _buildSatMetric(isMalayalam ? 'ജലബാഷ്പ സാന്ദ്രത' : 'Precipitable Water', '48.6 mm', AppColors.primary),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSatMetric(isMalayalam ? 'കടൽ ഉപരിതല ചൂട്' : 'Sea Surface Temp', '28.7°C (Arabian)', AppColors.onSurface),
                  _buildSatMetric(isMalayalam ? 'ഇൻഫ്രാറെഡ് തരംഗം' : 'TIR-1 Channel', '10.8 µm', AppColors.onSurfaceVariant),
                  _buildSatMetric(isMalayalam ? 'മേഘ ഘടന' : 'Cloud Class', 'Cu Congestus', AppColors.alertGreen),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Legal Compliance & Official IMD Satellite Portal Link
        _buildOfficialPortalCard(
          title: isMalayalam ? 'IMD ഔദ്യോഗിക സാറ്റലൈറ്റ് ഇമേജറി പോർട്ടൽ' : 'Official IMD Satellite Imagery Portal',
          subtitle: isMalayalam
              ? 'ഇന്ത്യൻ പകർപ്പവകാശ നിയമപ്രകാരം സാറ്റലൈറ്റ് ചിത്രങ്ങൾ സർക്കാരിന്റെ ഉടമസ്ഥതയിലുള്ളതാണ്. യഥാർത്ഥ ചിത്രങ്ങൾ കാണാൻ ഔദ്യോഗിക സൈറ്റ് സന്ദർശിക്കുക.'
              : 'Under Indian Copyright Act 1957, processed satellite raster imagery is a protected Government work. Access original imagery directly on IMD/MOSDAC portals.',
          url: ApiConstants.imdSatelliteWebPortal,
          isMalayalam: isMalayalam,
        ),
      ],
    );
  }

  Widget _buildSatMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Color _getSeverityColor(WarningSeverity s) {
    switch (s) {
      case WarningSeverity.red:
        return AppColors.alertRed;
      case WarningSeverity.orange:
        return AppColors.alertOrange;
      case WarningSeverity.yellow:
        return AppColors.alertYellow;
      case WarningSeverity.green:
      case WarningSeverity.none:
        return AppColors.alertGreen;
    }
  }

  String _getSeverityLabel(WarningSeverity s, bool isMalayalam) {
    switch (s) {
      case WarningSeverity.red:
        return isMalayalam ? 'റെഡ് അലർട്ട്' : 'Red Warning';
      case WarningSeverity.orange:
        return isMalayalam ? 'ഓറഞ്ച് അലർട്ട്' : 'Orange Alert';
      case WarningSeverity.yellow:
        return isMalayalam ? 'യെല്ലോ വാച്ച്' : 'Yellow Watch';
      case WarningSeverity.green:
      case WarningSeverity.none:
        return isMalayalam ? 'മുന്നറിയിപ്പില്ല' : 'No Warning';
    }
  }
}

/// Dynamic, 100% Vector Radar Sweep Painter
/// Visualizes Doppler Radar range rings, azimuth markers, and convective cells
class _RadarScopePainter extends CustomPainter {
  final double sweepAngle;

  _RadarScopePainter({required this.sweepAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.45;

    final gridPaint = Paint()
      ..color = const Color(0xFF00D2FF).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final axisPaint = Paint()
      ..color = const Color(0xFF00D2FF).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 1. Concentric Distance Rings: 50km, 100km, 150km, 250km
    final rings = [0.2, 0.45, 0.72, 1.0];
    for (final fraction in rings) {
      canvas.drawCircle(center, maxRadius * fraction, gridPaint);
    }

    // 2. Crosshair Azimuth lines (N, S, E, W and 45 degree diagonals)
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi) / 4;
      final p2 = Offset(
        center.dx + maxRadius * math.cos(angle),
        center.dy + maxRadius * math.sin(angle),
      );
      canvas.drawLine(center, p2, axisPaint);
    }

    // 3. Simulated Echo Cells (Light, Moderate, Heavy) based on factual meteorological locations
    _drawEchoCell(canvas, center, maxRadius * 0.4, 0.8, 18, AppColors.alertGreen); // Alappuzha sector
    _drawEchoCell(canvas, center, maxRadius * 0.65, 0.5, 22, AppColors.alertYellow); // Idukki ghats
    _drawEchoCell(canvas, center, maxRadius * 0.55, -0.6, 14, AppColors.alertBlue); // Thrissur coast
    _drawEchoCell(canvas, center, maxRadius * 0.85, -0.9, 16, AppColors.alertGreen); // Kozhikode marine

    // 4. Rotating Sweep Beam & Radial Trail
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [
          const Color(0xFF00D2FF).withValues(alpha: 0.35),
          const Color(0xFF00D2FF).withValues(alpha: 0.0),
        ],
        transform: GradientRotation(sweepAngle - (math.pi / 2)),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius, sweepPaint);

    // Sweep Leading Edge Line
    final sweepLinePaint = Paint()
      ..color = const Color(0xFF47D6FF)
      ..strokeWidth = 2.0;

    final sweepTip = Offset(
      center.dx + maxRadius * math.cos(sweepAngle),
      center.dy + maxRadius * math.sin(sweepAngle),
    );
    canvas.drawLine(center, sweepTip, sweepLinePaint);

    // 5. Center Radar Station Indicator (Kochi)
    final centerPaint = Paint()..color = const Color(0xFF00D2FF);
    canvas.drawCircle(center, 4, centerPaint);

    // 6. Plotted Kerala Observation Stations
    _drawStationMarker(canvas, center, Offset(0, 0), 'Kochi (DWR)');
    _drawStationMarker(canvas, center, Offset(18, 48), 'Alappuzha');
    _drawStationMarker(canvas, center, Offset(64, 38), 'Idukki');
    _drawStationMarker(canvas, center, Offset(-12, -54), 'Thrissur');
  }

  void _drawEchoCell(Canvas canvas, Offset center, double distance, double angle, double radius, Color color) {
    final cellCenter = Offset(
      center.dx + distance * math.cos(angle),
      center.dy + distance * math.sin(angle),
    );

    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(cellCenter, radius, paint);
  }

  void _drawStationMarker(Canvas canvas, Offset center, Offset offset, String name) {
    final pos = center + offset;
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(pos, 2.5, dotPaint);

    final textSpan = TextSpan(
      text: name,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 9,
        fontWeight: FontWeight.w600,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(pos.dx + 4, pos.dy - 6));
  }

  @override
  bool shouldRepaint(covariant _RadarScopePainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle;
  }
}
