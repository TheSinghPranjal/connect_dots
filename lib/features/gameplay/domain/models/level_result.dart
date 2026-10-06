import 'package:equatable/equatable.dart';

import 'cell_type.dart';

class LevelScore extends Equatable {
  const LevelScore({
    this.total = 0,
    this.pathPoints = 0,
    this.completionBonus = 0,
    this.coverageBonus = 0,
    this.efficiencyBonus = 0,
    this.perfectBonus = 0,
    this.comboBonus = 0,
    this.bonusNodePoints = 0,
    this.hintPenalty = 0,
    this.comboMultiplier = 1,
  });

  final int total;
  final int pathPoints;
  final int completionBonus;
  final int coverageBonus;
  final int efficiencyBonus;
  final int perfectBonus;
  final int comboBonus;
  final int bonusNodePoints;
  final int hintPenalty;
  final int comboMultiplier;

  LevelScore copyWith({
    int? total,
    int? pathPoints,
    int? completionBonus,
    int? coverageBonus,
    int? efficiencyBonus,
    int? perfectBonus,
    int? comboBonus,
    int? bonusNodePoints,
    int? hintPenalty,
    int? comboMultiplier,
  }) {
    return LevelScore(
      total: total ?? this.total,
      pathPoints: pathPoints ?? this.pathPoints,
      completionBonus: completionBonus ?? this.completionBonus,
      coverageBonus: coverageBonus ?? this.coverageBonus,
      efficiencyBonus: efficiencyBonus ?? this.efficiencyBonus,
      perfectBonus: perfectBonus ?? this.perfectBonus,
      comboBonus: comboBonus ?? this.comboBonus,
      bonusNodePoints: bonusNodePoints ?? this.bonusNodePoints,
      hintPenalty: hintPenalty ?? this.hintPenalty,
      comboMultiplier: comboMultiplier ?? this.comboMultiplier,
    );
  }

  @override
  List<Object?> get props => [
        total,
        pathPoints,
        completionBonus,
        coverageBonus,
        efficiencyBonus,
        perfectBonus,
        comboBonus,
        bonusNodePoints,
        hintPenalty,
        comboMultiplier,
      ];
}

class LevelResult extends Equatable {
  const LevelResult({
    required this.levelId,
    required this.completed,
    required this.stars,
    required this.score,
    required this.movesUsed,
    required this.timeUsedSeconds,
    required this.coverage,
    required this.usedHint,
    required this.wasPerfect,
    required this.bonusCollected,
    required this.coinsEarned,
    this.bestScore,
    this.isNewBest = false,
    this.failReason,
  });

  final int levelId;
  final bool completed;
  final int stars;
  final int score;
  final int movesUsed;
  final double timeUsedSeconds;
  final double coverage;
  final bool usedHint;
  final bool wasPerfect;
  final int bonusCollected;
  final int coinsEarned;
  final int? bestScore;
  final bool isNewBest;
  final ChallengeFailReason? failReason;

  @override
  List<Object?> get props => [
        levelId,
        completed,
        stars,
        score,
        movesUsed,
        timeUsedSeconds,
        coverage,
        usedHint,
        wasPerfect,
        bonusCollected,
        coinsEarned,
        bestScore,
        isNewBest,
        failReason,
      ];
}
