import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ogretmenim/veri/modeller/ogrenci_model.dart';
import 'package:ogretmenim/ozellikler/ogrenciler/ogrenciler_provider.dart';

class ExcelPreviewEditPage extends ConsumerStatefulWidget {
  final String? sinifAdi;
  final int? sinifId;

  const ExcelPreviewEditPage({super.key, this.sinifAdi, this.sinifId});

  @override
  ConsumerState<ExcelPreviewEditPage> createState() =>
      _ExcelPreviewEditPageState();
}

class _ExcelPreviewEditPageState extends ConsumerState<ExcelPreviewEditPage> {
  File? _selectedExcel;
  List<OgrenciModel> _students = [];
  List<String> _mevcutNumaralar = [];
  bool _loading = false;
  late String _sinifAdi;

  @override
  void initState() {
    super.initState();
    _sinifAdi = widget.sinifAdi ?? '';
  }

  // --------------------------------------------------
  // KAYDET
  // --------------------------------------------------
  Future<void> _saveSelectedStudents() async {
    if (widget.sinifId == null) return;

    final selected = _students
        .where((s) => s.selected && !_mevcutNumaralar.contains(s.numara))
        .toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kaydedilecek öğrenci yok')));
      return;
    }

    final provider = ref.read(ogrencilerProvider.notifier);

    for (final s in selected) {
      await provider.ogrenciEkle(
        s.copyWith(sinifId: widget.sinifId!, sinifAdi: _sinifAdi),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  // --------------------------------------------------
  // EXCEL SEÇ
  // --------------------------------------------------
  Future<void> _pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result?.files.single.path == null) return;

    _selectedExcel = File(result!.files.single.path!);
    await _parseExcel(_selectedExcel!);
  }

