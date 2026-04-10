import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/app_cache_service.dart';

const _channel = MethodChannel('io.github.hyperisland/test');
const kPrefGenericWhitelist = 'pref_generic_whitelist';
const kTemplateGenericProgress = 'generic_progress';
const kTemplateNotificationIsland = 'notification_island';
const kTemplateDownload = 'download';
const kTemplateDownloadLite = 'download_lite';
const kTemplateNotificationIslandLite = 'notification_island_lite';
const kRendererImageTextWithButtons4 = 'image_text_with_buttons_4';
const kRendererImageTextWithButtons4Wrap = 'image_text_with_buttons_4_wrap';
const kRendererImageTextWithRightTextButton =
    'image_text_with_right_text_button';
const kIconModeAuto = 'auto';
const kIconModeNotifSmall = 'notif_small';
const kIconModeNotifLarge = 'notif_large';
const kIconModeAppIcon = 'app_icon';
const kTriOptDefault = 'default';
const kTriOptOn = 'on';
const kTriOptOff = 'off';

class ChannelInfo {
  final String id;
  final String name;
  final String description;
  final int importance;

  const ChannelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.importance,
  });
}

class WhitelistController extends ChangeNotifier {
  List<AppInfo> _allApps = [];
  List<AppInfo> _sortedApps = [];
  List<AppInfo> _filteredApps = [];
  Set<String> enabledPackages = {};
  bool loading = true;
  String _searchQuery = '';
  bool showSystemApps = false;

  WhitelistController() {
    _load();
  }

  void _resort() {
    _sortedApps = List<AppInfo>.from(_allApps)
      ..sort((a, b) {
        final aOn = enabledPackages.contains(a.packageName);
        final bOn = enabledPackages.contains(b.packageName);
        if (aOn != bOn) return aOn ? -1 : 1;
        return a.appName.compareTo(b.appName);
      });
    _rebuildFilteredApps();
  }

  void _rebuildFilteredApps() {
    final q = _searchQuery.trim().toLowerCase();
    Iterable<AppInfo> source = showSystemApps
        ? _sortedApps
        : _sortedApps.where(
            (a) => !a.isSystem || enabledPackages.contains(a.packageName),
          );
    if (q.isNotEmpty) {
      source = source.where(
        (a) => a.appNameLower.contains(q) || a.packageNameLower.contains(q),
      );
    }
    _filteredApps = source is List<AppInfo> ? source : source.toList();
  }

  List<AppInfo> get filteredApps => _filteredApps;

  Future<void> refresh() => _load();

  Future<void> _load() async {
    loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final csv = prefs.getString(kPrefGenericWhitelist) ?? '';
      enabledPackages = csv.isEmpty
          ? {}
          : csv.split(',').where((s) => s.isNotEmpty).toSet();

      _allApps = await AppCacheService.instance.getApps();
      _resort();
    } catch (e) {
      debugPrint('WhitelistController._load error: $e');
    }

