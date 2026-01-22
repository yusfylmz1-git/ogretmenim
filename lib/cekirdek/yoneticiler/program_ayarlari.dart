import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgramAyarlari {
  static TimeOfDay baslangicSaati = const TimeOfDay(hour: 8, minute: 0);
  static int dersSuresi = 40;
  static int teneffusSuresi = 10;

  static Future<void> ayarlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    int hour = prefs.getInt('baslangic_saat') ?? 8;
    int minute = prefs.getInt('baslangic_dakika') ?? 0;
    baslangicSaati = TimeOfDay(hour: hour, minute: minute);
    dersSuresi = prefs.getInt('ders_suresi') ?? 40;
    teneffusSuresi = prefs.getInt('teneffus_suresi') ?? 10;
  }

  static Future<void> ayarlariKaydet(
    TimeOfDay baslangic,
    int ders,
    int teneffus,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('baslangic_saat', baslangic.hour);
    await prefs.setInt('baslangic_dakika', baslangic.minute);
    await prefs.setInt('ders_suresi', ders);
    await prefs.setInt('teneffus_suresi', teneffus);

    // Değerleri güncelle
    baslangicSaati = baslangic;
    dersSuresi = ders;
    teneffusSuresi = teneffus;
  }
}
