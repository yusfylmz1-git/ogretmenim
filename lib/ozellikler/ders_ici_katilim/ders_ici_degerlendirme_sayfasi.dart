import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/veri/modeller/ogrenci_model.dart';
// DİKKAT: Provider dosyanı oluşturduğun klasör yolunu kontrol et
import 'package:ogretmenim/ozellikler/ders_ici_katilim/degerlendirme_provider.dart';

class DersIciDegerlendirmeSayfasi extends ConsumerStatefulWidget {
  final OgrenciModel ogrenci;

  const DersIciDegerlendirmeSayfasi({Key? key, required this.ogrenci})
    : super(key: key);

  @override
  ConsumerState<DersIciDegerlendirmeSayfasi> createState() =>
      _DersIciDegerlendirmeSayfasiState();
}

class _DersIciDegerlendirmeSayfasiState
    extends ConsumerState<DersIciDegerlendirmeSayfasi> {
  // Varsayılan Ders (İleride ders programından otomatik çekilebilir)
  String _secilenDers = 'Matematik';
  final List<String> _dersler = [
    'Matematik',
    'Türkçe',
    'Fen Bilimleri',
    'Sosyal Bilgiler',
    'İngilizce',
    'Din Kültürü',
    'Görsel Sanatlar',
    'Müzik',
    'Beden Eğitimi',
  ];

  // Puanlar (Başlangıçta hepsi tam puan 20 olsun, öğretmen düşürsün - Psikolojik olarak daha iyidir)
  final Map<int, double> _puanlar = {
    1: 20.0, // Hazırlık
    2: 20.0, // Katılım
    3: 20.0, // Ödev
    4: 20.0, // Tutum
    5: 20.0, // Kavrama
  };

  // Kriter Listesi (Sabit Veri)
  final List<Map<String, dynamic>> _kriterListesi = [
    {'id': 1, 'baslik': 'Derse Hazırlık (Araç-Gereç)', 'icon': Icons.backpack},
    {'id': 2, 'baslik': 'Derse Katılım / Etkinlik', 'icon': Icons.front_hand},
    {'id': 3, 'baslik': 'Ödev / Sorumluluk', 'icon': Icons.assignment},
    {
      'id': 4,
      'baslik': 'Ders İçi Tutum / Davranış',
      'icon': Icons.sentiment_satisfied_alt,
    },
    {'id': 5, 'baslik': 'Konuyu Kavrama', 'icon': Icons.lightbulb},
  ];

  bool _yukleniyor = false;

  // Anlık Toplam Puan
  double get _toplamPuan => _puanlar.values.reduce((a, b) => a + b);

  // Renge Karar Ver (Puan düştükçe kızarır)
  Color get _skorRengi {
    if (_toplamPuan >= 85) return Colors.green; // Pekiyi
    if (_toplamPuan >= 70) return Colors.orange; // İyi
    return Colors.red; // Geliştirilmeli
  }

  // --- KAYDETME İŞLEMİ ---
  Future<void> _kaydet() async {
    setState(() => _yukleniyor = true);

    // Provider üzerinden kaydet (SQLite + Firebase)
    final basarili = await ref
        .read(degerlendirmeProvider.notifier)
        .puanKaydet(
          ogrenciId: widget.ogrenci.id!, // SQLite ID
          sinifId: widget.ogrenci.sinifId,
          dersAdi: _secilenDers,
          kriterPuanlari: _puanlar,
        );

    if (!mounted) return;
    setState(() => _yukleniyor = false);

    if (basarili) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Değerlendirme Başarıyla Kaydedildi!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // İş bitince listeye dön
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bir hata oluştu!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${widget.ogrenci.ad} ${widget.ogrenci.soyad}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "No: ${widget.ogrenci.numara}",
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: ProjeTemasi.anaRenk,
        actions: [
          IconButton(
            icon: _yukleniyor
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle, size: 32),
            onPressed: _yukleniyor ? null : _kaydet,
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 1. ÜST BİLGİ KARTI (Ders + Skor) ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ProjeTemasi.anaRenk,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ders Seçimi
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _secilenDers,
                      dropdownColor: ProjeTemasi.anaRenk,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      items: _dersler
                          .map(
                            (ders) => DropdownMenuItem(
                              value: ders,
                              child: Text(ders),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _secilenDers = val);
                      },
                    ),
                  ),
                ),
                // Büyük Skor
                Column(
                  children: [
                    const Text(
                      "TOPLAM",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      _toplamPuan.toInt().toString(),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: _skorRengi == Colors.red
                            ? Colors.white
                            : _skorRengi,
                        shadows: [
                          const Shadow(blurRadius: 10, color: Colors.black26),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- 2. PUANLAMA LİSTESİ (SLIDERLAR) ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _kriterListesi.length,
              itemBuilder: (context, index) {
                final kriter = _kriterListesi[index];
                final int id = kriter['id'];
                final double puan = _puanlar[id]!;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              kriter['icon'],
                              color: ProjeTemasi.anaRenk,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                kriter['baslik'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${puan.toInt()} Puan",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: ProjeTemasi.anaRenk,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _skorRengi,
                            inactiveTrackColor: Colors.grey.shade200,
                            thumbColor: _skorRengi,
                            overlayColor: _skorRengi.withOpacity(0.2),
                            trackHeight: 6.0,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8.0,
                            ),
                          ),
                          child: Slider(
                            value: puan,
                            min: 0,
                            max: 20,
                            divisions: 20, // 1'er 1'er artar
                            label: puan.toInt().toString(),
                            onChanged: (yeniDeger) {
                              setState(() {
                                _puanlar[id] = yeniDeger;
                              });
                            },
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