    loading = false;
    notifyListeners();
  }

  Future<void> setEnabled(String packageName, bool enabled) async {
    final changed = enabled
        ? enabledPackages.add(packageName)
        : enabledPackages.remove(packageName);
    if (!changed) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefGenericWhitelist, enabledPackages.join(','));
    _rebuildFilteredApps();
    notifyListeners();
  }

  void setSearch(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _rebuildFilteredApps();
    notifyListeners();
  }

  void setShowSystemApps(bool value) {
    if (showSystemApps == value) return;
    showSystemApps = value;
    _rebuildFilteredApps();
    notifyListeners();
  }

  Future<void> enableAll() async {
    var changed = false;
    for (final a in filteredApps) {
      if (enabledPackages.add(a.packageName)) {
        changed = true;
      }
    }
    if (!changed) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefGenericWhitelist, enabledPackages.join(','));
    _rebuildFilteredApps();
    notifyListeners();
  }

  Future<void> disableAll() async {
    var changed = false;
    for (final a in filteredApps) {
      if (enabledPackages.remove(a.packageName)) {
        changed = true;
      }
    }
    if (!changed) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefGenericWhitelist, enabledPackages.join(','));
    _rebuildFilteredApps();
    notifyListeners();
  }

  Future<void> setEnabledBatch(List<String> packages, bool enabled) async {
    var changed = false;
    for (final pkg in packages) {
      if (enabled) {
        if (enabledPackages.add(pkg)) {
          changed = true;
        }
      } else {
        if (enabledPackages.remove(pkg)) {
          changed = true;
        }
      }
    }
    if (!changed) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefGenericWhitelist, enabledPackages.join(','));
    _rebuildFilteredApps();
    notifyListeners();
  }

  Future<List<ChannelInfo>> getChannels(String packageName) async {
    try {
      final rawList =
          await _channel.invokeMethod<List<dynamic>>(
            'getNotificationChannels',
            {'packageName': packageName},
          ) ??
          [];
      return rawList.map((raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        return ChannelInfo(
          id: map['id'] as String,
          name: map['name'] as String? ?? map['id'] as String,
          description: map['description'] as String? ?? '',
          importance: map['importance'] as int? ?? 3,
        );
      }).toList();
    } on PlatformException {
      rethrow;
    } catch (e) {
      debugPrint('getChannels error: $e');
      return [];
    }
  }

  Future<Set<String>> getEnabledChannels(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final csv = prefs.getString('pref_channels_$packageName') ?? '';
    return csv.isEmpty ? {} : csv.split(',').where((s) => s.isNotEmpty).toSet();
  }

  Future<void> setEnabledChannels(
    String packageName,
    Set<String> channelIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_channels_$packageName', channelIds.join(','));
  }

  Map<String, String> getTemplates(AppLocalizations l10n) => {
    kTemplateGenericProgress: l10n.templateDownloadName,
    kTemplateNotificationIsland: l10n.templateNotificationIslandName,
    kTemplateNotificationIslandLite: l10n.templateNotificationIslandLiteName,
    kTemplateDownloadLite: l10n.templateDownloadLiteName,
  };

  Map<String, String> getRenderers(AppLocalizations l10n) => {
    kRendererImageTextWithButtons4: l10n.rendererImageTextWithButtons4Name,
    kRendererImageTextWithButtons4Wrap: l10n.rendererCoverInfoName,
    kRendererImageTextWithRightTextButton:
        l10n.rendererImageTextWithRightTextButtonName,
  };

  Future<Map<String, String>> getChannelTemplates(
    String packageName,
    List<String> channelIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return Map.fromEntries(
      channelIds.map((id) {
        final template =
            prefs.getString('pref_channel_template_${packageName}_$id') ??
            kTemplateNotificationIsland;
        return MapEntry(id, template);
      }),
    );
  }

  Future<void> setChannelTemplate(
    String packageName,
    String channelId,
    String template,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pref_channel_template_${packageName}_$channelId',
      template,
    );
  }

  Future<Map<String, Map<String, String>>> getChannelExtraSettings(
    String packageName,
    List<String> channelIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return Map.fromEntries(
      channelIds.map(
        (id) => MapEntry(id, {
          'icon':
              prefs.getString('pref_channel_icon_${packageName}_$id') ??
              kIconModeAuto,
          'focus_icon':
              prefs.getString('pref_channel_focus_icon_${packageName}_$id') ??
              kIconModeAuto,
          'focus':
              prefs.getString('pref_channel_focus_${packageName}_$id') ??
              kTriOptDefault,
          'preserve_small_icon':
              prefs.getString(
                'pref_channel_preserve_small_icon_${packageName}_$id',
              ) ??
              kTriOptDefault,
          'first_float':
              prefs.getString('pref_channel_first_float_${packageName}_$id') ??
              kTriOptDefault,
          'enable_float':
              prefs.getString('pref_channel_enable_float_${packageName}_$id') ??
              kTriOptDefault,
          'timeout':
              prefs.getString('pref_channel_timeout_${packageName}_$id') ?? '5',
          'marquee':
              prefs.getString('pref_channel_marquee_${packageName}_$id') ??
              kTriOptDefault,
          'renderer':
              prefs.getString('pref_channel_renderer_${packageName}_$id') ??
              kRendererImageTextWithButtons4,
          'restore_lockscreen':
              prefs.getString(
                'pref_channel_restore_lockscreen_${packageName}_$id',
              ) ??
              kTriOptDefault,
          'highlight_color':
              prefs.getString(
                'pref_channel_highlight_color_${packageName}_$id',
              ) ??
              '',
          'dynamic_highlight_color':
              prefs.getString(
                'pref_channel_dynamic_highlight_color_${packageName}_$id',
              ) ??
              kTriOptDefault,
          'outer_glow':
              prefs.getString('pref_channel_outer_glow_${packageName}_$id') ??
              kTriOptDefault,
          'show_left_highlight':
              prefs.getString(
                'pref_channel_show_left_highlight_${packageName}_$id',
              ) ??
              kTriOptOff,
          'show_right_highlight':
              prefs.getString(
                'pref_channel_show_right_highlight_${packageName}_$id',
              ) ??
              kTriOptOff,
        }),
      ),
    );
  }

  Future<void> setChannelIconMode(
    String packageName,
    String channelId,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_channel_icon_${packageName}_$channelId', value);
  }

  Future<void> setChannelFocusIconMode(
    String packageName,
    String channelId,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pref_channel_focus_icon_${packageName}_$channelId',
      value,
    );
  }

  Future<void> setChannelFocusNotif(
    String packageName,
    String channelId,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pref_channel_focus_${packageName}_$channelId',
      value,
    );
  }

  Future<void> setChannelPreserveSmallIcon(
    String packageName,
    String channelId,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pref_channel_preserve_small_icon_${packageName}_$channelId',
      value,
    );
  }

  Future<void> setChannelFirstFloat(
    String packageName,
    String channelId,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pref_channel_first_float_${packageName}_$channelId',
      value,
    );
  }

  Future<void> setChannelEnableFloat(
    String packageName,
    String channelId,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pref_channel_enable_float_${packageName}_$channelId',
      value,
    );
  }

  Future<void> setChannelTimeout(
    String packageName,
    String channelId,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pref_channel_timeout_${packageName}_$channelId',
      value,
    );
  }

  Future<void> setChannelMarquee(
    String packageName,
    String channelId,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pref_channel_marquee_${packageName}_$channelId',
      value,
    );
  }

  Future<void> setChannelRestoreLockscreen(
    String packageName,
    String channelId,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pref_channel_restore_lockscreen_${packageName}_$channelId',
      value,
    );
  }

  Future<void> setChannelShowIslandIcon(
    String packageName,
    String channelId,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pref_channel_show_island_icon_${packageName}_$channelId',
      value,
    );
  }

  Future<void> setChannelRenderer(
    String packageName,
    String channelId,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pref_channel_renderer_${packageName}_$channelId',
      value,
    );
  }

  Future<void> setChannelHighlightColor(
    String packageName,
    String channelId,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pref_channel_highlight_color_${packageName}_$channelId',
      value,
    );
  }

  Future<void> setChannelDynamicHighlightColor(
    String packageName,
    String channelId,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pref_channel_dynamic_highlight_color_${packageName}_$channelId',
      value,
    );
  }

  Future<void> setChannelOuterGlow(
    String packageName,
    String channelId,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pref_channel_outer_glow_${packageName}_$channelId',
      value,
    );
  }

  Future<void> setChannelShowLeftHighlight(
    String packageName,
    String channelId,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pref_channel_show_left_highlight_${packageName}_$channelId',
      value,
    );
  }

  Future<void> setChannelShowRightHighlight(
    String packageName,
    String channelId,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pref_channel_show_right_highlight_${packageName}_$channelId',
      value,
    );
  }

  Future<void> batchApplyChannelSettings(
    String packageName,
    List<String> channelIds,
    Map<String, String?> settings,
  ) async {
    if (channelIds.isEmpty || settings.values.every((v) => v == null)) return;
    final prefs = await SharedPreferences.getInstance();
    const keyMap = {
      'template': 'pref_channel_template',
      'renderer': 'pref_channel_renderer',
      'icon': 'pref_channel_icon',
      'focus_icon': 'pref_channel_focus_icon',
      'focus': 'pref_channel_focus',
      'preserve_small_icon': 'pref_channel_preserve_small_icon',
      'show_island_icon': 'pref_channel_show_island_icon',
      'first_float': 'pref_channel_first_float',
      'enable_float': 'pref_channel_enable_float',
      'timeout': 'pref_channel_timeout',
      'marquee': 'pref_channel_marquee',
      'restore_lockscreen': 'pref_channel_restore_lockscreen',
      'highlight_color': 'pref_channel_highlight_color',
      'dynamic_highlight_color': 'pref_channel_dynamic_highlight_color',
      'outer_glow': 'pref_channel_outer_glow',
      'show_left_highlight': 'pref_channel_show_left_highlight',
      'show_right_highlight': 'pref_channel_show_right_highlight',
    };
    final futures = <Future<bool>>[];
    for (final id in channelIds) {
      keyMap.forEach((settingKey, prefPrefix) {
        final value = settings[settingKey];
        if (value != null) {
          futures.add(
            prefs.setString('${prefPrefix}_${packageName}_$id', value),
          );
        }
      });
    }
    await Future.wait(futures);
  }

  Future<void> batchApplyToAllEnabledApps(
    Map<String, String?> settings, {
    void Function(int done, int total)? onProgress,
  }) async {
    if (enabledPackages.isEmpty || settings.values.every((v) => v == null)) {
      return;
    }
    final pkgList = enabledPackages.toList();
    final total = pkgList.length;

    for (var i = 0; i < total; i++) {
      final pkg = pkgList[i];
      try {
        final channels = await getChannels(pkg);
        final ids = channels.map((c) => c.id).toList();
        if (ids.isNotEmpty) {
          await batchApplyChannelSettings(pkg, ids, settings);
        }
      } catch (_) {}
      onProgress?.call(i + 1, total);
    }
  }
}
