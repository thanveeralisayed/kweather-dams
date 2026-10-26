import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettingsState {
  final bool isMalayalam;
  final bool isOfflineBannerDismissed;

  const AppSettingsState({
    this.isMalayalam = false,
    this.isOfflineBannerDismissed = false,
  });

  AppSettingsState copyWith({
    bool? isMalayalam,
    bool? isOfflineBannerDismissed,
  }) {
    return AppSettingsState(
      isMalayalam: isMalayalam ?? this.isMalayalam,
      isOfflineBannerDismissed: isOfflineBannerDismissed ?? this.isOfflineBannerDismissed,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() => const AppSettingsState();

  void toggleLanguage() {
    state = state.copyWith(isMalayalam: !state.isMalayalam);
  }

  void setMalayalam(bool enabled) {
    state = state.copyWith(isMalayalam: enabled);
  }

  void dismissOfflineBanner() {
    state = state.copyWith(isOfflineBannerDismissed: true);
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettingsState>(() {
  return AppSettingsNotifier();
});
