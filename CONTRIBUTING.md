# Contributing to HyperIsland

Thank you for your interest in contributing to **HyperIsland**! This project brings Dynamic
Island–style progress notifications to HyperOS 3 via LSPosed, and every contribution — whether it's
a bug fix, new feature, translation, or documentation improvement — is greatly appreciated.

Please take a few minutes to read through this guide before opening an issue or submitting a pull
request.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Prerequisites](#prerequisites)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [How to Contribute](#how-to-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features](#suggesting-features)
  - [Submitting Code Changes](#submitting-code-changes)
- [Branch Naming](#branch-naming)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Code Style & Linting](#code-style--linting)
- [Testing](#testing)
- [Translations (i18n)](#translations-i18n)
- [Updating the Changelog](#updating-the-changelog)
- [License](#license)

---

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for
everyone. Please be constructive in your feedback, patient with maintainers, and considerate of
other contributors.

---

## Prerequisites

Before you start, make sure you have the following installed and configured:

| Requirement                   | Version / Notes                                                              |
| ----------------------------- | ---------------------------------------------------------------------------- |
| **Flutter**                   | Latest stable recommended (must satisfy Dart SDK `^3.9.0` in `pubspec.yaml`) |
| **Java (JDK)**                | 17 (as configured in `android/app/build.gradle.kts`)                         |
| **Android SDK**               | API level 36 recommended (project `compileSdk = 36`)                         |
| **Android device / emulator** | Rooted device with **LSPosed** installed for full hook testing               |
| **Git**                       | Any recent version                                                           |

> **Note:** Full end-to-end testing of LSPosed hooks requires a rooted Android device running
> **HyperOS 3**. UI and configuration changes can be developed and tested on any Android emulator
> or device.

---

## Development Setup

1. **Fork the repository** on GitHub and clone your fork:

   ```bash
   git clone https://github.com/<your-username>/HyperIsland.git
   cd HyperIsland
   ```

2. **Install Flutter dependencies:**

   ```bash
   flutter pub get
   ```

3. **Run the app** on a connected device or emulator:

   ```bash
   flutter run
   ```

4. **Build a release APK** (arm64):

   ```bash
   flutter build apk --target-platform=android-arm64
   ```

   The output APK will be located at:
   `build/app/outputs/flutter-apk/app-release.apk`

5. **Install on a rooted device** and enable the module in LSPosed Manager to test hooks.

---

## Project Structure

```
HyperIsland/
├── android/                  # Native Android / LSPosed hook code
│   └── app/
├── assets/
│   └── images/               # App icons and images
├── lib/
│   ├── controllers/          # State management controllers
│   ├── l10n/                 # Localisation (ARB) files
│   ├── pages/                # UI screens
│   ├── services/             # Background services and helpers
│   ├── theme/                # App theming
│   ├── widgets/              # Reusable Flutter widgets
│   └── main.dart             # Entry point
├── test/                     # Widget and unit tests
├── pubspec.yaml              # Flutter / Dart dependencies
├── analysis_options.yaml     # Dart lint rules
├── CHANGELOG.md              # Root changelog
├── CONTRIBUTING.md           # Contribution guide
└── l10n.yaml                 # Localisation configuration
```

---

## How to Contribute

### Reporting Bugs

Before opening a bug report, please:

1. Search [existing issues](https://github.com/yusufyorunc/HyperIsland/issues) to avoid duplicates.
2. Reproduce the issue on the **latest release**.

When opening a bug report, include:

- **Device model** and **HyperOS version**
- **LSPosed version** and **module version**
- **Steps to reproduce** the issue
- **Expected behavior** vs **actual behavior**
- Relevant **logcat output** (use `adb logcat | grep HyperIsland`)
- Screenshots or screen recordings if applicable

### Suggesting Features

Feature requests are welcome! Please open an issue with the `enhancement` label and describe:

- **The problem** you are trying to solve
- **Your proposed solution**
- Any **alternative approaches** you considered

### Submitting Code Changes

1. Create a new branch from `master` (see [Branch Naming](#branch-naming)).
2. Make your changes, following the [Code Style](#code-style--linting) guidelines.
3. Add or update tests where appropriate.
4. Update `CHANGELOG.md` with a brief description of your change.
5. Push your branch and open a Pull Request against `master`.

---

## Branch Naming

Use descriptive, lowercase branch names with a type prefix:

| Type          | Example                        |
| ------------- | ------------------------------ |
| Bug fix       | `fix/download-manager-crash`   |
| New feature   | `feat/ai-summary-toggle`       |
| Documentation | `docs/update-readme`           |
| Refactor      | `refactor/channel-settings-ui` |
| Translation   | `i18n/add-korean`              |

---

## Commit Message Guidelines

This project follows the **Conventional Commits** specification.

```
<type>(<scope>): <short description>

[optional body]

[optional footer]
```

**Types:**

| Type       | When to use                                       |
| ---------- | ------------------------------------------------- |
| `feat`     | A new feature                                     |
| `fix`      | A bug fix                                         |
| `docs`     | Documentation only changes                        |
| `style`    | Code style changes (formatting, no logic change)  |
| `refactor` | Code changes that are neither a fix nor a feature |
| `perf`     | Performance improvements                          |
| `test`     | Adding or fixing tests                            |
| `chore`    | Build process, dependency updates, CI changes     |
| `i18n`     | Translation / localisation updates                |

**Examples:**

```
feat(ai): add customisable AI timeout setting
fix(download): fix -1 progress causing SystemUI crash
i18n(tr): update Turkish translations for v1.9.x
docs: update setup guide for HyperCeiler step
```

- Use the **imperative mood** in the subject line ("fix bug" not "fixed bug").
- Keep the subject line under **72 characters**.
- Reference related issues in the footer: `Closes #42`.

---

## Pull Request Guidelines

- **Target branch:** Always open PRs against `master`.
- **One concern per PR:** Keep PRs focused. Separate unrelated changes into different PRs.
- **Describe your changes:** Fill in the PR template completely — what changed, why, and how to test
  it.
- **Link issues:** Reference any related issues (e.g., `Fixes #12`).
- **Pass CI:** Ensure the build succeeds and all tests pass before requesting a review.
- **Respond to feedback:** Address review comments promptly; mark conversations as resolved once
  done.

---

## Code Style & Linting

This project uses the rules defined in [`analysis_options.yaml`](analysis_options.yaml), which is
based on `flutter_lints`.

Run the analyser before committing:

```bash
flutter analyze
```

Format your code with the official Dart formatter:

```bash
dart format .
```

Fix any warnings or errors reported by the analyser before submitting a PR.

---

## Testing

Run the existing test suite with:

```bash
flutter test
```

- Tests live in the `test/` directory.
- When adding new features or fixing bugs, add a corresponding test in `test/` where practical.
- UI changes that are difficult to unit-test should include a screenshot in the PR description.

---

## Translations (i18n)

HyperIsland currently supports **English**, **Simplified Chinese**, **Japanese**, and **Turkish**.
New language contributions are very welcome!

Localisation files are ARB files located in `lib/l10n/`. The configuration is in [
`l10n.yaml`](l10n.yaml).

**To add or update a translation:**

1. Copy `lib/l10n/app_en.arb` (the reference locale) to `lib/l10n/app_<locale>.arb`.
2. Translate all string values, keeping the keys unchanged.
3. Run `flutter gen-l10n` to regenerate the localisation code:

   ```bash
   flutter gen-l10n
   ```

4. If you are adding a **new language**, also update the README files to mention it.
5. Add any missing strings to `untranslated_messages.txt` and note them in your PR.

---

## Updating the Changelog

Every user-visible change must be recorded in [`CHANGELOG.md`](CHANGELOG.md).

Follow the existing format:

```markdown
# V<version> (<date>)

## <Category>

- Brief description of what changed.
```

Categories: **Features**, **Bug Fixes**, **Performance Improvements**, **Design Fixes**, **Breaking
Changes**.

---

## License

By contributing to HyperIsland, you agree that your contributions will be licensed under
the [MIT License](LICENSE) that covers this project.
