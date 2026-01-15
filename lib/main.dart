import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

// 👇 DİL DESTEĞİ İÇİN GEREKLİ KÜTÜPHANELER
import 'package:ogretmenim/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:ogretmenim/ozellikler/giris/ana_sayfa.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  runApp(const ProviderScope(child: OgretmenimUygulamasi()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [GoRoute(path: '/', builder: (context, state) => const AnaSayfa())],
);

class OgretmenimUygulamasi extends StatelessWidget {
  const OgretmenimUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    // 👇 ARADIĞIN KISIM BURASI
    return MaterialApp.router(
      title: 'Öğretmenim Asistanı',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: GoogleFonts.roboto().fontFamily,
      ),

      // 👇 EKLEMEN GEREKEN DİL AYARLARI BURADA
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'), // Türkçe
        Locale('en'), // İngilizce
      ],
      locale: const Locale('tr'), // Uygulama Türkçe açılsın
    );
  }
}
