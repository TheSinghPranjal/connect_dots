import 'package:flutter/services.dart';

abstract class HapticsManager {
  Future<void> light();
  Future<void> medium();
  Future<void> selection();
  Future<void> warning();
  Future<void> success();
  void setEnabled(bool enabled);
}

class SystemHapticsManager implements HapticsManager {
  bool _enabled = true;

  @override
  void setEnabled(bool enabled) => _enabled = enabled;

  @override
  Future<void> light() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  @override
  Future<void> medium() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  @override
  Future<void> selection() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }

  @override
  Future<void> warning() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  @override
  Future<void> success() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }
}
