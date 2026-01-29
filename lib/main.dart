import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

// YERELLEŞTİRME
import 'package:ogretmenim/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// TEMA VE AYARLAR
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/cekirdek/yoneticiler/program_ayarlari.dart';

// MODELLER VE VERİ YÖNETİMİ
import 'package:ogretmenim/modeller/profil_kontrol.dart';
import 'package:ogretmenim/veri/depolar/excel_yukleyici.dart'; // <-- YENİ EKLENDİ

// SAYFALAR
import 'package:ogretmenim/ozellikler/giris/ana_sayfa.dart';
import 'package:ogretmenim/ozellikler/giris/giris_ekrani.dart';
import 'package:ogretmenim/ozellikler/profil/profil_ayarlari.dart';
import 'package:ogretmenim/ozellikler/yonetim/admin_paneli_sayfasi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows/Linux/MacOS için veritabanı ayarı
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Firebase.initializeApp();

  // Tarih formatı başlatma (Takvim için şart)
  await initializeDateFormatting('tr_TR', null);

  // Ayarları Yükle
  await ProjeTemasi.temayiYukle();
  await ProgramAyarlari.ayarlariYukle();

  // --- EXCEL VERİLERİNİ YÜKLE (YENİ) ---
  // Uygulama açılırken veritabanını kontrol et, boşsa Excel'den doldur.
  print("🚀 Uygulama Başlatılıyor: Excel kontrol ediliyor...");
  await ExcelYukleyici.planlariYukle();
  print("✅ Excel işlemi tamamlandı.");
  // -------------------------------------

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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
        // 1. Bağlantı Bekleniyor
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Kullanıcı Giriş Yapmış mı?
        if (snapshot.hasData && snapshot.data != null) {
          final User user = snapshot.data!;

          // --- A) ADMIN KONTROLÜ ---
          // Admin mail adresin
          const String adminMail = "nflx.tr.avs1@gmail.com";

          if (user.email == adminMail) {
            print("👑 Admin Girişi: ${user.email}");
            return const AdminPaneliSayfasi();
          }

          // --- B) ÖĞRETMEN PROFİL KONTROLÜ ---
          // Eğer admin değilse, profil bilgilerini kontrol et
          print("👤 Standart Kullanıcı Girişi: ${user.email}");

          return FutureBuilder<bool>(
            future: profilEksikMi(user.uid),
            builder: (context, profilSnapshot) {
              // Profil kontrolü sürerken yükleniyor göster
              if (profilSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Hata olursa güvenli liman -> Ana Sayfa
              if (profilSnapshot.hasError) {
                print(
                  "Hata oluştu, ana sayfaya geçiliyor: ${profilSnapshot.error}",
                );
                return const AnaSayfa();
              }

              // Profil EKSİK ise -> Ayarlar Sayfası
              if (profilSnapshot.data == true) {
                print("⚠️ Profil Eksik -> Yönlendirme: Profil Ayarları");
                return const ProfilAyarlariSayfasi();
              }

              // Profil TAMAM ise -> Ana Sayfa
              print("✅ Profil Tamam -> Yönlendirme: Ana Sayfa");
              return const AnaSayfa();
            },
          );
        }

        // 3. Giriş Yapmamış: Giriş Ekranı
        return const GirisEkrani();
      },
    );
  }
}
