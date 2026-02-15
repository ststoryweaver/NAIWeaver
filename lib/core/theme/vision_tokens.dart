import 'package:flutter/material.dart';
import 'app_theme_config.dart';

/// Semantic design tokens derived from AppThemeConfig.
/// Replaces UiColors and provides all color/font tokens for the app.
class VisionTokens {
  final AppThemeConfig _config;

  VisionTokens(this._config);

  // — Colors —
  Color get background => _config.background;
  Color get surfaceHigh => _config.surfaceHigh;
  Color get surfaceMid => _config.surfaceMid;
  Color get textPrimary => _config.brightMode ? _config.textPrimary : _config.textDisabled;
  Color get textSecondary => _config.brightMode ? _config.textSecondary : _config.textDisabled;
  Color get textTertiary => _config.brightMode ? _config.textTertiary : _config.textDisabled;
  Color get textDisabled => _config.textDisabled;
  Color get textMinimal => _config.textMinimal;
  Color get borderStrong => _config.borderStrong;
  Color get borderMedium => _config.borderMedium;
  Color get borderSubtle => _config.borderSubtle;
  Color get accent => _config.accent;
  Color get accentEdit => _config.accentEdit;
  Color get accentSuccess => _config.accentSuccess;
  Color get accentDanger => _config.accentDanger;
  Color get logoColor => _config.logoColor;
  Color get accentCascade => _config.accentCascade;
  Color get accentVibeTransfer => _config.accentVibeTransfer;
  Color get accentRefCharacter => _config.accentRefCharacter;
  Color get accentRefStyle => _config.accentRefStyle;
  Color get accentRefCharStyle => _config.accentRefCharStyle;

  // — Backward-compatible aliases (replaces UiColors) —
  Color get headerText => textPrimary;
  Color get secondaryText => textSecondary;
  Color get hintText => textTertiary;

  // — Font —
  String get fontFamily => _config.fontFamily;
  double get fontScale => _config.fontScale;

  /// Returns a scaled font size. Use as: `t.fontSize(12)`.
  double fontSize(num base) => base.toDouble() * _config.fontScale;

  // — Prompt input —
  double get promptFontSize => _config.promptFontSize * _config.fontScale;
  int get promptMaxLines => _config.promptMaxLines;

  // — Bright mode —
  bool get brightMode => _config.brightMode;
}
