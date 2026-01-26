import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ogretmenim/veri/modeller/ders_model.dart';
// Kendi veritabanı dosyası yolunu kontrol et 👇
import 'package:ogretmenim/veri/veritabani/veritabani_yardimcisi.dart';

final derslerProvider = StateNotifierProvider<DerslerNotifier, List<DersModel>>(
  (ref) => DerslerNotifier(),
);

class DerslerNotifier extends StateNotifier<List<DersModel>> {
  DerslerNotifier() : super([]) {
    dersleriYukle();
  }

  // 1. DERSLERİ YÜKLE
  Future<void> dersleriYukle() async {
    final veriListesi = await VeritabaniYardimcisi.instance.dersleriGetir();

    if (veriListesi.isNotEmpty) {
      state = veriListesi.map((x) => DersModel.fromMap(x)).toList();
    } else {
      await _firebasedenVerileriGetirVeYereleKaydet();
    }
  }

  // Firebase -> SQLite Senkronizasyonu
  Future<void> _firebasedenVerileriGetirVeYereleKaydet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('dersler')
          .get();

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data();
          // Modeldeki factory isimlendirmesine uyduk: firebaseId -> docId
          final ders = DersModel.fromMap(data, firebaseId: doc.id);

          await VeritabaniYardimcisi.instance.dersEkle(ders.toMap());
        }

        // Listeyi tekrar çek
        dersleriYukle();
      }
    } catch (e) {
      print("Firebase senkronizasyon hatası: $e");
    }
  }

  // 2. DERS EKLE
  Future<void> dersEkle(DersModel ders) async {
    // A. Yerele Ekle
    final int id = await VeritabaniYardimcisi.instance.dersEkle(ders.toMap());

    // Model'e eklediğimiz copyWith sayesinde artık bu çalışacak ✅
    final yeniDers = ders.copyWith(id: id);

    // State'i güncelle
    state = [...state, yeniDers];

    // B. Firebase'e Ekle
    _firebaseEkle(yeniDers);
  }

  // 3. DERS SİL
  Future<void> dersSil(int id, DersModel ders) async {
    // A. Yerelden Sil
    await VeritabaniYardimcisi.instance.dersSil(id);

    // State'i güncelle
    state = state.where((d) => d.id != id).toList();

    // B. Firebase'den Sil
    _firebaseSil(ders);
  }

  // 4. DERS GÜNCELLE
  Future<void> dersGuncelle(DersModel ders) async {
    // A. Yereli Güncelle
    await VeritabaniYardimcisi.instance.dersGuncelle(ders.toMap());

    // State'i güncelle (copyWith mantığıyla listeyi yeniliyoruz)
    state = [
      for (final d in state)
        if (d.id == ders.id) ders else d,
    ];

    // B. Firebase Güncelle
    _firebaseGuncelle(ders);
  }

  // --- FIREBASE YARDIMCILARI ---

  Future<void> _firebaseEkle(DersModel ders) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('dersler')
            .add(ders.toMap());
      } catch (e) {
        print("Firebase ekleme hatası: $e");
      }
    }
  }

  Future<void> _firebaseSil(DersModel ders) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Modelindeki isim 'docId' olduğu için onu kullanıyoruz ✅
        if (ders.docId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('dersler')
              .doc(ders.docId)
              .delete();
        } else {
          // docId yoksa özelliklere göre bulup sil (Eski veriler için güvenlik)
          final query = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('dersler')
              .where('ders_adi', isEqualTo: ders.dersAdi)
              .where('gun', isEqualTo: ders.gun)
              .where('ders_saati_index', isEqualTo: ders.dersSaatiIndex)
              .get();

          for (var doc in query.docs) {
            await doc.reference.delete();
          }
        }
      } catch (e) {
        print("Firebase silme hatası: $e");
      }
    }
  }

  Future<void> _firebaseGuncelle(DersModel ders) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Modelindeki isim 'docId' ✅
      if (ders.docId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('dersler')
            .doc(ders.docId)
            .update(ders.toMap());
      } else {
        // ID yoksa silip tekrar ekle
        await _firebaseSil(ders);
        await _firebaseEkle(ders);
      }
    } catch (e) {
      print("Firebase güncelleme hatası: $e");
    }
  }
}
