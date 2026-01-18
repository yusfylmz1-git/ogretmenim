import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:ogretmenim/veri/modeller/ogrenci_model.dart';

class PdfServisi {
  // İsim Veritabanı
  static Set<String> _turkceIsimler = {};
  bool _isimlerYuklendi = false;

  // 1. İsimleri Yükle
  Future<void> _isimListesiniHazirla() async {
    if (_isimlerYuklendi) return;
    try {
      final String content = await rootBundle.loadString(
        'assets/turkce_isimler.txt',
      );
      _turkceIsimler = content
          .split('\n')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.length > 1)
          .toSet();
      _isimlerYuklendi = true;
      print("📚 İsim Veritabanı: ${_turkceIsimler.length} kayıt.");
    } catch (e) {
      print("⚠️ İsim listesi yüklenemedi, varsayılan mantık kullanılacak.");
      _isimlerYuklendi = true;
    }
  }

  // 2. Dosya Seç
  Future<File?> pdfDosyasiSec() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      return result?.files.single.path != null
          ? File(result!.files.single.path!)
          : null;
    } catch (e) {
      return null;
    }
  }

  // 3. ANA FONKSİYON
  Future<List<OgrenciModel>> ogrencileriAyikla(
    File pdfDosyasi,
    int sinifId,
  ) async {
    await _isimListesiniHazirla();

    // PDF metnini al
    String rawText = _pdfdenMetinCikar(pdfDosyasi);
    print("📄 Ham Veri Uzunluğu: ${rawText.length}");

    // 🔥 AMELİYAT: Yapışık metinleri ayır
    String temizMetin = _metniParcala(rawText);

    // Ayrıştırılmış metni kelime kelime (token) listesine çevir
    List<String> kelimeler = temizMetin
        .split(' ')
        .where((k) => k.length > 1)
        .toList();

    List<OgrenciModel> ogrenciler = [];

    // Algoritma: Listeyi tara, öğrenci yapısına benzeyen kalıpları yakala
    for (int i = 0; i < kelimeler.length; i++) {
      // ÇAPA 1: Okul Numarası (En belirgin özellik)
      // 2 ile 5 basamaklı bir sayı bulduk mu?
      if (_isOkulNo(kelimeler[i])) {
        String no = kelimeler[i];

        // Numaradan SONRAKİ kelimelere bak (İsim ve Soyad orada olmalı)
        // En fazla 5 kelime ileriye bakıyoruz
        List<String> adayIsimler = [];
        String cinsiyet = "Erkek"; // Varsayılan

        int j = i + 1;
        while (j < kelimeler.length && j < i + 6) {
          String kelime = kelimeler[j];

          // Eğer Cinsiyet kelimesine denk geldiysek dur
          if (_isCinsiyet(kelime)) {
            cinsiyet = _normalizeCinsiyet(kelime);
            break;
          }

          // Eğer yeni bir Numaraya denk geldiysek dur (Başka öğrenciye geçtik demektir)
          if (_isOkulNo(kelime)) break;

          // Eğer yasaklı kelimeyse (Sınıf, Şube vs) atla
          if (_isYasakli(kelime)) {
            j++;
            continue;
          }

          // Bu kelime İSİM LİSTEMİZDE var mı? veya Harf yapısı isme benziyor mu?
          if (_isGecerliIsimParcasi(kelime)) {
            adayIsimler.add(kelime);
          }

          j++;
        }

        // Eğer en az 2 isim parçası bulduysak (Ad + Soyad)
        if (adayIsimler.length >= 2) {
          String soyad = adayIsimler.last;
          String ad = adayIsimler.sublist(0, adayIsimler.length - 1).join(' ');

          // Çift kayıt kontrolü
          if (!ogrenciler.any((o) => o.numara == no)) {
            ogrenciler.add(
              OgrenciModel(
                ad: _titleCase(ad),
                soyad: _titleCase(soyad),
                numara: no,
                cinsiyet: cinsiyet,
                sinifId: sinifId,
              ),
            );
          }
        }
      }
    }

    print("✅ SONUÇ: ${ogrenciler.length} ÖĞRENCİ");
    return ogrenciler;
  }

  // ---------------------------------------------------------------------------
  // 🔥 KURTARICI FONKSİYON: Regex Ameliyatı
  // ---------------------------------------------------------------------------
  String _metniParcala(String text) {
    String islenen = text;

    // 1. Satır sonlarını boşluk yap
    islenen = islenen.replaceAll(RegExp(r'[\r\n\t]+'), ' ');

    // 2. Rakam ile Harf bitişikse ayır (1039AHMET -> 1039 AHMET)
    islenen = islenen.replaceAllMapped(
      RegExp(r'(\d)([a-zA-ZÇĞİÖŞÜçğıöşü])'),
      (m) => '${m[1]} ${m[2]}',
    );

    // 3. Harf ile Rakam bitişikse ayır (BAKSAL15 -> BAKSAL 15)
    islenen = islenen.replaceAllMapped(
      RegExp(r'([a-zA-ZÇĞİÖŞÜçğıöşü])(\d)'),
      (m) => '${m[1]} ${m[2]}',
    );

    // 4. Küçük Harf ile Büyük Harf bitişikse ayır (ahmetYILMAZ -> ahmet YILMAZ)
    islenen = islenen.replaceAllMapped(
      RegExp(r'([a-zçğıöşü])([A-ZÇĞİÖŞÜ])'),
      (m) => '${m[1]} ${m[2]}',
    );

    // 5. Çoklu boşlukları teke indir
    return islenen.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ---------------------------------------------------------------------------
  // YARDIMCI KONTROLLER
  // ---------------------------------------------------------------------------

  bool _isOkulNo(String s) {
    // 2 ile 5 basamak arası, 10'dan büyük sayılar (Sıra no 1,2,3 karışmasın diye)
    if (!RegExp(r'^\d+$').hasMatch(s)) return false;
    int? val = int.tryParse(s);
    return val != null && val > 10 && val < 99999;
  }

  bool _isCinsiyet(String s) =>
      RegExp(r'^(Erkek|Kız|Kiz|E|K)$', caseSensitive: false).hasMatch(s);

  bool _isYasakli(String s) {
    final lower = s.toLowerCase();
    return [
      'sınıf',
      'sinif',
      'şube',
      'sube',
      'no',
      'listesi',
      'merkez',
      'müdürlüğü',
      'valilik',
    ].any((y) => lower.contains(y));
  }

  bool _isGecerliIsimParcasi(String s) {
    // Sadece harf olmalı
    if (!RegExp(r'^[a-zA-ZÇĞİÖŞÜçğıöşü\.]+$').hasMatch(s)) return false;
    if (s.length < 2) return false;

    // Veritabanı yüklüyse ve içinde varsa kesin isimdir
    if (_turkceIsimler.contains(s.toLowerCase())) return true;

    // Veritabanında yoksa ama formatı uyuyorsa (Yabancı isim vs) kabul et
    return true;
  }

  String _pdfdenMetinCikar(File file) {
    final bytes = file.readAsBytesSync();
    final doc = PdfDocument(inputBytes: bytes);
    final text = PdfTextExtractor(doc).extractText();
    doc.dispose();
    return text;
  }

  String _titleCase(String text) {
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          if (word.length == 1) return word.toUpperCase();
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String _normalizeCinsiyet(String text) {
    return text.toLowerCase().startsWith('k') ? 'Kız' : 'Erkek';
  }
}
