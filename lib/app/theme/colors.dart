import 'package:flutter/material.dart';

import '../../features/gameplay/domain/models/color_id.dart';

class AppColors {
  AppColors._();

  // Brand / UI — teal-coral original identity (not Flow Free palette)
  static const Color brandTeal = Color(0xFF0D9488);
  static const Color brandCoral = Color(0xFFE11D48);
  static const Color brandAmber = Color(0xFFF59E0B);
  static const Color brandInk = Color(0xFF0F172A);
  static const Color brandMist = Color(0xFFF0FDFA);

  static const Color lightBackgroundTop = Color(0xFFECFDF5);
  static const Color lightBackgroundBottom = Color(0xFFF8FAFC);
  static const Color lightBoard = Color(0xFFFFFFFF);
  static const Color lightGrid = Color(0xFFCBD5E1);
  static const Color lightBlocked = Color(0xFF94A3B8);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightMuted = Color(0xFF64748B);

  static const Color darkBackgroundTop = Color(0xFF0B1220);
  static const Color darkBackgroundBottom = Color(0xFF111827);
  static const Color darkBoard = Color(0xFF1E293B);
  static const Color darkGrid = Color(0xFF334155);
  static const Color darkBlocked = Color(0xFF475569);
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkMuted = Color(0xFF94A3B8);

  static Color gameplayColor(ColorId id) {
    switch (id) {
      case ColorId.red:
        return const Color(0xFFFF2D68);
      case ColorId.blue:
        return const Color(0xFF2563EB);
      case ColorId.green:
        return const Color(0xFF16A34A);
      case ColorId.yellow:
        return const Color(0xFFEAB308);
      case ColorId.orange:
        return const Color(0xFFF97316);
      case ColorId.purple:
        return const Color(0xFF7C3AED);
      case ColorId.cyan:
        return const Color(0xFF06B6D4);
      case ColorId.pink:
        return const Color(0xFFDB2777);
    }
  }

  static Color gameplayDark(ColorId id) =>
      Color.lerp(gameplayColor(id), Colors.black, 0.25)!;

  static Color gameplayLight(ColorId id) =>
      Color.lerp(gameplayColor(id), Colors.white, 0.35)!;

  static Color gameplayGlow(ColorId id) =>
      gameplayColor(id).withValues(alpha: 0.45);
}

class BoardVisualConfig {
  const BoardVisualConfig({
    required this.boardFill,
    required this.gridLine,
    required this.blockedFill,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.pathWidthFactor,
    required this.endpointRadiusFactor,
  });

  final Color boardFill;
  final Color gridLine;
  final Color blockedFill;
  final Color backgroundTop;
  final Color backgroundBottom;
  final double pathWidthFactor;
  final double endpointRadiusFactor;

  factory BoardVisualConfig.light() => const BoardVisualConfig(
        boardFill: AppColors.lightBoard,
        gridLine: AppColors.lightGrid,
        blockedFill: AppColors.lightBlocked,
        backgroundTop: AppColors.lightBackgroundTop,
        backgroundBottom: AppColors.lightBackgroundBottom,
        pathWidthFactor: 0.4,
        endpointRadiusFactor: 0.4,
      );

  factory BoardVisualConfig.dark() => const BoardVisualConfig(
        boardFill: AppColors.darkBoard,
        gridLine: AppColors.darkGrid,
        blockedFill: AppColors.darkBlocked,
        backgroundTop: AppColors.darkBackgroundTop,
        backgroundBottom: AppColors.darkBackgroundBottom,
        pathWidthFactor: 0.38,
        endpointRadiusFactor: 0.32,
      );
}
