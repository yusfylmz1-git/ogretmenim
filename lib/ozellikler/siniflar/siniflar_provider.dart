import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ogretmenim/veri/modeller/sinif_model.dart';
import 'package:ogretmenim/veri/veritabani/veritabani_yardimcisi.dart';

final siniflarProvider =
    StateNotifierProvider<SiniflarNotifier, List<SinifModel>>(
      (ref) => SiniflarNotifier(),
    );

class SiniflarNotifier extends StateNotifier<List<SinifModel>> {
  SiniflarNotifier() : super([]) {
    siniflariYukle();
  }

  // Veritabanından sınıfları çek
  Future<void> siniflariYukle() async {
    final veriListesi = await VeritabaniYardimcisi.instance.siniflariGetir();
    // Veritabanından gelen ham veriyi (Map) SinifModel listesine çeviriyoruz
    state = veriListesi.map((x) => SinifModel.fromMap(x)).toList();
  }

  // Yeni sınıf ekle
  Future<void> sinifEkle(String ad, String aciklama) async {
    final yeniSinif = SinifModel(sinifAdi: ad, aciklama: aciklama);
    await VeritabaniYardimcisi.instance.sinifEkle(yeniSinif.toMap());
    await siniflariYukle(); // Listeyi yenile
  }

  // Sınıf sil
  Future<void> sinifSil(int id) async {
    await VeritabaniYardimcisi.instance.sinifSil(id);
    await siniflariYukle();
  }

  // 👇 YENİ: SINIF GÜNCELLEME (Edit)
  Future<void> sinifGuncelle(SinifModel sinif) async {
    // Veritabanı yardımcısında 'sinifGuncelle' yoksa oraya da eklememiz gerekebilir
    // Ama biz şimdilik standart update sorgusu kullanacağız.
    final db = await VeritabaniYardimcisi.instance.database;
    await db.update(
      'siniflar',
      sinif.toMap(),
      where: 'id = ?',
      whereArgs: [sinif.id],
    );
    await siniflariYukle();
  }
}
