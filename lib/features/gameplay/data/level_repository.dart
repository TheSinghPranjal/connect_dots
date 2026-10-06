import '../domain/models/level_definition.dart';
import 'campaign_level_factory.dart';

abstract class LevelRepository {
  Future<List<LevelDefinition>> getAllLevels();
  Future<LevelDefinition> getLevel(int levelNumber);
  int get levelCount;
}

class LocalLevelRepository implements LevelRepository {
  LocalLevelRepository({CampaignLevelFactory? factory})
      : _factory = factory ?? CampaignLevelFactory();

  final CampaignLevelFactory _factory;
  List<LevelDefinition>? _levels;

  @override
  int get levelCount => 100;

  @override
  Future<List<LevelDefinition>> getAllLevels() async {
    _levels ??= _factory.buildAll();
    return _levels!;
  }

  @override
  Future<LevelDefinition> getLevel(int levelNumber) async {
    final all = await getAllLevels();
    if (levelNumber < 1 || levelNumber > all.length) {
      throw StateError('Level $levelNumber not found');
    }
    final level = all[levelNumber - 1];
    if (levelNumber == 1) {
      return LevelDefinition(
        levelNumber: level.levelNumber,
        rows: level.rows,
        columns: level.columns,
        endpoints: level.endpoints,
        blockedCells: level.blockedCells,
        specialTiles: level.specialTiles,
        difficulty: level.difficulty,
        targetMoves: level.targetMoves,
        timeLimitSeconds: level.timeLimitSeconds,
        moveLimit: level.moveLimit,
        objective: level.objective,
        requiredBonusNodes: level.requiredBonusNodes,
        tutorialData: const {'showHand': true},
      );
    }
    return level;
  }
}
