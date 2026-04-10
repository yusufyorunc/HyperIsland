part of 'batch_channel_settings_sheet.dart';

String _colorToHex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

class _HighlightColorPickerDialog extends StatefulWidget {
  const _HighlightColorPickerDialog({
    required this.initialColor,
    required this.title,
    required this.hueLabel,
    required this.saturationLabel,
    required this.brightnessLabel,
    required this.cancelLabel,
    required this.applyLabel,
  });

  final Color initialColor;
  final String title;
  final String hueLabel;
  final String saturationLabel;
  final String brightnessLabel;
  final String cancelLabel;
  final String applyLabel;

  @override
  State<_HighlightColorPickerDialog> createState() =>
      _HighlightColorPickerDialogState();
}

class _HighlightColorPickerDialogState
    extends State<_HighlightColorPickerDialog> {
  static const List<Color> _presetColors = [
    Color(0xFFF44336),
    Color(0xFFFF9800),
    Color(0xFFFFEB3B),
    Color(0xFF4CAF50),
    Color(0xFF00BCD4),
    Color(0xFF2196F3),
    Color(0xFF3F51B5),
    Color(0xFF9C27B0),
  ];

  late HSVColor _selected;

  @override
  void initState() {
    super.initState();
    _selected = HSVColor.fromColor(widget.initialColor);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final selectedColor = _selected.toColor();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.palette_rounded,
                      size: 20,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline),
                        boxShadow: [
                          BoxShadow(
                            color: cs.shadow.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _colorToHex(selectedColor),
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${widget.hueLabel}: ${_selected.hue.round()}°',
                            style: text.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${widget.saturationLabel}: ${(_selected.saturation * 100).round()}%  ·  ${widget.brightnessLabel}: ${(_selected.value * 100).round()}%',
                            style: text.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final color in _presetColors)
                    _QuickColorDot(
                      color: color,
                      selected: selectedColor.toARGB32() == color.toARGB32(),
                      onTap: () => setState(() {
                        _selected = HSVColor.fromColor(color);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _ColorSlider(
                label: widget.hueLabel,
                value: _selected.hue,
                max: 360,
                valueLabel: '${_selected.hue.round()}°',
                onChanged: (v) =>
                    setState(() => _selected = _selected.withHue(v)),
                gradientColors: List.generate(
                  7,
                  (i) => HSVColor.fromAHSV(1, i * 60, 1, 1).toColor(),
                ),
              ),
              const SizedBox(height: 12),
              _ColorSlider(
                label: widget.saturationLabel,
                value: _selected.saturation * 100,
                max: 100,
                valueLabel: '${(_selected.saturation * 100).round()}%',
                onChanged: (v) => setState(
                  () => _selected = _selected.withSaturation(v / 100),
                ),
                gradientColors: [
                  HSVColor.fromAHSV(
                    1,
                    _selected.hue,
                    0,
                    _selected.value,
                  ).toColor(),
                  HSVColor.fromAHSV(
                    1,
                    _selected.hue,
                    1,
                    _selected.value,
                  ).toColor(),
                ],
              ),
              const SizedBox(height: 12),
              _ColorSlider(
                label: widget.brightnessLabel,
                value: _selected.value * 100,
                max: 100,
                valueLabel: '${(_selected.value * 100).round()}%',
                onChanged: (v) =>
                    setState(() => _selected = _selected.withValue(v / 100)),
                gradientColors: [
                  HSVColor.fromAHSV(
                    1,
                    _selected.hue,
                    _selected.saturation,
                    0,
                  ).toColor(),
                  HSVColor.fromAHSV(
                    1,
                    _selected.hue,
                    _selected.saturation,
                    1,
                  ).toColor(),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(widget.cancelLabel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, selectedColor),
                      child: Text(widget.applyLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickColorDot extends StatelessWidget {
  const _QuickColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? cs.onSurface : cs.outline,
              width: selected ? 2.2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightColorField extends StatelessWidget {
  const _HighlightColorField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.previewColor,
    required this.onChanged,
    required this.onPickColor,
    this.enabled = true,
    this.onReset,
    this.resetTooltip,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final Color previewColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickColor;
  final bool enabled;
  final VoidCallback? onReset;
  final String? resetTooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _SettingField(
      label: label,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
        ),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: enabled ? onPickColor : null,
                child: Ink(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: previewColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled: enabled,
                readOnly: !enabled,
                textInputAction: TextInputAction.done,
                scrollPadding: EdgeInsets.zero,
                onTapOutside: (_) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                decoration: InputDecoration(
                  hintText: hintText,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: cs.surface,
                ),
                onChanged: enabled ? onChanged : null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: enabled ? onPickColor : null,
              tooltip: label,
              icon: const Icon(Icons.palette_outlined),
            ),
            if (onReset != null)
              IconButton(
                onPressed: onReset,
                tooltip: resetTooltip,
                icon: const Icon(Icons.restart_alt_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(
  BuildContext context, {
  String? hintText,
  String? suffixText,
}) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    hintText: hintText,
    suffixText: suffixText,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: cs.surfaceContainerHighest,
  );
}

class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    required this.gradientColors,
    this.valueLabel,
  });

  final String label;
  final double value;
  final double max;
  final ValueChanged<double> onChanged;
  final List<Color> gradientColors;
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: text.bodyMedium)),
            if (valueLabel != null)
              Text(
                valueLabel!,
                style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: gradientColors),
              ),
            ),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 24,
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.12),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
              ),
              child: Slider(value: value, max: max, onChanged: onChanged),
            ),
          ],
        ),
      ],
    );
  }
}

class _HighlightSwitch extends StatelessWidget {
  const _HighlightSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    this.showNotChange = true,
  });

  final String label;
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final bool showNotChange;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onChanged == null
            ? null
            : () {
                if (showNotChange && value == null) {
                  onChanged!(true);
                } else {
                  onChanged!(!value!);
                }
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 8),
              Switch(
                value: value ?? false,
                onChanged: onChanged == null ? null : (v) => onChanged!(v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
