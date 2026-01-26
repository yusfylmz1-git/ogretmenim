import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ogretmenim/ozellikler/ogrenciler/ogrenci_ekle_sayfasi.dart';
import 'package:ogretmenim/ozellikler/ogrenciler/ogrenciler_provider.dart';
import 'package:ogretmenim/veri/modeller/sinif_model.dart';
import 'package:ogretmenim/cekirdek/araclar/pdf_servisi.dart';
import 'pdf_onizleme_sayfasi.dart';
import 'package:ogretmenim/cekirdek/araclar/bildirim_araci.dart';
import 'excel_preview_edit_page.dart';

class OgrencilerSayfasi extends ConsumerStatefulWidget {
  final SinifModel sinif;

  const OgrencilerSayfasi({super.key, required this.sinif});

  @override
  ConsumerState<OgrencilerSayfasi> createState() => _OgrencilerSayfasiState();
}

class _OgrencilerSayfasiState extends ConsumerState<OgrencilerSayfasi> {
  bool _aramaModu = false;
  final TextEditingController _aramaController = TextEditingController();
  String _aramaMetni = "";

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (widget.sinif.id != null) {
        ref
            .read(ogrencilerProvider.notifier)
            .ogrencileriYukle(widget.sinif.id!);
      }
    });

    _aramaController.addListener(() {
      setState(() {
        _aramaMetni = _aramaController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tumOgrenciler = ref.watch(ogrencilerProvider);
    final anaRenk = Theme.of(context).primaryColor;

    // --- KRİTİK DÜZELTME: FİLTRELEME ---
    // Gelen tüm listeyi değil, sadece bu sınıfa ait olanları alıyoruz.
    final sinifOgrencileri = tumOgrenciler
        .where((o) => o.sinifId == widget.sinif.id)
        .toList();

    // Numaraya göre sırala (Küçükten büyüğe)
    sinifOgrencileri.sort((a, b) {
      int noA = int.tryParse(a.numara) ?? 0;
      int noB = int.tryParse(b.numara) ?? 0;
      return noA.compareTo(noB);
    });

    // Arama filtresini "sinifOgrencileri" üzerinden yapıyoruz
    final goruntulenenListe = _aramaMetni.isEmpty
        ? sinifOgrencileri
        : sinifOgrencileri.where((ogrenci) {
            final adSoyad = "${ogrenci.ad} ${ogrenci.soyad ?? ''}"
                .toLowerCase();
            final numara = ogrenci.numara.toLowerCase();
            return adSoyad.contains(_aramaMetni) ||
                numara.contains(_aramaMetni);
          }).toList();

    // İstatistikler de filtrelenmiş listeden hesaplanmalı
    final int kizSayisi = sinifOgrencileri
        .where((o) => o.cinsiyet == 'Kız' || o.cinsiyet == 'Kiz')
        .length;
    final int erkekSayisi = sinifOgrencileri
        .where((o) => o.cinsiyet == 'Erkek')
        .length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: _aramaModu
            ? TextField(
                controller: _aramaController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'İsim veya numara...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : Text(widget.sinif.sinifAdi),
        centerTitle: true,
        backgroundColor: anaRenk,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (_aramaModu) {
              setState(() {
                _aramaModu = false;
                _aramaMetni = "";
                _aramaController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_aramaModu ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_aramaModu) {
                  _aramaModu = false;
                  _aramaMetni = "";
                  _aramaController.clear();
                } else {
                  _aramaModu = true;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. HEADER (Minimal Tasarım)
          if (!_aramaModu)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // İstatistikler
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Toplam ${sinifOgrencileri.length} Öğrenci",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _cinsiyetEtiketi("Kız: $kizSayisi", Colors.pink),
                            const SizedBox(width: 8),
                            _cinsiyetEtiketi(
                              "Erkek: $erkekSayisi",
                              Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Hızlı Ekleme Butonu (Sağ üstte)
                  ElevatedButton.icon(
                    onPressed: () => _eklemeSecenekleriniGoster(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: anaRenk,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text("Öğrenci Ekle"),
                  ),
                ],
              ),
            ),

          // 2. ÖĞRENCİ LİSTESİ
          Expanded(
            child: goruntulenenListe.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _aramaMetni.isEmpty
                              ? Icons.school_outlined
                              : Icons.search_off,
                          size: 70,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _aramaMetni.isEmpty
                              ? "Henüz öğrenci yok"
                              : "Sonuç bulunamadı",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: goruntulenenListe.length,
                    itemBuilder: (context, index) {
                      final ogrenci = goruntulenenListe[index];
                      final bool isKiz =
                          ogrenci.cinsiyet == 'Kız' ||
                          ogrenci.cinsiyet == 'Kiz';
                      final renk = isKiz ? Colors.pink : Colors.blue;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade100,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          leading: SizedBox(
                            width: 55,
                            height: 55,
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: renk.withOpacity(0.1),
                                    backgroundImage: ogrenci.fotoYolu != null
                                        ? FileImage(File(ogrenci.fotoYolu!))
                                        : null,
                                    child: ogrenci.fotoYolu == null
                                        ? Icon(
                                            isKiz ? Icons.face_3 : Icons.face,
                                            color: renk,
                                            size: 30,
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: renk.withOpacity(0.5),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      "${index + 1}",
                                      style: TextStyle(
                                        color: renk,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          title: Text(
                            "${ogrenci.ad} ${ogrenci.soyad ?? ''}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "No: ${ogrenci.numara}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isKiz ? "Kız" : "Erkek",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: renk,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () =>
                                _ogrenciIslemMenusuGoster(context, ogrenci),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OgrenciEkleSayfasi(
                                  duzenlenecekOgrenci: ogrenci,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _cinsiyetEtiketi(String yazi, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        yazi,
        style: TextStyle(
          color: renk,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _eklemeSecenekleriniGoster(BuildContext anaContext) {
    showModalBottomSheet(
      context: anaContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 1. ELLE EKLE
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.blue),
                  ),
                  title: const Text(
                    'Elle Ekle',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      anaContext,
                      MaterialPageRoute(
                        builder: (context) => OgrenciEkleSayfasi(
                          varsayilanSinifId: widget.sinif.id,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // 2. EXCEL'DEN ÇEK
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.table_view, color: Colors.green),
                  ),
                  title: const Text(
                    "Excel'den Çek (Önerilen)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(".xlsx dosyası yükle"),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      anaContext,
                      MaterialPageRoute(
                        builder: (context) => ExcelPreviewEditPage(
                          sinifAdi: widget.sinif.sinifAdi,
                          sinifId: widget.sinif.id,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // 3. PDF'TEN ÇEK
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  ),
                  title: const Text(
                    "PDF'ten Çek (e-Okul)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("Listeyi otomatik yükle"),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    final pdfDosyasi = await PdfServisi().pdfDosyasiSec();
                    if (pdfDosyasi != null) {
                      final bulunanlar = await PdfServisi().ogrencileriAyikla(
                        pdfDosyasi,
                        widget.sinif.id!,
                      );
                      if (anaContext.mounted) {
                        if (bulunanlar.isEmpty) {
                          BildirimAraci.tepeHataGoster(
                            anaContext,
                            "Öğrenci bulunamadı!",
                          );
                        } else {
                          Navigator.push(
                            anaContext,
                            MaterialPageRoute(
                              builder: (context) => PdfOnizlemeSayfasi(
                                bulunanListe: bulunanlar,
                                sinifId: widget.sinif.id!,
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _ogrenciIslemMenusuGoster(BuildContext context, dynamic ogrenci) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text("Düzenle"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        OgrenciEkleSayfasi(duzenlenecekOgrenci: ogrenci),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Öğrenciyi Sil"),
              onTap: () {
                Navigator.pop(context);
                _silmeOnayiGoster(context, ogrenci.id!);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _silmeOnayiGoster(BuildContext context, int ogrenciId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Öğrenciyi Sil"),
        content: const Text("Bu öğrenciyi silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(ogrencilerProvider.notifier)
                  .ogrenciSil(ogrenciId, widget.sinif.id!);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }
}
