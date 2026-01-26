import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilModel {
  final String uid;
  String? ad;
  String? soyad;
  String? brans;
  String? okul;
  String? mudur;
  String? cinsiyet;
  String? fotoUrl;

  // Constructor güncellendi: İster boş, ister dolu başlatılabilir.
  ProfilModel({
    required this.uid,
    this.ad,
    this.soyad,
    this.brans,
    this.okul,
    this.mudur,
    this.cinsiyet,
    this.fotoUrl,
  });

  // --- FIREBASE'DEN VERİ ÇEKME ---
  Future<void> verileriFirestoredanYukle() async {
    try {
      // Standart olarak 'users' koleksiyonunu kullanıyoruz.
      // Eğer 'teachers' kullanmak istersen burayı değiştirebilirsin.
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        ad = data['ad'] ?? '';
        soyad = data['soyad'] ?? '';
        brans = data['brans'] ?? '';
        okul = data['okul'] ?? '';
        mudur = data['mudur'] ?? '';
        cinsiyet = data['cinsiyet'] ?? 'Erkek';
        fotoUrl = data['fotoUrl'] ?? data['profilFotoUrl'];
      }
    } catch (e) {
      print("Veri yükleme hatası: $e");
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
        'fotoUrl': fotoUrl, // UI ile uyumlu isimlendirme
        'guncellemeTarihi': FieldValue.serverTimestamp(),
        // Senin eklediğin güzel özellikler:
        'rol': 'ogretmen',
        'vipUye': false,
      }, SetOptions(merge: true)); // Mevcut veriyi ezmeden birleştirir
    } catch (e) {
      print("Veri kaydetme hatası: $e");
      rethrow;
    }
  }

  // UI tarafında bazen tüm objeyi map olarak istemiştik, bu metod sigorta görevi görür
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
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
