enum CellType {
  empty,
  endpoint,
  path,
  blocked,
  special,
}

enum SpecialTileType {
  bonusNode,
  frozen,
  directionIndicator,
}

enum Difficulty {
  tutorial,
  easy,
  medium,
  hard,
  expert,
}

enum LevelObjectiveType {
  normal,
  bonusCollection,
  efficiency,
  timeChallenge,
  perfect,
}

enum GameplayStatus {
  ready,
  playing,
  paused,
  completing,
  completed,
  failed,
}

enum ChallengeFailReason {
  outOfMoves,
  timeUp,
}
