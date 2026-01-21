import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- MERKEZİ TEMA YÖNETİMİ ---
class ProjeTemasi {
  static bool get kadinKullaniciMi {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return false; // Test için manuel değiştirilebilir
  }

  static List<Color> get gradyanRenkleri => kadinKullaniciMi
      ? [const Color(0xFFFFF1F6), const Color(0xFFFCE4EC)]
      : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)];

  static Color get anaRenk =>
      kadinKullaniciMi ? const Color(0xFFD81B60) : const Color(0xFF3949AB);

  static Color get arkaPlan => Colors.white;
}

// --- EVRENSEL SAYFA ŞABLONU ---
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
            // 1. ÜST GRADIENT PANEL (Daha Kompakt)
            Container(
              width: double.infinity,
              height: 150, // 180'den 150'ye düşürülerek boşluk azaltıldı
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
                  padding: const EdgeInsets.only(
                    top: 10,
                  ), // İçeriği SafeArea içinde biraz aşağı aldık
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
                                      fontSize:
                                          20, // Font biraz küçültülerek modernleşti
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

            // 2. ÜSTE BİNEN İÇERİK (Daha Yukarıda)
            Transform.translate(
              offset: const Offset(
                0,
                -45,
              ), // -35'ten -45'e çekilerek boşluk yok edildi
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
