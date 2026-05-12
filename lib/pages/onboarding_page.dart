import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  static const _channel = MethodChannel('io.github.hyperisland/test');

  late final AnimationController _backgroundController;
  final _pageController = PageController();
  int _currentStep = 0;
  bool _checkingStatus = false;
  bool? _lsposedActive;
  bool? _rootGranted;
  int? _protocolVersion;
  int? _androidSdkVersion;
  bool _defaultFocusNotif = SettingsController.instance.defaultFocusNotif;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _refreshStatus();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    if (_checkingStatus) return;
    setState(() => _checkingStatus = true);
    try {
      final results = await Future.wait<Object>([
        _channel
            .invokeMethod<bool>('isModuleActive')
            .then((value) => value ?? false),
        _channel
            .invokeMethod<bool>('checkRootAccess')
            .then((value) => value ?? false),
        _channel
            .invokeMethod<int>('getFocusProtocolVersion')
            .then((value) => value ?? 0),
        _channel
            .invokeMethod<int>('getAndroidSdkVersion')
            .then((value) => value ?? 0),
      ]);
      if (!mounted) return;
      setState(() {
        _lsposedActive = results[0] as bool;
        _rootGranted = results[1] as bool;
        _protocolVersion = results[2] as int;
        _androidSdkVersion = results[3] as int;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lsposedActive = false;
        _rootGranted = false;
        _protocolVersion = 0;
        _androidSdkVersion = 0;
      });
    } finally {
      if (mounted) setState(() => _checkingStatus = false);
    }
  }

  Future<void> _goToStep(int step) async {
    if (step < 0) return;
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleNextStep(bool isLast) async {
    if (isLast) {
      await _finishOnboarding();
      return;
    }

    if (_currentStep == 1 &&
        (_lsposedActive != true ||
            _rootGranted != true ||
            (_protocolVersion ?? 0) < 3 ||
            (_androidSdkVersion ?? 0) < 35)) {
      final shouldContinue = await _confirmMissingPermission();
      if (!shouldContinue) return;
    }

    await _goToStep(_currentStep + 1);
  }

  Future<void> _finishOnboarding() async {
    await SettingsController.instance.setDefaultFocusNotif(_defaultFocusNotif);
    await SettingsController.instance.setOnboardingCompleted(true);
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  Future<bool> _confirmMissingPermission() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: Text(
          AppLocalizations.of(context)!.onboardingMissingPermissionTitle,
        ),
        content: Text(
          AppLocalizations.of(context)!.onboardingMissingPermissionMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.onboardingDialogContinue),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.onboardingDialogClose),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      _OnboardingStep(
        title: l10n.onboardingWelcomeTitle,
        subtitle: l10n.onboardingWelcomeSubtitle,
        icon: Icons.auto_awesome,
      ),
      _OnboardingStep(
        title: l10n.onboardingEnvironmentTitle,
        subtitle: l10n.onboardingEnvironmentSubtitle,
        icon: Icons.verified_outlined,
      ),
      _OnboardingStep(
        title: l10n.onboardingNotificationStyleTitle,
        subtitle: l10n.onboardingNotificationStyleSubtitle,
        icon: Icons.notifications_active_outlined,
      ),
      _OnboardingStep(
        title: l10n.onboardingFinishTitle,
        subtitle: l10n.onboardingFinishSubtitle,
        icon: Icons.rocket_launch_outlined,
      ),
    ];
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == steps.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) =>
                _OnboardingBackdrop(progress: _backgroundController.value),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                  child: Row(
                    children: [
                      Text(
                        l10n.onboardingAppName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        onPressed: _finishOnboarding,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: steps.length,
                    onPageChanged: (index) =>
                        setState(() => _currentStep = index),
                    itemBuilder: (context, index) => _OnboardingStepView(
                      step: steps[index],
                      stepIndex: index,
                      stepCount: steps.length,
                      statusPanel: index == 1
                          ? _EnvironmentStatusPanel(
                              checking: _checkingStatus,
                              lsposedActive: _lsposedActive,
                              rootGranted: _rootGranted,
                              protocolVersion: _protocolVersion,
                              androidSdkVersion: _androidSdkVersion,
                              l10n: l10n,
                              onRefresh: _refreshStatus,
                            )
                          : null,
                      contentPanel: index == 2
                          ? _NotificationStylePanel(
                              defaultFocusNotif: _defaultFocusNotif,
                              onChanged: (value) =>
                                  setState(() => _defaultFocusNotif = value),
                              l10n: l10n,
                            )
                          : null,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          steps.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: index == _currentStep ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: index == _currentStep ? 0.95 : 0.32,
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isFirst
                                  ? null
                                  : () => _goToStep(_currentStep - 1),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white38,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.38),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(l10n.onboardingPrevious),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: () => _handleNextStep(isLast),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF161031),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                isLast
                                    ? l10n.onboardingDone
                                    : l10n.onboardingNext,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _OnboardingStep {
  final String title;
  final String subtitle;
  final IconData icon;

  const _OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _OnboardingStepView extends StatelessWidget {
  final _OnboardingStep step;
  final int stepIndex;
  final int stepCount;
  final Widget? statusPanel;
  final Widget? contentPanel;

  const _OnboardingStepView({
    required this.step,
    required this.stepIndex,
    required this.stepCount,
    this.statusPanel,
    this.contentPanel,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height - 220,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 154,
              height: 154,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFFFFF), Color(0xFF9EEBFF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF73D7FF).withValues(alpha: 0.28),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(step.icon, size: 68, color: const Color(0xFF171233)),
            ),
            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(
                context,
              )!.onboardingStepLabel(stepIndex + 1, stepCount),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              step.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1.06,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                step.subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.74),
                  height: 1.55,
                ),
              ),
            ),
            if (statusPanel != null) ...[
              const SizedBox(height: 28),
              statusPanel!,
            ],
            if (contentPanel != null) ...[
              const SizedBox(height: 28),
              contentPanel!,
            ],
          ],
        ),
      ),
    );
  }
}

