import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/settings_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/blur_app_bar.dart';
import '../../widgets/color_picker_dialog.dart';
import '../../widgets/color_value_field.dart';
import '../../services/interaction_haptics.dart';

class HookExtensionPage extends StatefulWidget {
  const HookExtensionPage({super.key});

  @override
  State<HookExtensionPage> createState() => _HookExtensionPageState();
}

class _HookExtensionPageState extends State<HookExtensionPage> {
  static const _platform = MethodChannel('io.github.hyperisland/test');
  final _ctrl = SettingsController.instance;
  late int _uiStateHash;

  int _buildUiStateHash() => Object.hashAll([
    _ctrl.resumeNotification,
    _ctrl.settingsHomeEntry,
    _ctrl.bluetoothIsland,
    _ctrl.bluetoothIslandOuterGlow,
    _ctrl.bluetoothIslandOuterGlowColor,
    _ctrl.unlockAllFocus,
    _ctrl.unlockFocusAuth,
  ]);

  void _onChanged() {
    if (!mounted) return;
    final nextHash = _buildUiStateHash();
    if (nextHash == _uiStateHash) return;
    setState(() => _uiStateHash = nextHash);
  }

  @override
  void initState() {
    super.initState();
    _uiStateHash = _buildUiStateHash();
    _ctrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChanged);
    super.dispose();
  }

  Future<void> _onResumeNotificationChanged(bool value) async {
    if (!await _requestScopesIfEnabled(value, const [
      'com.android.providers.downloads',
      'com.xiaomi.android.app.downloadmanager',
    ])) {
      return;
    }
    await _ctrl.setResumeNotification(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.restartScopeApp),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _onSettingsHomeEntryChanged(bool value) async {
    if (!await _requestScopesIfEnabled(value, const ['com.android.settings'])) {
      return;
    }
    await _ctrl.setSettingsHomeEntry(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.restartScopeApp),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _onUnlockAllFocusChanged(bool value) async {
    if (!await _requestScopesIfEnabled(value, const ['com.android.systemui'])) {
      return;
    }
    await _ctrl.setUnlockAllFocus(value);
  }

  Future<void> _onBluetoothIslandChanged(bool value) async {
    if (!await _requestScopesIfEnabled(value, const ['com.android.systemui'])) {
      return;
    }
    await _ctrl.setBluetoothIsland(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.restartScopeApp),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _showBluetoothIslandSettings() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _BluetoothIslandSettingsDialog(
        enabled: _ctrl.bluetoothIsland,
        outerGlow: _ctrl.bluetoothIslandOuterGlow,
        outerGlowColor: _ctrl.bluetoothIslandOuterGlowColor,
        onApply: (enabled, outerGlow, outerGlowColor) async {
          final enabledChanged = enabled != _ctrl.bluetoothIsland;
          if (!await _requestScopesIfEnabled(enabled, const [
            'com.android.systemui',
          ])) {
            return false;
          }
          await _ctrl.setBluetoothIsland(enabled);
          await _ctrl.setBluetoothIslandOuterGlow(outerGlow);
          await _ctrl.setBluetoothIslandOuterGlowColor(outerGlowColor);
          if (mounted && enabledChanged) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.restartScopeApp),
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return true;
        },
      ),
    );
  }

  Future<void> _onUnlockFocusAuthChanged(bool value) async {
    if (!await _requestScopesIfEnabled(value, const ['com.xiaomi.xmsf'])) {
      return;
    }
    await _ctrl.setUnlockFocusAuth(value);
  }

  Future<bool> _requestScopesIfEnabled(
    bool enabled,
    List<String> packages,
  ) async {
    if (!enabled) return true;
    final fallbackMessage = AppLocalizations.of(
      context,
    )!.xposedScopeRequestFailed;
    try {
      await _platform.invokeMethod('requestXposedScope', {
        'packages': packages,
      });
      return true;
    } on PlatformException catch (e) {
      _showSnackBar(e.message ?? fallbackMessage);
      return false;
    } catch (_) {
      _showSnackBar(fallbackMessage);
      return false;
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      backgroundColor: cs.surface,
      body: BlurAppBarHost(
        title: l10n.hookExtensionSection,
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                _SectionLabel(l10n.hookScopeSettings),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerHighest,
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(l10n.settingsHomeEntryTitle, style: titleStyle),
                    subtitle: Text(l10n.settingsHomeEntrySubtitle),
                    value: _ctrl.settingsHomeEntry,
                    onChanged: InteractionHaptics.interceptToggle(
                      _onSettingsHomeEntryChanged,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _SectionLabel(l10n.hookScopeSystemUI),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerHighest,
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(l10n.unlockAllFocusTitle, style: titleStyle),
                    subtitle: Text(l10n.unlockAllFocusSubtitle),
                    value: _ctrl.unlockAllFocus,
                    onChanged: InteractionHaptics.interceptToggle(
                      _onUnlockAllFocusChanged,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerHighest,
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text('蓝牙超级岛', style: titleStyle),
                    subtitle: Text(
                      '${_ctrl.bluetoothIsland ? '已开启' : '已关闭'} · 监听蓝牙设备连接和断开，由 SystemUI 代发超级岛',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: InteractionHaptics.interceptButton(
                      _showBluetoothIslandSettings,
                    ),
                    onLongPress: InteractionHaptics.interceptButton(
                      _showBluetoothIslandSettings,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _SectionLabel(l10n.hookScopeXMSF),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerHighest,
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(l10n.unlockFocusAuthTitle, style: titleStyle),
                    subtitle: Text(l10n.unlockFocusAuthSubtitle),
                    value: _ctrl.unlockFocusAuth,
                    onChanged: InteractionHaptics.interceptToggle(
                      _onUnlockFocusAuthChanged,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _SectionLabel(l10n.downloadManagerSection),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerHighest,
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(l10n.keepFocusNotifTitle, style: titleStyle),
                    subtitle: Text(l10n.keepFocusNotifSubtitle),
                    value: _ctrl.resumeNotification,
                    onChanged: InteractionHaptics.interceptToggle(
                      _onResumeNotificationChanged,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ], addAutomaticKeepAlives: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _BluetoothIslandSettingsDialog extends StatefulWidget {
  const _BluetoothIslandSettingsDialog({
    required this.enabled,
    required this.outerGlow,
    required this.outerGlowColor,
    required this.onApply,
  });

  final bool enabled;
  final bool outerGlow;
  final String outerGlowColor;
  final Future<bool> Function(
    bool enabled,
    bool outerGlow,
    String outerGlowColor,
  )
  onApply;

  @override
  State<_BluetoothIslandSettingsDialog> createState() =>
      _BluetoothIslandSettingsDialogState();
}

class _BluetoothIslandSettingsDialogState
    extends State<_BluetoothIslandSettingsDialog> {
  late bool _outerGlow;
  late bool _enabled;
  late final TextEditingController _colorController;
  late String _outerGlowColor;

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled;
    _outerGlow = widget.outerGlow;
    _outerGlowColor = widget.outerGlowColor;
    _colorController = TextEditingController(text: _outerGlowColor);
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('蓝牙超级岛设置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('启用蓝牙超级岛'),
              subtitle: const Text('关闭后重启 SystemUI 生效，且不会注册蓝牙 Hook'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('外圈光效'),
              subtitle: const Text('控制蓝牙超级岛的外圈光效'),
              value: _outerGlow,
              onChanged: (value) => setState(() => _outerGlow = value),
            ),
            const SizedBox(height: 12),
            Text(
              '外圈光效颜色',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            ColorValueField(
              controller: _colorController,
              enabled: _outerGlow,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: '#AARRGGBB',
              ),
              previewColor: parseHexColor(_outerGlowColor),
              previewFallbackColor: cs.primary,
              onChanged: (value) => setState(() {
                _outerGlowColor = value.trim();
              }),
              onClear: () {
                _colorController.clear();
                setState(() => _outerGlowColor = '');
              },
              onPickColor: () async {
                final color = await showColorPickerDialog(
                  context,
                  initialHex: _outerGlowColor,
                  title: '外圈光效颜色',
                  enableAlpha: true,
                );
                if (color == null) return;
                final hex = colorToArgbHex(color);
                _colorController.text = hex;
                setState(() => _outerGlowColor = hex);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: InteractionHaptics.interceptButton(() {
            Navigator.pop(context);
          }),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: InteractionHaptics.interceptButton(() async {
            final applied = await widget.onApply(
              _enabled,
              _outerGlow,
              _outerGlowColor,
            );
            if (!applied) return;
            if (context.mounted) Navigator.pop(context);
          }),
          child: Text(AppLocalizations.of(context)!.apply),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
