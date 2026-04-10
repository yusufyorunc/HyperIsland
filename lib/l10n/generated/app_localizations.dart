import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('tr'),
    Locale('zh'),
  ];

  /// No description provided for @navHome.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get navHome;

  /// No description provided for @navApps.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamalar'**
  String get navApps;

  /// No description provided for @navSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get navSettings;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get confirm;

  /// No description provided for @ok.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// No description provided for @apply.
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get apply;

  /// No description provided for @noChange.
  ///
  /// In tr, this message translates to:
  /// **'Değiştirme'**
  String get noChange;

  /// No description provided for @newVersionFound.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Sürüm Bulundu'**
  String get newVersionFound;

  /// No description provided for @currentVersion.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut sürüm: {version}'**
  String currentVersion(String version);

  /// No description provided for @latestVersion.
  ///
  /// In tr, this message translates to:
  /// **'En son sürüm: {version}'**
  String latestVersion(String version);

  /// No description provided for @lsposedApiVersion.
  ///
  /// In tr, this message translates to:
  /// **'LSPosed API Sürümü: {version}'**
  String lsposedApiVersion(int version);

  /// No description provided for @later.
  ///
  /// In tr, this message translates to:
  /// **'Daha Sonra'**
  String get later;

  /// No description provided for @goUpdate.
  ///
  /// In tr, this message translates to:
  /// **'Güncelle'**
  String get goUpdate;

  /// No description provided for @sponsorSupport.
  ///
  /// In tr, this message translates to:
  /// **'Geliştiriciyi Destekle'**
  String get sponsorSupport;

  /// No description provided for @sponsorAuthor.
  ///
  /// In tr, this message translates to:
  /// **'Sponsor Ol'**
  String get sponsorAuthor;

  /// No description provided for @restartScope.
  ///
  /// In tr, this message translates to:
  /// **'Etki Alanını Yeniden Başlat'**
  String get restartScope;

  /// No description provided for @systemUI.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Arayüzü'**
  String get systemUI;

  /// No description provided for @downloadManager.
  ///
  /// In tr, this message translates to:
  /// **'İndirme Yöneticisi'**
  String get downloadManager;

  /// No description provided for @xmsf.
  ///
  /// In tr, this message translates to:
  /// **'XMSF (Xiaomi Hizmet Çerçevesi)'**
  String get xmsf;

  /// No description provided for @notificationTest.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Testi'**
  String get notificationTest;

  /// No description provided for @sendTestNotification.
  ///
  /// In tr, this message translates to:
  /// **'Test Bildirimi Gönder'**
  String get sendTestNotification;

  /// No description provided for @notes.
  ///
  /// In tr, this message translates to:
  /// **'Notlar'**
  String get notes;

  /// No description provided for @detectingModuleStatus.
  ///
  /// In tr, this message translates to:
  /// **'Modül durumu algılanıyor...'**
  String get detectingModuleStatus;

  /// No description provided for @moduleStatus.
  ///
  /// In tr, this message translates to:
  /// **'Modül Durumu'**
  String get moduleStatus;

  /// No description provided for @activated.
  ///
  /// In tr, this message translates to:
  /// **'Etkin'**
  String get activated;

  /// No description provided for @notActivated.
  ///
  /// In tr, this message translates to:
  /// **'Etkin Değil'**
  String get notActivated;

  /// No description provided for @enableInLSPosed.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bu modülü LSPosed içinde etkinleştirin'**
  String get enableInLSPosed;

  /// No description provided for @updateLSPosedRequired.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen LSPosed sürümünü güncelleyin'**
  String get updateLSPosedRequired;

  /// No description provided for @systemNotSupported.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Desteklenmiyor'**
  String get systemNotSupported;

  /// No description provided for @systemNotSupportedSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut sistem Dynamic Island özelliğini desteklemiyor (protokol sürümü {version}, gereken sürüm: 3)'**
  String systemNotSupportedSubtitle(int version);

  /// No description provided for @restartFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden başlatma başarısız: {message}'**
  String restartFailed(String message);

  /// No description provided for @restartRootRequired.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bu uygulamaya root izni verildiğini doğrulayın'**
  String get restartRootRequired;

  /// No description provided for @note1.
  ///
  /// In tr, this message translates to:
  /// **'1. Bu sayfa yalnızca Dynamic Island desteğini test etmek içindir; gerçek görünümü yansıtmaz.'**
  String get note1;

  /// No description provided for @note2.
  ///
  /// In tr, this message translates to:
  /// **'2. HyperCeiler\'da Sistem Arayüzü ve XMSF için odak bildirimi beyaz listesini kapatın.'**
  String get note2;

  /// No description provided for @note3.
  ///
  /// In tr, this message translates to:
  /// **'3. LSPosed Manager\'da etkinleştirdikten sonra ilgili etki alanındaki uygulamaları yeniden başlatmanız gerekir.'**
  String get note3;

  /// No description provided for @note4.
  ///
  /// In tr, this message translates to:
  /// **'4. Genel uyarlama desteklenir; uygun şablonu seçip deneyin.'**
  String get note4;

  /// No description provided for @behaviorSection.
  ///
  /// In tr, this message translates to:
  /// **'Davranış'**
  String get behaviorSection;

  /// No description provided for @defaultConfigSection.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Kanal Ayarları'**
  String get defaultConfigSection;

  /// No description provided for @appearanceSection.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get appearanceSection;

  /// No description provided for @configSection.
  ///
  /// In tr, this message translates to:
  /// **'Yapılandırma'**
  String get configSection;

  /// No description provided for @aboutSection.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get aboutSection;

  /// No description provided for @keepFocusNotifTitle.
  ///
  /// In tr, this message translates to:
  /// **'İndirme Duraklatılsa da Odak Bildirimini Koru'**
  String get keepFocusNotifTitle;

  /// No description provided for @keepFocusNotifSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İndirmeyi sürdürmek için tıklanabilir bir bildirim gösterir; durum senkronu bozulabilir.'**
  String get keepFocusNotifSubtitle;

  /// No description provided for @unlockAllFocusTitle.
  ///
  /// In tr, this message translates to:
  /// **'Odak Bildirimi Beyaz Listesini Kaldır'**
  String get unlockAllFocusTitle;

  /// No description provided for @unlockAllFocusSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sistem yetkisi olmadan tüm uygulamaların odak bildirimi göndermesine izin verir.'**
  String get unlockAllFocusSubtitle;

  /// No description provided for @unlockFocusAuthTitle.
  ///
  /// In tr, this message translates to:
  /// **'Odak Bildirimi İmza Doğrulamasını Kaldır'**
  String get unlockFocusAuthTitle;

  /// No description provided for @unlockFocusAuthSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İmza doğrulamasını atlayarak tüm uygulamaların saat/bilekliğe odak bildirimi göndermesine izin verir (XMSF hook gerekir).'**
  String get unlockFocusAuthSubtitle;

  /// No description provided for @checkUpdateOnLaunchTitle.
  ///
  /// In tr, this message translates to:
  /// **'Açılışta Güncellemeleri Denetle'**
  String get checkUpdateOnLaunchTitle;

  /// No description provided for @checkUpdateOnLaunchSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama açılırken yeni sürümleri otomatik denetler.'**
  String get checkUpdateOnLaunchSubtitle;

  /// No description provided for @showWelcomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Açılışta karşılama mesajını göster'**
  String get showWelcomeTitle;

  /// No description provided for @showWelcomeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama başladığında Ada üzerinde karşılama bilgisini göster'**
  String get showWelcomeSubtitle;

  /// No description provided for @checkUpdate.
  ///
  /// In tr, this message translates to:
  /// **'Güncellemeleri Denetle'**
  String get checkUpdate;

  /// No description provided for @alreadyLatest.
  ///
  /// In tr, this message translates to:
  /// **'Zaten en güncel sürümdesiniz'**
  String get alreadyLatest;

  /// No description provided for @useAppIconTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama simgesini kullan'**
  String get useAppIconTitle;

  /// No description provided for @useAppIconSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İndirme yöneticisi bildirimleri için uygulama simgesini kullan'**
  String get useAppIconSubtitle;

  /// No description provided for @roundIconTitle.
  ///
  /// In tr, this message translates to:
  /// **'Simge Köşelerini Yuvarla'**
  String get roundIconTitle;

  /// No description provided for @roundIconSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim simgelerine yuvarlatılmış köşe uygular.'**
  String get roundIconSubtitle;

  /// No description provided for @marqueeChannelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ada Metnini Kaydır'**
  String get marqueeChannelTitle;

  /// No description provided for @marqueeSpeedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaydırma Hızı'**
  String get marqueeSpeedTitle;

  /// No description provided for @marqueeSpeedLabel.
  ///
  /// In tr, this message translates to:
  /// **'{speed} px/sn'**
  String marqueeSpeedLabel(int speed);

  /// No description provided for @themeModeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get themeModeTitle;

  /// No description provided for @themeModeSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistemi Takip Et'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get themeModeDark;

  /// No description provided for @themeSeedColorTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tema rengi'**
  String get themeSeedColorTitle;

  /// No description provided for @themeSeedColorSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Seçili ön ayar'**
  String get themeSeedColorSubtitle;

  /// No description provided for @pureBlackThemeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Saf siyah koyu tema'**
  String get pureBlackThemeTitle;

  /// No description provided for @pureBlackThemeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Koyu moddayken gerçek siyah yüzeyler kullan'**
  String get pureBlackThemeSubtitle;

  /// No description provided for @languageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get languageTitle;

  /// No description provided for @languageAuto.
  ///
  /// In tr, this message translates to:
  /// **'Sistemi Takip Et'**
  String get languageAuto;

  /// No description provided for @languageZh.
  ///
  /// In tr, this message translates to:
  /// **'中文'**
  String get languageZh;

  /// No description provided for @languageEn.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageJa.
  ///
  /// In tr, this message translates to:
  /// **'日本語'**
  String get languageJa;

  /// No description provided for @languageTr.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get languageTr;

  /// No description provided for @exportToFile.
  ///
  /// In tr, this message translates to:
  /// **'Dosyaya Dışa Aktar'**
  String get exportToFile;

  /// No description provided for @exportToFileSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yapılandırmayı JSON dosyası olarak kaydeder.'**
  String get exportToFileSubtitle;

  /// No description provided for @exportToClipboard.
  ///
  /// In tr, this message translates to:
  /// **'Panoya Dışa Aktar'**
  String get exportToClipboard;

  /// No description provided for @exportToClipboardSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yapılandırmayı JSON metni olarak panoya kopyalar.'**
  String get exportToClipboardSubtitle;

  /// No description provided for @importFromFile.
  ///
  /// In tr, this message translates to:
  /// **'Dosyadan İçe Aktar'**
  String get importFromFile;

  /// No description provided for @importFromFileSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yapılandırmayı JSON dosyasından geri yükler.'**
  String get importFromFileSubtitle;

  /// No description provided for @importFromClipboard.
  ///
  /// In tr, this message translates to:
  /// **'Panodan İçe Aktar'**
  String get importFromClipboard;

  /// No description provided for @importFromClipboardSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Panodaki JSON metninden yapılandırmayı geri yükler.'**
  String get importFromClipboardSubtitle;

  /// No description provided for @exportConfig.
  ///
  /// In tr, this message translates to:
  /// **'Yapılandırmayı Dışa Aktar'**
  String get exportConfig;

  /// No description provided for @exportConfigSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Dosyaya veya panoya dışa aktarma yöntemini seçin'**
  String get exportConfigSubtitle;

  /// No description provided for @importConfig.
  ///
  /// In tr, this message translates to:
  /// **'Yapılandırmayı İçe Aktar'**
  String get importConfig;

  /// No description provided for @importConfigSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Dosyadan veya panodan içe aktarma yöntemini seçin'**
  String get importConfigSubtitle;

  /// No description provided for @qqGroup.
  ///
  /// In tr, this message translates to:
  /// **'QQ Topluluk Grubu'**
  String get qqGroup;

  /// No description provided for @restartScopeApp.
  ///
  /// In tr, this message translates to:
  /// **'Ayarların geçerli olması için etki alanındaki uygulamayı yeniden başlatın'**
  String get restartScopeApp;

  /// No description provided for @groupNumberCopied.
  ///
  /// In tr, this message translates to:
  /// **'Grup numarası panoya kopyalandı'**
  String get groupNumberCopied;

  /// No description provided for @exportedTo.
  ///
  /// In tr, this message translates to:
  /// **'Dışa aktarıldı: {path}'**
  String exportedTo(String path);

  /// No description provided for @exportFailed.
  ///
  /// In tr, this message translates to:
  /// **'Dışa aktarma başarısız: {error}'**
  String exportFailed(String error);

  /// No description provided for @configCopied.
  ///
  /// In tr, this message translates to:
  /// **'Yapılandırma panoya kopyalandı'**
  String get configCopied;

  /// No description provided for @importSuccess.
  ///
  /// In tr, this message translates to:
  /// **'İçe aktarma başarılı, toplam {count} öğe yüklendi. Lütfen uygulamayı yeniden başlatın.'**
  String importSuccess(int count);

  /// No description provided for @importFailed.
  ///
  /// In tr, this message translates to:
  /// **'İçe aktarma başarısız: {error}'**
  String importFailed(String error);

  /// No description provided for @appAdaptation.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Listesi'**
  String get appAdaptation;

  /// No description provided for @selectedAppsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} uygulama seçildi'**
  String selectedAppsCount(int count);

  /// No description provided for @cancelSelection.
  ///
  /// In tr, this message translates to:
  /// **'Seçimi İptal Et'**
  String get cancelSelection;

  /// No description provided for @deselectAll.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Seçimi Kaldır'**
  String get deselectAll;

  /// No description provided for @selectAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Seç'**
  String get selectAll;

  /// No description provided for @batchChannelSettings.
  ///
  /// In tr, this message translates to:
  /// **'Toplu Kanal Ayarı'**
  String get batchChannelSettings;

  /// No description provided for @selectEnabledApps.
  ///
  /// In tr, this message translates to:
  /// **'Etkin Uygulamaları Seç'**
  String get selectEnabledApps;

  /// No description provided for @batchEnable.
  ///
  /// In tr, this message translates to:
  /// **'Toplu Etkinleştir'**
  String get batchEnable;

  /// No description provided for @batchDisable.
  ///
  /// In tr, this message translates to:
  /// **'Toplu Devre Dışı Bırak'**
  String get batchDisable;

  /// No description provided for @multiSelect.
  ///
  /// In tr, this message translates to:
  /// **'Çoklu Seçim'**
  String get multiSelect;

  /// No description provided for @showSystemApps.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Uygulamaları'**
  String get showSystemApps;

  /// No description provided for @refreshList.
  ///
  /// In tr, this message translates to:
  /// **'Listeyi Yenile'**
  String get refreshList;

  /// No description provided for @enableAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Etkinleştir'**
  String get enableAll;

  /// No description provided for @disableAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Devre Dışı Bırak'**
  String get disableAll;

  /// No description provided for @enabledAppsCount.
  ///
  /// In tr, this message translates to:
  /// **'Dynamic Island, {count} uygulama için etkin'**
  String enabledAppsCount(int count);

  /// No description provided for @enabledAppsCountWithSystem.
  ///
  /// In tr, this message translates to:
  /// **'Dynamic Island, {count} uygulama için etkin (sistem uygulamaları dahil)'**
  String enabledAppsCountWithSystem(int count);

  /// No description provided for @searchApps.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama adında veya paket adında ara'**
  String get searchApps;

  /// No description provided for @noAppsFound.
  ///
  /// In tr, this message translates to:
  /// **'Yüklü uygulama bulunamadı\nUygulama listesi izninin açık olduğunu kontrol edin'**
  String get noAppsFound;

  /// No description provided for @noMatchingApps.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşen uygulama bulunamadı'**
  String get noMatchingApps;

  /// No description provided for @applyToSelectedAppsChannels.
  ///
  /// In tr, this message translates to:
  /// **'Seçili {count} uygulamanın etkin kanallarına uygulanacak'**
  String applyToSelectedAppsChannels(int count);

  /// No description provided for @applyingConfig.
  ///
  /// In tr, this message translates to:
  /// **'Yapılandırma uygulanıyor...'**
  String get applyingConfig;

  /// No description provided for @progressApps.
  ///
  /// In tr, this message translates to:
  /// **'{done} / {total} uygulama'**
  String progressApps(int done, int total);

  /// No description provided for @batchApplied.
  ///
  /// In tr, this message translates to:
  /// **'Toplu ayar {count} uygulamaya uygulandı'**
  String batchApplied(int count);

  /// No description provided for @cannotReadChannels.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Kanalları Okunamıyor'**
  String get cannotReadChannels;

  /// No description provided for @rootRequiredMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim kanallarını okumak için root izni gerekir.\nLütfen bu uygulamaya root izni verdiğinizi doğrulayıp tekrar deneyin.'**
  String get rootRequiredMessage;

  /// No description provided for @enableAllChannels.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Kanalları Etkinleştir'**
  String get enableAllChannels;

  /// No description provided for @noChannelsFound.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim kanalı bulunamadı'**
  String get noChannelsFound;

  /// No description provided for @noChannelsFoundSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu uygulama henüz bildirim kanalı oluşturmamış olabilir veya kanallar okunamıyor.'**
  String get noChannelsFoundSubtitle;

  /// No description provided for @allChannelsActive.
  ///
  /// In tr, this message translates to:
  /// **'Tüm {count} kanal için geçerli'**
  String allChannelsActive(int count);

  /// No description provided for @selectedChannels.
  ///
  /// In tr, this message translates to:
  /// **'{selected} / {total} kanal seçildi'**
  String selectedChannels(int selected, int total);

  /// No description provided for @allChannelsDisabled.
  ///
  /// In tr, this message translates to:
  /// **'Tüm {count} kanal (devre dışı)'**
  String allChannelsDisabled(int count);

  /// No description provided for @appDisabledBanner.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama devre dışı; aşağıdaki kanal ayarları etkisizdir'**
  String get appDisabledBanner;

  /// No description provided for @channelImportance.
  ///
  /// In tr, this message translates to:
  /// **'Önem: {importance}  ·  {id}'**
  String channelImportance(String importance, String id);

  /// No description provided for @channelSettings.
  ///
  /// In tr, this message translates to:
  /// **'Kanal Ayarları'**
  String get channelSettings;

  /// No description provided for @importanceNone.
  ///
  /// In tr, this message translates to:
  /// **'Yok'**
  String get importanceNone;

  /// No description provided for @importanceMin.
  ///
  /// In tr, this message translates to:
  /// **'En Düşük'**
  String get importanceMin;

  /// No description provided for @importanceLow.
  ///
  /// In tr, this message translates to:
  /// **'Düşük'**
  String get importanceLow;

  /// No description provided for @importanceDefault.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan'**
  String get importanceDefault;

  /// No description provided for @importanceHigh.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek'**
  String get importanceHigh;

  /// No description provided for @importanceUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmiyor'**
  String get importanceUnknown;

  /// No description provided for @applyToEnabledChannels.
  ///
  /// In tr, this message translates to:
  /// **'Etkin olan {count} kanala uygulanacak'**
  String applyToEnabledChannels(int count);

  /// No description provided for @applyToAllChannels.
  ///
  /// In tr, this message translates to:
  /// **'Tüm {count} kanala uygulanacak'**
  String applyToAllChannels(int count);

  /// No description provided for @templateDownloadName.
  ///
  /// In tr, this message translates to:
  /// **'İndirme'**
  String get templateDownloadName;

  /// No description provided for @templateNotificationIslandName.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Süper Ada'**
  String get templateNotificationIslandName;

  /// No description provided for @templateNotificationIslandLiteName.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Süper Ada -Lite'**
  String get templateNotificationIslandLiteName;

  /// No description provided for @templateDownloadLiteName.
  ///
  /// In tr, this message translates to:
  /// **'İndirme -Lite'**
  String get templateDownloadLiteName;

  /// No description provided for @islandSection.
  ///
  /// In tr, this message translates to:
  /// **'Ada'**
  String get islandSection;

  /// No description provided for @template.
  ///
  /// In tr, this message translates to:
  /// **'Şablon'**
  String get template;

  /// No description provided for @rendererLabel.
  ///
  /// In tr, this message translates to:
  /// **'Stil'**
  String get rendererLabel;

  /// No description provided for @rendererImageTextWithButtons4Name.
  ///
  /// In tr, this message translates to:
  /// **'Görsel + Metin + Alt Butonlar'**
  String get rendererImageTextWithButtons4Name;

  /// No description provided for @rendererCoverInfoName.
  ///
  /// In tr, this message translates to:
  /// **'Kapak Bilgisi + Otomatik Kaydırma'**
  String get rendererCoverInfoName;

  /// No description provided for @rendererImageTextWithRightTextButtonName.
  ///
  /// In tr, this message translates to:
  /// **'Görsel + Metin + Sağ Buton'**
  String get rendererImageTextWithRightTextButtonName;

  /// No description provided for @islandIcon.
  ///
  /// In tr, this message translates to:
  /// **'Ada Simgesi'**
  String get islandIcon;

  /// No description provided for @focusIconLabel.
  ///
  /// In tr, this message translates to:
  /// **'Odak Simgesi'**
  String get focusIconLabel;

  /// No description provided for @focusNotificationLabel.
  ///
  /// In tr, this message translates to:
  /// **'Odak Bildirimini Kullan'**
  String get focusNotificationLabel;

  /// No description provided for @preserveStatusBarSmallIconLabel.
  ///
  /// In tr, this message translates to:
  /// **'Durum Çubuğu Bildirim Simgesini Koru'**
  String get preserveStatusBarSmallIconLabel;

  /// No description provided for @islandIconLabel.
  ///
  /// In tr, this message translates to:
  /// **'Büyük Ada Simgesini Göster'**
  String get islandIconLabel;

  /// No description provided for @islandIconLabelSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu ayar açık olduğunda büyük Ada simgesi gösterilir (küçük Ada etkilenmez).'**
  String get islandIconLabelSubtitle;

  /// No description provided for @firstFloatLabel.
  ///
  /// In tr, this message translates to:
  /// **'İlk Bildirimde Genişlet'**
  String get firstFloatLabel;

  /// No description provided for @updateFloatLabel.
  ///
  /// In tr, this message translates to:
  /// **'Güncellemede Yeniden Genişlet'**
  String get updateFloatLabel;

  /// No description provided for @autoDisappear.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik Kapanma'**
  String get autoDisappear;

  /// No description provided for @seconds.
  ///
  /// In tr, this message translates to:
  /// **'sn'**
  String get seconds;

  /// No description provided for @highlightColorLabel.
  ///
  /// In tr, this message translates to:
  /// **'Vurgu Rengi'**
  String get highlightColorLabel;

  /// No description provided for @dynamicHighlightColorLabel.
  ///
  /// In tr, this message translates to:
  /// **'Dinamik vurgu rengi'**
  String get dynamicHighlightColorLabel;

  /// No description provided for @dynamicHighlightColorLabelSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu ayar açık olduğunda, simgenin dinamik vurgu rengini kullanır.'**
  String get dynamicHighlightColorLabelSubtitle;

  /// No description provided for @dynamicHighlightModeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get dynamicHighlightModeDark;

  /// No description provided for @dynamicHighlightModeDarker.
  ///
  /// In tr, this message translates to:
  /// **'Daha koyu'**
  String get dynamicHighlightModeDarker;

  /// No description provided for @outerGlowLabel.
  ///
  /// In tr, this message translates to:
  /// **'Çerçeve parlaması'**
  String get outerGlowLabel;

  /// No description provided for @highlightColorHint.
  ///
  /// In tr, this message translates to:
  /// **'#RRGGBB formatı, varsayılan için boş bırakın'**
  String get highlightColorHint;

  /// No description provided for @textHighlightLabel.
  ///
  /// In tr, this message translates to:
  /// **'Metin vurgusu'**
  String get textHighlightLabel;

  /// No description provided for @showLeftHighlightLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sol metin vurgusu'**
  String get showLeftHighlightLabel;

  /// No description provided for @showRightHighlightLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sağ metin vurgusu'**
  String get showRightHighlightLabel;

  /// No description provided for @showLeftHighlightShort.
  ///
  /// In tr, this message translates to:
  /// **'Sol'**
  String get showLeftHighlightShort;

  /// No description provided for @showRightHighlightShort.
  ///
  /// In tr, this message translates to:
  /// **'Sağ'**
  String get showRightHighlightShort;

  /// No description provided for @colorHue.
  ///
  /// In tr, this message translates to:
  /// **'Ton'**
  String get colorHue;

  /// No description provided for @colorSaturation.
  ///
  /// In tr, this message translates to:
  /// **'Doygunluk'**
  String get colorSaturation;

  /// No description provided for @colorBrightness.
  ///
  /// In tr, this message translates to:
  /// **'Parlaklık'**
  String get colorBrightness;

  /// No description provided for @onlyEnabledChannels.
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca Etkin Kanallara Uygula'**
  String get onlyEnabledChannels;

  /// No description provided for @enabledChannelsCount.
  ///
  /// In tr, this message translates to:
  /// **'{enabled} / {total} kanal etkin'**
  String enabledChannelsCount(int enabled, int total);

  /// No description provided for @iconModeAuto.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik'**
  String get iconModeAuto;

  /// No description provided for @iconModeNotifSmall.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Küçük Simgesi'**
  String get iconModeNotifSmall;

  /// No description provided for @iconModeNotifLarge.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Büyük Simgesi'**
  String get iconModeNotifLarge;

  /// No description provided for @iconModeAppIcon.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Simgesi'**
  String get iconModeAppIcon;

  /// No description provided for @optDefault.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan'**
  String get optDefault;

  /// No description provided for @optDefaultOn.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan (Açık)'**
  String get optDefaultOn;

  /// No description provided for @optDefaultOff.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan (Kapalı)'**
  String get optDefaultOff;

  /// No description provided for @optOn.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get optOn;

  /// No description provided for @optOff.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get optOff;

  /// No description provided for @errorInvalidFormat.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz yapılandırma biçimi'**
  String get errorInvalidFormat;

  /// No description provided for @errorNoStorageDir.
  ///
  /// In tr, this message translates to:
  /// **'Depolama dizinine erişilemiyor'**
  String get errorNoStorageDir;

  /// No description provided for @errorNoFileSelected.
  ///
  /// In tr, this message translates to:
  /// **'Dosya seçilmedi'**
  String get errorNoFileSelected;

  /// No description provided for @errorNoFilePath.
  ///
  /// In tr, this message translates to:
  /// **'Dosya yolu alınamıyor'**
  String get errorNoFilePath;

  /// No description provided for @errorEmptyClipboard.
  ///
  /// In tr, this message translates to:
  /// **'Pano boş'**
  String get errorEmptyClipboard;

  /// No description provided for @navBlacklist.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Kara Listesi'**
  String get navBlacklist;

  /// No description provided for @navBlacklistSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kara listedeki bir uygulama açıldığında odak bildiriminin otomatik genişletilmesi devre dışı kalır'**
  String get navBlacklistSubtitle;

  /// No description provided for @blacklistedAppsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} uygulamanın odak bildirimi engellendi'**
  String blacklistedAppsCount(int count);

  /// No description provided for @blacklistedAppsCountWithSystem.
  ///
  /// In tr, this message translates to:
  /// **'{count} uygulamanın odak bildirimi engellendi (sistem uygulamaları dahil)'**
  String blacklistedAppsCountWithSystem(int count);

  /// No description provided for @firstFloatLabelSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu ayar açık olduğunda ilk bildirim geldiğinde Ada genişler.'**
  String get firstFloatLabelSubtitle;

  /// No description provided for @updateFloatLabelSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu ayar açık olduğunda bildirim güncellendiğinde Ada yeniden genişler.'**
  String get updateFloatLabelSubtitle;

  /// No description provided for @marqueeChannelTitleSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu ayar açık olduğunda uzun metin Ada üzerinde kayarak gösterilir.'**
  String get marqueeChannelTitleSubtitle;

  /// No description provided for @focusNotificationLabelSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu ayar açık olduğunda normal bildirim yerine odak bildirimi gösterilir. Kapalıysa normal bildirim gösterilir.'**
  String get focusNotificationLabelSubtitle;

  /// No description provided for @preserveStatusBarSmallIconLabelSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu ayar açık olduğunda odak bildirimi sırasında durum çubuğu küçük simgesi görünür kalır.'**
  String get preserveStatusBarSmallIconLabelSubtitle;

  /// No description provided for @hideDesktopIconTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ana Ekran Simgesini Gizle'**
  String get hideDesktopIconTitle;

  /// No description provided for @hideDesktopIconSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama simgesini başlatıcıdan gizler. Gizledikten sonra LSPosed Manager üzerinden açın'**
  String get hideDesktopIconSubtitle;

  /// No description provided for @restoreLockscreenTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kilit Ekranı Bildirimini Geri Yükle'**
  String get restoreLockscreenTitle;

  /// No description provided for @restoreLockscreenSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kilit ekranında odak bildirimi işlemini atlayın, özgün gizlilik davranışını koruyun'**
  String get restoreLockscreenSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'tr', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
