import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/settings_controller.dart';
import '../controllers/whitelist_controller.dart';
import '../l10n/generated/app_localizations.dart';

part 'batch_channel_settings_sheet_parts.dart';

sealed class ChannelSettingsMode {
  const ChannelSettingsMode();
}

class SingleChannelMode extends ChannelSettingsMode {
  const SingleChannelMode({
    required this.channelName,
    required this.template,
    required this.renderer,
    required this.iconMode,
    required this.focusIconMode,
    required this.focusNotif,
    required this.preserveSmallIcon,
    required this.showIslandIcon,
    required this.firstFloat,
    required this.enableFloat,
    required this.islandTimeout,
    required this.marquee,
    required this.restoreLockscreen,
    required this.highlightColor,
    required this.dynamicHighlightColor,
    required this.outerGlow,
    required this.showLeftHighlight,
    required this.showRightHighlight,
  });

  final String channelName;
  final String template;
  final String renderer;
  final String iconMode;
  final String focusIconMode;
  final String focusNotif;
  final String preserveSmallIcon;
  final String showIslandIcon;
  final String firstFloat;
  final String enableFloat;
  final String islandTimeout;
  final String marquee;
  final String restoreLockscreen;
  final String highlightColor;
  final String dynamicHighlightColor;
  final String outerGlow;
  final String showLeftHighlight;
  final String showRightHighlight;
}

class BatchChannelMode extends ChannelSettingsMode {
  const BatchChannelMode({required this.scope});

  final BatchScope scope;
}

sealed class BatchScope {
  const BatchScope();
}

class SingleAppScope extends BatchScope {
  const SingleAppScope({
    required this.totalChannels,
    required this.enabledChannels,
  });

  final int totalChannels;
  final int enabledChannels;
}

class GlobalScope extends BatchScope {
  const GlobalScope({required this.subtitle});

  final String subtitle;
}

class BatchApplyResult {
  final Map<String, String?> settings;
  final bool onlyEnabled;

  const BatchApplyResult({required this.settings, required this.onlyEnabled});
}

class BatchChannelSettingsSheet extends StatefulWidget {
  const BatchChannelSettingsSheet({
    super.key,
    required this.mode,
    required this.templateLabels,
    required this.rendererLabels,
  });

  final ChannelSettingsMode mode;
  final Map<String, String> templateLabels;
  final Map<String, String> rendererLabels;

  static Future<BatchApplyResult?> show(
    BuildContext context, {
    required ChannelSettingsMode mode,
    required Map<String, String> templateLabels,
    required Map<String, String> rendererLabels,
  }) {
    return showModalBottomSheet<BatchApplyResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => BatchChannelSettingsSheet(
        mode: mode,
        templateLabels: templateLabels,
        rendererLabels: rendererLabels,
      ),
    );
  }

  @override
  State<BatchChannelSettingsSheet> createState() =>
      _BatchChannelSettingsSheetState();
}

class _BatchChannelSettingsSheetState extends State<BatchChannelSettingsSheet> {
  AppLocalizations _l10n(BuildContext context) => AppLocalizations.of(context)!;
  SettingsController get _ctrl => SettingsController.instance;

  String _defaultLabel(BuildContext context, bool value) =>
      value ? _l10n(context).optDefaultOn : _l10n(context).optDefaultOff;

  String? _template;
  String? _renderer;
  String? _iconMode;
  String? _focusIconMode;
  String? _focusNotif;
  String? _preserveSmallIcon;
  String? _showIslandIcon;
  String? _firstFloat;
  String? _enableFloat;
  String? _islandTimeout;
  String? _marquee;
  String? _restoreLockscreen;
  String? _highlightColor;
  String? _dynamicHighlightColor;
  String? _outerGlow;
  bool? _showLeftHighlight;
  bool? _showRightHighlight;

  bool _onlyEnabled = false;

  late final TextEditingController _timeoutController;
  late final TextEditingController _highlightColorController;

