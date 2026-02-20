import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/jukebox_soundfont.dart';

class SoundFontStorageService {
  static String soundFontPath(String soundfontsDir, JukeboxSoundFont sf) {
    return p.join(soundfontsDir, sf.filename);
  }

  static String partialPath(String soundfontsDir, JukeboxSoundFont sf) {
    return p.join(soundfontsDir, '${sf.filename}.part');
  }

  static Future<bool> isDownloaded(String soundfontsDir, JukeboxSoundFont sf) {
    return File(soundFontPath(soundfontsDir, sf)).exists();
  }

  static Future<void> delete(String soundfontsDir, JukeboxSoundFont sf) async {
    final file = File(soundFontPath(soundfontsDir, sf));
    if (await file.exists()) await file.delete();
  }

  static Future<void> deletePartial(String soundfontsDir, JukeboxSoundFont sf) async {
    final file = File(partialPath(soundfontsDir, sf));
    if (await file.exists()) await file.delete();
  }
}
