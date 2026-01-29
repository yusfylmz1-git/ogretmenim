import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// --- PROJE BAĞIMLILIKLARI ---
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/ozellikler/ders_ici_katilim/ders_ici_katilim_provider.dart';
import 'package:ogretmenim/veri/modeller/performans_model.dart';
import 'package:ogretmenim/ozellikler/ogrenciler/ogrenciler_provider.dart';

class DersIciKatilimSayfasi extends ConsumerStatefulWidget {
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
  DateTime _secilenTarih = DateTime.now();
  bool _yukleniyor = true;

  // YENİ: Hızlı doldur butonunun durumunu takip eden değişken
  bool _hizliDolduruldu = false;

  @override
  void initState() {
    super.initState();
    _verileriGetir();
  }

  Future<void> _verileriGetir() async {
    if (mounted) setState(() => _yukleniyor = true);

    await Future.microtask(() async {
      await ref
          .read(performansProvider.notifier)
          .verileriYukle(tarih: _secilenTarih);

      await ref
          .read(ogrencilerProvider.notifier)
          .ogrencileriYukle(widget.sinifId);
    });

    if (mounted) setState(() => _yukleniyor = false);
  }

  // --- TARİH FONKSİYONLARI ---
  void _tarihSec(BuildContext context) async {
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: _secilenTarih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'),
    );

