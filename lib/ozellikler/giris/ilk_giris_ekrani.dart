import 'package:flutter/material.dart';

class IlkGirisEkrani extends StatelessWidget {
  const IlkGirisEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                // Uygulama adı
                Text(
                  'ÖĞRETMEN\nASİSTANI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A7BD5),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                // Hoş geldiniz
                const Text(
                  'Hoş Geldiniz!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Öğretmenlik yolculuğunuzda yanınızdayız.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 32),
                // Google ile giriş butonu
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: Image.asset('assets/icon.png', width: 28, height: 28),
                    label: const Text(
                      'Google ile Giriş Yap',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {}, // TODO: Google giriş fonksiyonu
                  ),
                ),
                const SizedBox(height: 24),
                // KVKK ve Gizlilik metni
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(value: true, onChanged: (v) {}),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                          children: [
                            const TextSpan(text: 'KVKK Aydınlatma Metni ve '),
                            TextSpan(
                              text: 'Gizlilik Sözleşmesi',
                              style: const TextStyle(
                                color: Color(0xFF3A7BD5),
                                decoration: TextDecoration.underline,
                              ),
                              // TODO: onTap ile link açılabilir
                            ),
                            const TextSpan(text: "'ni okudum, onaylıyorum."),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
