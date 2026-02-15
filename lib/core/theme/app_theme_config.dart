import 'dart:convert';
import 'package:flutter/material.dart';

class AppThemeConfig {
  final String id;
  final String name;
  final bool isBuiltIn;

  // Colors
  final Color background;
  final Color surfaceHigh;
  final Color surfaceMid;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color textMinimal;
  final Color borderStrong;
  final Color borderMedium;
  final Color borderSubtle;
  final Color accent;
  final Color accentEdit;
  final Color accentSuccess;
  final Color accentDanger;
  final Color logoColor;
  final Color accentCascade;
  final Color accentVibeTransfer;
  final Color accentRefCharacter;
  final Color accentRefStyle;
  final Color accentRefCharStyle;

  // Font
  final String fontFamily;
  final double fontScale;

  // Prompt input
  final double promptFontSize;
  final int promptMaxLines;

  // Bright mode
  final bool brightMode;

  const AppThemeConfig({
    required this.id,
    required this.name,
    this.isBuiltIn = false,
    this.background = const Color(0xFF000000),
    this.surfaceHigh = const Color(0xFF0A0A0A),
    this.surfaceMid = const Color(0xFF050505),
    this.textPrimary = const Color(0xFFFFFFFF),
    this.textSecondary = const Color(0xC0FFFFFF), // white75
    this.textTertiary = const Color(0x78FFFFFF), // white47
    this.textDisabled = const Color(0x4FFFFFFF), // white31
    this.textMinimal = const Color(0x30FFFFFF), // white19
    this.borderStrong = const Color(0x3DFFFFFF), // white24
    this.borderMedium = const Color(0x1AFFFFFF), // white ~0.1
    this.borderSubtle = const Color(0x0DFFFFFF), // white ~0.05
    this.accent = const Color(0xFFFAFAFA),
    this.accentEdit = const Color(0xFFFF0066),
    this.accentSuccess = const Color(0xFF69F0AE), // greenAccent
    this.accentDanger = const Color(0xFFFF5252), // redAccent
    this.logoColor = const Color(0xFFFAFAFA),
    this.accentCascade = const Color(0xFF00BCD4),
    this.accentVibeTransfer = const Color(0xFF4CAF50),
    this.accentRefCharacter = const Color(0xFF18FFFF),
    this.accentRefStyle = const Color(0xFFFF00FF),
    this.accentRefCharStyle = const Color(0xFFFFD700),
    this.fontFamily = 'JetBrains Mono',
    this.fontScale = 1.0,
    this.promptFontSize = 13.0,
    this.promptMaxLines = 2,
    this.brightMode = true,
  });

