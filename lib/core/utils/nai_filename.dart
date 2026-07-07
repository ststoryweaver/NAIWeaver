/// Builds a NovelAI-style filename base from a prompt and seed, matching the
/// official NAI web UI convention (see issue #28):
///
///   prompt: `2::1girl::, long hair, artist:test, painting (medium)`
///   seed:   `12345678`
///   result: `2__1girl__, long hair, artist_test, painting (medium) s-12345678`
///
/// Only characters that are illegal in filenames are replaced — one `_` per
/// character, so `::` becomes `__` like NAI. Spaces, commas, parentheses,
/// braces, brackets, and letter case are all preserved. The Windows-illegal
/// set is used on every platform so filenames stay portable across sync and
/// export targets.
library;

/// Characters that cannot appear in Windows filenames (the strictest
/// platform), plus ASCII control characters.
final RegExp _illegalChars = RegExp(r'[<>:"/\\|?*\x00-\x1F]');

/// Windows also forbids trailing dots and spaces on filenames.
final RegExp _trailingDotsSpaces = RegExp(r'[. ]+$');

/// Maximum length of the prompt portion of the filename. NAI truncates long
/// prompts too; 100 keeps headroom under Windows' 260-char path limit once
/// the output directory, ` s-<seed>`, and `_(n).png` suffixes are added.
const int naiFilenamePromptMaxLength = 100;

/// Returns `<sanitized prompt> s-<seed>` for use as a filename base (no
/// extension). Falls back to `s-<seed>` if the prompt sanitizes to nothing,
/// or to the bare prompt if [seed] is empty.
String naiFilenameBase(String prompt, String seed) {
  var sanitized = prompt.trim().replaceAll(_illegalChars, '_');
  if (sanitized.length > naiFilenamePromptMaxLength) {
    sanitized = sanitized.substring(0, naiFilenamePromptMaxLength);
  }
  sanitized = sanitized.replaceAll(_trailingDotsSpaces, '');
  if (seed.isEmpty) return sanitized;
  if (sanitized.isEmpty) return 's-$seed';
  return '$sanitized s-$seed';
}
