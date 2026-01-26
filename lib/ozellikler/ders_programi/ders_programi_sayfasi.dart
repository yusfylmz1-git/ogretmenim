import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// PROJE TEMEL DOSYALARI
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/cekirdek/yoneticiler/program_ayarlari.dart';
import 'package:ogretmenim/ozellikler/profil/profil_ayarlari.dart';
import 'package:ogretmenim/veri/modeller/ders_model.dart';
import 'package:ogretmenim/veri/modeller/sinif_model.dart';
import 'package:ogretmenim/ozellikler/siniflar/siniflar_provider.dart';

// BİLEŞENLER
import 'dersler_provider.dart';
import 'bilesenler/ders_ekleme_paneli.dart';
import 'bilesenler/program_ayarlari_paneli.dart';

class DersProgramiSayfasi extends ConsumerStatefulWidget {
  const DersProgramiSayfasi({super.key});

  @override
  ConsumerState<DersProgramiSayfasi> createState() =>
      _DersProgramiSayfasiState();
}

class _DersProgramiSayfasiState extends ConsumerState<DersProgramiSayfasi> {
  DateTime _secilenTarih = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Verileri yükle
    Future.microtask(() {
      ref.read(derslerProvider.notifier).dersleriYukle();
      ref.read(siniflarProvider.notifier).siniflariYukle();
    });
  }

  // --- AYARLARI KAYDET ---
  Future<void> _ayarlariKaydet(
    TimeOfDay ilk,
    int ders,
    int teneffus,
    int sayi,
    bool ogle,
    int ogleSure,
  ) async {
    setState(() {
      ProgramAyarlari.ilkDersSaati = ilk;
      ProgramAyarlari.dersSuresi = ders;
      ProgramAyarlari.teneffusSuresi = teneffus;
      ProgramAyarlari.gunlukDersSayisi = sayi;
      ProgramAyarlari.ogleArasiVarMi = ogle;
      ProgramAyarlari.ogleArasiSuresi = ogleSure;
    });
  }

  // --- PANELLERİ AÇMA FONKSİYONLARI ---

  // GÜNCELLENEN FONKSİYON: Artık düzenlenecek dersi de alabiliyor
  void _dersIslemPaneliniAc(
    List<DersModel> mevcutDersler,
    List<SinifModel> sinifListesi, {
    DersModel? duzenlenecekDers, // Bu doluysa düzenleme modudur
  }) {
    final sinifAdlari = sinifListesi.map((s) => s.sinifAdi).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DersEklemePaneli(
        mevcutDersler: mevcutDersler,
        gunlukDersSayisi: ProgramAyarlari.gunlukDersSayisi,
        mevcutSiniflar: sinifAdlari,
        // Eğer düzenleme yapıyorsak dersi panele gönderiyoruz
        duzenlenecekDers: duzenlenecekDers,

        // Panelden gelen sonuç (yeni veya güncellenmiş ders)
        onDersKaydet: (gelenDers) {
          if (duzenlenecekDers != null) {
            // DÜZENLEME İŞLEMİ
            ref.read(derslerProvider.notifier).dersGuncelle(gelenDers);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Ders güncellendi ✅"),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 1),
              ),
            );
          } else {
            // EKLEME İŞLEMİ
            ref.read(derslerProvider.notifier).dersEkle(gelenDers);
          }
        },
      ),
    );
  }

  void _ayarlarPaneliniAc() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProgramAyarlariPaneli(
        ilkDersSaati: ProgramAyarlari.ilkDersSaati,
        dersSuresi: ProgramAyarlari.dersSuresi,
        teneffusSuresi: ProgramAyarlari.teneffusSuresi,
        gunlukDersSayisi: ProgramAyarlari.gunlukDersSayisi,
        ogleArasiVarMi: ProgramAyarlari.ogleArasiVarMi,
        ogleArasiSuresi: ProgramAyarlari.ogleArasiSuresi,
        onKaydet: _ayarlariKaydet,
      ),
    );
  }

  // --- SAAT HESAPLAMA ---
  String _saatAraligiHesapla(int dersIndex) {
    int baslangicDakika =
        ProgramAyarlari.ilkDersSaati.hour * 60 +
        ProgramAyarlari.ilkDersSaati.minute;

    int gecenSure =
        dersIndex *
        (ProgramAyarlari.dersSuresi + ProgramAyarlari.teneffusSuresi);

    if (ProgramAyarlari.ogleArasiVarMi && dersIndex >= 4) {
      gecenSure +=
          ProgramAyarlari.ogleArasiSuresi - ProgramAyarlari.teneffusSuresi;
    }

    int dersBaslamaDakikasi = baslangicDakika + gecenSure;
    int dersBitisDakikasi = dersBaslamaDakikasi + ProgramAyarlari.dersSuresi;

    String format(int dk) {
      int sa = (dk ~/ 60) % 24;
      int dak = dk % 60;
      return "${sa.toString().padLeft(2, '0')}:${dak.toString().padLeft(2, '0')}";
    }

    return "${format(dersBaslamaDakikasi)} - ${format(dersBitisDakikasi)}";
  }

  @override
  Widget build(BuildContext context) {
    final tumDersler = ref.watch(derslerProvider);
    final tumSiniflar = ref.watch(siniflarProvider);

    final anaRenk = ProjeTemasi.anaRenk;

    String gunIsmi = DateFormat('EEEE', 'tr_TR').format(_secilenTarih);

    var bugunkuDersler = tumDersler.where((d) => d.gun == gunIsmi).toList();
    bugunkuDersler.sort((a, b) => a.dersSaatiIndex.compareTo(b.dersSaatiIndex));

    return ProjeSayfaSablonu(
      baslikWidget: _profilBaslikWidget(),
      aksiyonlar: [
        IconButton(
          onPressed: _ayarlarPaneliniAc,
          icon: const Icon(Icons.tune_rounded, color: Color(0xFF1E293B)),
          tooltip: "Program Ayarları",
        ),
        _ekleButonu(tumDersler, tumSiniflar),
      ],
      icerik: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 80),
        children: [
          _gunSecimPaneli(anaRenk),
          const SizedBox(height: 20),
          bugunkuDersler.isEmpty
              ? _bosDersUyarisi()
              : Column(
                  children: bugunkuDersler.map((ders) {
                    return _dersKarti(ders);
                  }).toList(),
                ),
        ],
      ),
    );
  }

  // --- WIDGET PARÇALARI ---

  Widget _profilBaslikWidget() {
    final user = FirebaseAuth.instance.currentUser;
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfilAyarlariSayfasi(),
              ),
            ).then((_) => setState(() {}));
          },
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
        const Text(
          "Ders Programım",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _ekleButonu(List<DersModel> tumDersler, List<SinifModel> tumSiniflar) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, left: 5.0),
      child: Material(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          // Ekleme modunda paneli açıyoruz (duzenlenecekDers: null)
          onTap: () => _dersIslemPaneliniAc(tumDersler, tumSiniflar),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: const Row(
              children: [
                Icon(Icons.add_rounded, color: Color(0xFF1E293B), size: 18),
                SizedBox(width: 4),
                Text(
                  "EKLE",
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gunSecimPaneli(Color anaRenk) {
    return SizedBox(
      height: 75,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          DateTime bugun = DateTime.now();
          DateTime haftaBasi = bugun.subtract(
            Duration(days: bugun.weekday - 1),
          );
          DateTime gun = haftaBasi.add(Duration(days: index));
          bool secili =
              gun.day == _secilenTarih.day && gun.month == _secilenTarih.month;

          return GestureDetector(
            onTap: () => setState(() => _secilenTarih = gun),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: secili ? 65 : 55,
              decoration: BoxDecoration(
                color: secili ? anaRenk : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                boxShadow: secili
                    ? [
                        BoxShadow(
                          color: anaRenk.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', 'tr_TR').format(gun).substring(0, 1),
                    style: TextStyle(
                      color: secili ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    gun.day.toString(),
                    style: TextStyle(
                      color: secili ? Colors.white : Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- DERS KARTI (GÜNCELLENEN KISIM) ---
  Widget _dersKarti(DersModel ders) {
    String saat = _saatAraligiHesapla(ders.dersSaatiIndex);

    return Dismissible(
      key: Key(ders.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Dersi Sil"),
            content: Text("${ders.dersAdi} dersini silmek istiyor musunuz?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("İptal"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Sil", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(derslerProvider.notifier).dersSil(ders.id!, ders);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // SAAT INDEX (RENKLİ DAİRE)
            CircleAvatar(
              radius: 18,
              backgroundColor: ders.renk.withOpacity(0.1),
              child: Text(
                (ders.dersSaatiIndex + 1).toString(),
                style: TextStyle(color: ders.renk, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 15),

            // DERS BİLGİLERİ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ders.dersAdi,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "$saat • ${ders.sinif}",
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),

            // --- İŞTE BEKLENEN KALEM İKONU! ---
            IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                color: Colors.grey,
                size: 20,
              ),
              tooltip: "Dersi Düzenle",
              onPressed: () {
                // Mevcut verileri çekiyoruz
                final tumDersler = ref.read(derslerProvider);
                final tumSiniflar = ref.read(siniflarProvider);

                // Paneli "Düzenleme Modunda" açıyoruz
                _dersIslemPaneliniAc(
                  tumDersler,
                  tumSiniflar,
                  duzenlenecekDers: ders, // Seçili dersi gönder
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _bosDersUyarisi() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.event_note, size: 60, color: Colors.grey.shade200),
          const SizedBox(height: 15),
          Text(
            "Bu gün için ders eklenmemiş.",
            style: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
