import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ogretmenim/veri/modeller/ogrenci_model.dart';
import 'package:ogretmenim/veri/veritabani/veritabani_yardimcisi.dart';

final ogrencilerProvider =
    StateNotifierProvider<OgrencilerNotifier, List<OgrenciModel>>(
      (ref) => OgrencilerNotifier(),
    );

class OgrencilerNotifier extends StateNotifier<List<OgrenciModel>> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  OgrencilerNotifier() : super([]);

  // 1. ÖĞRENCİLERİ YÜKLE
  Future<void> ogrencileriYukle(int sinifId) async {
    try {
      final veriListesi = await VeritabaniYardimcisi.instance.ogrencileriGetir(
        sinifId,
      );

      if (veriListesi.isNotEmpty) {
        // Yerelde veri varsa listele
        state = veriListesi.map((x) => OgrenciModel.fromMap(x)).toList();
      } else {
        // Yerel boşsa buluttan çek
        await _firebasedenCekVeYereleKaydet(sinifId);
      }
    } catch (e) {
      print("Öğrenci yükleme hatası: $e");
    }
  }

  // Firebase -> SQLite Senkronizasyonu
  Future<void> _firebasedenCekVeYereleKaydet(int sinifId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('ogrenciler')
          .where('sinif_id', isEqualTo: sinifId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Mevcut yerel öğrencileri al (Numara bazlı kontrol için)
        final mevcutOgrenciler = await VeritabaniYardimcisi.instance
            .ogrencileriGetir(sinifId);
        final mevcutNumaralar = mevcutOgrenciler
            .map((e) => e['numara'].toString())
            .toSet();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          String numara = data['numara']?.toString() ?? '';

          // Eğer bu numara bu sınıfta zaten varsa, tekrar ekleme (Hayalet öğrenci önlemi)
          if (mevcutNumaralar.contains(numara)) continue;

          final ogrenci = OgrenciModel(
            id: null,
            docId: doc.id,
            ad: data['ad'] ?? '',
            soyad: data['soyad'] ?? '',
            numara: numara,
            sinifId: sinifId,
            cinsiyet: data['cinsiyet'] ?? 'Erkek',
            fotoYolu: data['foto_yolu'] ?? data['fotoUrl'],
            olusturulmaTarihi: data['olusturulmaTarihi']?.toString(),
            sinifAdi: data['sinifAdi'],
          );

          await VeritabaniYardimcisi.instance.ogrenciEkle(ogrenci.toMap());
        }

        // Listeyi son kez yerelden çek ve state'i güncelle
        final guncelVeri = await VeritabaniYardimcisi.instance.ogrencileriGetir(
          sinifId,
        );
        state = guncelVeri.map((x) => OgrenciModel.fromMap(x)).toList();
      } else {
        state = [];
      }
    } catch (e) {
      print("Firebase'den öğrenci çekme hatası: $e");
    }
  }

  // 2. ÖĞRENCİ EKLE (Önce Yerel, Sonra Bulut)
  Future<void> ogrenciEkle(OgrenciModel ogrenci) async {
    try {
      // A. SQLite'a ekle ve yeni ID'yi al
      final yeniId = await VeritabaniYardimcisi.instance.ogrenciEkle(
        ogrenci.toMap(),
      );

      // B. State'i hemen güncelle (Anlık tepki için)
      final yeniOgrenci = ogrenci.copyWith(id: yeniId);
      state = [...state, yeniOgrenci];

      // C. Firebase'e ekle (Arka plan işlemi gibi)
      final user = _auth.currentUser;
      if (user != null) {
        Map<String, dynamic> firebaseVeri = yeniOgrenci.toMap();
        firebaseVeri.remove('id'); // Yerel ID'yi göndermiyoruz
        firebaseVeri['olusturulmaTarihi'] = FieldValue.serverTimestamp();

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('ogrenciler')
            .add(firebaseVeri);
      }
    } catch (e) {
      print("Öğrenci ekleme hatası: $e");
    }
  }

  // 3. ÖĞRENCİ SİL
  Future<void> ogrenciSil(int id, int sinifId) async {
    OgrenciModel? silinecek;
    try {
      silinecek = state.firstWhere((o) => o.id == id);
    } catch (_) {}

    try {
      // A. Yerelden Sil
      await VeritabaniYardimcisi.instance.ogrenciSil(id);
      state = state.where((o) => o.id != id).toList();

      // B. Firebase'den Sil
      if (silinecek != null) {
        final user = _auth.currentUser;
        if (user != null) {
          final query = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('ogrenciler')
              .where('numara', isEqualTo: silinecek.numara)
              .where('sinif_id', isEqualTo: silinecek.sinifId)
              .get();

          for (var doc in query.docs) {
            await doc.reference.delete();
          }
        }
      }
    } catch (e) {
      print("Öğrenci silme hatası: $e");
    }
  }

  // 4. ÖĞRENCİ GÜNCELLE
  Future<void> ogrenciGuncelle(OgrenciModel ogrenci) async {
    try {
      // A. Yereli Güncelle
      await VeritabaniYardimcisi.instance.ogrenciGuncelle(ogrenci.toMap());

      // State güncelle
      state = [
        for (final o in state)
          if (o.id == ogrenci.id) ogrenci else o,
      ];

      // B. Firebase Güncelle
      final user = _auth.currentUser;
      if (user != null) {
        final query = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('ogrenciler')
            .where('numara', isEqualTo: ogrenci.numara)
            .where('sinif_id', isEqualTo: ogrenci.sinifId)
            .get();

        Map<String, dynamic> guncelVeri = ogrenci.toMap();
        guncelVeri.remove('id');

        for (var doc in query.docs) {
          await doc.reference.update(guncelVeri);
        }
      }
    } catch (e) {
      print("Öğrenci güncelleme hatası: $e");
    }
  }
}
