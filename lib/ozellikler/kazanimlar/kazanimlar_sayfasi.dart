import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/veri/veritabani/veritabani_yardimcisi.dart';

class KazanimlarSayfasi extends ConsumerStatefulWidget {
  const KazanimlarSayfasi({super.key});

  @override
  ConsumerState<KazanimlarSayfasi> createState() => _KazanimlarSayfasiState();
}

class _KazanimlarSayfasiState extends ConsumerState<KazanimlarSayfasi> {
  // --- STATE ---
  int? _secilenSinif;
  String? _secilenDers;
  bool _favorilerModu = false;
  late PageController _pageController;

  // Tarihler
  DateTime? _okulBaslangicTarihi;
  DateTime? _okulBitisTarihi;
  DateTime? _araTatil1Baslangic;
  DateTime? _yariyilBaslangic;
  DateTime? _yariyilBitis;
  DateTime? _araTatil2Baslangic;
  DateTime? _ramazanBayrami;
  DateTime? _kurbanBayrami;

  bool _icerikYukleniyor = false;
  final Set<String> _favoriDersler = {};

  final List<String> _dersler = [
    "Bilişim Teknolojileri",
    "Matematik",
    "Fen Bilimleri",
    "Türkçe",
    "Sosyal Bilgiler",
    "İngilizce",
    "Din Kültürü",
    "Görsel Sanatlar",
  ];

