import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ogretmenim/veri/modeller/sinif_model.dart';
import 'package:ogretmenim/veri/veritabani/veritabani_yardimcisi.dart';

// UI Tarafından Kullanılacak Provider
final siniflarProvider =
    StateNotifierProvider<SiniflarNotifier, List<SinifModel>>(
      (ref) => SiniflarNotifier(),
    );

class SiniflarNotifier extends StateNotifier<List<SinifModel>> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  SiniflarNotifier() : super([]) {
    // Uygulama açılır açılmaz verileri yükle
    siniflariYukle(ilkAcilis: true);
  }

  // 1. VERİLERİ YÜKLE (Offline-First Mantığı)
  Future<void> siniflariYukle({bool ilkAcilis = false}) async {
    // Önce yerel veritabanına bak (Çok hızlıdır)
    final veriListesi = await VeritabaniYardimcisi.instance.siniflariGetir();

    if (veriListesi.isNotEmpty) {
      // Yerelde veri varsa hemen göster
      state = veriListesi.map((x) => SinifModel.fromMap(x)).toList();
    } else if (ilkAcilis) {
      // Yerel boşsa ve uygulama ilk kez açılıyorsa Firebase'den çekmeye çalış
      await _firebasedenVerileriGetirVeYereleKaydet();
    } else {
      // Yerel boşsa listeyi temizle (Örn: Hepsini sildikten sonra)
      state = [];
    }
  }

  // Firebase -> SQLite Senkronizasyonu
  Future<void> _firebasedenVerileriGetirVeYereleKaydet() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('siniflar')
          .get();

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final sinif = SinifModel(
            id: null, // ID'yi SQLite otomatik verecek
            sinifAdi: data['sinifAdi'] ?? data['ad'] ?? '',
            aciklama: data['aciklama'] ?? '',
            olusturulmaTarihi: data['olusturulmaTarihi']?.toString(),
          );
          // Yerel veritabanına kaydet (conflictAlgorithm: ignore sayesinde çakışma olmaz)
          await VeritabaniYardimcisi.instance.sinifEkle(sinif.toMap());
        }

        // Yerel veritabanını tekrar oku ve ekrana yansıt (ID'leri almak için)
        final guncelVeri = await VeritabaniYardimcisi.instance.siniflariGetir();
        state = guncelVeri.map((x) => SinifModel.fromMap(x)).toList();
      }
    } catch (e) {
      print("Sınıf çekme hatası: $e");
    }
  }

  // 2. EKLEME (Hem Yerel Hem Bulut)
  Future<void> sinifEkle(String ad, String aciklama) async {
    final yeniSinif = SinifModel(
      sinifAdi: ad,
      aciklama: aciklama,
      olusturulmaTarihi: DateTime.now().toIso8601String(),
    );

    // 1. SQLite'a ekle
    await VeritabaniYardimcisi.instance.sinifEkle(yeniSinif.toMap());

    // 2. Firebase'e ekle
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('siniflar')
            .add({
              'sinifAdi': ad,
              'aciklama': aciklama,
              'olusturulmaTarihi': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        print("Firebase kayıt hatası: $e");
      }
    }
    // Listeyi yenile
    await siniflariYukle();
  }

  // 3. SİLME (KRİTİK TEMİZLİK)
  Future<void> sinifSil(int id, String sinifAdi) async {
    // A. Yerelden Sil (Cascade ayarlıysa öğrencileri de siler)
    await VeritabaniYardimcisi.instance.sinifSil(id);

    // UI'ı hemen güncelle (Kullanıcı beklemesin)
    state = state.where((s) => s.id != id).toList();

    // B. Firebase Temizliği
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // 1. Sınıfı Bul ve Sil
        var classQuery = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('siniflar')
            .where('sinifAdi', isEqualTo: sinifAdi)
            .get();

        // Eski versiyon uyumluluğu ('ad' veya 'sinifAdi')
        if (classQuery.docs.isEmpty) {
          classQuery = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('siniflar')
              .where('ad', isEqualTo: sinifAdi)
              .get();
        }

        for (var doc in classQuery.docs) {
          await doc.reference.delete();
        }

        // 2. HAYALET ÖĞRENCİ TEMİZLİĞİ 👻
        // Bu sınıf ID'sine bağlı tüm öğrencileri bulup siliyoruz.
        var studentQuery = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('ogrenciler')
            .where('sinif_id', isEqualTo: id)
            .get();

        for (var doc in studentQuery.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        print("Firebase silme hatası: $e");
      }
    }
  }

  // 4. GÜNCELLEME
  Future<void> sinifGuncelle(
    int id,
    String eskiAd,
    String yeniAd,
    String yeniAciklama,
  ) async {
    final guncelSinif = SinifModel(
      id: id,
      sinifAdi: yeniAd,
      aciklama: yeniAciklama,
      olusturulmaTarihi: DateTime.now().toIso8601String(),
    );

    // Yerel Güncelleme
    await (await VeritabaniYardimcisi.instance.database).update(
      'siniflar',
      guncelSinif.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    // Firebase Güncelleme
    final user = _auth.currentUser;
    if (user != null) {
      try {
        var query = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('siniflar')
            .where('sinifAdi', isEqualTo: eskiAd)
            .get();

        if (query.docs.isEmpty) {
          query = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('siniflar')
              .where('ad', isEqualTo: eskiAd)
              .get();
        }

        for (var doc in query.docs) {
          await doc.reference.update({
            'sinifAdi': yeniAd,
            'aciklama': yeniAciklama,
          });
        }
      } catch (e) {}
    }
    await siniflariYukle();
  }
}
