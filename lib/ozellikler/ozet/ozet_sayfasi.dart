import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ogretmenim/gen_l10n/app_localizations.dart';
import '../profil/profil_ayarlari.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/cekirdek/yoneticiler/program_ayarlari.dart';
import 'package:ogretmenim/veri/modeller/ders_model.dart';

class OzetSayfasi extends StatefulWidget {
  const OzetSayfasi({super.key});

  @override
  State<OzetSayfasi> createState() => _OzetSayfasiState();
}

class _OzetSayfasiState extends State<OzetSayfasi> {
  void _profilSayfasinaGit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilAyarlariSayfasi()),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  // --- SAAT HESAPLAMA ---
  String _dersSaatAriligiBul(int dersIndex) {
    int baslangicDk =
        ProgramAyarlari.baslangicSaati.hour * 60 +
        ProgramAyarlari.baslangicSaati.minute;
    int gecenSure =
        dersIndex *
        (ProgramAyarlari.dersSuresi + ProgramAyarlari.teneffusSuresi);

    int dersBaslama = baslangicDk + gecenSure;
    int dersBitis = dersBaslama + ProgramAyarlari.dersSuresi;

    String formatDk(int total) {
      int h = (total ~/ 60) % 24;
      int m = total % 60;
      return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
    }

    return "${formatDk(dersBaslama)} - ${formatDk(dersBitis)}";
  }

  @override
  Widget build(BuildContext context) {
    final dil = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return ProjeSayfaSablonu(
      baslikWidget: _profilBaslikWidget(context, dil),
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
              color: Color(0xFF1E293B),
              size: 24,
            ),
            onPressed: () {},
          ),
        ),
      ],
      icerik: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
        children: [
          _islemGridi(context),
          const SizedBox(height: 35),

          // --- DİNAMİK TIMELINE BÖLÜMÜ ---
          if (user != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('dersler')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                var tumDersler = snapshot.data!.docs
                    .map(
                      (doc) => DersModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList();

                // --- AKILLI GÜN SEÇİMİ ---
                // Önce bugüne bak, yoksa yarına, yoksa sonraki güne...
                // Böylece "Boş Kart" yerine en yakın dersi görürsün.
                DateTime dateKontrol = DateTime.now();
                String gosterilenGunIsmi = "";
                List<DersModel> gosterilecekDersler = [];

                // 7 gün sonrasına kadar kontrol et
                for (int i = 0; i < 7; i++) {
                  String gunIsmi = DateFormat(
                    'EEEE',
                    'tr_TR',
                  ).format(dateKontrol.add(Duration(days: i)));
                  var oGununDersleri = tumDersler
                      .where((d) => d.gun == gunIsmi)
                      .toList();

                  if (oGununDersleri.isNotEmpty) {
                    gosterilecekDersler = oGununDersleri;
                    gosterilenGunIsmi = (i == 0)
                        ? "Bugün"
                        : ((i == 1) ? "Yarın" : gunIsmi);
                    break;
                  }
                }

                // Eğer hiç ders yoksa (tüm hafta boşsa)
                if (gosterilecekDersler.isEmpty) {
                  return _bosGunMesaji();
                }

                // Saat sırasına diz
                gosterilecekDersler.sort(
                  (a, b) => a.dersSaatiIndex.compareTo(b.dersSaatiIndex),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BAŞLIK
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Akış & Duyurular",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            gosterilenGunIsmi,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: ProjeTemasi.anaRenk,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- TIMELINE LİSTESİ ---
                    ...List.generate(gosterilecekDersler.length, (index) {
                      final ders = gosterilecekDersler[index];
                      return _timelineItem(
                        baslik: ders.dersAdi,
                        icerik: "${ders.sinif} Sınıfı",
                        zaman: _dersSaatAriligiBul(ders.dersSaatiIndex),
                        renk: Color(ders.renkValue),
                        ikon: Icons.class_,
                        isLast: index == gosterilecekDersler.length - 1,
                      );
                    }),
                  ],
                );
              },
            ),

          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // --- SADE TIMELINE TASARIMI (ESKİ HALİ) ---
  Widget _timelineItem({
    required String baslik,
    required String icerik,
    required String zaman,
    required Color renk,
    required IconData ikon,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SOL SÜTUN (İkon ve Çizgi)
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: renk.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: renk.withOpacity(0.2), width: 1),
                ),
                child: Icon(ikon, size: 16, color: renk),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade200,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 15),

          // 2. SAĞ SÜTUN (İçerik)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 25.0, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Ders Adı
                      Text(
                        baslik,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      // Saat (SADE METİN - KART YOK)
                      Text(
                        zaman,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade400, // Silik gri renk
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Sınıf Bilgisi
                  Text(
                    icerik,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bosGunMesaji() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.event_busy, color: Colors.grey.shade400, size: 30),
          const SizedBox(width: 15),
          const Expanded(
            child: Text(
              "Yakın zamanda planlanmış ders bulunamadı.",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- DİĞER WIDGETLAR ---
  Widget _profilBaslikWidget(BuildContext context, AppLocalizations dil) {
    final user = FirebaseAuth.instance.currentUser;
    return Row(
      children: [
        GestureDetector(
          onTap: _profilSayfasinaGit,
          child: CircleAvatar(
            radius: 22,
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
                  color: renk.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
