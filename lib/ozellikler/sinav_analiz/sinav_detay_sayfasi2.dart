import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/veri/modeller/sinav_analiz.dart'; // Model eklendi
import 'package:ogretmenim/veri/veritabani/veritabani_yardimcisi.dart';

// 🔥 PDF KÜTÜPHANELERİ
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// --- Veri Modeli ---
class SoruIstatistikModel {
  final int soruNo;
  final double maxPuan;
  final double sinifOrtalamasi;
  final double basariYuzdesi;
  final double enDusukPuan;
  final double enYuksekPuan;
  final int sifirAlanSayisi;

  SoruIstatistikModel({
    required this.soruNo,
    required this.maxPuan,
    required this.sinifOrtalamasi,
    required this.basariYuzdesi,
    required this.enDusukPuan,
    required this.enYuksekPuan,
    required this.sifirAlanSayisi,
  });

  String get zorlukDerecesi {
    if (basariYuzdesi < 40) return "Zor";
    if (basariYuzdesi < 70) return "Orta";
    return "Kolay";
  }

  Color get zorlukRengi {
    if (basariYuzdesi < 40) return Colors.red;
    if (basariYuzdesi < 70) return Colors.amber.shade700;
    return Colors.green;
  }
}

enum SiralamaTipi { numarasi, enZor, enYuksekPuan }

class SinavDetaySayfasi2 extends StatefulWidget {
  final SinavAnaliz
  sinav; // 🔥 ARTIK TÜM NESNEYİ ALIYORUZ (Sınıf, Ders, Tarih için)
  final List<Map<String, dynamic>> notlar;

  const SinavDetaySayfasi2({
    super.key,
    required this.sinav,
    required this.notlar,
  });

  @override
  State<SinavDetaySayfasi2> createState() => _SinavDetaySayfasi2State();
}

class _SinavDetaySayfasi2State extends State<SinavDetaySayfasi2> {
  List<SoruIstatistikModel> _soruListesi = [];
  SiralamaTipi _aktifSiralama = SiralamaTipi.numarasi;

  @override
  void initState() {
    super.initState();
    _verileriHesaplaVeIsle();
  }

  void _verileriHesaplaVeIsle() {
    // Soru puanlarını sınav nesnesinden alıyoruz
    List<String> puanlarParcali = (widget.sinav.soruPuanlari ?? "").split(',');
    List<double> maxPuanlar = puanlarParcali
        .map((e) => double.tryParse(e) ?? 0)
        .toList();
    int soruSayisi = maxPuanlar.length;
    int ogrenciSayisi = widget.notlar.length;

    List<SoruIstatistikModel> tempListe = [];

    for (int i = 0; i < soruSayisi; i++) {
      double toplamPuan = 0;
      double min = 9999;
      double max = -1;
      int sifirSayisi = 0;

      for (var ogrenci in widget.notlar) {
        String? detay = ogrenci['soru_bazli_notlar'];
        if (detay != null && detay.isNotEmpty) {
          List<String> notlar = detay.split(',');
          if (i < notlar.length) {
            double not = double.tryParse(notlar[i]) ?? 0;
            toplamPuan += not;

            if (not < min) min = not;
            if (not > max) max = not;
            if (not == 0) sifirSayisi++;
          }
        }
      }

      if (ogrenciSayisi == 0) {
        min = 0;
        max = 0;
      }
      if (min == 9999) min = 0;

      double ortalama = ogrenciSayisi > 0 ? toplamPuan / ogrenciSayisi : 0;
      double basari = (maxPuanlar[i] > 0)
          ? (ortalama / maxPuanlar[i] * 100)
          : 0;

      tempListe.add(
        SoruIstatistikModel(
          soruNo: i + 1,
          maxPuan: maxPuanlar[i],
          sinifOrtalamasi: ortalama,
          basariYuzdesi: basari,
          enDusukPuan: min,
          enYuksekPuan: max,
          sifirAlanSayisi: sifirSayisi,
        ),
      );
    }

    setState(() {
      _soruListesi = tempListe;
      _listeyiSirala(_aktifSiralama);
    });
  }

  void _listeyiSirala(SiralamaTipi tip) {
    setState(() {
      _aktifSiralama = tip;
      switch (tip) {
        case SiralamaTipi.numarasi:
          _soruListesi.sort((a, b) => a.soruNo.compareTo(b.soruNo));
          break;
        case SiralamaTipi.enZor:
          _soruListesi.sort(
            (a, b) => a.basariYuzdesi.compareTo(b.basariYuzdesi),
          );
          break;
        case SiralamaTipi.enYuksekPuan:
          _soruListesi.sort((a, b) => b.maxPuan.compareTo(a.maxPuan));
          break;
      }
    });
  }

  // --- 🔥 TAM KAPSAMLI PDF RAPORU (RESİMDEKİ GİBİ) ---
  Future<void> _pdfRaporuOlustur() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final db = VeritabaniYardimcisi.instance;
      String okulAdi = await db.ayarGetir('okul_adi') ?? "OKUL ADI";
      String ogretmenAdi = await db.ayarGetir('ogretmen_adi') ?? "Öğretmen";
      String brans = await db.ayarGetir('brans') ?? "Branş";
      String tarihBugun = DateFormat('d.MM.yyyy').format(DateTime.now());

