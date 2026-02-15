import 'package:flutter/material.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/nai_coordinate_utils.dart';
import '../models/nai_character.dart';

class NaiGridSelector extends StatelessWidget {
  final NaiCoordinate selectedCoordinate;
  final ValueChanged<NaiCoordinate> onCoordinateSelected;

  const NaiGridSelector({
    super.key,
    required this.selectedCoordinate,
    required this.onCoordinateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: t.borderStrong),
          borderRadius: BorderRadius.circular(8),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(8),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: 25,
          itemBuilder: (context, index) {
            final coord = NaiCoordinateUtils.getCoordinateFromIndex(index);
            final isSelected = coord.x == selectedCoordinate.x &&
                coord.y == selectedCoordinate.y;

            return InkWell(
              onTap: () => onCoordinateSelected(coord),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? t.accent
                      : t.textMinimal,
                  borderRadius: BorderRadius.circular(4),
                  border: isSelected
                      ? null
                      : Border.all(color: t.textMinimal),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
