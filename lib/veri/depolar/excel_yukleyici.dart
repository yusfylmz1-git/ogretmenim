import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:excel/excel.dart';
import 'package:ogretmenim/veri/modeller/kazanim_model.dart';
import 'package:ogretmenim/veri/veritabani/veritabani_yardimcisi.dart';

class ExcelYukleyici {
  static Future<void> planlariYukle({bool zorlaGuncelle = false}) async {
    final db = VeritabaniYardimcisi.instance;

    // 1. Veri kontrolü
    if (!zorlaGuncelle) {
      final mevcutVeri = await db.database.then(
        (d) => d.query('kazanimlar', limit: 1),
      );
      if (mevcutVeri.isNotEmpty) {
        print("💾 Veritabanında zaten planlar var. Yükleme atlandı.");
        return;
      }
    }

    print("⏳ Excel dosyası okunuyor...");

    try {
      // 2. Dosyayı Asset'ten oku
      final ByteData data = await rootBundle.load('assets/planlar.xlsx');
      final List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      var excel = Excel.decodeBytes(bytes);

      final String tabloAdi = excel.tables.keys.first;
      final Sheet? sayfa = excel.tables[tabloAdi];

      if (sayfa == null) return;

      List<Map<String, dynamic>> eklenecekler = [];

      // 3. Satırları gez (1. satırdan başla, 0 başlık)
      for (int i = 1; i < sayfa.rows.length; i++) {
        final row = sayfa.rows[i];
        if (row.isEmpty) continue;

        // EXCEL SÜTUNLARI (Senin dosyanın yapısına göre):
        // A(0): Plan Sırası (Kullanmıyoruz)
        // B(1): Ders Tipi
        // C(2): Branş
        // D(3): Sınıf
        // E(4): Ünite
        // F(5): Kazanım
        // G(6): Hafta (Tatillerde boş olabilir)

        // Verileri güvenli şekilde al
        final dersTipi = row[1]?.value?.toString() ?? 'Ders';
        final brans = row[2]?.value?.toString() ?? '';
        final sinifRaw = row[3]?.value;
        final unite = row[4]?.value?.toString() ?? '';
        final kazanim = row[5]?.value?.toString() ?? '';
        final haftaRaw = row[6]?.value; // Burası tatilde boş gelebilir

        // Sınıfı sayıya çevir
        int sinif = 5;
        if (sinifRaw != null) sinif = int.tryParse(sinifRaw.toString()) ?? 5;

        // Haftayı sayıya çevir (BOŞSA 0 YAP)
        int hafta = 0;
        if (haftaRaw != null) {
          hafta = int.tryParse(haftaRaw.toString()) ?? 0;
        }

        // Modeli oluştur
        final model = KazanimModel(
          dersTipi: dersTipi,
          brans: brans,
          sinif: sinif,
          unite: unite,
          kazanim: kazanim,
          hafta: hafta, // Tatillerde 0 olarak kaydedilecek
        );

        eklenecekler.add(model.toMap());
      }

      // 4. Kaydet
      if (eklenecekler.isNotEmpty) {
        await db.kazanimlariTemizle();
        await db.topluKazanimEkle(eklenecekler);
        print(
          "✅ Başarılı: ${eklenecekler.length} adet satır veritabanına işlendi!",
        );
      }
    } catch (e) {
      print("❌ Excel Yükleme Hatası: $e");
    }
  }
}
