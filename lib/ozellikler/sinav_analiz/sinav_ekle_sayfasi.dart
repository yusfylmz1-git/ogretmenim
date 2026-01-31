import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/veri/veritabani/veritabani_yardimcisi.dart';

class SinavEkleSayfasi extends StatefulWidget {
  final int? duzenlenecekSinavId;

  const SinavEkleSayfasi({super.key, this.duzenlenecekSinavId});

  @override
  State<SinavEkleSayfasi> createState() => _SinavEkleSayfasiState();
}

class _SinavEkleSayfasiState extends State<SinavEkleSayfasi> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _sinavAdiController = TextEditingController();
  final TextEditingController _dersAdiController = TextEditingController();
  final TextEditingController _soruSayisiController = TextEditingController(
    text: "20",
  );

  final _db = VeritabaniYardimcisi.instance;

  DateTime _secilenTarih = DateTime.now();
  String? _secilenSinif;
  String _sinavTipi = 'klasik';

  List<String> _sinifListesi = [];
  List<Map<String, dynamic>> _ogrenciListesi = [];

  final Map<int, int> _verilenNotlar = {};
  final Map<int, Map<int, double>> _soruBazliNotlar = {};

  List<double> _soruPuanlari = [];
  bool _yukleniyor = true;
  double _anlikOrtalama = 0.0;
  int? _aktifOgrenciId;

  bool get _duzenlemeModu => widget.duzenlenecekSinavId != null;

  @override
  void initState() {
    super.initState();
    _baslangicIslemleri();
  }

  Future<void> _baslangicIslemleri() async {
    await _siniflariGetir();
    if (_duzenlemeModu) {
      await _mevcutSinaviYukle();
    } else {
      _varsayilanPuanlariHesapla();
    }
  }

  Future<void> _mevcutSinaviYukle() async {
    try {
      final sinav = await _db.sinavGetirById(widget.duzenlenecekSinavId!);
      if (sinav == null) return;

      _sinavAdiController.text = sinav['sinav_adi'];
      _dersAdiController.text = sinav['ders'];
      _secilenTarih = DateTime.parse(sinav['tarih']);
      _secilenSinif = sinav['sinif'];
      _sinavTipi = sinav['sinav_tipi'] ?? 'klasik';

      if (_sinavTipi == 'soru_bazli') {
        int dbSoruSayisi = sinav['soru_sayisi'] ?? 20;
        _soruSayisiController.text = dbSoruSayisi.toString();
        String? dbPuanlar = sinav['soru_puanlari'];
        if (dbPuanlar != null && dbPuanlar.isNotEmpty) {
          _soruPuanlari = dbPuanlar
              .split(',')
              .map((e) => double.parse(e))
              .toList();
        } else {
          _varsayilanPuanlariHesapla();
        }
      }

      if (_secilenSinif != null) {
        await _ogrencileriGetir(_secilenSinif!, verileriSifirlama: false);
      }

      final kayitliNotlar = await _db.notlariGetir(widget.duzenlenecekSinavId!);
      for (var kayit in kayitliNotlar) {
        int oId = kayit['ogrenci_id'];
        if (_sinavTipi == 'klasik') {
          _verilenNotlar[oId] = kayit['notu'];
        } else {
          String? soruNotlariStr = kayit['soru_bazli_notlar'];
          if (soruNotlariStr != null && soruNotlariStr.isNotEmpty) {
            List<double> notlar = soruNotlariStr
                .split(',')
                .map((e) => double.parse(e))
                .toList();
            _soruBazliNotlar[oId] = {};
            for (int i = 0; i < notlar.length; i++) {
              _soruBazliNotlar[oId]![i] = notlar[i];
            }
          }
        }
      }
      _ortalamaGuncelle();
      setState(() {});
    } catch (e) {
      debugPrint("Veri yükleme hatası: $e");
    }
  }

  void _varsayilanPuanlariHesapla() {
    int sayi = int.tryParse(_soruSayisiController.text) ?? 20;
    if (_soruPuanlari.length != sayi) {
      if (!_duzenlemeModu || _soruPuanlari.isEmpty) {
        _soruBazliNotlar.clear();
        _ortalamaGuncelle();
      }
    }
    if (sayi > 0) {
      if (_soruPuanlari.length != sayi) {
        double puan = 100 / sayi;
        puan = double.parse(puan.toStringAsFixed(2));
        _soruPuanlari = List.generate(sayi, (index) => puan);
      }
    }
  }

  @override
  void dispose() {
    _sinavAdiController.dispose();
    _dersAdiController.dispose();
    _soruSayisiController.dispose();
    super.dispose();
  }

  Future<void> _siniflariGetir() async {
    try {
      final siniflarRaw = await _db.siniflariGetir();
      final siniflar = siniflarRaw
          .map((e) => e['sinif_adi'] as String)
          .toSet()
          .toList();
      siniflar.sort();
      if (mounted)
        setState(() {
          _sinifListesi = siniflar;
          _yukleniyor = false;
        });
    } catch (e) {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _ogrencileriGetir(
    String sinifAdi, {
    bool verileriSifirlama = true,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _yukleniyor = true);
    try {
      final tumSiniflar = await _db.siniflariGetir();
      final secilenSinifMap = tumSiniflar.firstWhere(
        (e) => e['sinif_adi'] == sinifAdi,
        orElse: () => {},
      );
      if (secilenSinifMap.isNotEmpty) {
        final ogrenciler = await _db.ogrencileriGetir(secilenSinifMap['id']);
        if (mounted) {
          setState(() {
            _ogrenciListesi = ogrenciler;
            if (verileriSifirlama) {
              _verilenNotlar.clear();
              _soruBazliNotlar.clear();
              _anlikOrtalama = 0.0;
            }
            _yukleniyor = false;
          });
        }
      } else {
        if (mounted) setState(() => _yukleniyor = false);
      }
    } catch (e) {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  void _ortalamaGuncelle() {
    if (_ogrenciListesi.isEmpty) return;
    double toplamPuan = 0;
    int puanlananOgrenci = 0;

    if (_sinavTipi == 'klasik') {
      if (_verilenNotlar.isEmpty) {
        setState(() => _anlikOrtalama = 0.0);
        return;
      }
      for (var not in _verilenNotlar.values) {
        toplamPuan += not;
      }
      puanlananOgrenci = _verilenNotlar.length;
    } else {
      if (_soruBazliNotlar.isEmpty) {
        setState(() => _anlikOrtalama = 0.0);
        return;
      }
      for (var ogrenciNotlari in _soruBazliNotlar.values) {
        double ogrenciToplam = ogrenciNotlari.values.fold(
          0,
          (sum, p) => sum + p,
        );
        toplamPuan += ogrenciToplam;
      }
      puanlananOgrenci = _soruBazliNotlar.length;
    }

    setState(() {
      _anlikOrtalama = puanlananOgrenci == 0
          ? 0.0
          : toplamPuan / puanlananOgrenci;
    });
  }

  void _hizliGirisPenceresiAc() {
    if (_ogrenciListesi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Önce bir sınıf seçmelisiniz.")),
      );
      return;
    }
    List<TextEditingController> controllers = [];
    List<FocusNode> focusNodes = [];

    for (var ogrenci in _ogrenciListesi) {
      String baslangicDegeri = "";
      if (_soruBazliNotlar.containsKey(ogrenci['id'])) {
        List<String> puanlar = [];
        for (int i = 0; i < _soruPuanlari.length; i++) {
          double p = _soruBazliNotlar[ogrenci['id']]?[i] ?? 0;
          if (p > 0)
            puanlar.add(p % 1 == 0 ? p.toInt().toString() : p.toString());
        }
        if (puanlar.isNotEmpty) baslangicDegeri = puanlar.join(" - ");
      }
      controllers.add(TextEditingController(text: baslangicDegeri));
      focusNodes.add(FocusNode());
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.amber),
                  SizedBox(width: 8),
                  Text("Hızlı Giriş"),
                ],
              ),
              Text(
                "${_soruPuanlari.length} Soru",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "💡 İPUCU: Puanı yazıp BOŞLUK tuşuna basın.",
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _ogrenciListesi.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ogrenci = _ogrenciListesi[index];
                      return TextField(
                        controller: controllers[index],
                        focusNode: focusNodes[index],
                        keyboardType: TextInputType.number,
                        // 🔥 Klavye Dostu Ayar: Sıradaki öğrenciye geç
                        textInputAction: TextInputAction.next,
                        // 🔥 Klavye Dostu Ayar: Aktif kutuyu klavyenin üstüne at
                        scrollPadding: const EdgeInsets.only(bottom: 100),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9 \-\.,]'),
                          ),
                        ],
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(
                              left: 10,
                              right: 5,
                              top: 14,
                              bottom: 14,
                            ),
                            child: Text(
                              "${index + 1}. ${ogrenci['ad']} ${ogrenci['soyad']} : ",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          hintText: "10 5...",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                        ),
                        onChanged: (val) {
                          if (val.endsWith(" ") ||
                              val.endsWith(".") ||
                              val.endsWith(",")) {
                            String temizVal = val
                                .replaceAll(RegExp(r'[.,]'), ' ')
                                .trim();
                            List<String> parcalar = temizVal.split(
                              RegExp(r'[ -]+'),
                            );
                            List<String> validPuanlar = [];
                            for (int i = 0; i < parcalar.length; i++) {
                              if (i >= _soruPuanlari.length) break;
                              double p = double.tryParse(parcalar[i]) ?? 0;
                              if (p > _soruPuanlari[i]) p = _soruPuanlari[i];
                              validPuanlar.add(
                                p % 1 == 0
                                    ? p.toInt().toString()
                                    : p.toString(),
                              );
                            }
                            String yeniMetin = validPuanlar.join(" - ");
                            if (validPuanlar.length < _soruPuanlari.length)
                              yeniMetin += " - ";
                            if (controllers[index].text != yeniMetin) {
                              controllers[index].value = TextEditingValue(
                                text: yeniMetin,
                                selection: TextSelection.fromPosition(
                                  TextPosition(offset: yeniMetin.length),
                                ),
                              );
                            }
                            if (validPuanlar.length == _soruPuanlari.length) {
                              if (index < _ogrenciListesi.length - 1) {
                                focusNodes[index + 1].requestFocus();
                              } else {
                                focusNodes[index].unfocus();
                              }
                            }
                          } else {
                            String sonParca = val.split(RegExp(r'[ -]+')).last;
                            if (sonParca.length > 3) {
                              String duzeltilmis = val.substring(
                                0,
                                val.length - 1,
                              );
                              controllers[index].value = TextEditingValue(
                                text: duzeltilmis,
                                selection: TextSelection.fromPosition(
                                  TextPosition(offset: duzeltilmis.length),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                _hizliGirisKaydet(controllers);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: const Text("Uygula"),
            ),
          ],
        );
      },
    );
  }

  void _hizliGirisKaydet(List<TextEditingController> controllers) {
    int islenen = 0;
    for (int i = 0; i < _ogrenciListesi.length; i++) {
      String text = controllers[i].text.trim();
      if (text.isEmpty) continue;
      List<String> parcalar = text.split(RegExp(r'[ -]+'));
      int oId = _ogrenciListesi[i]['id'];
      if (!_soruBazliNotlar.containsKey(oId)) _soruBazliNotlar[oId] = {};
      for (int j = 0; j < parcalar.length; j++) {
        if (j >= _soruPuanlari.length) break;
        double? puan = double.tryParse(parcalar[j]);
        if (puan != null) {
          if (puan > _soruPuanlari[j]) puan = _soruPuanlari[j];
          _soruBazliNotlar[oId]![j] = puan;
        }
      }
      islenen++;
    }
    _ortalamaGuncelle();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ $islenen öğrencinin notları aktarıldı."),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _puanlamaPenceresiniAc() {
    int girilenSayi = int.tryParse(_soruSayisiController.text) ?? 0;
    if (girilenSayi <= 0) return;
    if (_soruPuanlari.length != girilenSayi) {
      double esitPuan = 100 / girilenSayi;
      esitPuan = double.parse(esitPuan.toStringAsFixed(2));
      _soruPuanlari = List.generate(girilenSayi, (index) => esitPuan);
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double toplam = _soruPuanlari.fold(0, (sum, item) => sum + item);
            bool toplamYuzMu = (toplam - 100).abs() < 0.5;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Soru Puanlarını Tanımla",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: toplamYuzMu
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Toplam:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${toplam.toStringAsFixed(1)} / 100",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: toplamYuzMu ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        separatorBuilder: (c, i) => const SizedBox(height: 8),
                        itemCount: _soruPuanlari.length,
                        itemBuilder: (context, index) {
                          return Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  initialValue: _soruPuanlari[index].toString(),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  // 🔥 MODAL İÇİNDE DE KAYDIRMA AYARI
                                  scrollPadding: const EdgeInsets.only(
                                    bottom: 120,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: "Puan",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 0,
                                    ),
                                  ),
                                  onChanged: (val) {
                                    double? yeniPuan = double.tryParse(
                                      val.replaceAll(',', '.'),
                                    );
                                    if (yeniPuan != null) {
                                      _soruPuanlari[index] = yeniPuan;
                                      setDialogState(() {});
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: toplamYuzMu
                      ? () {
                          Navigator.pop(context);
                          setState(() {});
                        }
                      : null,
                  child: const Text("Kaydet"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    if (_secilenSinif == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lütfen bir sınıf seçiniz")));
      return;
    }
    int soruSayisi = 0;
    String soruPuanlariString = "";
    List<Map<String, dynamic>> hazirlananNotlar = [];

    if (_sinavTipi == 'soru_bazli') {
      soruSayisi = int.tryParse(_soruSayisiController.text) ?? 0;
      if (soruSayisi <= 0) return;
      if (_soruPuanlari.length != soruSayisi) _varsayilanPuanlariHesapla();
      soruPuanlariString = _soruPuanlari.join(',');

      for (var ogrenci in _ogrenciListesi) {
        final oId = ogrenci['id'];
        if (_soruBazliNotlar.containsKey(oId)) {
          List<double> puanlar = [];
          double toplamOgrenciPuan = 0;
          for (int i = 0; i < soruSayisi; i++) {
            double p = _soruBazliNotlar[oId]?[i] ?? 0.0;
            puanlar.add(p);
            toplamOgrenciPuan += p;
          }
          hazirlananNotlar.add({
            'ogrenci_id': oId,
            'ogrenci_ad_soyad': "${ogrenci['ad']} ${ogrenci['soyad']}",
            'notu': toplamOgrenciPuan.round(),
            'toplam_not': toplamOgrenciPuan,
            'soru_bazli_notlar': puanlar.join(','),
          });
        }
      }
    } else {
      for (var ogrenci in _ogrenciListesi) {
        final oId = ogrenci['id'];
        if (_verilenNotlar.containsKey(oId)) {
          hazirlananNotlar.add({
            'ogrenci_id': oId,
            'ogrenci_ad_soyad': "${ogrenci['ad']} ${ogrenci['soyad']}",
            'notu': _verilenNotlar[oId],
            'toplam_not': _verilenNotlar[oId],
          });
        }
      }
    }

    if (hazirlananNotlar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen en az 1 öğrenciye not giriniz.")),
      );
      return;
    }

    setState(() => _yukleniyor = true);
    try {
      final sinavMap = {
        'sinav_adi': _sinavAdiController.text,
        'sinif': _secilenSinif,
        'ders': _dersAdiController.text,
        'tarih': _secilenTarih.toIso8601String(),
        'ortalama': _anlikOrtalama,
        'not_sayisi': hazirlananNotlar.length,
        'sinav_tipi': _sinavTipi,
        'soru_sayisi': soruSayisi,
        'soru_puanlari': soruPuanlariString,
      };

      if (_duzenlemeModu) {
        await _db.sinavGuncelle(
          sinavId: widget.duzenlenecekSinavId!,
          sinavBilgileri: sinavMap,
          yeniNotlar: hazirlananNotlar,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Sınav güncellendi!"),
              backgroundColor: Colors.blue,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        await _db.sinavVeNotlariTopluKaydet(
          sinavMap: sinavMap,
          notlarListesi: hazirlananNotlar,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Kaydedildi!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _tarihSec() async {
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: _secilenTarih,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'),
    );
    if (secilen != null) setState(() => _secilenTarih = secilen);
  }

  // --- 🔥 GÜZELLEŞTİRİLMİŞ WIDGET'LAR ---

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ProjeTemasi.anaRenk, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _buildModernDropdown() {
    return DropdownButtonFormField<String>(
      value: _secilenSinif,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: "Sınıf",
        prefixIcon: Icon(Icons.class_outlined, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: _sinifListesi
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() => _secilenSinif = val);
          _ogrencileriGetir(val);
        }
      },
    );
  }

  Widget _buildModernDatePicker() {
    return InkWell(
      onTap: _tarihSec,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              DateFormat('d MMM yyyy', 'tr_TR').format(_secilenTarih),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipSeciciButon(String baslik, String deger) {
    bool secili = _sinavTipi == deger;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _sinavTipi = deger;
            _verilenNotlar.clear();
            _soruBazliNotlar.clear();
            _anlikOrtalama = 0.0;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: secili ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: secili
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            baslik,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: secili
                  ? (deger == 'klasik'
                        ? Colors.blue.shade700
                        : Colors.purple.shade700)
                  : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProjeTemasi.arkaPlan,
      resizeToAvoidBottomInset: true, // Klavye açılınca yukarı iter
      body: Stack(
        children: [
          // 1. ÜST GRADYAN
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: ProjeTemasi.gradyanRenkleri,
              ),
            ),
          ),

          // 2. İÇERİK
          SafeArea(
            child: Column(
              children: [
                // Başlık
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF1E293B),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _duzenlemeModu
                            ? "Sınavı Düzenle ✏️"
                            : "Sınav Oluştur 📝",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 5),

                // Beyaz Kutu
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      child: _yukleniyor
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                              padding: const EdgeInsets.all(20),
                              children: [
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildModernTextField(
                                        controller: _sinavAdiController,
                                        label: "Sınav Başlığı",
                                        icon: Icons.title,
                                        validator: (v) => v!.isEmpty
                                            ? "Başlık giriniz"
                                            : null,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildModernTextField(
                                        controller: _dersAdiController,
                                        label: "Ders Adı",
                                        icon: Icons.book,
                                        validator: (v) => v!.isEmpty
                                            ? "Ders adı giriniz"
                                            : null,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildModernDropdown(),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildModernDatePicker(),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 20),
                                      const Divider(),
                                      const SizedBox(height: 10),

                                      // Sınav Tipi Seçici
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            _buildTipSeciciButon(
                                              "Klasik",
                                              'klasik',
                                            ),
                                            _buildTipSeciciButon(
                                              "Soru Bazlı",
                                              'soru_bazli',
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Soru Bazlı Ekstralar
                                      if (_sinavTipi == 'soru_bazli') ...[
                                        const SizedBox(height: 15),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildModernTextField(
                                                controller:
                                                    _soruSayisiController,
                                                label: "Soru Sayısı",
                                                icon: Icons.numbers,
                                                type: TextInputType.number,
                                                onChanged: (val) =>
                                                    _varsayilanPuanlariHesapla(),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed:
                                                    _puanlamaPenceresiniAc,
                                                icon: const Icon(
                                                  Icons.settings,
                                                  size: 18,
                                                ),
                                                label: const Text(
                                                  "Puanları\nTanımla",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.deepPurple,
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  elevation: 0,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],

                                      const SizedBox(height: 25),

                                      // Öğrenci Listesi Başlığı
                                      if (_secilenSinif != null) ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              "Öğrenci Notları",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (_sinavTipi == 'soru_bazli')
                                              TextButton.icon(
                                                onPressed:
                                                    _hizliGirisPenceresiAc,
                                                icon: const Icon(
                                                  Icons.flash_on,
                                                  size: 18,
                                                  color: Colors.amber,
                                                ),
                                                label: const Text(
                                                  "Hızlı Giriş",
                                                  style: TextStyle(
                                                    color: Colors.amber,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                style: TextButton.styleFrom(
                                                  backgroundColor: Colors.amber
                                                      .withOpacity(0.1),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.blue.shade100,
                                              ),
                                            ),
                                            child: Text(
                                              "Sınıf Ortalaması: ${_anlikOrtalama.toStringAsFixed(1)}",
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 15),

                                        _ogrenciListesi.isEmpty
                                            ? const Padding(
                                                padding: EdgeInsets.all(20),
                                                child: Center(
                                                  child: Text(
                                                    "Sınıfta öğrenci yok.",
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : ListView.separated(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemCount:
                                                    _ogrenciListesi.length,
                                                separatorBuilder: (c, i) =>
                                                    const SizedBox(height: 12),
                                                itemBuilder: (context, index) {
                                                  if (_sinavTipi == 'klasik')
                                                    return _buildKlasikOgrenciSatiri(
                                                      _ogrenciListesi[index],
                                                    );
                                                  return _buildSoruBazliOgrenciKarti(
                                                    _ogrenciListesi[index],
                                                  );
                                                },
                                              ),
                                      ] else ...[
                                        const Padding(
                                          padding: EdgeInsets.all(40),
                                          child: Center(
                                            child: Text(
                                              "Öğrencileri görmek için sınıf seçiniz 👆",
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],

                                      // 🔥 YENİ EKLENEN: LİSTE SONU BOŞLUĞU (Klavye payı)
                                      const SizedBox(height: 300),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 10),
        child: FloatingActionButton.extended(
          onPressed: _kaydet,
          label: Text(
            _duzenlemeModu ? "GÜNCELLE" : "ANALİZİ KAYDET",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          icon: Icon(
            _duzenlemeModu ? Icons.update : Icons.save,
            color: Colors.white,
          ),
          backgroundColor: _duzenlemeModu
              ? Colors.blue
              : const Color(0xFF10B981),
          elevation: 6,
        ),
      ),
    );
  }

  // --- KART TASARIMLARI (PREMIUM + KLAVYE DOSTU) ---

  Widget _buildKlasikOgrenciSatiri(Map<String, dynamic> ogrenci) {
    final int oId = ogrenci['id'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade50,
            child: Text(
              "${ogrenci['numara']}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "${ogrenci['ad']} ${ogrenci['soyad']}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          SizedBox(
            width: 70,
            child: TextFormField(
              key: ValueKey(oId),
              initialValue: _verilenNotlar[oId]?.toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 3,
              // 🔥 KLAVYE ÇÖZÜMÜ: Inputu yukarı it
              scrollPadding: const EdgeInsets.only(bottom: 150),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: "",
                hintText: "-",
                filled: true,
                fillColor: Colors.blue.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              onChanged: (val) {
                if (val.isNotEmpty) {
                  final not = int.tryParse(val);
                  if (not != null && not <= 100) _verilenNotlar[oId] = not;
                } else {
                  _verilenNotlar.remove(oId);
                }
                _ortalamaGuncelle();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoruBazliOgrenciKarti(Map<String, dynamic> ogrenci) {
    final int oId = ogrenci['id'];
    bool kartAcik = _aktifOgrenciId == oId;
    double toplamPuan = 0;
    if (_soruBazliNotlar.containsKey(oId)) {
      toplamPuan = _soruBazliNotlar[oId]!.values.fold(
        0,
        (sum, item) => sum + item,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kartAcik ? Colors.purple.shade200 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _aktifOgrenciId = _aktifOgrenciId == oId ? null : oId;
              });
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: Colors.purple.shade50,
              child: Text(
                "${ogrenci['numara']}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.purple,
                ),
              ),
            ),
            title: Text(
              "${ogrenci['ad']} ${ogrenci['soyad']}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: toplamPuan > 0 ? Colors.green : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    toplamPuan.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  kartAcik
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          if (kartAcik)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.2,
                ),
                itemCount: _soruPuanlari.length,
                itemBuilder: (context, index) {
                  double maxPuan = _soruPuanlari[index];
                  double mevcutPuan = _soruBazliNotlar[oId]?[index] ?? 0.0;
                  bool tamPuanMi = mevcutPuan == maxPuan;
                  bool sifirMi = mevcutPuan == 0;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (!_soruBazliNotlar.containsKey(oId))
                          _soruBazliNotlar[oId] = {};
                        _soruBazliNotlar[oId]![index] = tamPuanMi ? 0 : maxPuan;
                        _ortalamaGuncelle();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: tamPuanMi
                            ? Colors.green.shade100
                            : (sifirMi ? Colors.white : Colors.orange.shade100),
                        border: Border.all(
                          color: tamPuanMi
                              ? Colors.green
                              : (sifirMi
                                    ? Colors.grey.shade300
                                    : Colors.orange),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "S${index + 1}",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            mevcutPuan % 1 == 0
                                ? mevcutPuan.toInt().toString()
                                : mevcutPuan.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: tamPuanMi
                                  ? Colors.green.shade800
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
