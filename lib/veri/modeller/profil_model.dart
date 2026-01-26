import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilModel {
  final String uid; // Firebase User ID
  String? ad;
  String? soyad;
  String? brans;
  String? okul;
  String? mudur;
  String? cinsiyet;
  String? fotoUrl;

  ProfilModel({
    required this.uid,
    this.ad,
    this.soyad,
    this.brans,
    this.okul,
    this.mudur,
    this.cinsiyet = 'Erkek',
    this.fotoUrl,
  });

  // --- FIREBASE'DEN VERİ ÇEKME ---
  Future<void> verileriFirestoredanYukle() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        ad = data['ad'];
        soyad = data['soyad'];
        brans = data['brans'];
        okul = data['okul'];
        mudur = data['mudur'];
        cinsiyet = data['cinsiyet'] ?? 'Erkek';
        fotoUrl =
            data['fotoUrl'] ??
            data['photoUrl']; // photoUrl eski kayıtlardan kalmış olabilir
      }
    } catch (e) {
      print("Firestore veri yükleme hatası: $e");
      rethrow;
    }
  }

  // --- FIREBASE'E VERİ KAYDETME ---
  Future<void> verileriFirestoreaKaydet({
    required String ad,
    required String soyad,
    required String brans,
    required String okul,
    required String mudur,
    required String cinsiyet,
    String? fotoUrl,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'ad': ad,
        'soyad': soyad,
        'brans': brans,
        'okul': okul,
        'mudur': mudur,
        'cinsiyet': cinsiyet,
        'fotoUrl': fotoUrl,
        'sonGuncelleme': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Mevcut diğer verileri bozmadan birleştirir
    } catch (e) {
      print("Firestore veri kaydetme hatası: $e");
      rethrow;
    }
  }

  // Gerektiğinde Map'e çevirmek için (Mevcut yapıyı korumak adına ekledik)
  Map<String, dynamic> toMap() {
    return {
      'ad': ad,
      'soyad': soyad,
      'brans': brans,
      'okul': okul,
      'mudur': mudur,
      'cinsiyet': cinsiyet,
      'fotoUrl': fotoUrl,
    };
  }
}
