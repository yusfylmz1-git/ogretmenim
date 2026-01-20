import 'package:flutter/material.dart';
import 'package:ogretmenim/gen_l10n/app_localizations.dart';
import '../profil/profil_ayarlari.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OzetSayfasi extends StatelessWidget {
  const OzetSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    final dil = AppLocalizations.of(context)!;
    final anaRenk = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // --- MODERN APPBAR (Beyaz Çerçeveli Profil) ---
          Container(
            decoration: BoxDecoration(
              color: anaRenk,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(35),
              ),
              boxShadow: [
                BoxShadow(
                  color: anaRenk.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.only(
              top: 50,
              bottom: 25,
              left: 20,
              right: 20,
            ),
            child: Row(
              children: [
                // Modern beyaz çerçeveli profil fotoğrafı
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilAyarlariSayfasi(),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'profil_avatar',
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _profilFotoBuilder(),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // Hoş geldiniz alanı
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dil.hosgeldin,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        "Uygulamanız bugün için hazır.",
                        style: TextStyle(
                          color: Color(0xFFE0E7EF),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Sağ üst bildirim ikonu
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // --- ANA İÇERİK ALANI ---
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- İŞLEM BUTONLARI ---
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 1.15,
                    children: [
                      _islemButonu(
                        context,
                        "Ders İçi Katılım",
                        Icons.how_to_reg_rounded,
                        const Color(0xFF3B82F6),
                      ),
                      _islemButonu(
                        context,
                        "Kazanımlar",
                        Icons.auto_awesome_rounded,
                        const Color(0xFF10B981),
                      ),
                      _islemButonu(
                        context,
                        "Evraklarım",
                        Icons.folder_copy_rounded,
                        const Color(0xFFFB7185),
                      ),
                      _islemButonu(
                        context,
                        "Sınav Analizi",
                        Icons.bar_chart_rounded,
                        const Color(0xFF8B5CF6),
                      ),
                      _islemButonu(
                        context,
                        "Sınav Takibi",
                        Icons.event_note_rounded,
                        const Color(0xFFF59E0B),
                      ),
                      _islemButonu(
                        context,
                        "Analiz & Rapor",
                        Icons.analytics_rounded,
                        const Color(0xFF0EA5E9),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // --- DUYURULAR VE YAKLAŞANLAR (Özet Bölümü) ---
                  const Text(
                    "Duyurular ve Yaklaşanlar",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _duyuruKarti(
                    "Yaklaşan Sınav",
                    "8-A Matematik sınavı yarın 2. saatte.",
                    Icons.notification_important_rounded,
                    Colors.orange,
                  ),
                  _duyuruKarti(
                    "Genel Duyuru",
                    "Zümre toplantısı Cuma günü saat 15:30'da.",
                    Icons.campaign_rounded,
                    const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODERN İŞLEM BUTONU ---
  Widget _islemButonu(
    BuildContext context,
    String baslik,
    IconData ikon,
    Color renk,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [renk.withOpacity(0.18), renk.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: renk.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: renk.withOpacity(0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(child: Icon(ikon, color: renk, size: 44)),
              ),
              const SizedBox(height: 12),
              Text(
                baslik,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: renk.darken(0.25),
                  letterSpacing: -0.2,
                  height: 1.13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DUYURU KARTI ---
  Widget _duyuruKarti(String baslik, String icerik, IconData ikon, Color renk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: renk.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(ikon, color: renk, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  icerik,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- PROFİL FOTOĞRAFI YARDIMCISI ---
  Widget _profilFotoBuilder() {
    final user = FirebaseAuth.instance.currentUser;
    final googlePhoto = user?.photoURL;
    final mail = user?.email;

    return CircleAvatar(
      radius: 34,
      backgroundColor: const Color(0xFFF1F5F9),
      backgroundImage: (googlePhoto != null && googlePhoto.isNotEmpty)
          ? NetworkImage(googlePhoto)
          : null,
      child: (googlePhoto == null || googlePhoto.isEmpty)
          ? Text(
              mail != null ? mail[0].toUpperCase() : "A",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            )
          : null,
    );
  }
}

// Renk koyulaştırıcı extension
extension ColorBrightness on Color {
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
