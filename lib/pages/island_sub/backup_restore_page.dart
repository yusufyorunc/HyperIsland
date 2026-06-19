import 'package:flutter/material.dart';
import '../../controllers/config_io_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/blur_app_bar.dart';
import '../../services/interaction_haptics.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  final _ctrl = SettingsController.instance;
  String? _cleaningAction;

  bool get _cleaning => _cleaningAction != null;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  String _localizeConfigIOError(AppLocalizations l10n, ConfigIOError error) {
    return switch (error) {
      ConfigIOError.invalidFormat => l10n.errorInvalidFormat,
      ConfigIOError.noStorageDirectory => l10n.errorNoStorageDir,
      ConfigIOError.noFileSelected => l10n.errorNoFileSelected,
      ConfigIOError.noFilePath => l10n.errorNoFilePath,
      ConfigIOError.emptyClipboard => l10n.errorEmptyClipboard,
    };
  }

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

  Future<bool> _confirmCleanup({
    required String title,
    required String message,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: InteractionHaptics.interceptButton(
              () => Navigator.pop(ctx, false),
            ),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: InteractionHaptics.interceptButton(
              () => Navigator.pop(ctx, true),
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _cleanUninstalledAppConfig() async {
    if (_cleaning) return;
    final confirmed = await _confirmCleanup(
      title: '清理已卸载应用配置',
      message: '将删除已卸载应用的超级岛、Toast 转发、媒体岛和通知渠道配置，并修正已开启应用数量。此操作不可撤销，建议先导出备份。',
    );
    if (!confirmed || !mounted) return;

    setState(() => _cleaningAction = 'uninstalled');
    try {
      final count = await ConfigIOController.cleanUninstalledAppConfig();
      _showSnack('清理了 $count 条无用配置');
    } catch (e) {
      _showSnack('清理失败：$e');
    } finally {
      if (mounted) setState(() => _cleaningAction = null);
    }
  }

  Future<void> _cleanDisabledAppConfig() async {
    if (_cleaning) return;
    final confirmed = await _confirmCleanup(
      title: '清理未开启应用配置',
      message:
          '将删除未开启超级岛应用的 Toast 转发、媒体岛和通知渠道配置；已开启应用及全局配置会保留。此操作不可撤销，建议先导出备份。',
    );
    if (!confirmed || !mounted) return;

    setState(() => _cleaningAction = 'disabled');
    try {
      final count = await ConfigIOController.cleanDisabledAppConfig();
      _showSnack('清理了 $count 条无用配置');
    } catch (e) {
      _showSnack('清理失败：$e');
    } finally {
      if (mounted) setState(() => _cleaningAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      backgroundColor: cs.surface,
      body: BlurAppBarHost(
        title: l10n.backupRestoreSection,
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerHighest,
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        leading: const Icon(Icons.upload_file_outlined),
                        title: Text(l10n.exportToFile, style: titleStyle),
                        subtitle: Text(l10n.exportToFileSubtitle),
                        onTap: InteractionHaptics.interceptButton(
                          _exportToFile,
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: const Icon(Icons.copy_outlined),
                        title: Text(l10n.exportToClipboard, style: titleStyle),
                        subtitle: Text(l10n.exportToClipboardSubtitle),
                        onTap: InteractionHaptics.interceptButton(
                          _exportToClipboard,
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: const Icon(Icons.download_outlined),
                        title: Text(l10n.importFromFile, style: titleStyle),
                        subtitle: Text(l10n.importFromFileSubtitle),
                        onTap: InteractionHaptics.interceptButton(
                          _importFromFile,
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                        ),
                        leading: const Icon(Icons.paste_outlined),
                        title: Text(
                          l10n.importFromClipboard,
                          style: titleStyle,
                        ),
                        subtitle: Text(l10n.importFromClipboardSubtitle),
                        onTap: InteractionHaptics.interceptButton(
                          _importFromClipboard,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '配置清理',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerHighest,
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        enabled: !_cleaning,
                        leading: const Icon(Icons.delete_sweep_outlined),
                        title: Text('清理已卸载应用配置', style: titleStyle),
                        subtitle: const Text('删除已卸载应用残留配置，并修正已开启数量'),
                        trailing: _cleaningAction == 'uninstalled'
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        onTap: _cleaning
                            ? null
                            : InteractionHaptics.interceptButton(
                                _cleanUninstalledAppConfig,
                              ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                        ),
                        enabled: !_cleaning,
                        leading: const Icon(Icons.cleaning_services_outlined),
                        title: Text('清理未开启应用配置', style: titleStyle),
                        subtitle: const Text('删除未开启超级岛应用的应用级和渠道级配置'),
                        trailing: _cleaningAction == 'disabled'
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        onTap: _cleaning
                            ? null
                            : InteractionHaptics.interceptButton(
                                _cleanDisabledAppConfig,
                              ),
                      ),
                    ],
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
