import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/veri/modeller/sinav_analiz.dart';
import 'package:ogretmenim/veri/veritabani/veritabani_yardimcisi.dart';
import 'package:ogretmenim/ozellikler/sinav_analiz/sinav_detay_sayfasi2.dart';

// 🔥 PDF KÜTÜPHANELERİ
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SinavDetaySayfasi extends StatefulWidget {
  final SinavAnaliz sinav;

  const SinavDetaySayfasi({super.key, required this.sinav});

  @override
  State<SinavDetaySayfasi> createState() => _SinavDetaySayfasiState();
}

class _SinavDetaySayfasiState extends State<SinavDetaySayfasi> {
  List<Map<String, dynamic>> _notlar = [];
  bool _yukleniyor = true;

  // İstatistikler
  double _sinifOrtalamasi = 0.0;
  int _basariOrani = 0;
  int _enYuksekNot = 0;
  int _enDusukNot = 0;

  // Grafik Verileri
  List<int> _dagilim = [0, 0, 0, 0, 0];
  int _maxOgrenciSayisiGrafik = 1;

  // Soru Bazlı İstatistikler
  List<Map<String, dynamic>> _soruIstatistikleri = [];
  int _kolaySayisi = 0;
  int _ortaSayisi = 0;
  int _zorSayisi = 0;
  int _genelBasariYuzdesi = 0;

  @override
  void initState() {
    super.initState();
    _detaylariYukle();
  }

