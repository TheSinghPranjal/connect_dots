/// Central game configuration. Change [gameName] to rebrand.
class GameConstants {
  GameConstants._();

  static const String gameName = 'Flow Dots';
  static const String gameTagline = 'Connect. Fill. Flow.';
  static const int totalCampaignLevels = 100;
  static const int maxUndoStack = 30;
  static const int startingHints = 5;
  static const int startingCoins = 0;

  /// Coins
  static const int coinsPerLevel = 10;
  static const int coinsTwoStarBonus = 5;
  static const int coinsThreeStarBonus = 10;
  static const int coinsPerfectBonus = 10;
  static const int coinsMilestone50 = 50;
  static const int coinsCampaignComplete = 200;

  /// Scoring
  static const int pointsPerCell = 10;
  static const int constrainedRegionBonus = 50;
  static const int bonusNodePoints = 25;
  static const int completionColorBonus = 100;
  static const int coverageBonus = 100;
  static const int efficiencyBonusPerMove = 25;
  static const int perfectBonus = 200;
  static const int hintPenalty = 50;

  /// Layout
  static const double maxBoardLogicalWidth = 680;
  static const double boardPadding = 16;
  static const double minTouchTarget = 48;

  /// Animation timings (seconds)
  static const double endpointPulseDuration = 0.15;
  static const double pathSettleDuration = 0.2;
  static const double boardGlowDuration = 0.25;
  static const double starRevealInterval = 0.15;
  static const double scoreCountDuration = 0.6;
  static const double hintHighlightDuration = 1.5;
  static const double invalidWobbleDuration = 0.25;

  /// Progress schema
  static const int progressSchemaVersion = 1;
}
