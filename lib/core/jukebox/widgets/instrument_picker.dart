import 'package:flutter/material.dart';
import '../../theme/vision_tokens.dart';
import '../../l10n/l10n_extensions.dart';
import '../../../l10n/app_localizations.dart';

/// General MIDI instrument selector with ~20 popular instruments.
class InstrumentPicker extends StatelessWidget {
  final VisionTokens t;
  final int selectedProgram;
  final ValueChanged<int> onChanged;

  const InstrumentPicker({
    super.key,
    required this.t,
    required this.selectedProgram,
    required this.onChanged,
  });

  static const programNumbers = [0, 4, 6, 11, 13, 19, 24, 25, 27, 30, 32, 33, 40, 42, 46, 48, 56, 61, 65, 73, 80, 85];

  static String _instrumentName(AppLocalizations l, int program) {
    return switch (program) {
      0 => l.jukeboxInstrumentAcousticGrandPiano,
      4 => l.jukeboxInstrumentElectricPiano,
      6 => l.jukeboxInstrumentHarpsichord,
      11 => l.jukeboxInstrumentVibraphone,
      13 => l.jukeboxInstrumentXylophone,
      19 => l.jukeboxInstrumentChurchOrgan,
      24 => l.jukeboxInstrumentNylonGuitar,
      25 => l.jukeboxInstrumentSteelGuitar,
      27 => l.jukeboxInstrumentCleanElectricGuitar,
      30 => l.jukeboxInstrumentDistortionGuitar,
      32 => l.jukeboxInstrumentAcousticBass,
      33 => l.jukeboxInstrumentElectricBassFinger,
      40 => l.jukeboxInstrumentViolin,
      42 => l.jukeboxInstrumentCello,
      46 => l.jukeboxInstrumentOrchestralHarp,
      48 => l.jukeboxInstrumentStringEnsemble,
      56 => l.jukeboxInstrumentTrumpet,
      61 => l.jukeboxInstrumentFrenchHorn,
      65 => l.jukeboxInstrumentAltoSax,
      73 => l.jukeboxInstrumentFlute,
      80 => l.jukeboxInstrumentSquareLeadSynth,
      85 => l.jukeboxInstrumentLeadVoice,
      _ => 'Program $program',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: t.surfaceMid,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: t.borderSubtle),
      ),
      child: DropdownButton<int>(
        value: programNumbers.contains(selectedProgram) ? selectedProgram : 0,
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        isExpanded: true,
        dropdownColor: t.surfaceHigh,
        underline: const SizedBox.shrink(),
        icon: Icon(Icons.arrow_drop_down, color: t.accent),
        style: TextStyle(
          color: t.textPrimary,
          fontSize: t.fontSize(10),
          letterSpacing: 0.5,
        ),
        items: programNumbers.map((prog) {
          return DropdownMenuItem<int>(
            value: prog,
            child: Text(_instrumentName(l, prog)),
          );
        }).toList(),
      ),
    );
  }
}
