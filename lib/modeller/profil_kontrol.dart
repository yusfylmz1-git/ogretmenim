import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<bool> profilEksikMi(String uid) async {
  try {
    // 1. ÖNCE TELEFONUN KENDİ HAFIZASINA BAK (En Hızlı Yöntem)
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Hafızayı tazele (Çok önemli!)

    final localAd = prefs.getString('profil_ad');

    // Eğer telefonda isim varsa, veritabanını bekleme, direkt geçir.
    if (localAd != null && localAd.isNotEmpty) {
      print("✅ Profil Kontrol: Yerel hafızada veri var. Giriş izni verildi.");
      return false; // EKSİK DEĞİL (Geçir)
    }

    // 2. GOOGLE HESABI VARSA DİREKT GEÇİR (KİLİDİ KIRAN HAMLE)
    // Veritabanı bozuk olsa bile, kullanıcı Google ile girmişse onu engelleme.
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print(
        "✨ Profil Kontrol: Google kullanıcısı tespit edildi. Giriş izni veriliyor.",
      );

      // Google'dan gelen ismi hemen yerel hafızaya kaydedelim ki bir dahaki sefere sormasın
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        String ad = user.displayName!.split(" ").first;
        await prefs.setString('profil_ad', ad);
      } else {
        await prefs.setString('profil_ad', "Öğretmen");
      }

      // *** BURASI ÇOK ÖNEMLİ ***
      // Kullanıcı giriş yapmışsa kesinlikle 'false' dönüyoruz.
      return false;
    }

    // 3. FIREBASE KONTROLÜ (Yedek)
    // Not: Burası 'users' olmalı çünkü ProfilModel oraya kaydediyor.
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('ad') && data['ad'].toString().isNotEmpty) {
        await prefs.setString(
          'profil_ad',
          data['ad'],
        ); // Bulunca telefona da yaz
        return false; // EKSİK DEĞİL
      }
    }

    // Hiçbir yerde yoksa eksiktir
    return true;
  } catch (e) {
    // Hata durumunda (İnternet yok vs.) kullanıcıyı ayarlara hapsetmek yerine
    // içeri alalım (Bypass).
    print("Profil kontrol hatası (Bypass edildi): $e");
    return false; // HATA OLSA BİLE GEÇİR
  }
}