    if (secilen != null && secilen != _secilenTarih) {
      setState(() {
        _secilenTarih = secilen;
        _hizliDolduruldu = false; // Tarih değişince butonu sıfırla
      });
      _verileriGetir();
    }
  }

  void _gunDegistir(int gun) {
    setState(() {
      _secilenTarih = _secilenTarih.add(Duration(days: gun));
      _hizliDolduruldu = false; // Gün değişince butonu sıfırla
    });
    _verileriGetir();
  }

  @override
  Widget build(BuildContext context) {
    final tumOgrenciler = ref.watch(ogrencilerProvider);
    final sinifOgrencileri = tumOgrenciler
        .where((o) => o.sinifId == widget.sinifId)
        .toList();

    final state = ref.watch(performansProvider);
    final performanslar = state.performanslar;

    return ProjeSayfaSablonu(
      // --- GELİŞMİŞ BAŞLIK (GERİ BUTONU + TARİH) ---
      baslikWidget: Row(
        children: [
          // 1. GERİ DÖN BUTONU
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: Color(0xFF1E293B),
              ),
              onPressed: () => Navigator.pop(context),
              tooltip: "Geri Dön",
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),

          // 2. SINIF BİLGİSİ VE TARİH
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.sinifAdi,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              // Tarih Seçici Satırı
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _gunDegistir(-1),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.chevron_left,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _tarihSec(context),
                    child: Text(
                      DateFormat('d MMM EEE', 'tr_TR').format(_secilenTarih),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _gunDegistir(1),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // --- İNTERAKTİF HIZLI DOLDUR BUTONU ---
      aksiyonlar: [
        GestureDetector(
          onTap: () {
            if (sinifOgrencileri.isEmpty) return;

            setState(() => _hizliDolduruldu = true); // Rengi değiştir

            final idListesi = sinifOgrencileri.map((e) => e.id!).toList();
            ref
                .read(performansProvider.notifier)
                .hizliDoldur(idListesi, tarih: _secilenTarih);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Tüm sınıfa 100 puan verildi! ⚡"),
                duration: Duration(seconds: 1),
                backgroundColor: Colors.orange,
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 300,
            ), // Renk geçiş animasyonu
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // Basıldıysa Sarı, değilse Beyaz
              color: _hizliDolduruldu ? const Color(0xFFFFD700) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hizliDolduruldu ? Colors.orange : Colors.grey.shade200,
                width: 2,
              ),
              boxShadow: [
                if (!_hizliDolduruldu)
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Icon(
              Icons.flash_on_rounded,
              // Basıldıysa Beyaz, değilse Turuncu ikon
              color: _hizliDolduruldu ? Colors.white : Colors.orange,
              size: 24,
            ),
          ),
        ),
      ],

      // --- İÇERİK ---
      icerik: (state.yukleniyor || _yukleniyor)
          ? const Center(child: CircularProgressIndicator())
          : sinifOgrencileri.isEmpty
          ? _bosSinifUyaris()
          : Column(
              children: [
                _buildOzetBilgi(sinifOgrencileri, performanslar),
                const SizedBox(height: 15),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 80),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.68, // Kart boyunu biraz uzattım
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: sinifOgrencileri.length,
                  itemBuilder: (context, index) {
                    final ogrenci = sinifOgrencileri[index];
                    final kayit = performanslar[ogrenci.id];
                    return _buildOgrenciKarti(ogrenci, kayit);
                  },
                ),
              ],
            ),
    );
  }

  // --- MODERN KART TASARIMI ---
  Widget _buildOgrenciKarti(dynamic ogrenci, PerformansModel? kayit) {
    String tamAd = "${ogrenci.ad} ${ogrenci.soyad}";
    int puan = kayit?.puan ?? 0;
    bool degerlendirilmis = kayit != null;
    bool kitapVar = kayit?.kitap == 1;
    bool odevVar = kayit?.odev == 1;

    // Renk Paleti
    Color durumRengi = Colors.grey.shade300;
    Color yaziRengi = Colors.grey;
    if (degerlendirilmis) {
      if (puan >= 85) {
        durumRengi = const Color(0xFF10B981);
        yaziRengi = const Color(0xFF065F46);
      } // Yeşil
      else if (puan >= 50) {
        durumRengi = const Color(0xFFF59E0B);
        yaziRengi = const Color(0xFF92400E);
      } // Turuncu
      else {
        durumRengi = const Color(0xFFEF4444);
        yaziRengi = const Color(0xFF7F1D1D);
      } // Kırmızı
    }

    return GestureDetector(
      onTap: () => _degerlendirmePaneliniAc(ogrenci, kayit),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Sol Taraftaki Renkli Çizgi (Durum Çubuğu)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: durumRengi),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 6, 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // AVATAR
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: durumRengi.withOpacity(0.1),
                            border: Border.all(
                              color: durumRengi.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              tamAd.isNotEmpty ? tamAd[0] : "?",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: durumRengi,
                                fontSize: 20,
                              ),
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
                                color: durumRengi,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // İSİM
                    Text(
                      tamAd,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),

                    // KİTAP & ÖDEV İKONLARI (Varsa Göster)
                    if (degerlendirilmis)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (kitapVar)
                            const Icon(
                              Icons.menu_book_rounded,
                              size: 12,
                              color: Colors.blueGrey,
                            ),
                          if (kitapVar && odevVar) const SizedBox(width: 4),
                          if (odevVar)
                            const Icon(
                              Icons.edit_note_rounded,
                              size: 14,
                              color: Colors.blueGrey,
                            ),
                        ],
                      ),
                    const SizedBox(height: 4),

                    // PUAN KUTUSU
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: degerlendirilmis
                            ? durumRengi.withOpacity(0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        degerlendirilmis ? "$puan" : "-",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: degerlendirilmis ? yaziRengi : Colors.grey,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- YARDIMCI WIDGETLAR (Öncekilerle Aynı) ---
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
    int toplam = ogrenciler.length;
    int degerlendirilen = ogrenciler
        .where((o) => performanslar.containsKey(o.id))
        .length;
    double oran = toplam == 0 ? 0 : degerlendirilen / toplam;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircularProgressIndicator(
            value: oran,
            backgroundColor: Colors.blue.shade50,
            color: Colors.blue,
            strokeWidth: 6,
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$degerlendirilen / $toplam Öğrenci",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Text(
                "Değerlendirildi",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "Puanlama",
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _degerlendirmePaneliniAc(dynamic ogrenci, PerformansModel? mevcutKayit) {
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
              final formatliTarih = DateFormat(
                'yyyy-MM-dd',
              ).format(_secilenTarih);

              final model = PerformansModel(
                id: mevcutKayit?.id,
                ogrenciId: ogrenci.id!,
                tarih: formatliTarih,
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

// --- FORM WIDGET (DEĞİŞİKLİK YOK) ---
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
          _buildSwitch(
            "Kitap/Defter (+20p)",
            _kitap,
            (v) => setState(() => _kitap = v),
          ),
          _buildSwitch("Ödev (+20p)", _odev, (v) => setState(() => _odev = v)),
          const SizedBox(height: 20),
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
