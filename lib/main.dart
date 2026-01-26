import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ogretmenim/ozellikler/giris/ana_sayfa.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart'; // EKLENDİ: Tarih formatı için gerekli

import 'package:ogretmenim/gen_l10n/app_localizations.dart';

// TEMA VE AYARLAR
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
// Eğer ProgramAyarlari dosyan 'cekirdek/yoneticiler/' altındaysa bu doğru,
// ama 'ozellikler/profil/' altındaysa yolu kontrol etmelisin.
// Standart yapıya göre genelde: ozellikler/profil/program_ayarlari.dart olur.
// Hata alırsan import yolunu düzeltiriz.
import 'package:ogretmenim/cekirdek/yoneticiler/program_ayarlari.dart';
// SAYFALAR
import 'package:ogretmenim/ozellikler/giris/giris_ekrani.dart';
import 'package:ogretmenim/ozellikler/profil/profil_ayarlari.dart';
import 'package:ogretmenim/modeller/profil_kontrol.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows/Linux/MacOS için veritabanı ayarı
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Firebase.initializeApp();

  // --- KRİTİK EKLEME: TARİH FORMATI BAŞLATMA ---
  // Bu satır olmazsa Takvim/Program sayfası "tr_TR" verisini bulamaz ve çöker.
  await initializeDateFormatting('tr_TR', null);

  // --- AYARLARI YÜKLE ---
  await ProjeTemasi.temayiYukle();
  await ProgramAyarlari.ayarlariYukle();

  runApp(const ProviderScope(child: OgretmenimUygulamasi()));
}

class OgretmenimUygulamasi extends StatelessWidget {
  const OgretmenimUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Öğretmen Asistanı",

      // Tema Ayarları
      theme: ProjeTemasi.tema,

      // Dil Ayarları
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr', ''), // Varsayılan Türkçe
      // --- OTURUM KONTROLÜ ---
      home: const OturumKapisi(),
    );
  }
}

class OturumKapisi extends StatelessWidget {
  const OturumKapisi({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Bağlantı bekleniyor
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Kullanıcı Giriş Yapmış mı?
        if (snapshot.hasData) {
          // Evet: Profil eksik mi kontrol et
          return FutureBuilder<bool>(
            future: profilEksikMi(snapshot.data!.uid),
            builder: (context, profilSnapshot) {
              if (profilSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (profilSnapshot.hasError) {
                return const AnaSayfa(); // Hata varsa ana sayfaya devam et
              }
              if (profilSnapshot.data == true) {
                // Eksik profil: Profil ayarlarına yönlendir
                return const ProfilAyarlariSayfasi();
              }
              // Profil tamam: Ana sayfa
              return const AnaSayfa();
            },
          );
        }

        // 3. Hayır: Giriş Ekranına git
        return const GirisEkrani();
      },
    );
  }
}
