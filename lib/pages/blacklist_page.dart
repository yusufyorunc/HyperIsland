import 'dart:async';

import 'package:flutter/material.dart';
import '../controllers/blacklist_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/interaction_haptics.dart';
import '../services/app_cache_service.dart';
import '../widgets/app_list_widgets.dart';

class BlacklistPage extends StatefulWidget {
  const BlacklistPage({super.key});

  @override
  State<BlacklistPage> createState() => _BlacklistPageState();
}

class _BlacklistPageState extends State<BlacklistPage> {
  late final BlacklistController _ctrl;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  static const _menuPresetGames = 'preset_games';
  static const _menuToggleSystemApps = 'toggle_system_apps';
  static const _menuRefresh = 'refresh';
  static const _menuResetDefaults = 'reset_defaults';

  void _clearSearch() {
    _searchCtrl.clear();
    _ctrl.setSearch('');
  }

  bool _handleBackPressed() {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (_searchFocus.hasFocus && keyboardVisible) {
      _searchFocus.unfocus();
      return true;
    }

    if (!_searchFocus.hasFocus && _searchCtrl.text.isNotEmpty) {
      _clearSearch();
      return true;
    }

    return false;
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case _menuPresetGames:
        final count = await _ctrl.applyGamePreset();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.presetGamesSuccess(count))),
        );
        return;
      case _menuToggleSystemApps:
        _ctrl.setShowSystemApps(!_ctrl.showSystemApps);
        return;
      case _menuRefresh:
        await _ctrl.refresh();
        return;
      case _menuResetDefaults:
        final count = await _ctrl.resetToDefaults();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已恢复默认配置，共重置 $count 个应用')),
        );
        return;
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = BlacklistController();
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void deactivate() {
    _searchFocus.unfocus();
    super.deactivate();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final apps = _ctrl.filteredApps;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final consumed = _handleBackPressed();
        if (!consumed && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        body: RefreshIndicator(
          onRefresh: _ctrl.refresh,
          edgeOffset: 300.0,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar.large(
                backgroundColor: cs.surface,
                centerTitle: false,
                title: Text(l10n.filterRulesSection),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                    enabled: !_ctrl.loading,
                    onSelected: (value) {
                      unawaited(InteractionHaptics.button());
                      unawaited(_handleMenuAction(value));
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _menuPresetGames,
                        child: ListTile(
                          leading: const Icon(Icons.videogame_asset_outlined),
                          title: Text(l10n.presetGamesTitle),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: _menuToggleSystemApps,
                        child: ListTile(
                          leading: Icon(
                            _ctrl.showSystemApps
                                ? Icons.phone_android
                                : Icons.phone_android_outlined,
                          ),
                          title: Text(
                            _ctrl.showSystemApps ? '隐藏系统应用' : l10n.showSystemApps,
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: _menuRefresh,
                        child: ListTile(
                          leading: const Icon(Icons.refresh),
                          title: Text(l10n.refreshList),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: _menuResetDefaults,
                        child: ListTile(
                          leading: Icon(Icons.restore_outlined),
                          title: Text('恢复默认配置'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    '前台应用启动时，设置超级岛行为。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: AppListSearchHeader(
                    countText: '',
                    showCountText: false,
                    searchController: _searchCtrl,
                    searchFocusNode: _searchFocus,
                    hintText: l10n.searchApps,
                    onChanged: _ctrl.setSearch,
                    onClear: _clearSearch,
                  ),
                ),
              ),

              if (_ctrl.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (apps.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      _searchCtrl.text.isEmpty
                          ? l10n.noAppsFound
                          : l10n.noMatchingApps,
                      style: TextStyle(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList.separated(
                    itemCount: apps.length,
                    addAutomaticKeepAlives: false,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      final pkg = app.packageName;
                      return _AppTile(
                        key: ValueKey(pkg),
                        app: app,
                        action: _ctrl.actionForPackage(pkg),
                        onChanged: (v) => _ctrl.setSceneAction(pkg, v),
                        isFirst: index == 0,
                        isLast: index == apps.length - 1,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({
    super.key,
    required this.app,
    required this.action,
    required this.onChanged,
    required this.isFirst,
    required this.isLast,
  });

  final AppInfo app;
  final String action;
  final ValueChanged<String> onChanged;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final configured = action != kSceneActionDefault;

    return AppListItemFrame(
      app: app,
      onTap: () {},
      isFirst: isFirst,
      isLast: isLast,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: configured ? cs.primaryContainer : cs.surfaceContainerHigh,
          border: Border.all(
            color: configured ? cs.primary.withValues(alpha: 0.24) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: action,
            borderRadius: BorderRadius.circular(16),
            dropdownColor: cs.surfaceContainerHigh,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: configured ? cs.onPrimaryContainer : cs.onSurface,
              fontWeight: configured ? FontWeight.w600 : FontWeight.w400,
            ),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
            items: const [
              DropdownMenuItem(
                value: kSceneActionDefault,
                child: Text('默认'),
              ),
              DropdownMenuItem(
                value: kSceneActionSmallOnly,
                child: Text('关闭展开'),
              ),
              DropdownMenuItem(
                value: kSceneActionExpand,
                child: Text('自动展开'),
              ),
              DropdownMenuItem(
                value: kSceneActionSuppress,
                child: Text('回退'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
