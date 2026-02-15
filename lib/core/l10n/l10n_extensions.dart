import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

extension L10nExtension on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);
}
