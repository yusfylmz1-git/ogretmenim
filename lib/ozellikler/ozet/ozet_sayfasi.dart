import 'package:flutter/material.dart';
import 'package:ogretmenim/gen_l10n/app_localizations.dart';
import '../profil/profil_ayarlari.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';

class OzetSayfasi extends StatelessWidget {
  const OzetSayfasi({super.key});

  // Renkleri butonlara göre koyulaştıran yardımcı fonksiyon
  Color _rengiKarart(Color color, [double miktar = 0.3]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - miktar).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final dil = AppLocalizations.of(context)!;

    return ProjeSayfaSablonu(
      // 1. ÜST KISIM: Profil ve Hoş geldin Yazısı
      baslikWidget: _profilBaslikWidget(context, dil),

      // 2. AKSİYONLAR: Bildirim İkonu (Siyah detaylı ve kontrastlı)
      aksiyonlar: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.1)),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF1E293B), // Siyaha yakın koyu renk
              size: 24,
            ),
            onPressed: () {},
          ),
        ),
      ],

      // 3. ANA İÇERİK
      icerik: ListView(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(), // Şablonun kaydırmasını kullanır
        padding: const EdgeInsets.fromLTRB(
          16,
          20,
          16,
          80,
        ), // Milimetrik hizalama için sabit
        children: [
          _islemGridi(context),
          const SizedBox(height: 35),
          _duyuruBolumu(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // --- PROFİL BAŞLIK ALANI (Tasarım Bütünlüğü İçin Sabitlendi) ---
  Widget _profilBaslikWidget(BuildContext context, AppLocalizations dil) {
    final user = FirebaseAuth.instance.currentUser;
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfilAyarlariSayfasi(),
            ),
          ),
          child: CircleAvatar(
            radius: 22, // Sabitlendi (Sınıflar sayfasıyla aynı)
            backgroundColor: Colors.white,
            backgroundImage: (user?.photoURL != null)
                ? NetworkImage(user!.photoURL!)
                : null,
            child: (user?.photoURL == null)
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dil.hosgeldin,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
            const Text(
              "Bugün nasılsınız?",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- ANA İŞLEM BUTONLARI (GRID) ---
  Widget _islemGridi(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
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
    );
  }

  Widget _islemButonu(
    BuildContext context,
    String baslik,
    IconData ikon,
    Color renk,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [renk.withOpacity(0.15), renk.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: renk.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 28,
                child: Icon(ikon, color: renk, size: 32),
              ),
              const SizedBox(height: 10),
              Text(
                baslik,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: _rengiKarart(renk, 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DUYURU BÖLÜMÜ ---
  Widget _duyuruBolumu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Duyurular ve Yaklaşanlar",
          style: TextStyle(
            fontSize: 17,
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
      ],
    );
  }

  Widget _duyuruKarti(String baslik, String icerik, IconData ikon, Color renk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
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
            child: Icon(ikon, color: renk, size: 22),
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
                    fontSize: 14,
                  ),
                ),
                Text(
                  icerik,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
