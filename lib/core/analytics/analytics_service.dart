abstract class AnalyticsService {
  void logEvent(String name, [Map<String, Object?> params = const {}]);
}

class NoOpAnalyticsService implements AnalyticsService {
  @override
  void logEvent(String name, [Map<String, Object?> params = const {}]) {}
}

abstract class AdService {
  Future<void> showInterstitial();
  Future<void> showRewarded();
  Future<bool> isRewardedAvailable();
}

class NoOpAdService implements AdService {
  @override
  Future<void> showInterstitial() async {}

  @override
  Future<void> showRewarded() async {}

  @override
  Future<bool> isRewardedAvailable() async => false;
}