      // Genel İstatistik Hesapla
      double toplamPuan = 0;
      int maxNot = 0;
      int minNot = 100;
      int gecenler = 0;
      List<int> dagilim = [0, 0, 0, 0, 0]; // 0-24, 25-44, 45-69, 70-84, 85-100

      for (var kayit in widget.notlar) {
        int not = int.tryParse(kayit['notu'].toString()) ?? 0;
        toplamPuan += not;
        if (not > maxNot) maxNot = not;
        if (not < minNot) minNot = not;
        if (not >= 50) gecenler++;

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

      int ogrSayisi = widget.notlar.length;
      double genelOrtalama = ogrSayisi > 0 ? toplamPuan / ogrSayisi : 0;
      int basariOrani = ogrSayisi > 0
          ? ((gecenler / ogrSayisi) * 100).toInt()
          : 0;

      final pdf = pw.Document();
      final font = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          // HEADER
          header: (context) => pw.Column(
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
                "SORU BAZLI",
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Divider(),
            ],
          ),
          footer: (context) => pw.Column(
            children: [
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(tarihBugun, style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    "$ogretmenAdi - $brans",
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    "Sayfa ${context.pageNumber} / ${context.pagesCount}",
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
          build: (context) {
            // Soru Listesini Numaraya Göre Sırala (Tablo için)
            final siraliSoruListesi = List<SoruIstatistikModel>.from(
              _soruListesi,
            );
            siraliSoruListesi.sort((a, b) => a.soruNo.compareTo(b.soruNo));

            // Öğrenci Listesini Numaraya Göre Sırala
            final siraliOgrenciListesi = List<Map<String, dynamic>>.from(
              widget.notlar,
            );
            siraliOgrenciListesi.sort(
              (a, b) => (int.tryParse(a['numara'].toString()) ?? 0).compareTo(
                int.tryParse(b['numara'].toString()) ?? 0,
              ),
            );

            return [
              // 1. SINAV BİLGİLERİ
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(5),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "Sınıf: ${widget.sinav.sinif}",
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          "Tarih: ${DateFormat('d.MM.yyyy').format(widget.sinav.tarih)}",
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "Ders: ${widget.sinav.ders}",
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
              ),
              pw.SizedBox(height: 10),

              // 2. RENKLİ İSTATİSTİKLER
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
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
                      "Top. Öğrenci",
                      "$ogrSayisi",
                      PdfColors.blue700,
                    ),
                    _statItemRenkli(
                      "Ortalama",
                      genelOrtalama.toStringAsFixed(2),
                      PdfColors.green700,
                    ),
                    _statItemRenkli(
                      "Başarı",
                      "%$basariOrani",
                      PdfColors.orange700,
                    ),
                    _statItemRenkli("En Yüksek", "$maxNot", PdfColors.blue900),
                    _statItemRenkli("En Düşük", "$minNot", PdfColors.red700),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              // 3. NOT DAĞILIMI
              pw.Text(
                "Not Dağılımı",
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Table.fromTextArray(
                headers: ['Not Aralığı', 'Öğrenci Sayısı', 'Yüzde'],
                data: [
                  [
                    '0-24',
                    '${dagilim[0]}',
                    ogrSayisi > 0
                        ? '%${(dagilim[0] / ogrSayisi * 100).toStringAsFixed(1)}'
                        : '%0',
                  ],
                  [
                    '25-44',
                    '${dagilim[1]}',
                    ogrSayisi > 0
                        ? '%${(dagilim[1] / ogrSayisi * 100).toStringAsFixed(1)}'
                        : '%0',
                  ],
                  [
                    '45-69',
                    '${dagilim[2]}',
                    ogrSayisi > 0
                        ? '%${(dagilim[2] / ogrSayisi * 100).toStringAsFixed(1)}'
                        : '%0',
                  ],
                  [
                    '70-84',
                    '${dagilim[3]}',
                    ogrSayisi > 0
                        ? '%${(dagilim[3] / ogrSayisi * 100).toStringAsFixed(1)}'
                        : '%0',
                  ],
                  [
                    '85-100',
                    '${dagilim[4]}',
                    ogrSayisi > 0
                        ? '%${(dagilim[4] / ogrSayisi * 100).toStringAsFixed(1)}'
                        : '%0',
                  ],
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey700,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.center,
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
              ),
              pw.SizedBox(height: 15),

              // 4. SORU BAZLI ANALİZ ÖZETİ
              pw.Text(
                "Soru Bazlı Analiz",
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Table.fromTextArray(
                headers: ['Soru', 'Max Puan', 'Ortalama', 'Başarı %', 'Zorluk'],
                data: siraliSoruListesi
                    .map(
                      (s) => [
                        "${s.soruNo}",
                        s.maxPuan.toStringAsFixed(1),
                        s.sinifOrtalamasi.toStringAsFixed(2),
                        "%${s.basariYuzdesi.toStringAsFixed(1)}",
                        s.zorlukDerecesi,
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.center,
              ),
              pw.SizedBox(height: 15),

              // 5. 🔥 ÖĞRENCİ DETAYLARI (MATRIX TABLO)
              pw.Text(
                "Öğrenci Detayları",
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              _buildMatrixTable(
                siraliOgrenciListesi,
                widget.sinav.soruPuanlari ?? "",
              ),
            ];
          },
        ),
      );

      if (mounted) Navigator.pop(context);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '${widget.sinav.sinavAdi}_Analiz',
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("PDF Hatası: $e");
    }
  }

  pw.Widget _buildMatrixTable(
    List<Map<String, dynamic>> ogrenciler,
    String puanlarStr,
  ) {
    int soruSayisi = puanlarStr.split(',').length;
    List<String> headers = ['No', 'Adı Soyadı'];
    for (int i = 1; i <= soruSayisi; i++) headers.add('S$i');
    headers.add('TOPLAM');

    List<List<String>> data = [];
    for (var ogr in ogrenciler) {
      List<String> row = [
        (ogr['numara'] ?? '').toString(),
        ogr['ogrenci_ad_soyad'],
      ];

      String? detay = ogr['soru_bazli_notlar'];
      if (detay != null && detay.isNotEmpty) {
        List<String> p = detay.split(',');
        for (int k = 0; k < soruSayisi; k++) {
          if (k < p.length) {
            double val = double.tryParse(p[k]) ?? 0;
            row.add(
              val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1),
            );
          } else {
            row.add("-");
          }
        }
      } else {
        for (int k = 0; k < soruSayisi; k++) row.add("-");
      }
      row.add(ogr['notu'].toString());
      data.add(row);
    }

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 7,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      cellStyle: const pw.TextStyle(fontSize: 7),
      cellAlignment: pw.Alignment.center,
      cellAlignments: {1: pw.Alignment.centerLeft},
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
    );
  }

  pw.Widget _statItemRenkli(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          widget.sinav.sinavAdi,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: ProjeTemasi.anaRenk,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _pdfRaporuOlustur,
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: "Raporu Yazdır",
          ),
          PopupMenuButton<SiralamaTipi>(
            icon: const Icon(Icons.sort, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: _listeyiSirala,
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<SiralamaTipi>>[
                  const PopupMenuItem(
                    value: SiralamaTipi.numarasi,
                    child: Text('Soru Numarası'),
                  ),
                  const PopupMenuItem(
                    value: SiralamaTipi.enZor,
                    child: Text('En Zor Sorular'),
                  ),
                  const PopupMenuItem(
                    value: SiralamaTipi.enYuksekPuan,
                    child: Text('En Yüksek Puanlı'),
                  ),
                ],
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _soruListesi.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _buildKompaktSoruKarti(_soruListesi[index]);
        },
      ),
    );
  }

  Widget _buildKompaktSoruKarti(SoruIstatistikModel soru) {
    Color anaRenk = soru.zorlukRengi;
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ProjeTemasi.anaRenk.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${soru.soruNo}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: ProjeTemasi.anaRenk,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Soru ${soru.soruNo}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Max Puan: ${soru.maxPuan.toStringAsFixed(0)}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: anaRenk.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: anaRenk.withOpacity(0.3)),
                  ),
                  child: Text(
                    soru.zorlukDerecesi,
                    style: TextStyle(
                      color: anaRenk,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _miniBilgiKutusu(
                    "Ortalama",
                    soru.sinifOrtalamasi.toStringAsFixed(2),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _miniBilgiKutusu(
                    "Başarı",
                    "%${soru.basariYuzdesi.toStringAsFixed(0)}",
                    Colors.pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _altBilgi(
                    Icons.arrow_downward,
                    "En Düşük",
                    "${soru.enDusukPuan.toStringAsFixed(0)}",
                    Colors.red,
                  ),
                  Container(height: 20, width: 1, color: Colors.grey.shade300),
                  _altBilgi(
                    Icons.arrow_upward,
                    "En Yüksek",
                    "${soru.enYuksekPuan.toStringAsFixed(0)}",
                    Colors.green,
                  ),
                  Container(height: 20, width: 1, color: Colors.grey.shade300),
                  _altBilgi(
                    Icons.do_not_disturb_on,
                    "Boş/Sıfır",
                    "${soru.sifirAlanSayisi}",
                    Colors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: soru.basariYuzdesi / 100,
                backgroundColor: Colors.grey.shade200,
                color: anaRenk,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniBilgiKutusu(String baslik, String deger, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            baslik,
            style: TextStyle(fontSize: 12, color: renk.withOpacity(0.8)),
          ),
          Text(
            deger,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: renk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _altBilgi(IconData icon, String baslik, String deger, Color renk) {
    return Row(
      children: [
        Icon(icon, size: 14, color: renk),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              baslik,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
            ),
            Text(
              deger,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
