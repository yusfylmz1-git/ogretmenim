import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ogretmenim/veri/modeller/performans_model.dart';
import 'package:ogretmenim/veri/veritabani/veritabani_yardimcisi.dart';

// 1. DURUM (STATE) SINIFI
class GunlukPerformansState {
  final Map<int, PerformansModel> performanslar;
  final bool yukleniyor;

  GunlukPerformansState({required this.performanslar, this.yukleniyor = false});

  GunlukPerformansState copyWith({
    Map<int, PerformansModel>? performanslar,
    bool? yukleniyor,
  }) {
    return GunlukPerformansState(
      performanslar: performanslar ?? this.performanslar,
      yukleniyor: yukleniyor ?? this.yukleniyor,
    );
  }
}

// 2. YÖNETİCİ (NOTIFIER) SINIFI
class PerformansNotifier extends StateNotifier<GunlukPerformansState> {
  PerformansNotifier() : super(GunlukPerformansState(performanslar: {}));

  // Verileri Veritabanından Çek (TARİH DESTEKLİ)
  Future<void> verileriYukle({DateTime? tarih}) async {
    state = state.copyWith(yukleniyor: true);

    // Eğer tarih verilmediyse bugünü al
    final islemTarihi = tarih ?? DateTime.now();
    final formatliTarih = DateFormat('yyyy-MM-dd').format(islemTarihi);

    try {
      // Tüm performans verilerini çek
      final liste = await VeritabaniYardimcisi.instance.performanslariGetir();

      final Map<int, PerformansModel> yeniMap = {};

      // Sadece SEÇİLEN TARİHE ait olanları filtrele
      for (var veri in liste) {
        // Veritabanından Map olarak geliyor, Modele çeviriyoruz
        // Not: VeritabaniYardimcisi Map<String, dynamic> döndürür.
        if (veri['tarih'] == formatliTarih) {
          final model = PerformansModel.fromMap(veri);
          yeniMap[model.ogrenciId] = model;
        }
      }

      state = state.copyWith(performanslar: yeniMap, yukleniyor: false);
    } catch (e) {
      print("Veri yükleme hatası: $e");
      state = state.copyWith(yukleniyor: false);
    }
  }

  // Tekli Puan Kaydetme
  Future<void> puanKaydet(PerformansModel model) async {
    try {
      final guncelMap = Map<int, PerformansModel>.from(state.performanslar);

      if (model.id == null) {
        // KAYIT YOKSA -> EKLE (Insert)
        int id = await VeritabaniYardimcisi.instance.performansEkle(
          model.toMap(),
        );

        // Yeni ID ile modeli güncelle
        final yeniModel = PerformansModel(
          id: id,
          ogrenciId: model.ogrenciId,
          tarih: model.tarih,
          kitap: model.kitap,
          odev: model.odev,
          yildiz: model.yildiz,
          puan: model.puan,
        );
        guncelMap[model.ogrenciId] = yeniModel;
      } else {
        // KAYIT VARSA -> GÜNCELLE (Update)
        await VeritabaniYardimcisi.instance.performansGuncelle(model.toMap());
        guncelMap[model.ogrenciId] = model;
      }

      // Ekranı güncelle
      state = state.copyWith(performanslar: guncelMap);
    } catch (e) {
      print("Puan kaydetme hatası: $e");
    }
  }

  // --- HIZLI DOLDUR (TARİH DESTEKLİ) ---
  Future<void> hizliDoldur(List<int> ogrenciIdleri, {DateTime? tarih}) async {
    final islemTarihi = tarih ?? DateTime.now();
    final bugunFormatli = DateFormat('yyyy-MM-dd').format(islemTarihi);

    // Mevcut durumun kopyasını alıyoruz
    final guncelMap = Map<int, PerformansModel>.from(state.performanslar);

    for (var id in ogrenciIdleri) {
      // O gün için zaten kayıt var mı? Varsa ID'sini koru (Update yapabilmek için)
      final mevcutKayit = guncelMap[id];

      // Her öğrenci için 100 Puanlık Model
      final model = PerformansModel(
        id: mevcutKayit?.id, // Varsa ID'yi al, yoksa null (Insert olacak)
        ogrenciId: id,
        tarih: bugunFormatli, // SEÇİLEN TARİH
        kitap: 1,
        odev: 1,
        yildiz: 3,
        puan: 100,
      );

      if (model.id == null) {
        int yeniId = await VeritabaniYardimcisi.instance.performansEkle(
          model.toMap(),
        );
        // ID'yi alıp haritaya öyle koyuyoruz ki bir sonraki işlemde update olsun
        guncelMap[id] = PerformansModel(
          id: yeniId,
          ogrenciId: id,
          tarih: bugunFormatli,
          kitap: 1,
          odev: 1,
          yildiz: 3,
          puan: 100,
        );
      } else {
        await VeritabaniYardimcisi.instance.performansGuncelle(model.toMap());
        guncelMap[id] = model;
      }
    }

    // State'i yenile
    state = state.copyWith(performanslar: guncelMap);
  }
}

// 3. PROVIDER TANIMI
final performansProvider =
    StateNotifierProvider<PerformansNotifier, GunlukPerformansState>((ref) {
      return PerformansNotifier();
    });
