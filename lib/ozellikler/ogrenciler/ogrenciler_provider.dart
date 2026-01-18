import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ogretmenim/veri/modeller/ogrenci_model.dart';
import 'package:ogretmenim/veri/veritabani/veritabani_yardimcisi.dart';

final ogrencilerProvider =
    StateNotifierProvider<OgrencilerNotifier, List<OgrenciModel>>(
      (ref) => OgrencilerNotifier(),
    );

class OgrencilerNotifier extends StateNotifier<List<OgrenciModel>> {
  OgrencilerNotifier() : super([]);

  // 1. Öğrencileri Getir
  Future<void> ogrencileriYukle(int sinifId) async {
    final veriListesi = await VeritabaniYardimcisi.instance.ogrencileriGetir(
      sinifId,
    );
    state = veriListesi.map((x) => OgrenciModel.fromMap(x)).toList();
  }

  // 2. Ekle
  Future<void> ogrenciEkle(OgrenciModel ogrenci) async {
    await VeritabaniYardimcisi.instance.ogrenciEkle(ogrenci.toMap());
    await ogrencileriYukle(ogrenci.sinifId);
  }

  // 3. Sil
  Future<void> ogrenciSil(int id, int sinifId) async {
    await VeritabaniYardimcisi.instance.ogrenciSil(id);
    await ogrencileriYukle(sinifId);
  }

  // 4. GÜNCELLE (YENİ EKLENDİ) 👇
  Future<void> ogrenciGuncelle(OgrenciModel ogrenci) async {
    // Veritabanında ID'ye göre bulup günceller
    await VeritabaniYardimcisi.instance.ogrenciGuncelle(ogrenci.toMap());
    // Listeyi yenile
    await ogrencileriYukle(ogrenci.sinifId);
  }
}