  List<Map<String, dynamic>> _kazanimListesi = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _tarihleriHazirla();
  }

  // 1. TARİHLERİ YÜKLE
  Future<void> _tarihleriHazirla() async {
    final db = VeritabaniYardimcisi.instance;
    final bas = await db.ayarGetir('egitim_baslangic');
    final bit = await db.ayarGetir('egitim_bitis');
    final at1 = await db.ayarGetir('ara_tatil1');
    final yb = await db.ayarGetir('yariyil_baslangic');
    final ybt = await db.ayarGetir('yariyil_bitis');
    final at2 = await db.ayarGetir('ara_tatil2');

    // Bayramlar
    final rmz = await db.ayarGetir('tatil_ramazan');
    final krb = await db.ayarGetir('tatil_kurban');

    if (mounted) {
      setState(() {
        // Zorunlu alanlar (Varsayılanlar 2025-2026 takvimi)
        _okulBaslangicTarihi = bas != null
            ? DateTime.parse(bas)
            : DateTime(2025, 9, 8);
        _okulBitisTarihi = bit != null
            ? DateTime.parse(bit)
            : _okulBaslangicTarihi!.add(const Duration(days: 42 * 7));
        _araTatil1Baslangic = at1 != null
            ? DateTime.parse(at1)
            : _okulBaslangicTarihi!.add(const Duration(days: 9 * 7));
        _yariyilBaslangic = yb != null
            ? DateTime.parse(yb)
            : _okulBaslangicTarihi!.add(const Duration(days: 19 * 7));
        _yariyilBitis = ybt != null
            ? DateTime.parse(ybt)
            : _yariyilBaslangic!.add(const Duration(days: 14));
        _araTatil2Baslangic = at2 != null
            ? DateTime.parse(at2)
            : _okulBaslangicTarihi!.add(const Duration(days: 30 * 7));

        // Bayramlar (Varsa yükle)
        if (rmz != null && rmz.isNotEmpty)
          _ramazanBayrami = DateTime.parse(rmz);
        if (krb != null && krb.isNotEmpty) _kurbanBayrami = DateTime.parse(krb);
      });
    }
  }

  // 2. KARTLARI OLUŞTUR
  Future<void> _icerigiOlustur() async {
    if (_okulBaslangicTarihi == null ||
        _secilenSinif == null ||
        _secilenDers == null)
      return;
    setState(() => _icerikYukleniyor = true);

    final dbPlanlar = await VeritabaniYardimcisi.instance.planlariGetir(
      _secilenSinif!,
      _secilenDers!,
    );
    _kazanimListesi.clear();

    DateTime bitisSiniri = _okulBitisTarihi!;
    DateTime haftabasi = _okulBaslangicTarihi!;
    int dersHaftasiSayaci = 1;

    // DÖNGÜ
    while (haftabasi.isBefore(bitisSiniri)) {
      DateTime haftasonu = haftabasi.add(const Duration(days: 6));
      String? tatilAdi;

      // --- TATİL KONTROLLERİ ---

      // 1. Standart MEB Tatilleri (Aralık Kontrolü)
      if (_tarihAraligindaMi(haftabasi, haftasonu, _araTatil1Baslangic, null)) {
        tatilAdi = "1. ARA TATİL";
      } else if (_tarihAraligindaMi(
        haftabasi,
        haftasonu,
        _yariyilBaslangic,
        _yariyilBitis,
      )) {
        tatilAdi = "YARIYIL TATİLİ";
      } else if (_tarihAraligindaMi(
        haftabasi,
        haftasonu,
        _araTatil2Baslangic,
        null,
      )) {
        tatilAdi = "2. ARA TATİL";
      }
      // 2. Dini Bayramlar (Bu Hafta İçinde Başlıyor Mu?)
      // YENİ MANTIK: Bayramın başlangıç günü bu haftanın (Pzt-Pazar) içindeyse o hafta tatildir.
      else if (_haftaTatilIceriyorMu(haftabasi, _ramazanBayrami)) {
        tatilAdi = "RAMAZAN BAYRAMI";
      } else if (_haftaTatilIceriyorMu(haftabasi, _kurbanBayrami)) {
        tatilAdi = "KURBAN BAYRAMI";
      }

      // KART EKLEME
      if (tatilAdi != null) {
        // [TATİL]
        _kazanimListesi.add({
          "hafta": 0,
          "unite": tatilAdi,
          "kazanim": "",
          "tip": "Tatil",
          "baslangic": haftabasi,
          "bitis": haftasonu,
        });
      } else {
        // [DERS]
        final dbKaydi = dbPlanlar.firstWhere(
          (plan) => plan['hafta'] == dersHaftasiSayaci,
          orElse: () => {},
        );
        _kazanimListesi.add({
          "hafta": dersHaftasiSayaci,
          "unite": dbKaydi.isNotEmpty
              ? dbKaydi['unite']
              : "$dersHaftasiSayaci. Hafta",
          "kazanim": dbKaydi.isNotEmpty
              ? dbKaydi['kazanim']
              : "Bu hafta için veri girilmemiş.",
          "tip": "Ders",
          "baslangic": haftabasi,
          "bitis": haftasonu,
        });
        dersHaftasiSayaci++;
      }
      haftabasi = haftabasi.add(const Duration(days: 7));
    }

    if (mounted) {
      setState(() => _icerikYukleniyor = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) _buguneGit(animasyonlu: false);
      });
    }
  }

  // --- YENİLENMİŞ KONTROL FONKSİYONLARI ---

  // Standart Tatiller için (Aralık Çakışması)
  bool _tarihAraligindaMi(
    DateTime hBas,
    DateTime hSon,
    DateTime? tBas,
    DateTime? tBit,
  ) {
    if (tBas == null) return false;
    DateTime tBitis = tBit ?? tBas.add(const Duration(days: 6));
    // 12 saat tolerans
    return hBas.isBefore(tBitis.add(const Duration(hours: 12))) &&
        hSon.isAfter(tBas.subtract(const Duration(hours: 12)));
  }

  // Bayramlar için (Nokta Atışı Kontrol)
  // "Tatil başlangıç tarihi, bu haftanın (Pzt 00:00 - Pazar 23:59) içinde mi?"
  bool _haftaTatilIceriyorMu(DateTime haftaBasi, DateTime? tatilBaslangic) {
    if (tatilBaslangic == null) return false;
    DateTime haftaSonu = haftaBasi.add(
      const Duration(days: 6, hours: 23, minutes: 59),
    );

    // Tatil tarihi >= Hafta Başı VE Tatil Tarihi <= Hafta Sonu
    return tatilBaslangic.isAfter(
          haftaBasi.subtract(const Duration(seconds: 1)),
        ) &&
        tatilBaslangic.isBefore(haftaSonu);
  }

  // --- DİĞER YARDIMCILAR ---
  int _simdikiHaftayiBul() {
    if (_kazanimListesi.isEmpty) return 0;
    final bugun = DateTime.now();
    for (int i = 0; i < _kazanimListesi.length; i++) {
      if (bugun.isAfter(
            _kazanimListesi[i]['baslangic'].subtract(const Duration(days: 1)),
          ) &&
          bugun.isBefore(
            _kazanimListesi[i]['bitis'].add(const Duration(days: 1)),
          ))
        return i;
    }
    return _kazanimListesi.length > 0 ? _kazanimListesi.length - 1 : 0;
  }

  void _buguneGit({bool animasyonlu = true}) {
    if (!_pageController.hasClients || _kazanimListesi.isEmpty) return;
    int index = _simdikiHaftayiBul();
    if (animasyonlu) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
      );
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "📅 Bugünün haftasına dönüldü",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
          width: 200,
        ),
      );
    } else {
      _pageController.jumpToPage(index);
    }
  }

  String _tarihFormatla(DateTime tarih) =>
      DateFormat('d MMM', 'tr_TR').format(tarih);
  void _dersSec(int s, String d) {
    setState(() {
      _secilenSinif = s;
      _secilenDers = d;
      _favorilerModu = false;
    });
    _icerigiOlustur();
  }

  void _toggleFavori(int s, String d) {
    final k = "${s}_$d";
    setState(() {
      if (_favoriDersler.contains(k))
        _favoriDersler.remove(k);
      else
        _favoriDersler.add(k);
    });
  }

  bool _isFavori(int s, String d) => _favoriDersler.contains("${s}_$d");
  void _geriGit() {
    setState(() {
      if (_secilenDers != null) {
        _secilenDers = null;
        _kazanimListesi.clear();
      } else if (_secilenSinif != null)
        _secilenSinif = null;
      else if (_favorilerModu)
        _favorilerModu = false;
      else
        Navigator.pop(context);
    });
  }

  String _baslikGetir() => _secilenDers != null
      ? "$_secilenSinif. Sınıf $_secilenDers"
      : _favorilerModu
      ? "Favori Derslerim"
      : _secilenSinif != null
      ? "$_secilenSinif. Sınıf Dersleri"
      : "Kazanım & Planlar";

  @override
  Widget build(BuildContext context) {
    Widget icerik;
    if (_secilenDers != null && _icerikYukleniyor)
      icerik = const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      );
    else if (_secilenDers != null)
      icerik = _buildYatayKartlar();
    else if (_favorilerModu)
      icerik = _buildFavorilerListesi();
    else if (_secilenSinif != null)
      icerik = _buildDersListesi();
    else
      icerik = _buildSinifSecimi();

    return ProjeSayfaSablonu(
      baslikWidget: Row(
        children: [
          GestureDetector(
            onTap: _geriGit,
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              _baslikGetir(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_secilenDers != null)
            Tooltip(
              message: "Bugüne Git",
              child: GestureDetector(
                onTap: () => _buguneGit(animasyonlu: true),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.today_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => setState(() {
                _favorilerModu = !_favorilerModu;
                _secilenSinif = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _favorilerModu ? Colors.orange : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _favorilerModu
                        ? Colors.orange
                        : Colors.grey.shade300,
                  ),
                ),
                child: Icon(
                  _favorilerModu
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: _favorilerModu ? Colors.white : Colors.grey,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
      icerik: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Padding(
          key: ValueKey("$_secilenDers$_secilenSinif$_favorilerModu"),
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
          child: icerik,
        ),
      ),
    );
  }

  Widget _buildYatayKartlar() => _kazanimListesi.isEmpty
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_off_rounded,
                size: 60,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 10),
              const Text(
                "Plan bulunamadı.",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        )
      : SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _kazanimListesi.length,
            itemBuilder: (c, i) => _kazanimListesi[i]['tip'] == 'Tatil'
                ? _buildTatilKarti(
                    _kazanimListesi[i],
                    "${_tarihFormatla(_kazanimListesi[i]['baslangic'])} - ${_tarihFormatla(_kazanimListesi[i]['bitis'])}",
                  )
                : _buildDersKarti(
                    _kazanimListesi[i],
                    "${_tarihFormatla(_kazanimListesi[i]['baslangic'])} - ${_tarihFormatla(_kazanimListesi[i]['bitis'])}",
                  ),
          ),
        );
  Widget _buildFavorilerListesi() => ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _favoriDersler.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (c, i) {
      final p = _favoriDersler.toList()[i].split('_');
      return ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(p[1]),
        leading: CircleAvatar(
          child: Text(p[0]),
          backgroundColor: Colors.orange.shade100,
          foregroundColor: Colors.orange,
        ),
        onTap: () => _dersSec(int.parse(p[0]), p[1]),
      );
    },
  );
  Widget _buildDersListesi() => ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _dersler.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (c, i) {
      final d = _dersler[i];
      final f = _isFavori(_secilenSinif!, d);
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _dersSec(_secilenSinif!, d),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book, color: Color(0xFF10B981)),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    f ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: f ? Colors.orange : Colors.grey,
                  ),
                  onPressed: () => _toggleFavori(_secilenSinif!, d),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  Widget _buildSinifSecimi() => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 0.85,
    ),
    itemCount: 12,
    itemBuilder: (c, i) => GestureDetector(
      onTap: () => setState(() => _secilenSinif = i + 1),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
              child: Text(
                "${i + 1}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(height: 5),
            const Text("Sınıf", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    ),
  );
  Widget _buildDersKarti(Map<String, dynamic> v, String t) {
    final a = _simdikiHaftayiBul();
    final b = _kazanimListesi.indexOf(v) == a;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: b ? Border.all(color: const Color(0xFF10B981), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: b ? const Color(0xFF10B981) : Colors.grey.shade700,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Text(
                  "${v['hafta']}. Hafta",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (b)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "BU HAFTA",
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 5),
                Text(t, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    v['unite'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    v['kazanim'],
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTatilKarti(Map<String, dynamic> v, String t) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.orange.shade50, Colors.white],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.orange.shade100, width: 2),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wb_sunny_rounded, size: 80, color: Colors.orange),
        const SizedBox(height: 20),
        Text(
          v['unite'],
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          t,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade800,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "İyi Tatiller! 🎈",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    ),
  );
}