class _EnvironmentStatusPanel extends StatelessWidget {
  final bool checking;
  final bool? lsposedActive;
  final bool? rootGranted;
  final int? protocolVersion;
  final int? androidSdkVersion;
  final AppLocalizations l10n;
  final VoidCallback onRefresh;

  const _EnvironmentStatusPanel({
    required this.checking,
    required this.lsposedActive,
    required this.rootGranted,
    required this.protocolVersion,
    required this.androidSdkVersion,
    required this.l10n,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ColoredBox(
          color: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      l10n.onboardingStatusTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: checking ? null : onRefresh,
                      icon: checking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 18),
                      label: Text(l10n.onboardingRetry),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _StatusRow(
                  title: l10n.onboardingLsposedStatus,
                  passed: lsposedActive,
                ),
                const SizedBox(height: 10),
                _StatusRow(
                  title: l10n.onboardingRootStatus,
                  passed: rootGranted,
                ),
                const SizedBox(height: 10),
                _StatusRow(
                  title: l10n.onboardingProtocolStatus,
                  passed: protocolVersion == null
                      ? null
                      : protocolVersion! >= 3,
                  value: protocolVersion == null || protocolVersion! >= 3
                      ? null
                      : l10n.onboardingUnsupportedSystem,
                ),
                const SizedBox(height: 10),
                _AndroidVersionRow(sdkVersion: androidSdkVersion, l10n: l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationStylePanel extends StatelessWidget {
  final bool defaultFocusNotif;
  final ValueChanged<bool> onChanged;
  final AppLocalizations l10n;

  const _NotificationStylePanel({
    required this.defaultFocusNotif,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        children: [
          _NotificationStyleOption(
            label: l10n.focusNotificationLabel,
            assetPath: 'assets/images/notification1.png',
            selected: defaultFocusNotif,
            onTap: () => onChanged(true),
          ),
          const SizedBox(height: 14),
          _NotificationStyleOption(
            label: l10n.onboardingOriginalNotificationLabel,
            assetPath: 'assets/images/notification2.png',
            selected: !defaultFocusNotif,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _NotificationStyleOption extends StatelessWidget {
  final String label;
  final String assetPath;
  final bool selected;
  final VoidCallback onTap;

  const _NotificationStyleOption({
    required this.label,
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFF9EEBFF)
        : Colors.white.withValues(alpha: 0.14);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: selected ? 0.16 : 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF73D7FF).withValues(alpha: 0.2),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    key: ValueKey(selected),
                    color: selected ? const Color(0xFF9EEBFF) : Colors.white54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                assetPath,
                fit: BoxFit.fitWidth,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 86,
                  alignment: Alignment.center,
                  color: Colors.white.withValues(alpha: 0.08),
                  child: Text(
                    assetPath,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String title;
  final bool? passed;
  final String? value;

  const _StatusRow({required this.title, required this.passed, this.value});

  @override
  Widget build(BuildContext context) {
    final waiting = passed == null;
    final ok = passed == true;
    final color = waiting
        ? Colors.white60
        : ok
        ? const Color(0xFF77F2B7)
        : const Color(0xFFFF8A8A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    value!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            waiting
                ? Icons.hourglass_empty_rounded
                : ok
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _AndroidVersionRow extends StatelessWidget {
  final int? sdkVersion;
  final AppLocalizations l10n;

  const _AndroidVersionRow({required this.sdkVersion, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final waiting = sdkVersion == null;
    final value = switch (sdkVersion) {
      null => null,
      35 => l10n.onboardingAndroid15Limited,
      final version when version > 0 && version < 35 =>
        l10n.onboardingUnsupportedSystem,
      0 => l10n.onboardingUnsupportedSystem,
      _ => null,
    };
    final color = waiting
        ? Colors.white60
        : sdkVersion != null && sdkVersion! >= 36
        ? const Color(0xFF77F2B7)
        : sdkVersion == 35
        ? const Color(0xFFFFB45C)
        : const Color(0xFFFF8A8A);
    final icon = waiting
        ? Icons.hourglass_empty_rounded
        : sdkVersion != null && sdkVersion! >= 36
        ? Icons.check_circle_rounded
        : sdkVersion == 35
        ? Icons.warning_amber_rounded
        : Icons.cancel_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.onboardingAndroidStatus,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(icon, color: color),
        ],
      ),
    );
  }
}

class _OnboardingBackdrop extends StatelessWidget {
  final double progress;

  const _OnboardingBackdrop({required this.progress});

  @override
  Widget build(BuildContext context) {
    final phase = progress * math.pi * 2;
    final hueShift = math.sin(phase) * 0.5 + 0.5;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.95 + math.sin(phase * 0.42) * 0.18, -1),
          end: Alignment(0.95 + math.cos(phase * 0.36) * 0.18, 1),
          colors: [
            Color.lerp(
              const Color(0xFF060716),
              const Color(0xFF11163F),
              hueShift,
            )!,
            Color.lerp(
              const Color(0xFF171233),
              const Color(0xFF102D4D),
              1 - hueShift,
            )!,
            Color.lerp(
              const Color(0xFF062837),
              const Color(0xFF220D42),
              hueShift,
            )!,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _GlowPainter(progress),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double progress;

  const _GlowPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final phase = progress * math.pi * 2;
    final spots = [
      (
        Offset(
          size.width * (0.18 + math.sin(phase * 0.72) * 0.18),
          size.height * (0.2 + math.cos(phase * 0.58) * 0.12),
        ),
        size.width * 0.56,
        const Color(0xFF7A5CFF),
      ),
      (
        Offset(
          size.width * (0.84 + math.cos(phase * 0.64) * 0.14),
          size.height * (0.18 + math.sin(phase * 0.76) * 0.16),
        ),
        size.width * 0.46,
        const Color(0xFF12D6FF),
      ),
      (
        Offset(
          size.width * (0.76 + math.sin(phase * 0.52) * 0.2),
          size.height * (0.78 + math.cos(phase * 0.66) * 0.11),
        ),
        size.width * 0.58,
        const Color(0xFF18FFB2),
      ),
    ];

    for (final spot in spots) {
      paint.shader = RadialGradient(
        colors: [spot.$3.withValues(alpha: 0.28), spot.$3.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: spot.$1, radius: spot.$2));
      canvas.drawCircle(spot.$1, spot.$2, paint);
    }

    paint
      ..shader = null
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver
      ..color = const Color(0xFF050611).withValues(alpha: 0.34);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
