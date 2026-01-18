import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ogretmenim/veri/modeller/ogrenci_model.dart';

class ExcelServisi {
  // 1. DOSYA SEÇİCİ
  Future<File?> excelDosyasiSec() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  // 2. OKUMA FONKSİYONU
  Future<List<OgrenciModel>> ogrencileriAyikla(
    File excelDosyasi,
    int sinifId, {
    String? seciliSinifAdi, // yeni parametre
  }) async {
    List<OgrenciModel> ogrenciler = [];

    try {
      var bytes = excelDosyasi.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      // İlk sayfayı al
      var table = excel.tables[excel.tables.keys.first];

      if (table == null) return [];

      int? colNo;
      int? colAd;
      int? colSoyad;
      int? colCinsiyet;
      bool baslikBulundu = false;

      for (var row in table.rows) {
        List<String> rowValues = row
            .map((e) => e?.value.toString().trim() ?? "")
            .toList();
        print('Excel satırı: $rowValues');

        // Başlıkları Bul
        if (!baslikBulundu) {
          for (int i = 0; i < rowValues.length; i++) {
            String hucre = rowValues[i].toLowerCase();
            if (hucre.contains("no") && !hucre.contains("sıra")) colNo = i;
            if (hucre == "adı" || hucre.contains("ad")) colAd = i;
            if (hucre.contains("soyad")) colSoyad = i;
            if (hucre.contains("cinsiyet")) colCinsiyet = i;
            if (hucre.contains("isim soyisim") ||
                hucre.contains("isimsoyisim") ||
                hucre.contains("ad soyad") ||
                hucre.contains("adsoyad")) {
              colAd = i;
              colSoyad = null; // birleşik sütun
            }
          }
          print(
            'Başlık indexleri: no=$colNo, ad=$colAd, soyad=$colSoyad, cinsiyet=$colCinsiyet',
          );
          if (colNo != null && (colAd != null || colSoyad != null)) {
            baslikBulundu = true;
            continue;
          }
        }

        // Verileri Oku
        if (baslikBulundu) {
          if (colNo != null && colNo < rowValues.length) {
            String numara = rowValues[colNo];

            if (RegExp(r'^\d+$').hasMatch(numara)) {
              String ad = "";
              String soyad = "";
              if (colAd != null && colAd < rowValues.length) {
                ad = _titleCase(rowValues[colAd]);
                if (colSoyad == null && ad.contains(' ')) {
                  var parts = ad.split(' ');
                  soyad = parts.last;
                  ad = parts.sublist(0, parts.length - 1).join(' ');
                }
              }
              if (colSoyad != null && colSoyad < rowValues.length) {
                soyad = _titleCase(rowValues[colSoyad]);
              }

              String cinsiyet =
                  (colCinsiyet != null && colCinsiyet < rowValues.length)
                  ? rowValues[colCinsiyet]
                  : "Erkek";

              // Sınıf ve şube bilgisini dönüştür
              String duzenliSinif = "";
              if (rowValues.length > 3) {
                String sinifCell = rowValues[3];
                // Tüm harfleri büyük yap, gereksiz boşlukları kaldır
                sinifCell = sinifCell
                    .replaceAll("şubesi", "")
                    .replaceAll("Şubesi", "")
                    .replaceAll("sınıf", "")
                    .replaceAll("Sınıf", "")
                    .replaceAll("/", "")
                    .replaceAll(".", "")
                    .replaceAll("  ", " ")
                    .trim();
                RegExp reg = RegExp(
                  r'(\d+)\s*([A-Za-z])',
                  caseSensitive: false,
                );
                var match = reg.firstMatch(sinifCell);
                if (match != null) {
                  duzenliSinif =
                      "${match.group(1)}-${match.group(2)?.toUpperCase()}";
                }
              }

              print(
                'Çekilen öğrenci: no=$numara, ad=$ad, soyad=$soyad, cinsiyet=$cinsiyet, sinifId=$sinifId, duzenliSinif=$duzenliSinif',
              );

              // Sadece seçili sınıfa ait öğrencileri ekle
              if (duzenliSinif.isNotEmpty && seciliSinifAdi != null) {
                // Eşleşmede harf büyük/küçük ve boşlukları yok say
                String normDuzenliSinif = duzenliSinif
                    .replaceAll(" ", "")
                    .toUpperCase();
                String normSeciliSinifAdi = seciliSinifAdi
                    .replaceAll(" ", "")
                    .toUpperCase();
                if (normDuzenliSinif == normSeciliSinifAdi) {
                  ogrenciler.add(
                    OgrenciModel(
                      ad: ad,
                      soyad: soyad,
                      numara: numara,
                      cinsiyet: _normalizeCinsiyet(cinsiyet),
                      sinifId: sinifId,
                      sinifAdi: duzenliSinif,
                    ),
                  );
                }
              }
            }
          }
        }
      }
      return ogrenciler;
    } catch (e) {
      print("Excel Hatası: $e");
      return [];
    }
  }

  String _normalizeCinsiyet(String text) {
    return text.toLowerCase().startsWith('k') ? 'Kız' : 'Erkek';
  }

  String _titleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          if (word.length == 1) return word.toUpperCase();
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
