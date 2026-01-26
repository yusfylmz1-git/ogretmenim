import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:ui';
import 'dart:io';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({Key? key}) : super(key: key);

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  bool _loading = false;
  String? _hataMesaji;
  bool _kvkkOnay = false;

  // --- ÜSTTEN İNEN MODERN UYARI ---
  void _usttenUyariGoster(BuildContext context, String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mesaj,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE11D48),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          left: 20,
          right: 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- KVKK ÖNİZLEME PENCERESİ ---
  void _kvkkOnizlemeGoster(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'KVKK ve Gizlilik Sözleşmesi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Bu sözleşme, kişisel verilerinizin nasıl işlendiğini ve korunduğunu açıklamaktadır...\n\n'
            '1. Veri Sorumlusu: Öğretmen Asistanı Ekibi\n'
            '2. İşlenen Veriler: Google Profil Bilgileri\n'
            '3. Amaç: Uygulama içi senkronizasyon ve kullanıcı deneyimi geliştirme.\n\n'
            'Verileriniz asla üçüncü taraflarla paylaşılmaz.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ANLADIM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2070A3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ÇIKIŞ ONAY PANELİ ---
  void _cikisOnaySorgusu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 45,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () => exit(0),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Text(
                    'Çıkış Yap',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFF453A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.white12, thickness: 1),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 1.2),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Vazgeç',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 35),
            ],
          ),
        );
      },
    );
  }

  // --- GİRİŞ MANTIĞI (GÜNCELLENDİ) ---
  Future<void> _googleIleGiris() async {
    // 1. KVKK Kontrolü
    if (!_kvkkOnay) {
      _usttenUyariGoster(
        context,
        'Devam etmek için KVKK metnini onaylamanız gerekir.',
      );
      return;
    }

    // 2. Yükleniyor durumunu başlat
    setState(() {
      _loading = true;
      _hataMesaji = null;
    });

    try {
      // 3. Google Sign-In Başlat
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Kullanıcı iptal ettiyse yükleniyor'u kapat
      if (googleUser == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      // 4. Google'dan Kimlik Bilgilerini Al
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Firebase'e Giriş Yap
      // BURASI ÖNEMLİ: Giriş başarılı olduğu an main.dart'taki StreamBuilder tetiklenir
      // ve bu sayfa (GirisEkrani) dispose edilir (yok edilir).
      await FirebaseAuth.instance.signInWithCredential(credential);

      // BAŞARILI OLURSA BURADAN SONRA HİÇBİR ŞEY YAPMIYORUZ.
      // setState() ÇAĞIRMIYORUZ. Çünkü sayfa artık yok.
    } catch (e) {
      // Sadece hata olursa ekran hala açıktır, o zaman kullanıcıya bilgi ver.
      if (mounted) {
        setState(() {
          _hataMesaji = 'Giriş başarısız: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _cikisOnaySorgusu(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Arka Plan Süslemeleri
            Positioned(
              top: -height * 0.1,
              left: -width * 0.2,
              child: Container(
                width: width * 0.8,
                height: width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE0F2FE).withOpacity(0.6),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: height * 0.2,
              right: -width * 0.3,
              child: Container(
                width: width * 0.7,
                height: width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFF0FDF4).withOpacity(0.5),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.transparent),
            ),

            // İçerik (Logo ve Hoş Geldiniz)
            Positioned(
              top: height * 0.12,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Image.asset(
                    'assets/splash_logo.png',
                    height: height * 0.22,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 35),
                  const Text(
                    'Hoş Geldiniz',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Eğitimde dijital dönüşümün adresi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Alt Mavi Panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: height * 0.42,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2070A3), Color(0xFF60A5FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Giriş Yapın',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Devam etmek için hesabınızı kullanın.',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      const SizedBox(height: 25),
                      if (_hataMesaji != null)
                        Text(
                          _hataMesaji!,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                          ),
                        ),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _googleIleGiris,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(strokeWidth: 2)
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/google_logo.png',
                                      height: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Google ile Devam Et',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // KVKK Checkbox ve Sade Metin
                      Row(
                        children: [
                          Checkbox(
                            value: _kvkkOnay,
                            activeColor: Colors.white,
                            checkColor: const Color(0xFF2070A3),
                            onChanged: (val) =>
                                setState(() => _kvkkOnay = val!),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _kvkkOnizlemeGoster(context),
                              child: const Text(
                                'KVKK Aydınlatma Metni ve Gizlilik Sözleşmesini okudum, onaylıyorum.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '© 2026 Öğretmen Asistanı. Tüm hakları saklıdır.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
