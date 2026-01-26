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
// import 'package:ogretmenim/ozellikler/ogrenciler/ogrenciler_provider.dart'; // Buradan sildik çünkü burada kullanmayacağız

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
    // Öğrencileri yükleyemeyiz çünkü hangi sınıfın öğrencisi henüz belli değil.
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
          () {},
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
          () {},
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

  // --- SINIF SEÇİM PANELİ (Gerçek Veri) ---
  void _sinifSecimPaneliniAc(BuildContext context) {
    // 1. Provider'dan gerçek sınıf listesini al
    final siniflar = ref.watch(siniflarProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Hangi Sınıf?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(thickness: 1, height: 20),

              // Liste Boşsa Uyarı Ver
              if (siniflar.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.class_outlined,
                        size: 50,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Henüz hiç sınıf eklenmemiş.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                // Liste Doluysa Sınıfları Göster
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true, // Liste içeriği kadar yer kaplasın
                    itemCount: siniflar.length,
                    itemBuilder: (context, index) {
                      final sinif = siniflar[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        title: Text(
                          sinif.sinifAdi,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          Navigator.pop(context); // Paneli kapat

                          // Seçilen sınıfa git (ID kontrolü ile)
                          if (sinif.id != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DersIciKatilimSayfasi(
                                  sinifId: sinif.id!,
                                  sinifAdi: sinif.sinifAdi,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