  bool get _isSingle => widget.mode is SingleChannelMode;
  bool get _dynamicHighlightEnabled {
    final mode = _dynamicHighlightColor;
    if (mode == null) return false;
    switch (mode.toLowerCase()) {
      case kTriOptOn:
      case 'dark':
      case 'darker':
        return true;
      case kTriOptDefault:
        return _ctrl.defaultDynamicHighlightColor;
      default:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.mode case SingleChannelMode m) {
      _template = m.template;
      _renderer = m.renderer;
      _iconMode = m.iconMode;
      _focusIconMode = m.focusIconMode;
      _focusNotif = m.focusNotif;
      _preserveSmallIcon = m.preserveSmallIcon;
      _showIslandIcon = m.showIslandIcon;
      _firstFloat = m.firstFloat;
      _enableFloat = m.enableFloat;
      _islandTimeout = m.islandTimeout;
      _marquee = m.marquee;
      _restoreLockscreen = m.restoreLockscreen;
      _highlightColor = m.highlightColor;
      _dynamicHighlightColor = m.dynamicHighlightColor;
      _outerGlow = m.outerGlow;
      _showLeftHighlight = m.showLeftHighlight == kTriOptOn;
      _showRightHighlight = m.showRightHighlight == kTriOptOn;
      _timeoutController = TextEditingController(text: m.islandTimeout);
      _highlightColorController = TextEditingController(text: m.highlightColor);
    } else {
      _timeoutController = TextEditingController();
      _highlightColorController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _timeoutController.dispose();
    _highlightColorController.dispose();
    super.dispose();
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return null;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(value).withAlpha(255);
  }

  Future<Color?> _showColorPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final initialColor =
        _parseColor(_highlightColor) ?? Theme.of(context).colorScheme.primary;
    return showDialog<Color>(
      context: context,
      builder: (ctx) => _HighlightColorPickerDialog(
        initialColor: initialColor,
        title: l10n.highlightColorLabel,
        hueLabel: l10n.colorHue,
        saturationLabel: l10n.colorSaturation,
        brightnessLabel: l10n.colorBrightness,
        cancelLabel: l10n.cancel,
        applyLabel: l10n.apply,
      ),
    );
  }

  bool get _hasAnyChange =>
      _isSingle ||
      _template != null ||
      _renderer != null ||
      _iconMode != null ||
      _focusIconMode != null ||
      _focusNotif != null ||
      _preserveSmallIcon != null ||
      _showIslandIcon != null ||
      _firstFloat != null ||
      _enableFloat != null ||
      _islandTimeout != null ||
      _marquee != null ||
      _restoreLockscreen != null ||
      _highlightColor != null ||
      _dynamicHighlightColor != null ||
      _outerGlow != null ||
      _showLeftHighlight != null ||
      _showRightHighlight != null;

  String _title(AppLocalizations l10n) => switch (widget.mode) {
    SingleChannelMode m => m.channelName,
    BatchChannelMode _ => l10n.batchChannelSettings,
  };

  String _subtitle(AppLocalizations l10n) => switch (widget.mode) {
    SingleChannelMode _ => l10n.channelSettings,
    BatchChannelMode(scope: final s) => switch (s) {
      SingleAppScope(:final totalChannels, :final enabledChannels) =>
        _onlyEnabled
            ? l10n.applyToEnabledChannels(enabledChannels)
            : l10n.applyToAllChannels(totalChannels),
      GlobalScope(:final subtitle) => subtitle,
    },
  };

