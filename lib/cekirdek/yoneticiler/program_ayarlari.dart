import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgramAyarlari {
  // Varsayılan Değerler
  static TimeOfDay ilkDersSaati = const TimeOfDay(hour: 8, minute: 0);
  static int dersSuresi = 40;
  static int teneffusSuresi = 10;
  static int gunlukDersSayisi = 8; // YENİ ÖZELLİK
  static bool ogleArasiVarMi = false; // YENİ ÖZELLİK
  static int ogleArasiSuresi = 45; // YENİ ÖZELLİK

  // Hafızadan Ayarları Yükle (Uygulama açılırken çalışır)
  static Future<void> ayarlariYukle() async {
    final prefs = await SharedPreferences.getInstance();

    // Eski isimlerle (baslangic_saat) çakışmaması için yeni anahtarlar kullandık
    int hour = prefs.getInt('ilkDersSaatiHour') ?? 8;
    int minute = prefs.getInt('ilkDersSaatiMinute') ?? 0;
    ilkDersSaati = TimeOfDay(hour: hour, minute: minute);

    dersSuresi = prefs.getInt('dersSuresi') ?? 40;
    teneffusSuresi = prefs.getInt('teneffusSuresi') ?? 10;

    // Yeni özelliklerin yüklenmesi
    gunlukDersSayisi = prefs.getInt('gunlukDersSayisi') ?? 8;
    ogleArasiVarMi = prefs.getBool('ogleArasiVarMi') ?? false;
    ogleArasiSuresi = prefs.getInt('ogleArasiSuresi') ?? 45;
  }
}