  Future<void> _detaylariYukle() async {
    setState(() => _yukleniyor = true);

    try {
      final notlar = await VeritabaniYardimcisi.instance.notlariGetir(
        widget.sinav.id!,
      );

      // 🔥 Soru bazlıysa analiz yap
      if (widget.sinav.sinavTipi == 'soru_bazli' &&
          widget.sinav.soruPuanlari != null) {
        _soruAnaliziYap(notlar);
      }

      if (notlar.isNotEmpty) {
        double toplam = 0;
        int max = 0;
        int min = 100;
        int gecenler = 0;
        List<int> tempDagilim = [0, 0, 0, 0, 0];

        for (var kayit in notlar) {
          int not = int.tryParse(kayit['notu'].toString()) ?? 0;
          toplam += not;

          if (not > max) max = not;
          if (not < min) min = not;

          if (not >= 50) gecenler++;

          if (not < 45) {
            tempDagilim[0]++;
          } else if (not < 55) {
            tempDagilim[1]++;
          } else if (not < 70) {
            tempDagilim[2]++;
          } else if (not < 85) {
            tempDagilim[3]++;
          } else {
            tempDagilim[4]++;
          }
        }

        int maxCubuk = 0;
        for (var sayi in tempDagilim) {
          if (sayi > maxCubuk) maxCubuk = sayi;
        }

        if (mounted) {
          setState(() {
            _notlar = List.from(notlar);
            _notlar.sort((a, b) => (b['notu'] ?? 0).compareTo(a['notu'] ?? 0));

            _sinifOrtalamasi = toplam / notlar.length;
            _enYuksekNot = max;
            _enDusukNot = min;
            _basariOrani = ((gecenler / notlar.length) * 100).toInt();
            _dagilim = tempDagilim;
            _maxOgrenciSayisiGrafik = maxCubuk == 0 ? 1 : maxCubuk;
            _yukleniyor = false;
          });
        }
      } else {
        if (mounted) setState(() => _yukleniyor = false);
      }
    } catch (e) {
      debugPrint("Hata: $e");
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  void _soruAnaliziYap(List<Map<String, dynamic>> notlar) {
    if (notlar.isEmpty) return;

    List<String> soruPuanlariStr = widget.sinav.soruPuanlari!.split(',');
    List<double> maxPuanlar = soruPuanlariStr
        .map((e) => double.tryParse(e) ?? 0)
        .toList();

    int soruSayisi = maxPuanlar.length;
    List<double> soruToplamPuanlari = List.filled(soruSayisi, 0.0);

    for (var ogrenciKaydi in notlar) {
      String? detay = ogrenciKaydi['soru_bazli_notlar'];
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

    _soruIstatistikleri.clear();
    int ogrenciSayisi = notlar.length;
    _kolaySayisi = 0;
    _ortaSayisi = 0;
    _zorSayisi = 0;
    double toplamBasari = 0;

    for (int i = 0; i < soruSayisi; i++) {
      double sinifinAldigiToplam = soruToplamPuanlari[i];
      double alabilecekleriMaxToplam = maxPuanlar[i] * ogrenciSayisi;
      double basariYuzdesi = alabilecekleriMaxToplam > 0
          ? (sinifinAldigiToplam / alabilecekleriMaxToplam) * 100
          : 0;

      toplamBasari += basariYuzdesi;

      if (basariYuzdesi < 40)
        _zorSayisi++;
      else if (basariYuzdesi < 70)
        _ortaSayisi++;
      else
        _kolaySayisi++;

      _soruIstatistikleri.add({
        'soru': i + 1,
        'max_puan': maxPuanlar[i],
        'sinif_ort': (sinifinAldigiToplam / ogrenciSayisi),
        'basari': basariYuzdesi,
      });
    }

    if (soruSayisi > 0) {
      _genelBasariYuzdesi = (toplamBasari / soruSayisi).round();
    }
  }

  // --- 🔥 AKILLI PDF OLUŞTURMA FONKSİYONU (GÜNCELLENDİ) ---
  Future<Uint8List> _pdfOlustur() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // Profil Bilgilerini Çek
    String okulAdi =
        await VeritabaniYardimcisi.instance.ayarGetir('okul_adi') ?? "OKUL ADI";
    String ogretmenAdi =
        await VeritabaniYardimcisi.instance.ayarGetir('ogretmen_adi') ??
        "Öğretmen";
    String tarihBugun = DateFormat('d.MM.yyyy').format(DateTime.now());

    // 🔥 Sınav Tipini Kontrol Et (Klasik mi, Soru Bazlı mı?)
    bool soruBazliMi =
        widget.sinav.sinavTipi == 'soru_bazli' &&
        widget.sinav.soruPuanlari != null;

    // Listeyi Numaraya Göre Sırala
    List<Map<String, dynamic>> siraliList = List.from(_notlar);
    siraliList.sort((a, b) {
      int n1 = int.tryParse(a['numara'].toString()) ?? 0;
      int n2 = int.tryParse(b['numara'].toString()) ?? 0;
      return n1.compareTo(n2);
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (context) => pw.Column(
          children: [
            pw.Text(
              okulAdi.toUpperCase(),
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              "${widget.sinav.sinavAdi} (${widget.sinav.ders})",
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              "Sınıf: ${widget.sinav.sinif} - Tarih: ${DateFormat('d.MM.yyyy').format(widget.sinav.tarih)}",
              style: const pw.TextStyle(fontSize: 12),
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
                pw.Text(
                  "Rapor Tarihi: $tarihBugun",
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  "Öğretmen: $ogretmenAdi",
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  "Sayfa ${context.pageNumber}/${context.pagesCount}",
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        build: (pw.Context context) {
          List<pw.Widget> widgets = [];

          // 1. GENEL İSTATİSTİKLER (Her iki tipte de görünür)
          widgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _pdfStatItem("Ortalama", _sinifOrtalamasi.toStringAsFixed(1)),
                  _pdfStatItem("Başarı", "%$_basariOrani"),
                  _pdfStatItem("En Yüksek", "$_enYuksekNot"),
                  _pdfStatItem("En Düşük", "$_enDusukNot"),
                ],
              ),
            ),
          );

          // 🔥 2. TABLO SEÇİMİ (BURAYI GÜNCELLEDİK)
          if (soruBazliMi) {
            // --- A. SORU BAZLI DETAYLI TABLO ---
            List<String> puanlarStr = widget.sinav.soruPuanlari!.split(',');
            int soruSayisi = puanlarStr.length;

            // Başlıklar: No, Adı Soyadı, S1, S2, ..., Puan
            List<String> headers = ['No', 'Adı Soyadı'];
            for (int i = 1; i <= soruSayisi; i++) headers.add('S$i');
            headers.add('Puan');

            List<List<String>> data = [];
            for (var ogrenci in siraliList) {
              List<String> satir = [
                (ogrenci['numara'] ?? '').toString(),
                ogrenci['ogrenci_ad_soyad'],
              ];

              String? detay = ogrenci['soru_bazli_notlar'];
              if (detay != null && detay.isNotEmpty) {
                List<String> alinanPuanlar = detay.split(',');
                for (int k = 0; k < soruSayisi; k++) {
                  if (k < alinanPuanlar.length) {
                    double p = double.tryParse(alinanPuanlar[k]) ?? 0;
                    satir.add(
                      p % 1 == 0 ? p.toInt().toString() : p.toStringAsFixed(1),
                    );
                  } else {
                    satir.add("-");
                  }
                }
              } else {
                for (int k = 0; k < soruSayisi; k++) satir.add("-");
              }
              satir.add(ogrenci['notu'].toString());
              data.add(satir);
            }

            widgets.add(
              pw.Text(
                "Soru Bazlı Detay Tablosu",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 10));
            widgets.add(
              pw.Table.fromTextArray(
                headers: headers,
                data: data,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 8,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue800,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.center,
                cellAlignments: {1: pw.Alignment.centerLeft},
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
              ),
            );
          } else {
            // --- B. KLASİK LİSTE ---
            widgets.add(
              pw.Text(
                "Sınav Sonuç Listesi",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 10));
            widgets.add(
              pw.Table.fromTextArray(
                headers: ['Sıra', 'Numara', 'Adı Soyadı', 'Puan'],
                data: List<List<dynamic>>.generate(
                  siraliList.length,
                  (index) => [
                    (index + 1).toString(),
                    siraliList[index]['ogrenci_ad_soyad'],
                    siraliList[index]['numara'] ?? '-',
                    siraliList[index]['notu'].toString(),
                  ],
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue700,
                ),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                },
              ),
            );
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
      ],
    );
  }

  void _pdfDialogGoster() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      size: 50,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "PDF Raporu Hazır!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Ne yapmak istersiniz?",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final pdfData = await _pdfOlustur();
                          await Printing.sharePdf(
                            bytes: pdfData,
                            filename: 'sinav_raporu.pdf',
                          );
                        },
                        icon: const Icon(Icons.share, color: Colors.purple),
                        label: const Text(
                          "Paylaş",
                          style: TextStyle(color: Colors.purple),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: Colors.purple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final pdfData = await _pdfOlustur();
                          await Printing.layoutPdf(
                            onLayout: (PdfPageFormat format) async => pdfData,
                            name: 'Sinav Raporu',
                          );
                        },
                        icon: const Icon(Icons.print, color: Colors.white),
                        label: const Text(
                          "Yazdır",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "İptal",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool soruBazli = widget.sinav.sinavTipi == 'soru_bazli';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Analiz Raporu",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: ProjeTemasi.anaRenk,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBilgiKarti(),
                  const SizedBox(height: 24),

                  // 🔥 Soru Bazlı Özet Kartı
                  if (soruBazli) ...[
                    _buildSoruBazliOzetKarti(),
                    const SizedBox(height: 24),
                  ],

                  const Text(
                    "📊 Genel İstatistikler",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatCard(
                        "Ortalama",
                        _sinifOrtalamasi.toStringAsFixed(1),
                        Icons.show_chart,
                        Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        "Başarı",
                        "%$_basariOrani",
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatCard(
                        "En Yüksek",
                        "$_enYuksekNot",
                        Icons.star_outline,
                        Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        "En Düşük",
                        "$_enDusukNot",
                        Icons.arrow_downward,
                        Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "📈 Not Dağılımı",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBar(
                          label: "0-44",
                          count: _dagilim[0],
                          color: Colors.red,
                        ),
                        _buildBar(
                          label: "45-54",
                          count: _dagilim[1],
                          color: Colors.orange,
                        ),
                        _buildBar(
                          label: "55-69",
                          count: _dagilim[2],
                          color: Colors.yellow.shade700,
                        ),
                        _buildBar(
                          label: "70-84",
                          count: _dagilim[3],
                          color: Colors.blue,
                        ),
                        _buildBar(
                          label: "85+",
                          count: _dagilim[4],
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "👥 Öğrenci Listesi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _notlar.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _buildOgrenciRow(index + 1, _notlar[index]);
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pdfDialogGoster,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("PDF Rapor"),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  // 🔥 Soru Bazlı Özet Kartı
  Widget _buildSoruBazliOzetKarti() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                "Soru Bazlı Analiz Özeti",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _ozetKutu(
                "Toplam Soru",
                "${_soruIstatistikleri.length}",
                Icons.list,
                Colors.blue,
              ),
              const SizedBox(width: 10),
              _ozetKutu(
                "Ort. Başarı",
                "%$_genelBasariYuzdesi",
                Icons.percent,
                Colors.pink,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniDurumKutu("Kolay", _kolaySayisi, Colors.green),
              _miniDurumKutu("Orta", _ortaSayisi, Colors.orange),
              _miniDurumKutu("Zor", _zorSayisi, Colors.red),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              // ... butonun onPressed kısmı ...
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SinavDetaySayfasi2(
                      sinav: widget
                          .sinav, // 🔥 ARTIK SADECE İSMİ DEĞİL, TÜM SINAV BİLGİSİNİ GÖNDERİYORUZ
                      notlar: _notlar,
                    ),
                  ),
                );
              },
              // ...
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              label: const Text(
                "Soru Bazlı Detaylara Git",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ozetKutu(String baslik, String deger, IconData ikon, Color renk) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(ikon, color: renk, size: 20),
            const SizedBox(height: 5),
            Text(
              deger,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: renk,
              ),
            ),
            Text(
              baslik,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniDurumKutu(String etiket, int sayi, Color renk) {
    return Column(
      children: [
        Icon(Icons.face, color: renk),
        Text(
          "$sayi soru",
          style: TextStyle(fontWeight: FontWeight.bold, color: renk),
        ),
        Text(
          etiket,
          style: TextStyle(fontSize: 10, color: renk.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildBilgiKarti() {
    String tarihText = "-";
    try {
      tarihText = DateFormat('d MMM yyyy', 'tr_TR').format(widget.sinav.tarih);
    } catch (_) {}
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.black87),
              SizedBox(width: 8),
              Text(
                "Sınav Bilgileri",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 12),
          _buildBilgiSatiri("Sınıf", widget.sinav.sinif),
          _buildBilgiSatiri("Ders", widget.sinav.ders),
          _buildBilgiSatiri("Tarih", tarihText),
          _buildBilgiSatiri("Toplam Puan", "100"),
        ],
      ),
    );
  }

  Widget _buildBilgiSatiri(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            baslik,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            deger,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar({
    required String label,
    required int count,
    required Color color,
  }) {
    double barHeight = (count / _maxOgrenciSayisiGrafik) * 140;
    if (count > 0 && barHeight < 8) barHeight = 8;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (count > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              "$count",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        Container(
          width: 30,
          height: count == 0 ? 4 : barHeight,
          decoration: BoxDecoration(
            color: count == 0 ? Colors.grey.shade100 : color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOgrenciRow(int sira, Map<String, dynamic> ogrenci) {
    int not = int.tryParse(ogrenci['notu'].toString()) ?? 0;
    Color notRengi = not >= 85
        ? Colors.green
        : (not >= 70 ? Colors.blue : (not >= 50 ? Colors.orange : Colors.red));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ProjeTemasi.anaRenk.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              "$sira",
              style: TextStyle(
                color: ProjeTemasi.anaRenk,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ogrenci['ogrenci_ad_soyad'] ?? "İsimsiz",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (ogrenci['numara'] != null)
                  Text(
                    "No: ${ogrenci['numara']}",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: notRengi.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "$not",
              style: TextStyle(
                color: notRengi,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
