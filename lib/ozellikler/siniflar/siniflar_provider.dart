import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ogretmenim/veri/modeller/sinif_model.dart';
import 'package:ogretmenim/veri/veritabani/veritabani_yardimcisi.dart';

// Sayfaların dinleyeceği "Sınıf Listesi" yayıncısı
final siniflarProvider =
    StateNotifierProvider<SiniflarNotifier, List<SinifModel>>(
      (ref) => SiniflarNotifier(),
    );

class SiniflarNotifier extends StateNotifier<List<SinifModel>> {
  SiniflarNotifier() : super([]) {
    // Uygulama açılır açılmaz verileri yükle
    tumSiniflariYukle();
  }

  // Veritabanından verileri çekip listeyi günceller
  Future<void> tumSiniflariYukle() async {
    final veriListesi = await VeritabaniYardimcisi.instance.siniflariGetir();
    // Gelen ham veriyi (Map) bizim Sınıf Modeline çevir
    state = veriListesi.map((x) => SinifModel.fromMap(x)).toList();
  }

  // Yeni Sınıf Ekle
  Future<void> sinifEkle(String ad, String aciklama) async {
    final yeniSinif = SinifModel(sinifAdi: ad, aciklama: aciklama);

    // Veritabanına kaydet
    await VeritabaniYardimcisi.instance.sinifEkle(yeniSinif.toMap());

    // Listeyi yenile ki ekranda görünsün
    await tumSiniflariYukle();
  }

  // Sınıf Sil
  Future<void> sinifSil(int id) async {
    await VeritabaniYardimcisi.instance.sinifSil(id);
    await tumSiniflariYukle();
  }
}
