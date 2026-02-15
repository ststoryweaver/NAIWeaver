import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../features/director_ref/models/director_reference.dart';
import '../../features/vibe_transfer/models/vibe_transfer.dart';

class SavedDirectorRef {
  final String name;
  final DirectorReference reference;
  final DateTime savedAt;

  SavedDirectorRef({
    required this.name,
    required this.reference,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'reference': reference.toJson(),
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedDirectorRef.fromJson(Map<String, dynamic> json) =>
      SavedDirectorRef(
        name: json['name'] as String,
        reference:
            DirectorReference.fromJson(json['reference'] as Map<String, dynamic>),
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
}

class SavedVibeTransfer {
  final String name;
  final VibeTransfer vibe;
  final DateTime savedAt;

  SavedVibeTransfer({
    required this.name,
    required this.vibe,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'vibe': vibe.toJson(),
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedVibeTransfer.fromJson(Map<String, dynamic> json) =>
      SavedVibeTransfer(
        name: json['name'] as String,
        vibe: VibeTransfer.fromJson(json['vibe'] as Map<String, dynamic>),
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
}

class ReferenceLibrary {
  List<SavedDirectorRef> directorRefs;
  List<SavedVibeTransfer> vibeTransfers;

  ReferenceLibrary({
    this.directorRefs = const [],
    this.vibeTransfers = const [],
  });

  Map<String, dynamic> toJson() => {
        'directorRefs': directorRefs.map((r) => r.toJson()).toList(),
        'vibeTransfers': vibeTransfers.map((v) => v.toJson()).toList(),
      };

  factory ReferenceLibrary.fromJson(Map<String, dynamic> json) =>
      ReferenceLibrary(
        directorRefs: (json['directorRefs'] as List<dynamic>?)
                ?.map((r) => SavedDirectorRef.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
        vibeTransfers: (json['vibeTransfers'] as List<dynamic>?)
                ?.map((v) => SavedVibeTransfer.fromJson(v as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class ReferenceLibraryService {
  static Future<ReferenceLibrary> load(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return ReferenceLibrary();
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return ReferenceLibrary.fromJson(json);
    } catch (e) {
      debugPrint('ReferenceLibraryService: load error: $e');
      return ReferenceLibrary();
    }
  }

  static Future<void> save(String filePath, ReferenceLibrary library) async {
    try {
      final file = File(filePath);
      await file.writeAsString(jsonEncode(library.toJson()));
    } catch (e) {
      debugPrint('ReferenceLibraryService: save error: $e');
    }
  }
}
