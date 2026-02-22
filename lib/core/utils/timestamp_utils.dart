/// Generates a compact HHmmss timestamp for ML output filenames.
String generateTimestamp() =>
    DateTime.now().toIso8601String().replaceAll(RegExp(r'[:\-T]'), '').substring(8, 14);
