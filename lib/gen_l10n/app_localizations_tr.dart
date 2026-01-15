// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get uygulamaBasligi => 'Öğretmenim Asistanı';

  @override
  String get hosgeldin => 'Hoş Geldiniz Hocam 👋';

  @override
  String get ozet => 'Özet';

  @override
  String get siniflar => 'Sınıflar';

  @override
  String get program => 'Program';

  @override
  String get menu => 'Menü';

  @override
  String get bugunDersProgramiBos => 'Bugün Ders Programı\nBoş Görünüyor';

  @override
  String get sinifEkle => 'Sınıf Ekle';

  @override
  String get sinifAdi => 'Sınıf Adı (Örn: 9-A)';

  @override
  String get aciklama => 'Açıklama (Opsiyonel)';

  @override
  String get kaydet => 'Kaydet';

  @override
  String get iptal => 'İptal';

  @override
  String get sinifMevcutDegil => 'Henüz sınıf eklemediniz.';

  @override
  String get sinifSil => 'Sınıfı Sil';

  @override
  String get sinifSilOnay =>
      'Bu sınıfı silmek istediğinize emin misiniz? (Öğrenciler de silinecektir)';

  @override
  String get ogrenciEkle => 'Öğrenci Ekle';

  @override
  String get ad => 'Ad';

  @override
  String get soyad => 'Soyad';

  @override
  String get numara => 'Numara';

  @override
  String get cinsiyet => 'Cinsiyet';

  @override
  String get erkek => 'Erkek';

  @override
  String get kiz => 'Kız';

  @override
  String get fotografSec => 'Fotoğraf Seç';

  @override
  String get ogrenciMevcutDegil => 'Bu sınıfta henüz öğrenci yok.';

  @override
  String get ogrenciSil => 'Öğrenciyi Sil';

  @override
  String get ogrenciSilOnay => 'Bu öğrenciyi silmek istediğinize emin misiniz?';
}
