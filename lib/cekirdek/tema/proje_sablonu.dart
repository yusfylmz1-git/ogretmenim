import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProjeTemasi {
  // --- 1. TEK BİR DEĞİŞKEN: ERKEK Mİ? ---
  static bool erkekMi = true;

  // --- 2. HAFIZADAN OKU ---
  static Future<void> temayiYukle() async {
    final prefs = await SharedPreferences.getInstance();
    erkekMi = prefs.getBool('cinsiyet_erkek') ?? true;
  }

  // --- 3. HAFIZAYA KAYDET ---
  static Future<void> temayiDegistir(bool yeniDurumErkek) async {
    erkekMi = yeniDurumErkek;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cinsiyet_erkek', yeniDurumErkek);
  }

  // --- 4. RENKLER ---
  static List<Color> get gradyanRenkleri => erkekMi
      ? [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)] // Mavi Tonlar
      : [const Color(0xFFFFF1F6), const Color(0xFFFCE4EC)]; // Pembe Tonlar

  static Color get anaRenk =>
      erkekMi ? const Color(0xFF3949AB) : const Color(0xFFD81B60);

  static Color get arkaPlan => Colors.white;

  // --- 5. EKSİK OLAN PARÇA: TEMA VERİSİ (ThemeData) ---
  // main.dart dosyasının aradığı 'tema' budur.
  static ThemeData get tema => ThemeData(
    useMaterial3: true,
    primaryColor: anaRenk,
    scaffoldBackgroundColor: arkaPlan,
    colorScheme: ColorScheme.fromSeed(
      seedColor: anaRenk,
      primary: anaRenk,
      surface: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: anaRenk),
      titleTextStyle: TextStyle(
        color: anaRenk,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: anaRenk,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

// --- SAYFA ŞABLONU ---
class ProjeSayfaSablonu extends StatelessWidget {
  final String? baslikMetin;
  final Widget? baslikWidget;
  final List<Widget>? aksiyonlar;
  final Widget icerik;
  final Widget? altWidget;

  const ProjeSayfaSablonu({
    super.key,
    this.baslikMetin,
    this.baslikWidget,
    this.aksiyonlar,
    required this.icerik,
    this.altWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProjeTemasi.arkaPlan,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ÜST PANEL
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: ProjeTemasi.gradyanRenkleri,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child:
                                  baslikWidget ??
                                  Text(
                                    baslikMetin ?? "",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E293B),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                            ),
                            if (aksiyonlar != null) Row(children: aksiyonlar!),
                          ],
                        ),
                      ),
                      if (altWidget != null) altWidget!,
                    ],
                  ),
                ),
              ),
            ),
            // İÇERİK
            Transform.translate(
              offset: const Offset(0, -45),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 25,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: icerik,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
