import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../providers/generation_notifier.dart';
import '../models/nai_character.dart';
import 'character_chip.dart';
import 'character_editor_sheet.dart';
import 'action_interaction_sheet.dart';

class CharacterShelf extends StatelessWidget {
  const CharacterShelf({super.key});

  void _openEditor(BuildContext context, GenerationNotifier notifier, int index,
      NaiCharacter character) {
    final t = context.tRead;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surfaceHigh,
      builder: (context) => CharacterEditorSheet(
        index: index,
        character: character,
        onSave: (updated) => notifier.updateCharacter(index, updated),
        onDelete: () => notifier.removeCharacter(index),
      ),
    );
  }

  void _openInteractionEditor(
      BuildContext context, GenerationNotifier notifier, int index1, int index2) {
    // Find existing interaction involving these two characters
    final existing = notifier.state.interactions.cast<NaiInteraction?>().firstWhere(
      (i) => i != null &&
          ((i.sourceCharacterIndices.contains(index1) && i.targetCharacterIndices.contains(index2)) ||
           (i.sourceCharacterIndices.contains(index2) && i.targetCharacterIndices.contains(index1)) ||
           (i.type == InteractionType.mutual && i.sourceCharacterIndices.contains(index1) && i.sourceCharacterIndices.contains(index2))),
      orElse: () => null,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      builder: (context) => ActionInteractionSheet(
        sourceIndices: existing?.sourceCharacterIndices ?? [index1],
        targetIndices: existing?.targetCharacterIndices ?? [index2],
        initialType: existing?.type ?? InteractionType.sourceTarget,
        characters: notifier.state.characters,
        initialInteraction: existing,
        onSave: (updated) => notifier.updateInteraction(updated, replacing: existing),
        onDelete: () {
          if (existing != null) notifier.removeInteraction(existing);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<GenerationNotifier,
        (List<NaiCharacter>, List<NaiInteraction>, bool)>(
      selector: (_, n) => (
        n.state.characters,
        n.state.interactions,
        n.state.autoPositioning,
      ),
      builder: (context, data, _) {
        final notifier = context.read<GenerationNotifier>();
        final characters = data.$1;
        final interactions = data.$2;
        final autoPositioning = data.$3;

        // Total items: [autoChip] + char1, link1-2, char2, link2-3, ..., charN, [addButton]
        final hasAutoChip = characters.isNotEmpty;
        int itemCount = characters.isNotEmpty ? (characters.length * 2) - 1 : 0;
        if (hasAutoChip) itemCount += 1; // AUTO chip
        if (characters.length < 6) {
          itemCount += 1; // Add character button
        }

        final mobile = isMobile(context);
        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: mobile ? 40 : 28,
            margin: const EdgeInsets.only(top: 4, bottom: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: itemCount,
              itemBuilder: (context, index) {
                // AUTO chip is the first item when characters exist
                if (hasAutoChip && index == 0) {
                  return _AutoPositionChip(
                    isActive: autoPositioning,
                    onTap: () => notifier.setAutoPositioning(!autoPositioning),
                  );
                }

                // Adjust index for the AUTO chip offset
                final adjustedIndex = hasAutoChip ? index - 1 : index;

                // Check if it's the "Add Character" button
                if (characters.length < 6 && index == itemCount - 1) {
                  return _AddCharacterButton(onTap: notifier.addCharacter);
                }

                // Even indices are character chips (0, 2, 4...)
                // Odd indices are link buttons (1, 3, 5...)
                if (adjustedIndex.isEven) {
                  final charIndex = adjustedIndex ~/ 2;
                  return CharacterChip(
                    index: charIndex,
                    character: characters[charIndex],
                    onTap: () => _openEditor(context, notifier, charIndex, characters[charIndex]),
                    onLongPress: () => notifier.removeCharacter(charIndex),
                  );
                } else {
                  final charIndex1 = adjustedIndex ~/ 2;
                  final charIndex2 = charIndex1 + 1;
                  final hasInteraction = interactions.any((i) =>
                      (i.sourceCharacterIndices.contains(charIndex1) && i.targetCharacterIndices.contains(charIndex2)) ||
                      (i.sourceCharacterIndices.contains(charIndex2) && i.targetCharacterIndices.contains(charIndex1)) ||
                      (i.type == InteractionType.mutual && i.sourceCharacterIndices.contains(charIndex1) && i.sourceCharacterIndices.contains(charIndex2)));

                  return _LinkButton(
                    isActive: hasInteraction,
                    onTap: () => _openInteractionEditor(context, notifier, charIndex1, charIndex2),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _LinkButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _LinkButton({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: mobile ? 24 : 16,
        height: mobile ? 40 : 28,
        child: Center(
          child: Icon(
            Icons.link,
            size: mobile ? 18 : 14,
            color: isActive ? t.accentSuccess : t.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _AutoPositionChip extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _AutoPositionChip({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: mobile ? 40 : 28,
          padding: EdgeInsets.symmetric(horizontal: mobile ? 10 : 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.orange : t.borderSubtle,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isActive ? Colors.orange : t.textMinimal,
              width: 0.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            'AUTO',
            style: TextStyle(
              color: isActive ? t.background : t.textDisabled,
              fontSize: t.fontSize(mobile ? 9 : 8),
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddCharacterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCharacterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: mobile ? 40 : 32,
          decoration: BoxDecoration(
            color: t.textMinimal,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: t.textMinimal, width: 0.5),
          ),
          child: Icon(Icons.add, size: mobile ? 18 : 14, color: t.textDisabled),
        ),
      ),
    );
  }
}

