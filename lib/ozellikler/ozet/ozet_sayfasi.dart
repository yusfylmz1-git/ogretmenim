import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ogretmenim/gen_l10n/app_localizations.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/cekirdek/yoneticiler/program_ayarlari.dart';
import 'package:ogretmenim/veri/modeller/ders_model.dart';
import 'package:ogretmenim/ozellikler/profil/profil_ayarlari.dart';
import 'package:ogretmenim/ozellikler/ders_programi/dersler_provider.dart';
// Sayfa geçişleri ve veri için eklenen importlar:
import 'package:ogretmenim/ozellikler/ders_ici_katilim/ders_ici_katilim_sayfasi.dart';
import 'package:ogretmenim/ozellikler/siniflar/siniflar_provider.dart';
// YENİ EKLENEN IMPORT (Sınıf Ekleme Sayfasına Gitmek İçin):
import 'package:ogretmenim/ozellikler/siniflar/siniflar_sayfasi.dart';
import 'package:ogretmenim/ozellikler/kazanimlar/kazanimlar_sayfasi.dart';
import 'package:ogretmenim/ozellikler/sinav_analiz/sinav_analizi_sayfasi.dart';

class OzetSayfasi extends ConsumerStatefulWidget {
  const OzetSayfasi({super.key});

  @override
  ConsumerState<OzetSayfasi> createState() => _OzetSayfasiState();
}

class _OzetSayfasiState extends ConsumerState<OzetSayfasi> {
  // --- ÖN YÜKLEME (Lazy Loading Çözümü) ---
  @override
  void initState() {
    super.initState();
    // Sayfa açılır açılmaz SADECE sınıfları yüklüyoruz.
    Future.microtask(() {
      ref.read(siniflarProvider.notifier).siniflariYukle();
    });
  }
  // ----------------------------------------

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
        ProgramAyarlari.ilkDersSaati.hour * 60 +
        ProgramAyarlari.ilkDersSaati.minute;

    int gecenSure =
        dersIndex *
        (ProgramAyarlari.dersSuresi + ProgramAyarlari.teneffusSuresi);

    if (ProgramAyarlari.ogleArasiVarMi && dersIndex >= 4) {
      gecenSure +=
          (ProgramAyarlari.ogleArasiSuresi - ProgramAyarlari.teneffusSuresi);
    }

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

    // Dersleri Provider'dan dinle
    final tumDersler = ref.watch(derslerProvider);

    // --- AKILLI GÜN SEÇİMİ ---
    DateTime dateKontrol = DateTime.now();
    String gosterilenGunIsmi = "";
    List<DersModel> gosterilecekDersler = [];

    for (int i = 0; i < 7; i++) {
      String gunIsmi = DateFormat(
        'EEEE',
        'tr_TR',
      ).format(dateKontrol.add(Duration(days: i)));
      var oGununDersleri = tumDersler
          .where((d) => d.gun.toLowerCase() == gunIsmi.toLowerCase())
          .toList();

      if (oGununDersleri.isNotEmpty) {
        gosterilecekDersler = oGununDersleri;
        gosterilenGunIsmi = (i == 0) ? "Bugün" : ((i == 1) ? "Yarın" : gunIsmi);
        break;
      }
    }

    gosterilecekDersler.sort(
      (a, b) => a.dersSaatiIndex.compareTo(b.dersSaatiIndex),
    );

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

