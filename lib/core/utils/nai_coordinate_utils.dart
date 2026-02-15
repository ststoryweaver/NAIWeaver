import '../../features/generation/models/nai_character.dart';

class NaiCoordinateUtils {
  static const List<double> standardPoints = [0.1, 0.3, 0.5, 0.7, 0.9];

  /// Maps a 5x5 grid index (0-24) to NAI standard center points.
  static NaiCoordinate getCoordinateFromIndex(int index) {
    if (index < 0 || index > 24) {
      return NaiCoordinate(x: 0.5, y: 0.5);
    }
    final int row = index ~/ 5;
    final int col = index % 5;
    return NaiCoordinate(
      x: standardPoints[col],
      y: standardPoints[row],
    );
  }
}
