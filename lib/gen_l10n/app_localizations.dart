import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
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
    Locale('tr'),
  ];

  /// No description provided for @uygulamaBasligi.
  ///
  /// In tr, this message translates to:
  /// **'Öğretmenim Asistanı'**
  String get uygulamaBasligi;

  /// No description provided for @hosgeldin.
  ///
  /// In tr, this message translates to:
  /// **'Hoş Geldiniz Hocam 👋'**
  String get hosgeldin;

  /// No description provided for @ozet.
  ///
  /// In tr, this message translates to:
  /// **'Özet'**
  String get ozet;

  /// No description provided for @siniflar.
  ///
  /// In tr, this message translates to:
  /// **'Sınıflar'**
  String get siniflar;

  /// No description provided for @program.
  ///
  /// In tr, this message translates to:
  /// **'Program'**
  String get program;

  /// No description provided for @menu.
  ///
  /// In tr, this message translates to:
  /// **'Menü'**
  String get menu;

  /// No description provided for @bugunDersProgramiBos.
  ///
  /// In tr, this message translates to:
  /// **'Bugün Ders Programı\nBoş Görünüyor'**
  String get bugunDersProgramiBos;

  /// No description provided for @sinifEkle.
  ///
  /// In tr, this message translates to:
  /// **'Sınıf Ekle'**
  String get sinifEkle;

  /// No description provided for @sinifAdi.
  ///
  /// In tr, this message translates to:
  /// **'Sınıf Adı (Örn: 9-A)'**
  String get sinifAdi;

  /// No description provided for @aciklama.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama (Opsiyonel)'**
  String get aciklama;

  /// No description provided for @kaydet.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get kaydet;

  /// No description provided for @iptal.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get iptal;

  /// No description provided for @sinifMevcutDegil.
  ///
  /// In tr, this message translates to:
  /// **'Henüz sınıf eklemediniz.'**
  String get sinifMevcutDegil;

  /// No description provided for @sinifSil.
  ///
  /// In tr, this message translates to:
  /// **'Sınıfı Sil'**
  String get sinifSil;

  /// No description provided for @sinifSilOnay.
  ///
  /// In tr, this message translates to:
  /// **'Bu sınıfı silmek istediğinize emin misiniz? (Öğrenciler de silinecektir)'**
  String get sinifSilOnay;

  /// No description provided for @ogrenciEkle.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenci Ekle'**
  String get ogrenciEkle;

  /// No description provided for @ad.
  ///
  /// In tr, this message translates to:
  /// **'Ad'**
  String get ad;

  /// No description provided for @soyad.
  ///
  /// In tr, this message translates to:
  /// **'Soyad'**
  String get soyad;

  /// No description provided for @numara.
  ///
  /// In tr, this message translates to:
  /// **'Numara'**
  String get numara;

  /// No description provided for @cinsiyet.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyet'**
  String get cinsiyet;

  /// No description provided for @erkek.
  ///
  /// In tr, this message translates to:
  /// **'Erkek'**
  String get erkek;

  /// No description provided for @kiz.
  ///
  /// In tr, this message translates to:
  /// **'Kız'**
  String get kiz;

  /// No description provided for @fotografSec.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Seç'**
  String get fotografSec;

  /// No description provided for @ogrenciMevcutDegil.
  ///
  /// In tr, this message translates to:
  /// **'Bu sınıfta henüz öğrenci yok.'**
  String get ogrenciMevcutDegil;

  /// No description provided for @ogrenciSil.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenciyi Sil'**
  String get ogrenciSil;

  /// No description provided for @ogrenciSilOnay.
  ///
  /// In tr, this message translates to:
  /// **'Bu öğrenciyi silmek istediğinize emin misiniz?'**
  String get ogrenciSilOnay;
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
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