          // --- TIMELINE ---
          if (gosterilecekDersler.isEmpty)
            _bosGunMesaji()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                ...List.generate(gosterilecekDersler.length, (index) {
                  final ders = gosterilecekDersler[index];
                  return _timelineItem(
                    baslik: ders.dersAdi,
                    icerik: "${ders.sinif} Sınıfı",
                    zaman: _dersSaatAriligiBul(ders.dersSaatiIndex),
                    renk: ders.renk,
                    ikon: Icons.class_,
                    isLast: index == gosterilecekDersler.length - 1,
                  );
                }),
              ],
            ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // --- WIDGETLAR ---

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 25.0, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        baslik,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        zaman,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
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
          () {
            // Panel açma fonksiyonunu çağırıyoruz
            _sinifSecimPaneliniAc(context);
          },
        ),
        _islemButonu(
          context,
          "Kazanımlar",
          Icons.auto_awesome_rounded,
          const Color(0xFF10B981),
          () {
            // YÖNLENDİRME EKLENDİ
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const KazanimlarSayfasi(),
              ),
            );
          },
        ),
        _islemButonu(
          context,
          "Evraklarım",
          Icons.folder_copy_rounded,
          const Color(0xFFFB7185),
          () {},
        ),
        _islemButonu(
          context,
          "Sınav Analizi",
          Icons.bar_chart_rounded,
          const Color(0xFF8B5CF6),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SinavAnalizSayfasi(),
              ),
            );
          },
        ),
        _islemButonu(
          context,
          "Sınav Takibi",
          Icons.event_note_rounded,
          const Color(0xFFF59E0B),
          () {},
        ),
        _islemButonu(
          context,
          "Analiz & Rapor",
          Icons.analytics_rounded,
          const Color(0xFF0EA5E9),
          () {},
        ),
      ],
    );
  }

  Widget _islemButonu(
    BuildContext context,
    String baslik,
    IconData ikon,
    Color renk,
    VoidCallback onTap,
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
          onTap: onTap,
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

  // --- GELİŞMİŞ SINIF SEÇİM PANELİ (Sıralı + Scrollable + Boş Durum) ---
  void _sinifSecimPaneliniAc(BuildContext context) {
    // 1. Provider'dan listeyi al ve kopyasını oluştur (Sıralama için)
    final hamListe = ref.watch(siniflarProvider);
    final siniflar = List.of(hamListe);

    // 2. SIRALAMA: Sınıf adına göre A'dan Z'ye sırala
    siniflar.sort((a, b) => a.sinifAdi.compareTo(b.sinifAdi));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Panelin boyunu esnek yapar
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5, // Ekranın yarısı kadar açılsın
          minChildSize: 0.3,
          maxChildSize: 0.85, // En fazla %85'e kadar uzasın
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                children: [
                  // Tutamaç (Gri Çizgi)
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const Text(
                    "Hangi Sınıf?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${siniflar.length} Sınıf Listelendi",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const Divider(height: 20),

                  // --- İÇERİK KONTROLÜ ---
                  if (siniflar.isEmpty)
                    // DURUM 1: HİÇ SINIF YOKSA
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.class_outlined,
                              size: 50,
                              color: Colors.orange.shade300,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Henüz hiç sınıf eklememişsiniz.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // SINIF EKLE BUTONU
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text(
                                "Yeni Sınıf Ekle",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context); // Paneli kapat
                                // Sınıflar Sayfasına Git
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SiniflarSayfasi(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // DURUM 2: SINIFLAR VARSA (LİSTELE)
                    Expanded(
                      child: ListView.builder(
                        controller: controller, // Kaydırma kontrolü
                        itemCount: siniflar.length,
                        itemBuilder: (context, index) {
                          final sinif = siniflar[index];
                          return Card(
                            elevation: 0,
                            color: Colors.grey.shade50,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                child: Text(
                                  sinif.sinifAdi.isNotEmpty
                                      ? sinif.sinifAdi[0]
                                      : "?",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              title: Text(
                                sinif.sinifAdi,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                "Ders İçi Performans Girişi",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 18,
                                color: Colors.blue,
                              ),
                              onTap: () {
                                Navigator.pop(context); // Paneli kapat

                                if (sinif.id != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DersIciKatilimSayfasi(
                                            sinifId: sinif.id!,
                                            sinifAdi: sinif.sinifAdi,
                                          ),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
