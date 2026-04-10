import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'modern_slider.dart';
import 'section_label.dart';

class SettingsSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class SettingsItem extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showTrailingIcon;

  const SettingsItem({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.showTrailingIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: cs.primary),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: titleStyle),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing!,
              ] else if (onTap != null && showTrailingIcon) ...[
                const SizedBox(width: 16),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final dividedChildren = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i < children.length - 1) {
        dividedChildren.add(
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 18, top: 12, bottom: 8),
          child: SectionLabel(title),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(children: dividedChildren),
          ),
        ),
      ],
    );
  }
}

class SettingsRadioOption<T> extends StatelessWidget {
  const SettingsRadioOption(this.label, this.value, {super.key});

  final String label;
  final T value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>(title: Text(label), value: value);
  }
}

class MarqueeSpeedTile extends StatefulWidget {
  final AppLocalizations l10n;
  final int initialValue;
  final ValueChanged<int> onChanged;

  const MarqueeSpeedTile({
    super.key,
    required this.l10n,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<MarqueeSpeedTile> createState() => _MarqueeSpeedTileState();
}

class _MarqueeSpeedTileState extends State<MarqueeSpeedTile> {
  late int _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant MarqueeSpeedTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _currentValue = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.l10n.marqueeChannelTitle, style: titleStyle),
              ),
              Text(
                widget.l10n.marqueeSpeedLabel(_currentValue),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.primary),
              ),
              if (_currentValue != 100)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  padding: const EdgeInsets.only(left: 8),
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() => _currentValue = 100);
                    widget.onChanged(100);
                  },
                ),
            ],
          ),
          Row(
            children: [
              Text(
                widget.l10n.marqueeSpeedTitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              Expanded(
                child: SliderTheme(
                  data: ModernSliderTheme.theme(context),
                  child: Slider(
                    value: _currentValue.toDouble(),
                    min: 20,
                    max: 500,
                    divisions: 48,
                    onChanged: (v) => setState(() => _currentValue = v.round()),
                    onChangeEnd: (v) => widget.onChanged(v.round()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
