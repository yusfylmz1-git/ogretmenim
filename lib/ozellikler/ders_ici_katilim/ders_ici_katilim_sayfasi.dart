import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// --- PROJE BAĞIMLILIKLARI ---
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/ozellikler/ders_ici_katilim/ders_ici_katilim_provider.dart';
import 'package:ogretmenim/veri/modeller/performans_model.dart';
import 'package:ogretmenim/ozellikler/ogrenciler/ogrenciler_provider.dart';

class DersIciKatilimSayfasi extends ConsumerStatefulWidget {
  // Artık bu sayfa açılırken "Hangi sınıfın yoklaması?" diye soracak
  final int sinifId;
  final String sinifAdi;

  const DersIciKatilimSayfasi({
    Key? key,
    required this.sinifId,
    required this.sinifAdi,
  }) : super(key: key);

  @override
  ConsumerState<DersIciKatilimSayfasi> createState() =>
      _DersIciKatilimSayfasiState();
}

class _DersIciKatilimSayfasiState extends ConsumerState<DersIciKatilimSayfasi> {
  @override
  void initState() {
    super.initState();
    // Sayfa açılınca hem performansları hem de BU SINIFIN öğrencilerini yükle
    Future.microtask(() {
      // 1. Performans verilerini çek
      ref.read(performansProvider.notifier).verileriYukle();

      // 2. KRİTİK DÜZELTME: Bu sınıfa ait öğrencileri getir!
      ref.read(ogrencilerProvider.notifier).ogrencileriYukle(widget.sinifId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. GERÇEK ÖĞRENCİLERİ GETİR
    final tumOgrenciler = ref.watch(ogrencilerProvider);

    // Sadece seçilen sınıfa ait öğrencileri filtrele (Güvenlik önlemi)
    final sinifOgrencileri = tumOgrenciler
        .where((o) => o.sinifId == widget.sinifId)
        .toList();

    // 2. PERFORMANS VERİLERİNİ GETİR
    final state = ref.watch(performansProvider);
    final performanslar = state.performanslar;

    // --- PROJE ŞABLONU KULLANIMI ---
    return ProjeSayfaSablonu(
      // Başlık
      baslikWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.sinifAdi,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            DateFormat('d MMMM EEEE', 'tr_TR').format(DateTime.now()),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),

      // Sağ Üst Butonlar (Hızlı Doldur)
      aksiyonlar: [
        Container(
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: Colors.yellow.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.orange),
            tooltip: "Hızlı Doldur (Herkes 100)",
            onPressed: () {
              if (sinifOgrencileri.isEmpty) return;

              // Force unwrap (!) kullanıyoruz çünkü DB'den gelen öğrencinin ID'si vardır.
              final idListesi = sinifOgrencileri.map((e) => e.id!).toList();
              ref.read(performansProvider.notifier).hizliDoldur(idListesi);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Tüm sınıfa 100 puan verildi! 🚀"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ],

      // Sayfa İçeriği
      icerik: state.yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : sinifOgrencileri.isEmpty
          ? _bosSinifUyaris()
          : Column(
              children: [
                _buildOzetBilgi(sinifOgrencileri, performanslar),
                const SizedBox(height: 10),

                // Liste Görünümü
                GridView.builder(
                  shrinkWrap: true, // İçerik kadar yer kapla
                  physics:
                      const NeverScrollableScrollPhysics(), // Ana sayfayla birlikte kay
                  padding: const EdgeInsets.only(bottom: 80), // Fab için boşluk
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: sinifOgrencileri.length,
                  itemBuilder: (context, index) {
                    final ogrenci = sinifOgrencileri[index];
                    // Bu öğrencinin veritabanında kaydı var mı?
                    final kayit = performanslar[ogrenci.id];

                    return _buildOgrenciKarti(ogrenci, kayit);
                  },
                ),
              ],
            ),
    );
  }

  // --- YARDIMCI WIDGETLAR ---

  Widget _bosSinifUyaris() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text(
            "Bu sınıfta henüz öğrenci yok.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOzetBilgi(
    List<dynamic> ogrenciler,
    Map<int, PerformansModel> performanslar,
  ) {
    // 1. Toplam Mevcut
    int toplam = ogrenciler.length;

    // 2. Kaç kişinin kaydı var? (Canlı Hesaplama)
    int degerlendirilen = ogrenciler
        .where((o) => performanslar.containsKey(o.id))
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart, color: Colors.blue),
          const SizedBox(width: 10),
          Text(
            "$degerlendirilen / $toplam Değerlendirildi",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const Spacer(),
          const Text(
            "Puanlama Modu",
            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildOgrenciKarti(dynamic ogrenci, PerformansModel? kayit) {
    // DÜZELTME: İsimleri birleştiriyoruz
    String tamAd = "${ogrenci.ad} ${ogrenci.soyad}";

    int puan = kayit?.puan ?? 0;
    bool degerlendirilmis = kayit != null;

    Color puanRengi = Colors.grey;
    if (puan >= 80)
      puanRengi = Colors.green;
    else if (puan >= 50)
      puanRengi = Colors.orange;
    else if (puan > 0)
      puanRengi = Colors.red;

    return GestureDetector(
      onTap: () => _degerlendirmePaneliniAc(ogrenci, kayit),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: degerlendirilmis
                ? puanRengi.withOpacity(0.5)
                : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade100,
                  radius: 24,
                  // Baş harf
                  child: Text(
                    tamAd.isNotEmpty ? tamAd[0] : "?",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (degerlendirilmis)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: puanRengi,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                tamAd,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: puanRengi.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                degerlendirilmis ? "$puan" : "-",
                style: TextStyle(
                  color: puanRengi,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PANEL ---
  void _degerlendirmePaneliniAc(dynamic ogrenci, PerformansModel? mevcutKayit) {
    // DÜZELTME: İsmi burada birleştiriyoruz
    String tamAd = "${ogrenci.ad} ${ogrenci.soyad}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DegerlendirmeFormu(
            ogrenciAdi: tamAd,
            numara: int.tryParse(ogrenci.numara.toString()) ?? 0,
            baslangicKitap: mevcutKayit?.kitap == 1,
            baslangicOdev: mevcutKayit?.odev == 1,
            baslangicYildiz: mevcutKayit?.yildiz ?? 1,
            onKaydet: (yeniPuan, kitap, odev, yildiz) {
              final bugun = DateFormat('yyyy-MM-dd').format(DateTime.now());
              final model = PerformansModel(
                id: mevcutKayit?.id,
                ogrenciId: ogrenci.id!,
                tarih: bugun,
                kitap: kitap ? 1 : 0,
                odev: odev ? 1 : 0,
                yildiz: yildiz,
                puan: yeniPuan,
              );

              ref.read(performansProvider.notifier).puanKaydet(model);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
}

// --- FORM WIDGET ---
class DegerlendirmeFormu extends StatefulWidget {
  final String ogrenciAdi;
  final int numara;
  final bool baslangicKitap;
  final bool baslangicOdev;
  final int baslangicYildiz;
  final Function(int puan, bool kitap, bool odev, int yildiz) onKaydet;

  const DegerlendirmeFormu({
    Key? key,
    required this.ogrenciAdi,
    required this.numara,
    this.baslangicKitap = false,
    this.baslangicOdev = false,
    this.baslangicYildiz = 1,
    required this.onKaydet,
  }) : super(key: key);

  @override
  State<DegerlendirmeFormu> createState() => _DegerlendirmeFormuState();
}

class _DegerlendirmeFormuState extends State<DegerlendirmeFormu> {
  late bool _kitap;
  late bool _odev;
  late int _yildiz;

  @override
  void initState() {
    super.initState();
    _kitap = widget.baslangicKitap;
    _odev = widget.baslangicOdev;
    _yildiz = widget.baslangicYildiz;
  }

  int _puanHesapla() {
    int toplam = 0;
    if (_kitap) toplam += 20;
    if (_odev) toplam += 20;
    toplam += (_yildiz * 20);
    return toplam;
  }

  @override
  Widget build(BuildContext context) {
    int guncelPuan = _puanHesapla();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tutamaç
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.ogrenciAdi,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    "#${widget.numara}",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
            ],
          ),
          const Divider(height: 30),

          // Switchler
          _buildSwitch(
            "Kitap/Defter (+20p)",
            _kitap,
            (v) => setState(() => _kitap = v),
          ),
          _buildSwitch("Ödev (+20p)", _odev, (v) => setState(() => _odev = v)),

          const SizedBox(height: 20),

          // Yıldızlar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _yildizButonu(1, "Geliştirilmeli"),
              _yildizButonu(2, "İyi"),
              _yildizButonu(3, "Çok İyi"),
            ],
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () =>
                  widget.onKaydet(guncelPuan, _kitap, _odev, _yildiz),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "KAYDET",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$guncelPuan Puan",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
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

  Widget _buildSwitch(String title, bool val, Function(bool) onChange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: val ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: val ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: val ? Colors.green.shade800 : Colors.black87,
          ),
        ),
        value: val,
        activeColor: Colors.green,
        onChanged: onChange,
      ),
    );
  }

  Widget _yildizButonu(int seviye, String etiket) {
    bool secili = _yildiz == seviye;
    return GestureDetector(
      onTap: () => setState(() => _yildiz = seviye),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: secili ? Colors.orange.shade100 : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(
                color: secili ? Colors.orange : Colors.transparent,
                width: 3,
              ),
              boxShadow: secili
                  ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              Icons.star,
              color: secili ? Colors.orange : Colors.grey.shade400,
              size: 34,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            etiket,
            style: TextStyle(
              fontSize: 12,
              fontWeight: secili ? FontWeight.bold : FontWeight.normal,
              color: secili ? Colors.orange.shade800 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
