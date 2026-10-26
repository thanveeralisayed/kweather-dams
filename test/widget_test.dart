import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kweather/main.dart';
import 'package:kweather/screens/main_shell.dart';
import 'package:kweather/screens/weather/weather_dashboard_screen.dart';
import 'package:kweather/screens/dams/dam_reservoir_screen.dart';
import 'package:kweather/screens/radar/radar_map_screen.dart';
import 'package:kweather/screens/bulletins/bulletins_screen.dart';
import 'package:kweather/core/widgets/kweather_monochrome_icon.dart';

void main() {
  group('Phase 4: Widget Integration Tests', () {
    testWidgets('KWeatherApp renders MainShell with bottom navigation tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: KWeatherApp(),
        ),
      );

      // Verify MainShell is rendered
      expect(find.byType(MainShell), findsOneWidget);

      // Verify WeatherDashboardScreen is present in widget tree
      expect(find.byType(WeatherDashboardScreen), findsOneWidget);

      // Verify bottom navigation bar has the 4 defined tabs
      expect(find.text('Weather'), findsOneWidget);
      expect(find.text('Dams'), findsOneWidget);
      expect(find.text('Radar & Map'), findsOneWidget);
      expect(find.text('Bulletins'), findsOneWidget);
    });

    testWidgets('Navigation bar switches between Weather, Dams, Radar, Bulletins', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: KWeatherApp(),
        ),
      );

      // Initially Weather Dashboard is visible
      expect(find.byType(WeatherDashboardScreen), findsOneWidget);

      // Tap on Dams Tab
      await tester.tap(find.text('Dams'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(DamReservoirScreen), findsOneWidget);

      // Tap on Radar Tab
      await tester.tap(find.text('Radar & Map'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(RadarMapScreen), findsOneWidget);

      // Tap on Bulletins Tab
      await tester.tap(find.text('Bulletins'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(BulletinsScreen), findsOneWidget);

      // Switch back to Weather Tab
      await tester.tap(find.text('Weather'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(WeatherDashboardScreen), findsOneWidget);
    });

    testWidgets('Language toggle switches between English and Malayalam', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: KWeatherApp(),
        ),
      );

      // Default is English, language toggle chip shows 'മലയാളം'
      expect(find.text('മലയാളം'), findsOneWidget);

      // Tap on the language toggle
      await tester.tap(find.text('മലയാളം'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Now active language is Malayalam, chip shows 'English'
      expect(find.text('English'), findsOneWidget);

      // Navigation labels are in Malayalam
      expect(find.text('കാലാവസ്ഥ'), findsOneWidget);
      expect(find.text('ഡാമുകൾ'), findsOneWidget);
      expect(find.text('റഡാർ'), findsOneWidget);
      expect(find.text('മുന്നറിയിപ്പ്'), findsOneWidget);

      // Tap again to switch back
      await tester.tap(find.text('English'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('മലയാളം'), findsOneWidget);
      expect(find.text('Weather'), findsOneWidget);
    });

    testWidgets('RadarMapScreen renders 100% vector radar scope without proprietary Image.network', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RadarMapScreen(),
            ),
          ),
        ),
      );

      // Advance one animation tick
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Must find CustomPaint for vector radar scope
      expect(find.byType(CustomPaint), findsWidgets);

      // Must find official radar telemetry text
      expect(find.text('Kochi DWR Radar • Live Telemetry Scope'), findsOneWidget);
      expect(find.text('250 km PPI'), findsOneWidget);

      // Copyright compliance guarantee: Zero Image.network calls for proprietary satellite/radar imagery
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('DamReservoirScreen displays statewide storage and authority tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DamReservoirScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Statewide storage summary banner
      expect(find.text('Statewide Reservoir Storage'), findsOneWidget);
      expect(find.text('37 Major Dams (17 KSEB + 20 Irrigation)'), findsOneWidget);

      // Authority filter tabs
      expect(find.text('All Dams (37)'), findsOneWidget);
      expect(find.text('KSEB Hydro (17)'), findsOneWidget);
      expect(find.text('Irrigation (20)'), findsOneWidget);
    });

    testWidgets('KWeatherMonochromeIcon renders custom vector painter and adapts to color and background', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                KWeatherMonochromeIcon(size: 48, color: Colors.white),
                KWeatherMonochromeIcon(size: 32, withBackground: true),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(KWeatherMonochromeIcon), findsNWidgets(2));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('MainShell displays KWeatherMonochromeIcon in top AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: KWeatherApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Must find KWeatherMonochromeIcon in AppBar
      expect(find.descendant(of: find.byType(AppBar), matching: find.byType(KWeatherMonochromeIcon)), findsOneWidget);
    });
  });
}
