# Flow Dots

An original mobile path-connecting puzzle game built with Flutter and Riverpod.

Connect matching colored endpoints with non-crossing paths and fill every playable cell.

> Inspired by the broad gameplay feel of path puzzles and drag-to-connect games — all branding, levels, art, and systems are original.

## Game name

Change the display name in one place:

```dart
// lib/core/constants/game_constants.dart
static const String gameName = 'Flow Dots';
```

## Architecture

```
lib/
  app/                  # MaterialApp, theme, router
  core/                 # constants, geometry, audio, storage, providers
  features/
    gameplay/           # domain engine, levels, board UI
    home/
    level_selection/
    progress/
    settings/
    results / stats / daily / how_to_play
  shared/
```

- **Domain engine** (`FlowGameEngine`) is pure Dart — no Flutter UI types.
- **Riverpod** owns gameplay, progress, and settings state.
- **CustomPainter** renders the board; it never decides win/lose.
- **Persistence** via `SharedPreferences` behind repository interfaces.

## Gameplay rules

1. Each color has exactly two endpoints.
2. Paths move only horizontally/vertically.
3. Paths cannot permanently overlap or cross.
4. Blocked cells cannot be entered and do not need filling.
5. A level is won only when every pair is connected **and** every fillable cell is occupied.

## Loss conditions

- Levels **1–90**: no hard loss — edit, undo, restart freely.
- Levels **91–100**: challenge mode with move limits (and optional timers). Exceeding the limit shows **OUT OF MOVES** / **TIME'S UP**.

## Levels

Exactly **100** campaign levels are built deterministically by `CampaignLevelFactory` using fixed seeds and a space-filling path splitter (`LevelGenerator`).

Progression:

| Levels | Board | Focus |
|--------|-------|--------|
| 1–10 | 4×4 | Tutorial |
| 11–30 | 5×5 | Easy → medium |
| 31–50 | 6×6 | Medium → hard |
| 51–70 | 7×7 | Blocked cells, bonus nodes |
| 71–90 | 8×8 | Hard / expert |
| 91–100 | 9×9 | Challenge (move limits) |

### How to add Level 101

1. Extend `CampaignLevelFactory._specFor` (or load JSON).
2. Bump `GameConstants.totalCampaignLevels`.
3. Add solver coverage in `test/level_validation/`.
4. Run `flutter test`.

## Riverpod providers

| Provider | Role |
|----------|------|
| `gameControllerProvider` | Active session, pointer commands |
| `progressControllerProvider` | Unlock, stars, coins, hints |
| `settingsControllerProvider` | Sound, haptics, color assist, theme |
| `levelRepositoryProvider` | Campaign level access |
| `audioManagerProvider` | Sound hooks (no-op by default) |

## Win / persistence

On completion the controller computes `LevelResult`, awards coins/stars, unlocks the next level, and writes progress through `ProgressRepository`.

## Run

```bash
flutter pub get
flutter run
flutter test
flutter analyze
flutter build apk --debug
```

## Tests

- `test/gameplay/` — engine, adjacency, backtracking, win rules
- `test/level_validation/` — 100 levels schema + solvability samples
- `test/progress/` — unlock / JSON
- `test/scoring/` — stars / non-negative score

## Debug (dev only)

Use Riverpod overrides or call:

- `progressController.unlockAllLevels(100)`
- `progressController.addCoins` / `addHints`
- `LevelValidator` / `LevelSolver` in tests

## Platforms

Android / iOS phones and tablets — portrait-first, square responsive board, SafeArea respected.

## Audio / ads / analytics

Abstractions as no-ops (`AudioManager`, `AdService`, `AnalyticsService`) so the game runs offline without assets or SDKs.
