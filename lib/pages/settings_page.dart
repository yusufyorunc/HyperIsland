import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../controllers/config_io_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/update_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/animated_settings_tab_bar.dart';
import 'blacklist_page.dart';

const _themeColorPresets = <Color>[
  Color(0xFF6750A4),
  Color(0xFF006A6A),
  Color(0xFF1565C0),
  Color(0xFF2E7D32),
  Color(0xFFEF6C00),
  Color(0xFFB3261E),
];

String _seedColorHex(Color color) {
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  final _ctrl = SettingsController.instance;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  void _showRestartSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.restartScopeApp),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _localizeConfigIOError(AppLocalizations l10n, ConfigIOError error) =>
      switch (error) {
        ConfigIOError.invalidFormat => l10n.errorInvalidFormat,
        ConfigIOError.noStorageDirectory => l10n.errorNoStorageDir,
        ConfigIOError.noFileSelected => l10n.errorNoFileSelected,
        ConfigIOError.noFilePath => l10n.errorNoFilePath,
        ConfigIOError.emptyClipboard => l10n.errorEmptyClipboard,
      };

  Future<void> _exportToFile() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final path = await ConfigIOController.exportToFile();
      _showSnack(l10n.exportedTo(path));
    } on ConfigIOException catch (e) {
      _showSnack(l10n.exportFailed(_localizeConfigIOError(l10n, e.error)));
    } catch (e) {
      _showSnack(l10n.exportFailed(e.toString()));
    }
  }

  Future<void> _exportToClipboard() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ConfigIOController.exportToClipboard();
      _showSnack(l10n.configCopied);
    } on ConfigIOException catch (e) {
      _showSnack(l10n.exportFailed(_localizeConfigIOError(l10n, e.error)));
    } catch (e) {
      _showSnack(l10n.exportFailed(e.toString()));
    }
  }

  Future<void> _importFromFile() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final count = await ConfigIOController.importFromFile();
      _showSnack(l10n.importSuccess(count));
    } on ConfigIOException catch (e) {
      _showSnack(l10n.importFailed(_localizeConfigIOError(l10n, e.error)));
    } catch (e) {
      _showSnack(l10n.importFailed(e.toString()));
    }
  }

  Future<void> _importFromClipboard() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final count = await ConfigIOController.importFromClipboard();
      _showSnack(l10n.importSuccess(count));
    } on ConfigIOException catch (e) {
      _showSnack(l10n.importFailed(_localizeConfigIOError(l10n, e.error)));
    } catch (e) {
      _showSnack(l10n.importFailed(e.toString()));
    }
  }

  String _themeModeLabel(AppLocalizations l10n) => switch (_ctrl.themeMode) {
    ThemeMode.light => l10n.themeModeLight,
    ThemeMode.dark => l10n.themeModeDark,
    ThemeMode.system => l10n.themeModeSystem,
  };

  String _localeLabel(AppLocalizations l10n) {
    if (_ctrl.locale == null) return l10n.languageAuto;
    return switch (_ctrl.locale!.languageCode) {
      'zh' => l10n.languageZh,
      'en' => l10n.languageEn,
      'ja' => l10n.languageJa,
      'tr' => l10n.languageTr,
      _ => _ctrl.locale!.languageCode,
    };
  }

  Future<void> _showThemeModeDialog(AppLocalizations l10n) async {
    if (!mounted) return;
    final result = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.themeModeTitle),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: _ctrl.themeMode,
            onChanged: (v) => Navigator.of(ctx).pop(v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SettingsRadioOption<ThemeMode>(
                  l10n.themeModeSystem,
                  ThemeMode.system,
                ),
                SettingsRadioOption<ThemeMode>(
                  l10n.themeModeLight,
                  ThemeMode.light,
                ),
                SettingsRadioOption<ThemeMode>(
                  l10n.themeModeDark,
                  ThemeMode.dark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (result != null) _ctrl.setThemeMode(result);
  }

  Future<void> _showLanguageDialog(AppLocalizations l10n) async {
    if (!mounted) return;
    final result = await showDialog<Locale?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.languageTitle),
        children: [
          RadioGroup<Locale?>(
            groupValue: _ctrl.locale,
            onChanged: (v) => Navigator.of(ctx).pop(v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SettingsRadioOption<Locale?>(l10n.languageAuto, null),
                SettingsRadioOption<Locale?>(
                  l10n.languageZh,
                  const Locale('zh'),
                ),
                SettingsRadioOption<Locale?>(
                  l10n.languageEn,
                  const Locale('en'),
                ),
                SettingsRadioOption<Locale?>(
                  l10n.languageJa,
                  const Locale('ja'),
                ),
                SettingsRadioOption<Locale?>(
                  l10n.languageTr,
                  const Locale('tr'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (result != _ctrl.locale) _ctrl.setLocale(result);
  }

  List<Color> _themeColorChoices() {
    final current = _ctrl.themeSeedColor;
    final hasCurrent = _themeColorPresets.any(
      (color) => color.toARGB32() == current.toARGB32(),
    );
    if (hasCurrent) return _themeColorPresets;
    return [current, ..._themeColorPresets];
  }

  Future<void> _showThemeSeedDialog(AppLocalizations l10n) async {
    if (!mounted) return;
    final choices = _themeColorChoices();
    final current = choices.firstWhere(
      (color) => color.toARGB32() == _ctrl.themeSeedColor.toARGB32(),
      orElse: () => choices.first,
    );

    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.themeSeedColorTitle),
        children: [
          RadioGroup<Color>(
            groupValue: current,
            onChanged: (value) => Navigator.of(ctx).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final color in choices)
                  RadioListTile<Color>(
                    value: color,
                    title: Text(_seedColorHex(color)),
                    secondary: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(ctx).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (result != null) {
      await _ctrl.setThemeSeedColor(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final tabs = [
      (Icons.tune_rounded, l10n.behaviorSection),
      (Icons.palette_outlined, l10n.appearanceSection),
      (Icons.settings_applications_outlined, l10n.defaultConfigSection),
      (Icons.sync_alt_rounded, l10n.configSection),
      (Icons.info_outline_rounded, l10n.aboutSection),
    ];

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.navSettings,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        bottom: AnimatedSettingsTabBar(controller: _tabController, tabs: tabs),
      ),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          if (_ctrl.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _BehaviorTab(
                ctrl: _ctrl,
                l10n: l10n,
                onRestartSnack: _showRestartSnack,
              ),
              _AppearanceTab(
                ctrl: _ctrl,
                l10n: l10n,
                onRestartSnack: _showRestartSnack,
                onShowThemeSeedDialog: () => _showThemeSeedDialog(l10n),
                onShowThemeDialog: () => _showThemeModeDialog(l10n),
                onShowLanguageDialog: () => _showLanguageDialog(l10n),
                themeSeedColorLabel:
                    '${l10n.themeSeedColorSubtitle}: ${_seedColorHex(_ctrl.themeSeedColor)}',
                themeModeLabel: _themeModeLabel(l10n),
                localeLabel: _localeLabel(l10n),
              ),
              _DefaultConfigTab(ctrl: _ctrl, l10n: l10n),
              _BackupTab(
                l10n: l10n,
                onExportFile: _exportToFile,
                onExportClipboard: _exportToClipboard,
                onImportFile: _importFromFile,
                onImportClipboard: _importFromClipboard,
              ),
              _AboutTab(l10n: l10n, onShowSnack: _showSnack),
            ],
          );
        },
      ),
    );
  }
}

class _TabScrollView extends StatelessWidget {
  final List<Widget> children;

  const _TabScrollView({required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: children,
    );
  }
}

class _BehaviorTab extends StatelessWidget {
  final SettingsController ctrl;
  final AppLocalizations l10n;
  final VoidCallback onRestartSnack;

  const _BehaviorTab({
    required this.ctrl,
    required this.l10n,
    required this.onRestartSnack,
  });

  @override
  Widget build(BuildContext context) {
    return _TabScrollView(
      children: [
        SettingsSection(
          title: l10n.navBlacklist,
          children: [
            SettingsItem(
              icon: Icons.block_rounded,
              title: l10n.navBlacklist,
              subtitle: l10n.navBlacklistSubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlacklistPage()),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l10n.behaviorSection,
          children: [
            SettingsSwitch(
              title: l10n.keepFocusNotifTitle,
              subtitle: l10n.keepFocusNotifSubtitle,
              value: ctrl.resumeNotification,
              onChanged: (v) async {
                await ctrl.setResumeNotification(v);
                onRestartSnack();
              },
            ),
            SettingsSwitch(
              title: l10n.unlockAllFocusTitle,
              subtitle: l10n.unlockAllFocusSubtitle,
              value: ctrl.unlockAllFocus,
              onChanged: ctrl.setUnlockAllFocus,
            ),
            SettingsSwitch(
              title: l10n.unlockFocusAuthTitle,
              subtitle: l10n.unlockFocusAuthSubtitle,
              value: ctrl.unlockFocusAuth,
              onChanged: ctrl.setUnlockFocusAuth,
            ),
            SettingsSwitch(
              title: l10n.showWelcomeTitle,
              subtitle: l10n.showWelcomeSubtitle,
              value: ctrl.showWelcome,
              onChanged: ctrl.setShowWelcome,
            ),
            SettingsSwitch(
              title: l10n.hideDesktopIconTitle,
              subtitle: l10n.hideDesktopIconSubtitle,
              value: ctrl.hideDesktopIcon,
              onChanged: ctrl.setHideDesktopIcon,
            ),
            SettingsSwitch(
              title: l10n.checkUpdateOnLaunchTitle,
              subtitle: l10n.checkUpdateOnLaunchSubtitle,
              value: ctrl.checkUpdateOnLaunch,
              onChanged: ctrl.setCheckUpdateOnLaunch,
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AppearanceTab extends StatelessWidget {
  final SettingsController ctrl;
  final AppLocalizations l10n;
  final VoidCallback onRestartSnack;
  final VoidCallback onShowThemeSeedDialog;
  final VoidCallback onShowThemeDialog;
  final VoidCallback onShowLanguageDialog;
  final String themeSeedColorLabel;
  final String themeModeLabel;
  final String localeLabel;

  const _AppearanceTab({
    required this.ctrl,
    required this.l10n,
    required this.onRestartSnack,
    required this.onShowThemeSeedDialog,
    required this.onShowThemeDialog,
    required this.onShowLanguageDialog,
    required this.themeSeedColorLabel,
    required this.themeModeLabel,
    required this.localeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _TabScrollView(
      children: [
        SettingsSection(
          title: l10n.appearanceSection,
          children: [
            SettingsSwitch(
              title: l10n.useAppIconTitle,
              subtitle: l10n.useAppIconSubtitle,
              value: ctrl.useHookAppIcon,
              onChanged: (v) async {
                await ctrl.setUseHookAppIcon(v);
                onRestartSnack();
              },
            ),
            SettingsSwitch(
              title: l10n.roundIconTitle,
              subtitle: l10n.roundIconSubtitle,
              value: ctrl.roundIcon,
              onChanged: ctrl.setRoundIcon,
            ),
            MarqueeSpeedTile(
              l10n: l10n,
              initialValue: ctrl.marqueeSpeed,
              onChanged: ctrl.setMarqueeSpeed,
            ),
            SettingsItem(
              icon: Icons.color_lens_outlined,
              title: l10n.themeSeedColorTitle,
              subtitle: themeSeedColorLabel,
              onTap: onShowThemeSeedDialog,
            ),
            SettingsSwitch(
              title: l10n.pureBlackThemeTitle,
              subtitle: l10n.pureBlackThemeSubtitle,
              value: ctrl.pureBlackTheme,
              onChanged: ctrl.setPureBlackTheme,
            ),
            SettingsItem(
              icon: Icons.palette_outlined,
              title: l10n.themeModeTitle,
              subtitle: themeModeLabel,
              onTap: onShowThemeDialog,
            ),
            SettingsItem(
              icon: Icons.language_rounded,
              title: l10n.languageTitle,
              subtitle: localeLabel,
              onTap: onShowLanguageDialog,
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _DefaultConfigTab extends StatelessWidget {
  final SettingsController ctrl;
  final AppLocalizations l10n;

  const _DefaultConfigTab({required this.ctrl, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return _TabScrollView(
      children: [
        SettingsSection(
          title: l10n.defaultConfigSection,
          children: [
            SettingsSwitch(
              title: l10n.firstFloatLabel,
              subtitle: l10n.firstFloatLabelSubtitle,
              value: ctrl.defaultFirstFloat,
              onChanged: ctrl.setDefaultFirstFloat,
            ),
            SettingsSwitch(
              title: l10n.updateFloatLabel,
              subtitle: l10n.updateFloatLabelSubtitle,
              value: ctrl.defaultEnableFloat,
              onChanged: ctrl.setDefaultEnableFloat,
            ),
            SettingsSwitch(
              title: l10n.marqueeChannelTitle,
              subtitle: l10n.marqueeChannelTitleSubtitle,
              value: ctrl.defaultMarquee,
              onChanged: ctrl.setDefaultMarquee,
            ),
            SettingsSwitch(
              title: l10n.focusNotificationLabel,
              subtitle: l10n.focusNotificationLabelSubtitle,
              value: ctrl.defaultFocusNotif,
              onChanged: ctrl.setDefaultFocusNotif,
            ),
            SettingsSwitch(
              title: l10n.restoreLockscreenTitle,
              subtitle: l10n.restoreLockscreenSubtitle,
              value: ctrl.defaultRestoreLockscreen,
              onChanged: ctrl.setDefaultRestoreLockscreen,
            ),
            SettingsSwitch(
              title: l10n.islandIconLabel,
              subtitle: l10n.islandIconLabelSubtitle,
              value: ctrl.defaultShowIslandIcon,
              onChanged: ctrl.setDefaultShowIslandIcon,
            ),
            SettingsSwitch(
              title: l10n.preserveStatusBarSmallIconLabel,
              subtitle: l10n.preserveStatusBarSmallIconLabelSubtitle,
              value: ctrl.defaultPreserveSmallIcon,
              onChanged: ctrl.setDefaultPreserveSmallIcon,
            ),
            SettingsSwitch(
              title: l10n.dynamicHighlightColorLabel,
              subtitle: l10n.dynamicHighlightColorLabelSubtitle,
              value: ctrl.defaultDynamicHighlightColor,
              onChanged: ctrl.setDefaultDynamicHighlightColor,
            ),
            SettingsSwitch(
              title: l10n.outerGlowLabel,
              subtitle: l10n.outerGlowLabel,
              value: ctrl.defaultOuterGlow,
              onChanged: ctrl.setDefaultOuterGlow,
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _BackupTab extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onExportFile;
  final VoidCallback onExportClipboard;
  final VoidCallback onImportFile;
  final VoidCallback onImportClipboard;

  const _BackupTab({
    required this.l10n,
    required this.onExportFile,
    required this.onExportClipboard,
    required this.onImportFile,
    required this.onImportClipboard,
  });

  @override
  Widget build(BuildContext context) {
    return _TabScrollView(
      children: [
        SettingsSection(
          title: l10n.exportConfig,
          children: [
            SettingsItem(
              icon: Icons.upload_file_outlined,
              title: l10n.exportToFile,
              subtitle: l10n.exportToFileSubtitle,
              onTap: onExportFile,
              showTrailingIcon: false,
            ),
            SettingsItem(
              icon: Icons.copy_outlined,
              title: l10n.exportToClipboard,
              subtitle: l10n.exportToClipboardSubtitle,
              onTap: onExportClipboard,
              showTrailingIcon: false,
            ),
          ],
        ),
        SettingsSection(
          title: l10n.importConfig,
          children: [
            SettingsItem(
              icon: Icons.download_outlined,
              title: l10n.importFromFile,
              subtitle: l10n.importFromFileSubtitle,
              onTap: onImportFile,
              showTrailingIcon: false,
            ),
            SettingsItem(
              icon: Icons.paste_outlined,
              title: l10n.importFromClipboard,
              subtitle: l10n.importFromClipboardSubtitle,
              onTap: onImportClipboard,
              showTrailingIcon: false,
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AboutTab extends StatefulWidget {
  final AppLocalizations l10n;
  final void Function(String) onShowSnack;

  const _AboutTab({required this.l10n, required this.onShowSnack});

  @override
  State<_AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<_AboutTab> {
  bool _checkingUpdate = false;

  Future<void> _doCheckUpdate() async {
    setState(() => _checkingUpdate = true);
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        await UpdateController.checkAndShow(
          context,
          info.version,
          showUpToDate: true,
        );
      }
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return _TabScrollView(
      children: [
        SettingsSection(
          title: l10n.aboutSection,
          children: [
            SettingsItem(
              icon: Icons.system_update_outlined,
              title: l10n.checkUpdate,
              onTap: _checkingUpdate ? null : _doCheckUpdate,
              trailing: _checkingUpdate
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            SettingsItem(
              icon: Icons.code_rounded,
              title: 'GitHub',
              subtitle: 'yusufyorunc/HyperIsland',
              showTrailingIcon: false,
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => launchUrl(
                Uri.parse('https://github.com/yusufyorunc/HyperIsland'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            SettingsItem(
              icon: Icons.group_outlined,
              title: l10n.qqGroup,
              subtitle: '1045114341',
              showTrailingIcon: false,
              trailing: const Icon(Icons.copy, size: 18),
              onTap: () {
                Clipboard.setData(const ClipboardData(text: '1045114341'));
                widget.onShowSnack(l10n.groupNumberCopied);
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
