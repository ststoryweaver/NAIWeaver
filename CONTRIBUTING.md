# Contributing to NAIWeaver

Thanks for your interest in contributing! Here's how to get started.

## Development Setup

1. Install Flutter (stable channel, SDK ^3.10.7)
2. Clone the repository
3. Run `flutter pub get`
4. Run `flutter run -d windows` (or `-d chrome` for web)

## Code Style

- Follow existing patterns in the codebase
- Use `flutter analyze` before submitting — no new warnings
- Format with `dart format lib/`
- State management uses Provider + ChangeNotifier — keep that pattern
- Feature code goes in `lib/features/{name}/` with `models/`, `providers/`, `services/`, `widgets/` sub-folders
- ML processing code goes in `lib/core/ml/`
- Tools Hub features go in `lib/features/tools/{tool_name}/` (e.g., `director_tools/`, `enhance/`, `ml/`)
- Shared utilities go in `lib/core/` (services, utils, widgets)

## Pull Request Process

1. Fork the repository and create a branch from `main`
2. Make your changes with clear, focused commits
3. Ensure `flutter analyze` passes with no new issues
4. Update documentation if adding new features
5. Open a PR with a clear description of what changed and why

## Feature Requests

Feature requests are welcome! Please open a [GitHub Issue](../../issues) with the `enhancement` label. Include:

- A clear description of the feature and the problem it solves
- Any reference to NovelAI API capabilities it would use
- Mockups or examples if applicable

Check the [ROADMAP.md](ROADMAP.md) for planned features — your idea might already be on the list.

## Localization

NAIWeaver supports multiple languages via Flutter's ARB localization system. To add a new language:

1. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_XX.arb` (where `XX` is the language code, e.g., `ko`, `zh`, `de`)
2. Translate all string values in the new `.arb` file
3. Add the new locale to the `supportedLocales` list in `main.dart`
4. Run `flutter gen-l10n` (or let `flutter run` regenerate automatically)
5. Test the new language by switching locale in **TOOLS > SETTINGS**

Existing languages: English (`en`), Japanese (`ja`).

## Reporting Issues

- Use GitHub Issues for bug reports and feature requests
- Include steps to reproduce for bugs
- Include platform info (Windows/Android/Web) and Flutter version
- Screenshots or error logs are helpful

## Architecture Notes

See [ARCHITECTURE.md](ARCHITECTURE.md) for a detailed breakdown of the codebase structure, data flow, and design decisions.
