import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ogretmenim/veri/modeller/performans_model.dart';
import 'package:ogretmenim/veri/yerel_veri/performans_servisi.dart';

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

  final _servis = PerformansServisi();

  // Verileri Veritabanından Çek
  Future<void> verileriYukle() async {
    state = state.copyWith(yukleniyor: true);

    final bugun = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final liste = await _servis.gunlukListeyiGetir(bugun);

    final Map<int, PerformansModel> yeniMap = {};
    for (var p in liste) {
      yeniMap[p.ogrenciId] = p;
    }

    state = state.copyWith(performanslar: yeniMap, yukleniyor: false);
  }

  // Tekli Puan Kaydetme
  Future<void> puanKaydet(PerformansModel model) async {
    // 1. Veritabanına yaz
    await _servis.performansKaydet(model);

    // 2. Ekranı güncelle
    final guncelMap = Map<int, PerformansModel>.from(state.performanslar);
    guncelMap[model.ogrenciId] = model;

    state = state.copyWith(performanslar: guncelMap);
  }

  // --- YENİ EKLENEN: HIZLI DOLDUR (Sihirli Değnek) ---
  // Listesi verilen tüm öğrencilere 100 puan basar.
  Future<void> hizliDoldur(List<int> ogrenciIdleri) async {
    final bugun = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Mevcut durumun kopyasını alıyoruz
    final guncelMap = Map<int, PerformansModel>.from(state.performanslar);

    for (var id in ogrenciIdleri) {
      // Her öğrenci için 100 Puanlık Model (Kitap Var, Ödev Var, 3 Yıldız)
      final model = PerformansModel(
        ogrenciId: id,
        tarih: bugun,
        kitap: 1, // Evet
        odev: 1, // Evet
        yildiz: 3, // 3 Yıldız (Full)
        puan: 100,
      );

      // Veritabanına kaydet
      await _servis.performansKaydet(model);

      // Haritayı güncelle
      guncelMap[id] = model;
    }

    // State'i yenile (Ekranda hepsi yeşil olacak)
    state = state.copyWith(performanslar: guncelMap);
  }
}

// 3. PROVIDER TANIMI
final performansProvider =
    StateNotifierProvider<PerformansNotifier, GunlukPerformansState>((ref) {
      return PerformansNotifier();
    });
