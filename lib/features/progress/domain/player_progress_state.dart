import 'package:equatable/equatable.dart';

class PlayerProgressState extends Equatable {
  const PlayerProgressState({
    this.version = 1,
    this.highestUnlockedLevel = 1,
    this.coins = 0,
    this.hints = 5,
    this.levels = const {},
    this.perfectCompletions = 0,
    this.totalBonusNodesCollected = 0,
    this.dailyChallengeDate,
    this.dailyChallengeCompleted = false,
  });

  final int version;
  final int highestUnlockedLevel;
  final int coins;
  final int hints;
  final Map<int, LevelProgressEntry> levels;
  final int perfectCompletions;
  final int totalBonusNodesCollected;
  final String? dailyChallengeDate;
  final bool dailyChallengeCompleted;

  int get levelsCompleted =>
      levels.values.where((e) => e.completed).length;

  int get totalStars =>
      levels.values.fold(0, (sum, e) => sum + e.stars);

  LevelProgressEntry? entryFor(int levelId) => levels[levelId];

  bool isUnlocked(int levelId) => levelId <= highestUnlockedLevel;

  PlayerProgressState copyWith({
    int? version,
    int? highestUnlockedLevel,
    int? coins,
    int? hints,
    Map<int, LevelProgressEntry>? levels,
    int? perfectCompletions,
    int? totalBonusNodesCollected,
    String? dailyChallengeDate,
    bool? dailyChallengeCompleted,
  }) {
    return PlayerProgressState(
      version: version ?? this.version,
      highestUnlockedLevel: highestUnlockedLevel ?? this.highestUnlockedLevel,
      coins: coins ?? this.coins,
      hints: hints ?? this.hints,
      levels: levels ?? this.levels,
      perfectCompletions: perfectCompletions ?? this.perfectCompletions,
      totalBonusNodesCollected:
          totalBonusNodesCollected ?? this.totalBonusNodesCollected,
      dailyChallengeDate: dailyChallengeDate ?? this.dailyChallengeDate,
      dailyChallengeCompleted:
          dailyChallengeCompleted ?? this.dailyChallengeCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'highestUnlockedLevel': highestUnlockedLevel,
        'coins': coins,
        'hints': hints,
        'perfectCompletions': perfectCompletions,
        'totalBonusNodesCollected': totalBonusNodesCollected,
        'dailyChallengeDate': dailyChallengeDate,
        'dailyChallengeCompleted': dailyChallengeCompleted,
        'levels': levels.map((k, v) => MapEntry(k.toString(), v.toJson())),
      };

  factory PlayerProgressState.fromJson(Map<String, dynamic> json) {
    final levelsJson = json['levels'] as Map<String, dynamic>? ?? {};
    return PlayerProgressState(
      version: json['version'] as int? ?? 1,
      highestUnlockedLevel: json['highestUnlockedLevel'] as int? ?? 1,
      coins: json['coins'] as int? ?? 0,
      hints: json['hints'] as int? ?? 5,
      perfectCompletions: json['perfectCompletions'] as int? ?? 0,
      totalBonusNodesCollected: json['totalBonusNodesCollected'] as int? ?? 0,
      dailyChallengeDate: json['dailyChallengeDate'] as String?,
      dailyChallengeCompleted: json['dailyChallengeCompleted'] as bool? ?? false,
      levels: levelsJson.map(
        (k, v) => MapEntry(
          int.parse(k),
          LevelProgressEntry.fromJson(v as Map<String, dynamic>),
        ),
      ),
    );
  }

  static const empty = PlayerProgressState();

  @override
  List<Object?> get props => [
        version,
        highestUnlockedLevel,
        coins,
        hints,
        levels,
        perfectCompletions,
        totalBonusNodesCollected,
        dailyChallengeDate,
        dailyChallengeCompleted,
      ];
}

class LevelProgressEntry extends Equatable {
  const LevelProgressEntry({
    this.completed = false,
    this.stars = 0,
    this.bestScore = 0,
    this.bestMoves,
    this.bestTime,
  });

  final bool completed;
  final int stars;
  final int bestScore;
  final int? bestMoves;
  final double? bestTime;

  LevelProgressEntry copyWith({
    bool? completed,
    int? stars,
    int? bestScore,
    int? bestMoves,
    double? bestTime,
  }) {
    return LevelProgressEntry(
      completed: completed ?? this.completed,
      stars: stars ?? this.stars,
      bestScore: bestScore ?? this.bestScore,
      bestMoves: bestMoves ?? this.bestMoves,
      bestTime: bestTime ?? this.bestTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'completed': completed,
        'stars': stars,
        'bestScore': bestScore,
        'bestMoves': bestMoves,
        'bestTime': bestTime,
      };

  factory LevelProgressEntry.fromJson(Map<String, dynamic> json) =>
      LevelProgressEntry(
        completed: json['completed'] as bool? ?? false,
        stars: json['stars'] as int? ?? 0,
        bestScore: json['bestScore'] as int? ?? 0,
        bestMoves: json['bestMoves'] as int?,
        bestTime: (json['bestTime'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props =>
      [completed, stars, bestScore, bestMoves, bestTime];
}
