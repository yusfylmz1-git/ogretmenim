import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/veri/modeller/sinav_analiz.dart';
import 'package:ogretmenim/veri/veritabani/veritabani_yardimcisi.dart';
import 'package:ogretmenim/ozellikler/sinav_analiz/sinav_ekle_sayfasi.dart';
import 'package:ogretmenim/ozellikler/sinav_analiz/sinav_detay_sayfasi.dart';

// 🔥 PDF KÜTÜPHANELERİ
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SinavAnalizSayfasi extends StatefulWidget {
  const SinavAnalizSayfasi({super.key});

  @override
  State<SinavAnalizSayfasi> createState() => _SinavAnalizSayfasiState();
}

class _SinavAnalizSayfasiState extends State<SinavAnalizSayfasi> {
  List<SinavAnaliz> _sinavlar = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  static List<SinavAnaliz> _verileriDonustur(
    List<Map<String, dynamic>> hamVeriler,
  ) {
    final List<SinavAnaliz> sonuc = [];
    for (var veri in hamVeriler) {
      try {
        sonuc.add(SinavAnaliz.fromMap(veri));
      } catch (e) {
        debugPrint("❌ Veri dönüştürme hatası: $e");
      }
    }
    return sonuc;
  }

  Future<void> _verileriYukle() async {
    if (!mounted) return;
    setState(() => _yukleniyor = true);

    try {
      final List<Map<String, dynamic>> hamVeriler = await VeritabaniYardimcisi
          .instance
          .sinavlariGetir();

      if (!mounted) return;

      if (hamVeriler.isEmpty) {
        setState(() {
          _sinavlar = [];
          _yukleniyor = false;
        });
        return;
      }

      List<SinavAnaliz> donusturulmusVeriler;
      if (hamVeriler.length > 20) {
        donusturulmusVeriler = await compute(_verileriDonustur, hamVeriler);
      } else {
        donusturulmusVeriler = _verileriDonustur(hamVeriler);
      }

      if (!mounted) return;
      setState(() {
        _sinavlar = donusturulmusVeriler;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _yukleniyor = false);
      debugPrint("Hata: $e");
    }
  }

  Future<void> _sil(int id) async {
    await VeritabaniYardimcisi.instance.sinavSil(id);
    if (!mounted) return;
    setState(() {
      _sinavlar.removeWhere((element) => element.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Sınav silindi"),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _yeniSinavEkle() async {
    final sonuc = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const SinavEkleSayfasi()),
    );

    if (sonuc == true && mounted) {
      await _verileriYukle();
    }
  }

  void _detayaGit(SinavAnaliz sinav) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SinavDetaySayfasi(sinav: sinav)),
    );
  }

  void _duzenle(SinavAnaliz sinav) async {
    final sonuc = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SinavEkleSayfasi(duzenlenecekSinavId: sinav.id),
      ),
    );

    if (sonuc == true && mounted) {
      await _verileriYukle();
    }
  }

  // --- 🔥 GÖRSELDEKİ GİBİ PROFESYONEL PDF MOTORU ---
  Future<void> _pdfIslemiYap(SinavAnaliz sinav, {required bool paylas}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final notlar = await VeritabaniYardimcisi.instance.notlariGetir(
        sinav.id!,
      );

      // Profil Bilgileri
      String okulAdi =
          await VeritabaniYardimcisi.instance.ayarGetir('okul_adi') ??
          "OKUL ADI";
      String ogretmenAdi =
          await VeritabaniYardimcisi.instance.ayarGetir('ogretmen_adi') ??
          "Öğretmen";
      String tarihBugun = DateFormat('d.MM.yyyy').format(DateTime.now());

      // KONTROL: Sınav Tipi
      bool soruBazliMi =
          sinav.sinavTipi == 'soru_bazli' && sinav.soruPuanlari != null;

      // --- İSTATİSTİK HESAPLAMA ---
      double toplam = 0;
      int max = 0;
      int min = 100;
      int gecenler = 0;
      // Not Aralıkları: 0-24, 25-44, 45-69, 70-84, 85-100
      List<int> dagilim = [0, 0, 0, 0, 0];

      for (var kayit in notlar) {
        int not = int.tryParse(kayit['notu'].toString()) ?? 0;
        toplam += not;
        if (not > max) max = not;
        if (not < min) min = not;
        if (not >= 50) gecenler++;

        // Dağılım Hesapla (Görseldeki aralıklara göre)
        if (not < 25)
          dagilim[0]++;
        else if (not < 45)
          dagilim[1]++;
        else if (not < 70)
          dagilim[2]++;
        else if (not < 85)
          dagilim[3]++;
        else
          dagilim[4]++;
      }

      int basariOrani = notlar.isEmpty
          ? 0
          : ((gecenler / notlar.length) * 100).toInt();
      double ortalama = notlar.isEmpty ? 0 : toplam / notlar.length;

      // Sıralama
      List<Map<String, dynamic>> siraliNotlar = List.from(notlar);
      siraliNotlar.sort((a, b) {
        int no1 = int.tryParse(a['numara'].toString()) ?? 0;
        int no2 = int.tryParse(b['numara'].toString()) ?? 0;
        return no1.compareTo(no2);
      });

      // --- PDF OLUŞTURMA ---
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),

          // HEADER: Okul Adı
          header: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Text(
                  okulAdi.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  "SINAV ANALİZ RAPORU",
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  sinav.sinavAdi.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),
              ],
            );
          },

          footer: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Rapor Tarihi: $tarihBugun",
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      "Öğretmen: $ogretmenAdi",
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      "Sayfa ${context.pageNumber} / ${context.pagesCount}",
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ],
            );
          },

          build: (pw.Context context) {
            return [
              // 1. SINAV BİLGİLERİ KUTUSU (Görseldeki gibi)
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(5),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Sınav Bilgileri",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Divider(color: PdfColors.grey300),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "Sınıf: ${sinav.sinif}",
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                            pw.Text(
                              "Tarih: ${DateFormat('d.MM.yyyy').format(sinav.tarih)}",
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "Ders: ${sinav.ders}",
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                            pw.Text(
                              "Toplam Puan: 100",
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              // 2. İSTATİSTİKLER KUTUSU (Renkli Başlıklar)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(5),
                  ),
                  border: pw.Border.all(color: PdfColors.blue100),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _statItemRenkli(
                      "Toplam Öğrenci",
                      "${notlar.length}",
                      PdfColors.blue700,
                    ),
                    _statItemRenkli(
                      "Ortalama",
                      ortalama.toStringAsFixed(2),
                      PdfColors.green700,
                    ),
                    _statItemRenkli(
                      "Başarı Oranı",
                      "%$basariOrani",
                      PdfColors.orange700,
                    ),
                    _statItemRenkli("En Yüksek", "$max", PdfColors.blue900),
                    _statItemRenkli("En Düşük", "$min", PdfColors.red700),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // 3. NOT DAĞILIMI TABLOSU (Görseldeki aralıklarla)
              pw.Text(
                "Not Dağılımı",
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Table.fromTextArray(
                headers: ['Not Aralığı', 'Öğrenci Sayısı', 'Yüzde'],
                data: [
                  [
                    '0-24',
                    '${dagilim[0]}',
                    notlar.isEmpty
                        ? '%0'
                        : '%${(dagilim[0] / notlar.length * 100).toStringAsFixed(1)}',
                  ],
                  [
                    '25-44',
                    '${dagilim[1]}',
                    notlar.isEmpty
                        ? '%0'
                        : '%${(dagilim[1] / notlar.length * 100).toStringAsFixed(1)}',
                  ],
                  [
                    '45-69',
                    '${dagilim[2]}',
                    notlar.isEmpty
                        ? '%0'
                        : '%${(dagilim[2] / notlar.length * 100).toStringAsFixed(1)}',
                  ],
                  [
                    '70-84',
                    '${dagilim[3]}',
                    notlar.isEmpty
                        ? '%0'
                        : '%${(dagilim[3] / notlar.length * 100).toStringAsFixed(1)}',
                  ],
                  [
                    '85-100',
                    '${dagilim[4]}',
                    notlar.isEmpty
                        ? '%0'
                        : '%${(dagilim[4] / notlar.length * 100).toStringAsFixed(1)}',
                  ],
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey700,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.center,
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // 4. DETAYLI ANALİZ TABLOSU (Duruma Göre Değişir)
              if (soruBazliMi) ...[
                pw.Text(
                  "Soru Bazlı Analiz",
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                _buildSoruTablosu(sinav, notlar, siraliNotlar),
              ] else ...[
                pw.Text(
                  "Öğrenci Not Listesi",
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                _buildKlasikTablo(siraliNotlar),
              ],
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      if (mounted) Navigator.pop(context);

      if (paylas) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: '${sinav.sinavAdi}_Rapor.pdf',
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: sinav.sinavAdi,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("PDF Hatası: $e");
    }
  }

  // --- YARDIMCI PDF WIDGETLARI ---

  pw.Widget _statItemRenkli(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _buildSoruTablosu(
    SinavAnaliz sinav,
    List<Map<String, dynamic>> notlar,
    List<Map<String, dynamic>> siraliNotlar,
  ) {
    List<String> puanlarStr = sinav.soruPuanlari!.split(',');
    int soruSayisi = puanlarStr.length;

    // 1. Tablo: Her sorunun analizi (Zorluk, Başarı vb.) - GÖRSELDEKİ ÜST TABLO
    // Bunu hesaplamak biraz uzun ama görseldeki gibi yapmak için gerekli
    List<List<String>> soruAnalizData = [];
    List<double> maxPuanlar = puanlarStr
        .map((e) => double.tryParse(e) ?? 0)
        .toList();
    List<double> soruToplamPuanlari = List.filled(soruSayisi, 0.0);

    for (var ogrenci in notlar) {
      String? detay = ogrenci['soru_bazli_notlar'];
      if (detay != null && detay.isNotEmpty) {
        List<double> ogrPuanlari = detay
            .split(',')
            .map((e) => double.tryParse(e) ?? 0)
            .toList();
        for (int i = 0; i < ogrPuanlari.length; i++) {
          if (i < soruSayisi) soruToplamPuanlari[i] += ogrPuanlari[i];
        }
      }
    }

    for (int i = 0; i < soruSayisi; i++) {
      double sinifOrt = notlar.isNotEmpty
          ? soruToplamPuanlari[i] / notlar.length
          : 0;
      double basari = (notlar.isNotEmpty && maxPuanlar[i] > 0)
          ? (sinifOrt / maxPuanlar[i] * 100)
          : 0;
      String zorluk = basari < 40 ? "Zor" : (basari < 70 ? "Orta" : "Kolay");

      soruAnalizData.add([
        "${i + 1}",
        maxPuanlar[i].toStringAsFixed(1),
        sinifOrt.toStringAsFixed(2),
        "%${basari.toStringAsFixed(1)}",
        zorluk,
      ]);
    }

    // 2. Tablo: Öğrenci bazlı detaylar - GÖRSELDEKİ ALT TABLO
    List<String> headersOgrenci = ['No', 'Adı Soyadı'];
    for (int i = 1; i <= soruSayisi; i++) headersOgrenci.add('S$i');
    headersOgrenci.add('TOPLAM');

    List<List<String>> dataOgrenci = [];
    for (var ogrenci in siraliNotlar) {
      List<String> satir = [
        (ogrenci['numara'] ?? '').toString(),
        ogrenci['ogrenci_ad_soyad'],
      ];
      String? detay = ogrenci['soru_bazli_notlar'];
      if (detay != null && detay.isNotEmpty) {
        List<String> p = detay.split(',');
        for (int k = 0; k < soruSayisi; k++) {
          if (k < p.length) {
            double val = double.tryParse(p[k]) ?? 0;
            satir.add(
              val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1),
            );
          } else {
            satir.add("-");
          }
        }
      } else {
        for (int k = 0; k < soruSayisi; k++) satir.add("-");
      }
      satir.add(ogrenci['notu'].toString());
      dataOgrenci.add(satir);
    }

    return pw.Column(
      children: [
        // Soru Analiz Tablosu
        pw.Table.fromTextArray(
          headers: ['Soru', 'Max Puan', 'Ortalama', 'Başarı %', 'Zorluk'],
          data: soruAnalizData,
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 8,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignment: pw.Alignment.center,
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          "Öğrenci Detayları",
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        // Öğrenci Detay Tablosu
        pw.Table.fromTextArray(
          headers: headersOgrenci,
          data: dataOgrenci,
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 8,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignment: pw.Alignment.center,
          cellAlignments: {1: pw.Alignment.centerLeft},
        ),
      ],
    );
  }

  pw.Widget _buildKlasikTablo(List<Map<String, dynamic>> siraliNotlar) {
    return pw.Table.fromTextArray(
      headers: ['Sıra', 'Numara', 'Adı Soyadı', 'Puan'],
      data: List<List<dynamic>>.generate(
        siraliNotlar.length,
        (index) => [
          (index + 1).toString(),
          siraliNotlar[index]['numara'] ?? '-',
          siraliNotlar[index]['ogrenci_ad_soyad'],
          siraliNotlar[index]['notu'].toString(),
        ],
      ),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {0: pw.Alignment.center, 3: pw.Alignment.center},
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProjeTemasi.arkaPlan,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: ProjeTemasi.gradyanRenkleri,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFF1E293B),
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Analizler",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ProjeTemasi.anaRenk.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: ProjeTemasi.anaRenk.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          "${_sinavlar.length}",
                          style: TextStyle(
                            color: ProjeTemasi.anaRenk,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
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
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF10B981),
                              ),
                            )
                          : _sinavlar.isEmpty
                          ? _bosDurum()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                20,
                                16,
                                100,
                              ),
                              itemCount: _sinavlar.length,
                              physics: const BouncingScrollPhysics(),
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                return _buildMinimalSinavKarti(
                                  _sinavlar[index],
                                );
                              },
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
          onPressed: _yeniSinavEkle,
          label: const Text(
            "Yeni Analiz",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
          backgroundColor: const Color(0xFF10B981),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildMinimalSinavKarti(SinavAnaliz sinav) {
    final bool soruBazli = sinav.sinavTipi == 'soru_bazli';
    String tarihText = "-";
    try {
      tarihText = DateFormat('d MMM', 'tr_TR').format(sinav.tarih);
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 12, right: 0),
        visualDensity: VisualDensity.compact,
        dense: true,
        onTap: () => _detayaGit(sinav),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: soruBazli
              ? Colors.purple.shade50
              : Colors.blue.shade50,
          child: Icon(
            soruBazli ? Icons.checklist_rtl : Icons.analytics_rounded,
            color: soruBazli ? Colors.purple : Colors.blue,
            size: 18,
          ),
        ),
        title: Text(
          sinav.sinavAdi,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF1E293B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          "${sinav.sinif} • ${sinav.ders} • $tarihText",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                sinav.ortalama > 0 ? sinav.ortalama.toStringAsFixed(1) : "-",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.green,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Colors.grey.shade600,
                size: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'duzenle':
                    _duzenle(sinav);
                    break;
                  case 'paylas':
                    _pdfIslemiYap(sinav, paylas: true);
                    break;
                  case 'pdf':
                    _pdfIslemiYap(sinav, paylas: false);
                    break;
                  case 'sil':
                    _sil(sinav.id!);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'duzenle',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue, size: 20),
                      SizedBox(width: 10),
                      Text('Düzenle'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'paylas',
                  child: Row(
                    children: [
                      Icon(Icons.share, color: Colors.orange, size: 20),
                      SizedBox(width: 10),
                      Text('Paylaş'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.green, size: 20),
                      SizedBox(width: 10),
                      Text('PDF Rapor'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'sil',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      SizedBox(width: 10),
                      Text('Sil', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bosDurum() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Henüz sınav eklenmemiş",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Aşağıdaki + butonuna basarak\nilk sınavını oluşturabilirsin.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