  // --------------------------------------------------
  // EXCEL OKU
  // --------------------------------------------------
  Future<void> _parseExcel(File file) async {
    setState(() => _loading = true);
    try {
      final provider = ref.read(ogrencilerProvider.notifier);
      await provider.ogrencileriYukle(widget.sinifId!);

      _mevcutNumaralar = ref
          .read(ogrencilerProvider)
          .map((e) => e.numara)
          .toList();

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final List<OgrenciModel> list = [];

      for (final table in excel.tables.keys) {
        final rows = excel.tables[table]!.rows;
        if (rows.length < 2) continue;

        // Başlık satırı
        final headerRow = rows.first;
        // ...
        int? colNo, colAd, colSoyad, colAdSoyad, colCinsiyet;
        for (int i = 0; i < headerRow.length; i++) {
          var hucre = headerRow[i]?.value?.toString() ?? '';
          hucre = hucre
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9ğüşöçıi ]'), '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          hucre = hucre
              .replaceAll('ı', 'i')
              .replaceAll('ğ', 'g')
              .replaceAll('ü', 'u')
              .replaceAll('ş', 's')
              .replaceAll('ö', 'o')
              .replaceAll('ç', 'c');
          if ((hucre.contains('no') || hucre.contains('numara')) &&
              !hucre.contains('sira'))
            colNo = i;
          // isim/ad/adı
          if (hucre == 'isim' || hucre == 'adi' || hucre == 'ad') colAd = i;
          // soyisim/soyad
          if (hucre == 'soyisim' || hucre == 'soyad') colSoyad = i;
          // birleşik başlıklar
          if (hucre.contains('isim soyisim') ||
              hucre.contains('isimsoyisim') ||
              hucre.contains('ad soyad') ||
              hucre.contains('adsoyad')) {
            colAdSoyad = i;
          }
          // cinsiyet
          if (hucre == 'cinsiyet' || hucre == 'gender') colCinsiyet = i;
        }
        if (colNo == null) continue;
        // Eğer hem ad hem soyad yoksa, birleşik başlık olmalı
        if (colAd == null && colSoyad == null && colAdSoyad == null) continue;

        for (final row in rows.skip(1)) {
          if (row.length < 2) continue;
          final no = colNo < row.length
              ? row[colNo]?.value?.toString().trim() ?? ''
              : '';
          String ad = '', soyad = '';
          if (colAdSoyad != null && colAdSoyad < row.length) {
            // Birleşik hücreden ayır
            String adSoyad = row[colAdSoyad]?.value?.toString().trim() ?? '';
            final parts = adSoyad.split(RegExp(r'\s+'));
            if (parts.length > 1) {
              soyad = parts.last;
              ad = parts.sublist(0, parts.length - 1).join(' ');
            } else {
              ad = adSoyad;
              soyad = '';
            }
          } else {
            // Ayrı hücrelerden al
            ad = colAd != null && colAd < row.length
                ? row[colAd]?.value?.toString().trim() ?? ''
                : '';
            soyad = colSoyad != null && colSoyad < row.length
                ? row[colSoyad]?.value?.toString().trim() ?? ''
                : '';
          }
          if (no.isEmpty || ad.isEmpty) continue;
          // Cinsiyet sütunu varsa oku, yoksa 'Erkek' ata
          String cinsiyet = 'Erkek';
          if (colCinsiyet != null && colCinsiyet < row.length) {
            final raw =
                row[colCinsiyet]?.value?.toString().trim().toLowerCase() ?? '';
            if (raw == 'kız' || raw == 'kiz' || raw == 'female' || raw == 'f') {
              cinsiyet = 'Kız';
            } else if (raw == 'erkek' || raw == 'male' || raw == 'e') {
              cinsiyet = 'Erkek';
            } else if (raw.isNotEmpty) {
              // Diğer değerler için ilk harfi büyük yap
              cinsiyet = raw[0].toUpperCase() + raw.substring(1);
            }
          }
          list.add(
            OgrenciModel(
              numara: no,
              ad: ad,
              soyad: soyad,
              sinifId: widget.sinifId!,
              sinifAdi: _sinifAdi,
              cinsiyet: cinsiyet,
              selected: !_mevcutNumaralar.contains(no),
            ),
          );
        }
      }

      setState(() {
        _students = list;
        _loading = false;
      });

      if (list.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel dosyasından öğrenci bulunamadı!'),
          ),
        );
      }
    } catch (e, st) {
      setState(() => _loading = false);
      debugPrint('Excel okuma hatası: $e\n$st');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Excel okuma hatası: $e')));
    }
  }

  // --------------------------------------------------
  // ÖRNEK EXCEL İNDİR
  // --------------------------------------------------
  Future<void> _downloadExampleExcel() async {
    final bytes = await DefaultAssetBundle.of(
      context,
    ).load('assets/excel_ornek.xlsx');

    final Directory dir = Platform.isAndroid
        ? Directory('/storage/emulated/0/Download')
        : (await getDownloadsDirectory())!;

    final file = File('${dir.path}/excel_ornek.xlsx');
    await file.writeAsBytes(bytes.buffer.asUint8List());

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Örnek Excel indirildi')));
  }

  // --------------------------------------------------
  // ÖRNEK EXCEL PAYLAŞ
  // --------------------------------------------------
  Future<void> _shareExampleExcel() async {
    final bytes = await DefaultAssetBundle.of(
      context,
    ).load('assets/excel_ornek.xlsx');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/excel_ornek.xlsx');
    await file.writeAsBytes(bytes.buffer.asUint8List());

    await Share.shareXFiles([XFile(file.path)]);
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Excelden Toplu Öğrenci Ekle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ÜST KUTU
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Örnek Excel',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text('No, Ad, Soyad'),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _downloadExampleExcel,
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareExampleExcel,
                ),
              ],
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Excelden Veri Çek'),
              onPressed: _pickExcelFile,
            ),

            const SizedBox(height: 12),

            if (_loading) const CircularProgressIndicator(),

            // ÖĞRENCİLER
            if (_students.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (context, i) {
                    final s = _students[i];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: s.selected,
                              onChanged: (v) {
                                setState(() {
                                  _students[i] = s.copyWith(
                                    selected: v ?? false,
                                  );
                                });
                              },
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // AD + SOYAD
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: s.ad,
                                          maxLength: 12,
                                          decoration: const InputDecoration(
                                            hintText: 'Ad',
                                            isDense: true,
                                            counterText: '',
                                          ),
                                          onChanged: (v) {
                                            _students[i] = s.copyWith(
                                              ad: v.trim(),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: s.soyad ?? '',
                                          maxLength: 12,
                                          decoration: const InputDecoration(
                                            hintText: 'Soyad',
                                            isDense: true,
                                            counterText: '',
                                          ),
                                          onChanged: (v) {
                                            _students[i] = s.copyWith(
                                              soyad: v.trim(),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  // NO + CİNSİYET (OVERFLOW YOK)
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 6,
                                    children: [
                                      SizedBox(
                                        width: 90,
                                        child: TextFormField(
                                          initialValue: s.numara,
                                          maxLength: 6,
                                          decoration: const InputDecoration(
                                            hintText: 'No',
                                            isDense: true,
                                            counterText: '',
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: DropdownButtonFormField<String>(
                                          value: s.cinsiyet == 'Kız'
                                              ? 'K'
                                              : 'E',
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'E',
                                              child: Text('Erkek'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'K',
                                              child: Text('Kız'),
                                            ),
                                          ],
                                          onChanged: (v) {
                                            setState(() {
                                              _students[i] = s.copyWith(
                                                cinsiyet: v == 'E'
                                                    ? 'Erkek'
                                                    : 'Kız',
                                              );
                                            });
                                          },
                                          decoration: const InputDecoration(
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _students.removeAt(i);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Kaydet'),
              onPressed: _saveSelectedStudents,
            ),
          ],
        ),
      ),
    );
  }
}
