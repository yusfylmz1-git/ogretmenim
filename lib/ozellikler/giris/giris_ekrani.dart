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
  bool _kvkkOnay = true;

  // --- GÖRSELDEKİYLE AYNI MODERN DARK BOTTOM SHEET ---
  void _cikisOnaySorgusu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87, // Arka planı daha koyu karartır
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E), // Görseldeki koyu antrasit tonu
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Üstteki gri tutamaç (Handle)
              Container(
                width: 45,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Tıklanabilir "Çıkış Yap" Yazısı (Görseldeki gibi turuncu-kırmızı tonu)
              InkWell(
                onTap: () => exit(0),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Text(
                    'Çıkış Yap',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFF453A), // Modern iOS/Banka kırmızısı
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Görseldeki ince ayraç çizgisi
              const Divider(color: Colors.white12, thickness: 1),
              const SizedBox(height: 25),
              // Oval Vazgeç Butonu (Görseldeki beyaz çerçeveli stadium buton)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 1.2),
                      shape: const StadiumBorder(), // Görseldeki tam oval yapı
                    ),
                    child: const Text(
                      'Vazgeç',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 35), // Alt navigasyon çubuğu için pay
            ],
          ),
        );
      },
    );
  }

  Future<void> _googleIleGiris() async {
    if (!_kvkkOnay) {
      setState(() => _hataMesaji = 'Lütfen sözleşmeyi onaylayın.');
      return;
    }
    setState(() {
      _loading = true;
      _hataMesaji = null;
    });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _loading = false;
          _hataMesaji = 'Giriş iptal edildi.';
        });
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      setState(() => _hataMesaji = 'Giriş başarısız: $e');
    } finally {
      setState(() => _loading = false);
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
            // --- ARKA PLAN SÜSLEMELERİ ---
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

            // --- İÇERİK ---
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

            // --- ALT MAVİ PANEL ---
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

                      // KVKK Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _kvkkOnay,
                            activeColor: Colors.white,
                            checkColor: const Color(0xFF2070A3),
                            onChanged: (val) =>
                                setState(() => _kvkkOnay = val!),
                          ),
                          const Expanded(
                            child: Text(
                              'KVKK Aydınlatma Metni ve Gizlilik Sözleşmesini okudum, onaylıyorum.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
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