  void _submit() {
    Navigator.pop(
      context,
      BatchApplyResult(
        settings: {
          'template': _template,
          'renderer': _renderer,
          'icon': _iconMode,
          'focus_icon': _focusIconMode,
          'focus': _focusNotif,
          'preserve_small_icon': _focusNotif == kTriOptOff
              ? kTriOptOff
              : _preserveSmallIcon,
          'show_island_icon': _showIslandIcon,
          'first_float': _firstFloat,
          'enable_float': _enableFloat,
          'timeout': _islandTimeout,
          'marquee': _marquee,
          'restore_lockscreen': _restoreLockscreen,
          'highlight_color': _highlightColor,
          'dynamic_highlight_color': _isSingle
              ? (_dynamicHighlightColor ?? kTriOptDefault)
              : _dynamicHighlightColor,
          'outer_glow': _isSingle ? (_outerGlow ?? kTriOptDefault) : _outerGlow,
          'show_left_highlight': _showLeftHighlight == null
              ? null
              : (_showLeftHighlight! ? kTriOptOn : kTriOptOff),
          'show_right_highlight': _showRightHighlight == null
              ? null
              : (_showRightHighlight! ? kTriOptOn : kTriOptOff),
        },
        onlyEnabled: switch (widget.mode) {
          BatchChannelMode(scope: SingleAppScope()) => _onlyEnabled,
          _ => false,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final titleBottomPadding = 12.0;
    final contentTopPadding = 12.0;
    final contentBottomPadding = 4.0;
    final sectionTitleGap = 6.0;
    final gridGap = 12.0;
    final rowGap = 10.0;
    final blockGap = 16.0;
    final scopeGap = 12.0;
    final endGap = 20.0;

    return _KeyboardInsetPadding(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, titleBottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(l10n),
                  style: text.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(l10n),
                  style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                24,
                contentTopPadding,
                24,
                contentBottomPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.mode case BatchChannelMode(
                    scope: SingleAppScope(
                      :final totalChannels,
                      :final enabledChannels,
                    ),
                  )) ...[
                    _ScopeToggleCard(
                      totalChannels: totalChannels,
                      enabledChannels: enabledChannels,
                      value: _onlyEnabled,
                      onChanged: enabledChannels > 0
                          ? (v) => setState(() => _onlyEnabled = v)
                          : null,
                    ),
                    SizedBox(height: scopeGap),
                    const Divider(height: 1),
                    SizedBox(height: scopeGap),
                  ],

                  _SectionLabel(l10n.template),
                  SizedBox(height: sectionTitleGap),
                  _TwoColumnFields(
                    gap: gridGap,
                    children: [
                      _BatchSettingRow(
                        label: l10n.template,
                        value: _template,
                        showNotChange: !_isSingle,
                        items: widget.templateLabels.entries
                            .map(
                              (e) => DropdownMenuItem<String?>(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _template = v),
                      ),
                      _BatchSettingRow(
                        label: l10n.rendererLabel,
                        value: _renderer,
                        showNotChange: !_isSingle,
                        items: widget.rendererLabels.entries
                            .map(
                              (e) => DropdownMenuItem<String?>(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _renderer = v),
                      ),
                    ],
                  ),
                  SizedBox(height: blockGap),

                  _SectionLabel(l10n.islandSection),
                  SizedBox(height: sectionTitleGap),
                  _TwoColumnFields(
                    gap: gridGap,
                    children: [
                      _BatchSettingRow(
                        label: l10n.islandIcon,
                        value: _iconMode,
                        showNotChange: !_isSingle,
                        items: [
                          DropdownMenuItem(
                            value: kIconModeAuto,
                            child: Text(l10n.iconModeAuto),
                          ),
                          DropdownMenuItem(
                            value: kIconModeNotifSmall,
                            child: Text(l10n.iconModeNotifSmall),
                          ),
                          DropdownMenuItem(
                            value: kIconModeNotifLarge,
                            child: Text(l10n.iconModeNotifLarge),
                          ),
                          DropdownMenuItem(
                            value: kIconModeAppIcon,
                            child: Text(l10n.iconModeAppIcon),
                          ),
                        ],
                        onChanged: (v) => setState(() => _iconMode = v),
                      ),
                      _BatchSettingRow(
                        label: l10n.islandIconLabel,
                        value: _showIslandIcon,
                        showNotChange: !_isSingle,
                        items: [
                          DropdownMenuItem(
                            value: kTriOptDefault,
                            child: Text(
                              _defaultLabel(
                                context,
                                _ctrl.defaultShowIslandIcon,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: kTriOptOn,
                            child: Text(l10n.optOn),
                          ),
                          DropdownMenuItem(
                            value: kTriOptOff,
                            child: Text(l10n.optOff),
                          ),
                        ],
                        onChanged: (v) => setState(() => _showIslandIcon = v),
                      ),
                      _BatchSettingRow(
                        label: l10n.firstFloatLabel,
                        value: _firstFloat,
                        showNotChange: !_isSingle,
                        items: [
                          DropdownMenuItem(
                            value: kTriOptDefault,
                            child: Text(
                              _defaultLabel(context, _ctrl.defaultFirstFloat),
                            ),
                          ),
                          DropdownMenuItem(
                            value: kTriOptOn,
                            child: Text(l10n.optOn),
                          ),
                          DropdownMenuItem(
                            value: kTriOptOff,
                            child: Text(l10n.optOff),
                          ),
                        ],
                        onChanged: (v) => setState(() => _firstFloat = v),
                      ),
                      _BatchSettingRow(
                        label: l10n.updateFloatLabel,
                        value: _enableFloat,
                        showNotChange: !_isSingle,
                        items: [
                          DropdownMenuItem(
                            value: kTriOptDefault,
                            child: Text(
                              _defaultLabel(context, _ctrl.defaultEnableFloat),
                            ),
                          ),
                          DropdownMenuItem(
                            value: kTriOptOn,
                            child: Text(l10n.optOn),
                          ),
                          DropdownMenuItem(
                            value: kTriOptOff,
                            child: Text(l10n.optOff),
                          ),
                        ],
                        onChanged: (v) => setState(() => _enableFloat = v),
                      ),
                      _BatchSettingRow(
                        label: l10n.marqueeChannelTitle,
                        value: _marquee,
                        showNotChange: !_isSingle,
                        items: [
                          DropdownMenuItem(
                            value: kTriOptDefault,
                            child: Text(
                              _defaultLabel(context, _ctrl.defaultMarquee),
                            ),
                          ),
                          DropdownMenuItem(
                            value: kTriOptOn,
                            child: Text(l10n.optOn),
                          ),
                          DropdownMenuItem(
                            value: kTriOptOff,
                            child: Text(l10n.optOff),
                          ),
                        ],
                        onChanged: (v) => setState(() => _marquee = v),
                      ),
                      _SettingField(
                        label: l10n.autoDisappear,
                        child: TextFormField(
                          controller: _timeoutController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          scrollPadding: EdgeInsets.zero,
                          onTapOutside: (_) {
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: _fieldDecoration(
                            context,
                            hintText: _isSingle ? null : l10n.noChange,
                            suffixText: _islandTimeout != null
                                ? l10n.seconds
                                : null,
                          ),
                          onChanged: (v) {
                            final trimmed = v.trim();
                            final n = int.tryParse(trimmed);
                            final valid =
                                trimmed.isNotEmpty && n != null && n >= 1;
                            setState(() {
                              if (valid) {
                                _islandTimeout = trimmed;
                              } else if (!_isSingle) {
                                _islandTimeout = null;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: rowGap),
                  _HighlightColorField(
                    label: l10n.highlightColorLabel,
                    hintText: _isSingle
                        ? l10n.highlightColorHint
                        : l10n.noChange,
                    controller: _highlightColorController,
                    previewColor: _parseColor(_highlightColor) ?? cs.primary,
                    enabled: !_dynamicHighlightEnabled,
                    onChanged: (v) {
                      if (_dynamicHighlightEnabled) return;
                      final trimmed = v.trim();
                      setState(() {
                        if (trimmed.isNotEmpty) {
                          _highlightColor = trimmed;
                        } else if (!_isSingle) {
                          _highlightColor = null;
                        }
                      });
                    },
                    onPickColor: () async {
                      if (_dynamicHighlightEnabled) return;
                      final color = await _showColorPicker(context);
                      if (color != null) {
                        final hex = _colorToHex(color);
                        _highlightColorController.text = hex;
                        setState(() => _highlightColor = hex);
                      }
                    },
                    onReset: !_isSingle && !_dynamicHighlightEnabled
                        ? () {
                            _highlightColorController.clear();
                            setState(() => _highlightColor = null);
                          }
                        : null,
                    resetTooltip: l10n.optDefault,
                  ),
                  SizedBox(height: rowGap),
                  _BatchSettingRow(
                    label: l10n.dynamicHighlightColorLabel,
                    value: _dynamicHighlightColor,
                    showNotChange: !_isSingle,
                    items: [
                      DropdownMenuItem(
                        value: kTriOptDefault,
                        child: Text(
                          _defaultLabel(
                            context,
                            _ctrl.defaultDynamicHighlightColor,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: kTriOptOff,
                        child: Text(l10n.optOff),
                      ),
                      DropdownMenuItem(
                        value: kTriOptOn,
                        child: Text(l10n.optOn),
                      ),
                      DropdownMenuItem(
                        value: 'dark',
                        child: Text(l10n.dynamicHighlightModeDark),
                      ),
                      DropdownMenuItem(
                        value: 'darker',
                        child: Text(l10n.dynamicHighlightModeDarker),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      _dynamicHighlightColor = v;
                    }),
                  ),
                  SizedBox(height: rowGap),
                  _SettingField(
                    label: l10n.textHighlightLabel,
                    child: Row(
                      children: [
                        Expanded(
                          child: _HighlightSwitch(
                            label: l10n.showLeftHighlightShort,
                            value: _showLeftHighlight,
                            showNotChange: !_isSingle,
                            onChanged: (v) =>
                                setState(() => _showLeftHighlight = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HighlightSwitch(
                            label: l10n.showRightHighlightShort,
                            value: _showRightHighlight,
                            showNotChange: !_isSingle,
                            onChanged: (v) =>
                                setState(() => _showRightHighlight = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: blockGap),

                  _SectionLabel(l10n.focusNotificationLabel),
                  SizedBox(height: sectionTitleGap),
                  _TwoColumnFields(
                    gap: gridGap,
                    children: [
                      _BatchSettingRow(
                        label: l10n.focusIconLabel,
                        value: _focusIconMode,
                        showNotChange: !_isSingle,
                        items: [
                          DropdownMenuItem(
                            value: kIconModeAuto,
                            child: Text(l10n.iconModeAuto),
                          ),
                          DropdownMenuItem(
                            value: kIconModeNotifSmall,
                            child: Text(l10n.iconModeNotifSmall),
                          ),
                          DropdownMenuItem(
                            value: kIconModeNotifLarge,
                            child: Text(l10n.iconModeNotifLarge),
                          ),
                          DropdownMenuItem(
                            value: kIconModeAppIcon,
                            child: Text(l10n.iconModeAppIcon),
                          ),
                        ],
                        onChanged: (v) => setState(() => _focusIconMode = v),
                      ),
                      _BatchSettingRow(
                        label: l10n.focusNotificationLabel,
                        value: _focusNotif,
                        showNotChange: !_isSingle,
                        items: [
                          DropdownMenuItem(
                            value: kTriOptDefault,
                            child: Text(
                              _defaultLabel(context, _ctrl.defaultFocusNotif),
                            ),
                          ),
                          DropdownMenuItem(
                            value: kTriOptOn,
                            child: Text(l10n.optOn),
                          ),
                          DropdownMenuItem(
                            value: kTriOptOff,
                            child: Text(l10n.optOff),
                          ),
                        ],
                        onChanged: (v) => setState(() {
                          _focusNotif = v;
                          if (v == kTriOptOff) _preserveSmallIcon = kTriOptOff;
                        }),
                      ),
                      _BatchSettingRow(
                        label: l10n.preserveStatusBarSmallIconLabel,
                        value: _focusNotif == kTriOptOff
                            ? kTriOptOff
                            : _preserveSmallIcon,
                        showNotChange: !_isSingle,
                        items: [
                          DropdownMenuItem(
                            value: kTriOptDefault,
                            child: Text(
                              _defaultLabel(
                                context,
                                _ctrl.defaultPreserveSmallIcon,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: kTriOptOn,
                            child: Text(l10n.optOn),
                          ),
                          DropdownMenuItem(
                            value: kTriOptOff,
                            child: Text(l10n.optOff),
                          ),
                        ],
                        onChanged: _focusNotif == kTriOptOff
                            ? null
                            : (v) => setState(() => _preserveSmallIcon = v),
                      ),
                      _BatchSettingRow(
                        label: l10n.restoreLockscreenTitle,
                        value: _restoreLockscreen,
                        showNotChange: !_isSingle,
                        items: [
                          DropdownMenuItem(
                            value: kTriOptDefault,
                            child: Text(
                              _defaultLabel(
                                context,
                                _ctrl.defaultRestoreLockscreen,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: kTriOptOn,
                            child: Text(l10n.optOn),
                          ),
                          DropdownMenuItem(
                            value: kTriOptOff,
                            child: Text(l10n.optOff),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _restoreLockscreen = v),
                      ),
                      _BatchSettingRow(
                        label: l10n.outerGlowLabel,
                        value: _outerGlow,
                        showNotChange: !_isSingle,
                        items: [
                          DropdownMenuItem(
                            value: kTriOptDefault,
                            child: Text(
                              _defaultLabel(context, _ctrl.defaultOuterGlow),
                            ),
                          ),
                          DropdownMenuItem(
                            value: kTriOptOn,
                            child: Text(l10n.optOn),
                          ),
                          DropdownMenuItem(
                            value: kTriOptOff,
                            child: Text(l10n.optOff),
                          ),
                        ],
                        onChanged: (v) => setState(() => _outerGlow = v),
                      ),
                    ],
                  ),
                  SizedBox(height: endGap),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _hasAnyChange ? _submit : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n.apply),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyboardInsetPadding extends StatelessWidget {
  const _KeyboardInsetPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TwoColumnFields extends StatelessWidget {
  const _TwoColumnFields({required this.children, required this.gap});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _ScopeToggleCard extends StatelessWidget {
  const _ScopeToggleCard({
    required this.totalChannels,
    required this.enabledChannels,
    required this.value,
    required this.onChanged,
  });

  final int totalChannels;
  final int enabledChannels;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final active = onChanged != null;

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: active ? () => onChanged!(!value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.onlyEnabledChannels,
                      style: text.bodyMedium?.copyWith(
                        color: active
                            ? null
                            : cs.onSurface.withValues(alpha: 0.38),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.enabledChannelsCount(enabledChannels, totalChannels),
                      style: text.bodySmall?.copyWith(
                        color: active
                            ? cs.onSurfaceVariant
                            : cs.onSurface.withValues(alpha: 0.28),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchSettingRow extends StatelessWidget {
  const _BatchSettingRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.showNotChange = true,
  });

  final String label;
  final String? value;
  final List<DropdownMenuItem<String?>> items;
  final ValueChanged<String?>? onChanged;
  final bool showNotChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _SettingField(
      label: label,
      child: DropdownButtonFormField<String?>(
        key: ValueKey(value),
        initialValue: value,
        isExpanded: true,
        items: [
          if (showNotChange)
            DropdownMenuItem<String?>(value: null, child: Text(l10n.noChange)),
          ...items,
        ],
        onChanged: onChanged,
        decoration: _fieldDecoration(context),
      ),
    );
  }
}

class _SettingField extends StatelessWidget {
  const _SettingField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant);
    final lineHeight =
        (labelStyle?.fontSize ?? 14) * (labelStyle?.height ?? 1.2);
    final reservedLabelHeight = lineHeight * 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: reservedLabelHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          ),
        ),
        const SizedBox(height: 1),
        child,
      ],
    );
  }
}
