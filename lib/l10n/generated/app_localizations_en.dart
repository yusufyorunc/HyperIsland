// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home'; [cite: 1]

  @override
  String get navApps => 'Apps'; [cite: 1]

  @override
  String get navSettings => 'Settings'; [cite: 1]

  @override
  String get cancel => 'Cancel'; [cite: 1]

  @override
  String get confirm => 'Confirm'; [cite: 1]

  @override
  String get ok => 'OK'; [cite: 1]

  @override
  String get apply => 'Apply'; [cite: 1]

  @override
  String get noChange => 'No change'; [cite: 1]

  @override
  String get newVersionFound => 'New Version Available'; [cite: 1]

  @override
  String currentVersion(String version) {
    return 'Current version: $version'; [cite: 1]
  }

  @override
  String latestVersion(String version) {
    return 'Latest version: $version'; [cite: 1]
  }

  @override
  String get later => 'Later'; [cite: 1]

  @override
  String get goUpdate => 'Update'; [cite: 1]

  @override
  String get sponsorSupport => 'Support the Author'; [cite: 1]

  @override
  String get sponsorAuthor => 'Sponsor'; [cite: 1]

  @override
  String get restartScope => 'Restart Scope'; [cite: 1]

  @override
  String get systemUI => 'System UI'; [cite: 1]

  @override
  String get downloadManager => 'Download Manager'; [cite: 1]

  @override
  String get xmsf => 'XMSF (Xiaomi Service Framework)'; [cite: 1]

  @override
  String get notificationTest => 'Notification Test'; [cite: 1]

  @override
  String get sendTestNotification => 'Send Test Notification'; [cite: 1]

  @override
  String get notes => 'Notes'; [cite: 1]

  @override
  String get detectingModuleStatus => 'Detecting module status...'; [cite: 1]

  @override
  String get moduleStatus => 'Module Status'; [cite: 1]

  @override
  String get activated => 'Activated'; [cite: 1]

  @override
  String get notActivated => 'Not Activated'; [cite: 1]

  @override
  String get enableInLSPosed => 'Please enable this module in LSPosed'; [cite: 1]

  @override
  String lsposedApiVersion(int version) {
    return 'LSPosed API Version: $version';
  }

  @override
  String get updateLSPosedRequired => 'Please update LSPosed version'; [cite: 1]

  @override
  String get systemNotSupported => 'System Not Supported'; [cite: 1]

  @override
  String systemNotSupportedSubtitle(int version) {
    return 'Current system does not support Dynamic Island (protocol version $version, requires version 3)'; [cite: 2]
  }

  @override
  String restartFailed(String message) {
    return 'Restart failed: $message'; [cite: 2]
  }

  @override
  String get restartRootRequired =>
      'Please check if ROOT permission has been granted to this app'; [cite: 2]

  @override
  String get note1 =>
      '1. This page is only for testing Dynamic Island support, not actual effects'; [cite: 3]

  @override
  String get note2 =>
      '2. Disable focus notification whitelist for System UI and MIUI Framework in HyperCeiler'; [cite: 3]

  @override
  String get note3 =>
      '3. After activating in LSPosed Manager, you must restart the related scope app'; [cite: 4]

  @override
  String get note4 =>
      '4. General adaptation is supported, try checking an appropriate template'; [cite: 4]

  @override
  String get behaviorSection => 'Behavior'; [cite: 4]

  @override
  String get defaultConfigSection => 'Default Channel Settings'; [cite: 4]

  @override
  String get appearanceSection => 'Appearance'; [cite: 4]

  @override
  String get configSection => 'Configuration'; [cite: 4]

  @override
  String get aboutSection => 'About'; [cite: 4]

  @override
  String get keepFocusNotifTitle => 'Keep notification after download pause'; [cite: 4]

  @override
  String get keepFocusNotifSubtitle =>
      'Show a focus notification to resume download, but state synchronization issues may occur'; [cite: 4]

  @override
  String get unlockAllFocusTitle => 'Remove focus notification whitelist'; [cite: 4]

  @override
  String get unlockAllFocusSubtitle =>
      'Allow all apps to send focus notifications without system authorization'; [cite: 4]

  @override
  String get unlockFocusAuthTitle =>
      'Remove focus notification signature verification'; [cite: 4]

  @override
  String get unlockFocusAuthSubtitle =>
      'Allow all apps to send focus notifications to watch/bracelet, bypassing signature check (requires hooking XMSF)'; [cite: 4]

  @override
  String get checkUpdateOnLaunchTitle => 'Check for updates on launch'; [cite: 4]

  @override
  String get checkUpdateOnLaunchSubtitle =>
      'Automatically check for new versions when the app starts'; [cite: 4]

  @override
  String get showWelcomeTitle => 'Show welcome message on launch';

  @override
  String get showWelcomeSubtitle => 'Display welcome information on Island when the app starts';

  @override
  String get interactionHapticsTitle => 'Interaction Haptics';

  @override
  String get interactionHapticsSubtitle => 'Enable Hyper custom haptic feedback for switches, sliders, and buttons';

  @override
  String get checkUpdate => 'Check for updates'; [cite: 4]

  @override
  String get alreadyLatest => 'Already on the latest version'; [cite: 4]

  @override
  String get useAppIconTitle => 'Use App Icon';

  @override
  String get useAppIconSubtitle => 'Use the app icon for download manager notifications';

  @override
  String get roundIconTitle => 'Round icon corners'; [cite: 4]

  @override
  String get roundIconSubtitle => 'Add rounded corners to notification icons'; [cite: 4]

  @override
  String get marqueeChannelTitle => 'Text Scrolling Island'; [cite: 4]

  @override
  String get marqueeSpeedTitle => 'Speed'; [cite: 4]

  @override
  String marqueeSpeedLabel(int speed) {
    return '$speed px/s'; [cite: 4]
  }

  @override
  String get themeModeTitle => 'Color mode'; [cite: 5]

  @override
  String get themeModeSystem => 'Follow system'; [cite: 5]

  @override
  String get themeModeLight => 'Light'; [cite: 5]

  @override
  String get themeModeDark => 'Dark'; [cite: 5]

  @override
  String get languageTitle => 'Language'; [cite: 5]

  @override
  String get languageAuto => 'Follow system'; [cite: 5]

  @override
  String get languageZh => '中文'; [cite: 5]

  @override
  String get languageEn => 'English'; [cite: 5]

  @override
  String get languageJa => '日本語'; [cite: 5]

  @override
  String get languageTr => 'Türkçe'; [cite: 5]

  @override
  String get exportToFile => 'Export to file'; [cite: 5]

  @override
  String get exportToFileSubtitle => 'Save configuration as a JSON file'; [cite: 5]

  @override
  String get exportToClipboard => 'Export to clipboard'; [cite: 5]

  @override
  String get exportToClipboardSubtitle => 'Copy configuration as JSON text'; [cite: 5]

  @override
  String get exportConfig => 'Export Configuration';

  @override
  String get exportConfigSubtitle => 'Choose to export to file or clipboard';

  @override
  String get importFromFile => 'Import from file'; [cite: 5]

  @override
  String get importFromFileSubtitle => 'Restore configuration from a JSON file'; [cite: 5]

  @override
  String get importFromClipboard => 'Import from clipboard'; [cite: 5]

  @override
  String get importFromClipboardSubtitle =>
      'Restore configuration from JSON text in clipboard'; [cite: 5]

  @override
  String get importConfig => 'Import Configuration';

  @override
  String get importConfigSubtitle => 'Choose to import from file or clipboard';

  @override
  String get qqGroup => 'QQ Group'; [cite: 5]

  @override
  String get restartScopeApp =>
      'Please restart the scope app for settings to take effect'; [cite: 5]

  @override
  String get groupNumberCopied => 'Group number copied to clipboard'; [cite: 5]

  @override
  String exportedTo(String path) {
    return 'Exported to: $path'; [cite: 5]
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error'; [cite: 5]
  }

  @override
  String get configCopied => 'Configuration copied to clipboard'; [cite: 5]

  @override
  String importSuccess(int count) {
    return 'Import successful, $count items, please restart the app'; [cite: 5]
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error'; [cite: 5]
  }

  @override
  String get appAdaptation => 'App Adaptation'; [cite: 5]

  @override
  String selectedAppsCount(int count) {
    return '$count apps selected'; [cite: 6]
  }

  @override
  String get cancelSelection => 'Cancel selection'; [cite: 6]

  @override
  String get deselectAll => 'Deselect all'; [cite: 6]

  @override
  String get selectAll => 'Select all'; [cite: 6]

  @override
  String get batchChannelSettings => 'Batch channel settings'; [cite: 6]

  @override
  String get selectEnabledApps => 'Select enabled apps'; [cite: 6]

  @override
  String get batchEnable => 'Batch enable'; [cite: 6]

  @override
  String get batchDisable => 'Batch disable'; [cite: 6]

  @override
  String get multiSelect => 'Multi-select'; [cite: 6]

  @override
  String get showSystemApps => 'Show system apps'; [cite: 6]

  @override
  String get refreshList => 'Refresh list'; [cite: 6]

  @override
  String get enableAll => 'Enable all'; [cite: 6]

  @override
  String get disableAll => 'Disable all'; [cite: 6]

  @override
  String enabledAppsCount(int count) {
    return 'Dynamic Island enabled for $count apps'; [cite: 6]
  }

  @override
  String enabledAppsCountWithSystem(int count) {
    return 'Dynamic Island enabled for $count apps (including system apps)'; [cite: 6]
  }

  @override
  String get searchApps => 'Search app name or package name'; [cite: 6]

  @override
  String get noAppsFound =>
      'No installed apps found\nPlease check if app list permission is enabled'; [cite: 6]

  @override
  String get noMatchingApps => 'No matching apps'; [cite: 6]

  @override
  String applyToSelectedAppsChannels(int count) {
    return 'Will apply to enabled channels of $count selected apps'; [cite: 6]
  }

  @override
  String get applyingConfig => 'Applying configuration...'; [cite: 6]

  @override
  String progressApps(int done, int total) {
    return 'Progress: $done / $total'; [cite: 6]
  }

  @override
  String batchApplied(int count) {
    return 'Batch applied to $count apps'; [cite: 6]
  }

  @override
  String get cannotReadChannels => 'Cannot Read Notification Channels'; [cite: 6]

  @override
  String get rootRequiredMessage =>
      'Reading notification channels requires ROOT permission.\nPlease confirm ROOT permission is granted and try again.'; [cite: 6]

  @override
  String get enableAllChannels => 'Enable all channels'; [cite: 6]

  @override
  String get noChannelsFound => 'No notification channels found'; [cite: 6]

  @override
  String get noChannelsFoundSubtitle =>
      'This app has no notification channels, or they cannot be read'; [cite: 7]

  @override
  String allChannelsActive(int count) {
    return 'Active for all $count channels'; [cite: 7]
  }

  @override
  String selectedChannels(int selected, int total) {
    return '$selected / $total channels selected'; [cite: 7]
  }

  @override
  String allChannelsDisabled(int count) {
    return 'All $count channels (disabled)'; [cite: 7]
  }

  @override
  String get appDisabledBanner =>
      'App is disabled, the following channel settings have no effect'; [cite: 7]

  @override
  String channelImportance(String importance, String id) {
    return 'Importance: $importance  ·  $id'; [cite: 7]
  }

  @override
  String get channelSettings => 'Channel settings'; [cite: 7]

  @override
  String get importanceNone => 'None'; [cite: 7]

  @override
  String get importanceMin => 'Min'; [cite: 7]

  @override
  String get importanceLow => 'Low'; [cite: 7]

  @override
  String get importanceDefault => 'Default'; [cite: 7]

  @override
  String get importanceHigh => 'High'; [cite: 7]

  @override
  String get importanceUnknown => 'Unknown'; [cite: 7]

  @override
  String applyToEnabledChannels(int count) {
    return 'Will apply to $count enabled channels'; [cite: 7]
  }

  @override
  String applyToAllChannels(int count) {
    return 'Will apply to all $count channels'; [cite: 7]
  }

  @override
  String get templateDownloadName => 'Download'; [cite: 7]

  @override
  String get templateNotificationIslandName => 'Notification Island'; [cite: 7]

  @override
  String get templateNotificationIslandLiteName => 'Notification Island|Lite'; [cite: 7]

  @override
  String get templateDownloadLiteName => 'Download|Lite'; [cite: 7]

  @override
  String get islandSection => 'Island'; [cite: 7]

  @override
  String get template => 'Template'; [cite: 7]

  @override
  String get rendererLabel => 'Style'; [cite: 7]

  @override
  String get rendererImageTextWithButtons4Name =>
      'Image+Text+Bottom Text Buttons'; [cite: 7]

  @override
  String get rendererCoverInfoName => 'Cover Info+Auto Wrap'; [cite: 7]

  @override
  String get rendererImageTextWithRightTextButtonName =>
      'Image+Text+Right Text Button'; [cite: 7, 8]

  @override
  String get islandIcon => 'Island icon'; [cite: 8]

  @override
  String get islandIconLabel => 'Large island icon'; [cite: 8]

  @override
  String get islandIconLabelSubtitle =>
      'Show the large icon of the island when enabled (small island not affected)'; [cite: 8]

  @override
  String get focusIconLabel => 'Focus icon'; [cite: 8]

  @override
  String get focusNotificationLabel => 'Focus notification'; [cite: 8]

  @override
  String get preserveStatusBarSmallIconLabel => 'Status bar icon'; [cite: 8]

  @override
  String get restoreLockscreenTitle => 'Restore Lockscreen Notification'; [cite: 10]

  @override
  String get restoreLockscreenSubtitle =>
      'Skip focus notification processing on lockscreen, keep original privacy behavior'; [cite: 10]

  @override
  String get firstFloatLabel => 'First float'; [cite: 8]

  @override
  String get updateFloatLabel => 'Update float'; [cite: 8]

  @override
  String get autoDisappear => 'Auto dismiss'; [cite: 8]

  @override
  String get seconds => 's'; [cite: 8]

  @override
  String get onlyEnabledChannels => 'Only apply to enabled channels'; [cite: 8]

  @override
  String enabledChannelsCount(int enabled, int total) {
    return '$enabled / $total channels enabled'; [cite: 8]
  }

  @override
  String get iconModeAuto => 'Auto'; [cite: 8]

  @override
  String get iconModeNotifSmall => 'Small notification icon'; [cite: 8]

  @override
  String get iconModeNotifLarge => 'Large notification icon'; [cite: 8]

  @override
  String get iconModeAppIcon => 'App icon'; [cite: 8]

  @override
  String get optDefault => 'Default'; [cite: 8]

  @override
  String get optDefaultOn => 'Default (On)'; [cite: 8]

  @override
  String get optDefaultOff => 'Default (Off)'; [cite: 8]

  @override
  String get optOn => 'On'; [cite: 8]

  @override
  String get optOff => 'Off'; [cite: 8]

  @override
  String get errorInvalidFormat => 'Invalid configuration format'; [cite: 8]

  @override
  String get errorNoStorageDir => 'Cannot get storage directory'; [cite: 8]

  @override
  String get errorNoFileSelected => 'No file selected'; [cite: 8]

  @override
  String get errorNoFilePath => 'Cannot get file path'; [cite: 8]

  @override
  String get errorEmptyClipboard => 'Clipboard is empty'; [cite: 8]

  @override
  String get navBlacklist => 'Focus Blacklist'; [cite: 8]

  @override
  String get navBlacklistSubtitle =>
      'Block focus notification float or hide for specific apps'; [cite: 9]

  @override
  String get presetGamesTitle => 'Quick Filter Popular Games'; [cite: 9]

  @override
  String presetGamesSuccess(int count) {
    return 'Added $count installed games to blacklist from preset'; [cite: 9]
  }

  @override
  String blacklistedAppsCount(int count) {
    return 'Blocked focus notifications for $count apps'; [cite: 9]
  }

  @override
  String blacklistedAppsCountWithSystem(int count) {
    return 'Blocked focus notifications for $count apps (including system apps)'; [cite: 9]
  }

  @override
  String get firstFloatLabelSubtitle =>
      'Whether to expand as focus notification when Island receives notification for the first time'; [cite: 9]

  @override
  String get updateFloatLabelSubtitle =>
      'Whether to expand notification when Island updates'; [cite: 9]

  @override
  String get marqueeChannelTitleSubtitle =>
      'Whether to scroll long messages on Island'; [cite: 9]

  @override
  String get focusNotificationLabelSubtitle =>
      'Replace notification with focus notification (shows original notification when disabled)'; [cite: 9]

  @override
  String get preserveStatusBarSmallIconLabelSubtitle =>
      'Whether to force keep status bar icon when focus notification is displayed'; [cite: 8]

  @override
  String get aiConfigSection => 'AI Enhancement'; [cite: 9]

  @override
  String get aiConfigTitle => 'AI Notification Summary'; [cite: 9]

  @override
  String get aiConfigSubtitleEnabled =>
      'Enabled · Tap to configure AI parameters'; [cite: 9]

  @override
  String get aiConfigSubtitleDisabled => 'Disabled · Tap to configure'; [cite: 9]

  @override
  String get aiEnabledTitle => 'Enable AI Summary'; [cite: 9]

  @override
  String get aiEnabledSubtitle =>
      'AI generates Island left/right text, falls back on timeout or error'; [cite: 9]

  @override
  String get aiApiSection => 'API Parameters'; [cite: 10]

  @override
  String get aiUrlLabel => 'API URL'; [cite: 10]

  @override
  String get aiUrlHint => 'https://api.openai.com/v1/chat/completions'; [cite: 10]

  @override
  String get aiApiKeyLabel => 'API Key'; [cite: 10]

  @override
  String get aiApiKeyHint => 'sk-...'; [cite: 10]

  @override
  String get aiModelLabel => 'Model'; [cite: 10]

  @override
  String get aiModelHint => 'gpt-4o-mini'; [cite: 10]

  @override
  String get aiPromptLabel => 'Custom Prompt'; [cite: 10]

  @override
  String get aiPromptHint =>
      'Leave empty to use default: Extract key info, left and right each no more than 6 words or 12 characters'; [cite: 10]

  @override
  String get aiPromptInUserTitle => 'Put prompt in user message'; [cite: 10]

  @override
  String get aiPromptInUserSubtitle =>
      'Some models do not support system instructions; enable to put prompt in user message'; [cite: 10]

  @override
  String get aiTimeoutTitle => 'AI Response Timeout';

  @override
  String aiTimeoutLabel(int seconds) {
    return 'AI Response Timeout'; [cite: 10]
  }

  @override
  String get aiTemperatureTitle => 'Sampling Temperature';

  @override
  String get aiTemperatureSubtitle => 'Control the randomness of responses. 0 is precise, 1 is more creative';

  @override
  String get aiMaxTokensTitle => 'Max Tokens';

  @override
  String get aiMaxTokensSubtitle => 'Limit the maximum length of AI-generated responses';

  @override
  String get aiDefaultPromptFull =>
      'Leave empty to use default prompt: Extract key info from notification, no more than 6 words or 12 characters for left and right sides';

  @override
  String get aiTestButton => 'Test Connection'; [cite: 10]

  @override
  String get aiTestUrlEmpty => 'Please enter an API URL first'; [cite: 10]

  @override
  String get aiLastLogTitle => 'Recent AI Request Log';

  @override
  String get aiLastLogSubtitle => 'AI requests triggered by connection tests or notifications are displayed here';

  @override
  String get aiLastLogEmpty => 'No AI request logs to display yet';

  @override
  String get aiLastLogSourceLabel => 'Source';

  @override
  String get aiLastLogTimeLabel => 'Time';

  @override
  String get aiLastLogStatusLabel => 'Status';

  @override
  String get aiLastLogDurationLabel => 'Duration';

  @override
  String get aiLastLogSourceNotification => 'Notification Trigger';

  @override
  String get aiLastLogSourceSettingsTest => 'Settings Test';

  @override
  String get aiLastLogRendered => 'Rendered';

  @override
  String get aiLastLogRaw => 'Raw';

  @override
  String get aiLastLogCopy => 'Copy Log';

  @override
  String get aiLastLogCopied => 'AI request log copied';

  @override
  String get aiLastLogRequest => 'Request';

  @override
  String get aiLastLogResponse => 'Response';

  @override
  String get aiLastLogUsage => 'Token Usage';

  @override
  String get aiLastLogMessages => 'Messages';

  @override
  String get aiLastLogError => 'Error';

  @override
  String get aiLastLogHttpCode => 'HTTP Status';

  @override
  String get aiLastLogLeftText => 'Left Text';

  @override
  String get aiLastLogRightText => 'Right Text';

  @override
  String get aiLastLogAssistantContent => 'Model Response Content';

  @override
  String get aiConfigSaveButton => 'Save'; [cite: 10]

  @override
  String get aiConfigSaved => 'AI configuration saved'; [cite: 10]

  @override
  String get aiConfigTips =>
      'AI receives the app package, title, and content of each notification, and returns short left (source) and right (content) text. Compatible with OpenAI-format APIs (e.g. DeepSeek, Claude). Falls back to default logic if no response.'; [cite: 10]

  @override
  String get templateAiNotificationIslandName => 'AI Notification Island'; [cite: 10]

  @override
  String get hideDesktopIconTitle => 'Hide Desktop Icon'; [cite: 10]

  @override
  String get hideDesktopIconSubtitle =>
      'Hide the app icon from launcher. Open via LSPosed Manager after hiding'; [cite: 10]
}
