// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get uygulamaBasligi => 'Teacher Assistant';

  @override
  String get hosgeldin => 'Welcome Teacher 👋';

  @override
  String get ozet => 'Dashboard';

  @override
  String get siniflar => 'Classes';

  @override
  String get program => 'Schedule';

  @override
  String get menu => 'Menu';

  @override
  String get bugunDersProgramiBos => 'Today\'s Schedule\nLooks Empty';

  @override
  String get sinifEkle => 'Add Class';

  @override
  String get sinifAdi => 'Class Name (e.g. 9-A)';

  @override
  String get aciklama => 'Description (Optional)';

  @override
  String get kaydet => 'Save';

  @override
  String get iptal => 'Cancel';

  @override
  String get sinifMevcutDegil => 'No classes added yet.';

  @override
  String get sinifSil => 'Delete Class';

  @override
  String get sinifSilOnay =>
      'Are you sure you want to delete this class? (Students will also be deleted)';

  @override
  String get ogrenciEkle => 'Add Student';

  @override
  String get ad => 'Name';

  @override
  String get soyad => 'Surname';

  @override
  String get numara => 'Number';

  @override
  String get cinsiyet => 'Gender';

  @override
  String get erkek => 'Male';

  @override
  String get kiz => 'Female';

  @override
  String get fotografSec => 'Select Photo';

  @override
  String get ogrenciMevcutDegil => 'No students in this class yet.';

  @override
  String get ogrenciSil => 'Delete Student';

  @override
  String get ogrenciSilOnay => 'Are you sure you want to delete this student?';
}
