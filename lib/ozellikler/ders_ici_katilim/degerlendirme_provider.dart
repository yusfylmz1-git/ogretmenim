import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Aşağıdaki model yolunun senin projendeki yerini kontrol et
import 'package:ogretmenim/veri/modeller/degerlendirme_model.dart';
import 'package:ogretmenim/veri/veritabani/veritabani_yardimcisi.dart';

final degerlendirmeProvider =
    StateNotifierProvider<DegerlendirmeNotifier, List<DegerlendirmeModel>>(
      (ref) => DegerlendirmeNotifier(),
    );

class DegerlendirmeNotifier extends StateNotifier<List<DegerlendirmeModel>> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  DegerlendirmeNotifier() : super([]);

  // --- 1. GEÇMİŞ DEĞERLENDİRMELERİ GETİR ---
  Future<void> gecmisiYukle(int ogrenciId, String dersAdi) async {
    try {
      final veriListesi = await VeritabaniYardimcisi.instance
          .ogrenciNotlariniGetir(ogrenciId, dersAdi);

      if (veriListesi.isNotEmpty) {
        // Veritabanından gelen Map listesini Model listesine çevir
        state = veriListesi.map((x) => DegerlendirmeModel.fromMap(x)).toList();
      } else {
        state = [];
      }
    } catch (e) {
      print("Geçmiş yükleme hatası: $e");
    }
  }

  // --- 2. PUAN KAYDET (SQLite + Firebase) ---
  Future<bool> puanKaydet({
    required int ogrenciId,
    required int sinifId,
    required String dersAdi,
    required Map<int, double> kriterPuanlari, // {kriterId: puan}
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Toplam Puanı Hesapla
    double toplamPuan = kriterPuanlari.values.fold(0, (a, b) => a + b);
    String tarih = DateTime.now().toIso8601String();

    try {
      final db = await VeritabaniYardimcisi.instance.database;

      // SQLite Transaction: Veri bütünlüğü için (Ya hepsi kaydolur ya hiçbiri)
      await db.transaction((txn) async {
        // A. Ana Tabloya Ekle
        int degerlendirmeId = await txn.insert('ogrenci_degerlendirmeleri', {
          'ogrenci_id': ogrenciId,
          'sinif_id': sinifId,
          'ders_adi': dersAdi,
          'tarih': tarih,
          'toplam_puan': toplamPuan,
        });

        // B. Detay Tablosuna Kriterleri Ekle
        for (var entry in kriterPuanlari.entries) {
          await txn.insert('degerlendirme_detaylari', {
            'degerlendirme_id': degerlendirmeId,
            'kriter_id': entry.key,
            'verilen_puan': entry.value,
          });
        }

        // C. State'i Güncelle (Listeye yeni kaydı ekle ki arayüz güncellensin)
        final yeniKayit = DegerlendirmeModel(
          id: degerlendirmeId,
          ogrenciId: ogrenciId,
          sinifId: sinifId,
          dersAdi: dersAdi,
          tarih: tarih,
          toplamPuan: toplamPuan,
          kriterPuanlari: kriterPuanlari,
        );
        state = [yeniKayit, ...state];
      });

      // D. Firebase Yedekleme (Arka planda çalışır, UI'ı bekletmez)
      _firebaseYedekle(
        uid: user.uid,
        ogrenciId: ogrenciId,
        sinifId: sinifId,
        dersAdi: dersAdi,
        toplamPuan: toplamPuan,
        kriterPuanlari: kriterPuanlari,
        tarih: tarih,
      );

      return true;
    } catch (e) {
      print("Kayıt hatası: $e");
      return false;
    }
  }

  // --- 3. FIREBASE YEDEKLEME (Private) ---
  Future<void> _firebaseYedekle({
    required String uid,
    required int ogrenciId,
    required int sinifId,
    required String dersAdi,
    required double toplamPuan,
    required Map<int, double> kriterPuanlari,
    required String tarih,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('degerlendirmeler')
          .add({
            'local_ogrenci_id': ogrenciId,
            'local_sinif_id': sinifId,
            'ders_adi': dersAdi,
            'tarih': tarih,
            'toplam_puan': toplamPuan,
            'detaylar': kriterPuanlari.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print("Firebase yedekleme hatası: $e");
    }
  }
}