  AppThemeConfig copyWith({
    String? id,
    String? name,
    bool? isBuiltIn,
    Color? background,
    Color? surfaceHigh,
    Color? surfaceMid,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? textMinimal,
    Color? borderStrong,
    Color? borderMedium,
    Color? borderSubtle,
    Color? accent,
    Color? accentEdit,
    Color? accentSuccess,
    Color? accentDanger,
    Color? logoColor,
    Color? accentCascade,
    Color? accentVibeTransfer,
    Color? accentRefCharacter,
    Color? accentRefStyle,
    Color? accentRefCharStyle,
    String? fontFamily,
    double? fontScale,
    double? promptFontSize,
    int? promptMaxLines,
    bool? brightMode,
  }) {
    return AppThemeConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      background: background ?? this.background,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceMid: surfaceMid ?? this.surfaceMid,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      textMinimal: textMinimal ?? this.textMinimal,
      borderStrong: borderStrong ?? this.borderStrong,
      borderMedium: borderMedium ?? this.borderMedium,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      accent: accent ?? this.accent,
      accentEdit: accentEdit ?? this.accentEdit,
      accentSuccess: accentSuccess ?? this.accentSuccess,
      accentDanger: accentDanger ?? this.accentDanger,
      logoColor: logoColor ?? this.logoColor,
      accentCascade: accentCascade ?? this.accentCascade,
      accentVibeTransfer: accentVibeTransfer ?? this.accentVibeTransfer,
      accentRefCharacter: accentRefCharacter ?? this.accentRefCharacter,
      accentRefStyle: accentRefStyle ?? this.accentRefStyle,
      accentRefCharStyle: accentRefCharStyle ?? this.accentRefCharStyle,
      fontFamily: fontFamily ?? this.fontFamily,
      fontScale: fontScale ?? this.fontScale,
      promptFontSize: promptFontSize ?? this.promptFontSize,
      promptMaxLines: promptMaxLines ?? this.promptMaxLines,
      brightMode: brightMode ?? this.brightMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isBuiltIn': isBuiltIn,
    'background': background.toARGB32(),
    'surfaceHigh': surfaceHigh.toARGB32(),
    'surfaceMid': surfaceMid.toARGB32(),
    'textPrimary': textPrimary.toARGB32(),
    'textSecondary': textSecondary.toARGB32(),
    'textTertiary': textTertiary.toARGB32(),
    'textDisabled': textDisabled.toARGB32(),
    'textMinimal': textMinimal.toARGB32(),
    'borderStrong': borderStrong.toARGB32(),
    'borderMedium': borderMedium.toARGB32(),
    'borderSubtle': borderSubtle.toARGB32(),
    'accent': accent.toARGB32(),
    'accentEdit': accentEdit.toARGB32(),
    'accentSuccess': accentSuccess.toARGB32(),
    'accentDanger': accentDanger.toARGB32(),
    'logoColor': logoColor.toARGB32(),
    'accentCascade': accentCascade.toARGB32(),
    'accentVibeTransfer': accentVibeTransfer.toARGB32(),
    'accentRefCharacter': accentRefCharacter.toARGB32(),
    'accentRefStyle': accentRefStyle.toARGB32(),
    'accentRefCharStyle': accentRefCharStyle.toARGB32(),
    'fontFamily': fontFamily,
    'fontScale': fontScale,
    'promptFontSize': promptFontSize,
    'promptMaxLines': promptMaxLines,
    'brightMode': brightMode,
  };

  factory AppThemeConfig.fromJson(Map<String, dynamic> json) {
    return AppThemeConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      background: Color(json['background'] as int),
      surfaceHigh: Color(json['surfaceHigh'] as int),
      surfaceMid: Color(json['surfaceMid'] as int),
      textPrimary: Color(json['textPrimary'] as int),
      textSecondary: Color(json['textSecondary'] as int),
      textTertiary: Color(json['textTertiary'] as int),
      textDisabled: Color(json['textDisabled'] as int),
      textMinimal: Color(json['textMinimal'] as int),
      borderStrong: Color(json['borderStrong'] as int),
      borderMedium: Color(json['borderMedium'] as int),
      borderSubtle: Color(json['borderSubtle'] as int),
      accent: Color(json['accent'] as int),
      accentEdit: Color(json['accentEdit'] as int),
      accentSuccess: Color(json['accentSuccess'] as int),
      accentDanger: Color(json['accentDanger'] as int),
      logoColor: Color(json['logoColor'] as int? ?? 0xFFFAFAFA),
      accentCascade: Color(json['accentCascade'] as int? ?? 0xFF00BCD4),
      accentVibeTransfer: Color(json['accentVibeTransfer'] as int? ?? 0xFF4CAF50),
      accentRefCharacter: Color(json['accentRefCharacter'] as int? ?? 0xFF18FFFF),
      accentRefStyle: Color(json['accentRefStyle'] as int? ?? 0xFFFF00FF),
      accentRefCharStyle: Color(json['accentRefCharStyle'] as int? ?? 0xFFFFD700),
      fontFamily: json['fontFamily'] as String? ?? 'JetBrains Mono',
      fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
      promptFontSize: (json['promptFontSize'] as num?)?.toDouble() ?? 13.0,
      promptMaxLines: (json['promptMaxLines'] as num?)?.toInt() ?? 2,
      brightMode: json['brightMode'] as bool? ?? true,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory AppThemeConfig.fromJsonString(String source) =>
      AppThemeConfig.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
