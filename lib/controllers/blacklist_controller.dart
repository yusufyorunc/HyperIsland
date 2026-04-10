import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_cache_service.dart';

const kPrefAppBlacklist = 'pref_app_blacklist';

class BlacklistController extends ChangeNotifier {
  List<AppInfo> _allApps = [];
  List<AppInfo> _sortedApps = [];
  List<AppInfo> _filteredApps = [];
  Set<String> blacklistedPackages = {};
  bool loading = true;
  String _searchQuery = '';
  bool showSystemApps = false;

  BlacklistController() {
    _load();
  }

  void _resort() {
    _sortedApps = List<AppInfo>.from(_allApps)
      ..sort((a, b) {
        final aOn = blacklistedPackages.contains(a.packageName);
        final bOn = blacklistedPackages.contains(b.packageName);
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
            (a) => !a.isSystem || blacklistedPackages.contains(a.packageName),
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
      final csv = prefs.getString(kPrefAppBlacklist) ?? '';
      blacklistedPackages = csv.isEmpty
          ? {}
          : csv.split(',').where((s) => s.isNotEmpty).toSet();

      _allApps = await AppCacheService.instance.getApps();
      _resort();
    } catch (e) {
      debugPrint('BlacklistController._load error: $e');
    }

    loading = false;
    notifyListeners();
  }

  Future<void> setBlacklisted(String packageName, bool enabled) async {
    final changed = enabled
        ? blacklistedPackages.add(packageName)
        : blacklistedPackages.remove(packageName);
    if (!changed) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefAppBlacklist, blacklistedPackages.join(','));
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
      if (blacklistedPackages.add(a.packageName)) {
        changed = true;
      }
    }
    if (!changed) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefAppBlacklist, blacklistedPackages.join(','));
    _rebuildFilteredApps();
    notifyListeners();
  }

  Future<void> disableAll() async {
    var changed = false;
    for (final a in filteredApps) {
      if (blacklistedPackages.remove(a.packageName)) {
        changed = true;
      }
    }
    if (!changed) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefAppBlacklist, blacklistedPackages.join(','));
    _rebuildFilteredApps();
    notifyListeners();
  }
}
