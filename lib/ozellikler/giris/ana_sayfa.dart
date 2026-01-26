import 'package:flutter/material.dart';
import 'package:ogretmenim/gen_l10n/app_localizations.dart';
import 'package:ogretmenim/ozellikler/siniflar/siniflar_sayfasi.dart';
import 'package:ogretmenim/ozellikler/ozet/ozet_sayfasi.dart';
import 'package:ogretmenim/ozellikler/ders_programi/ders_programi_sayfasi.dart';
// Profil ayarlarını (Menü) import ediyoruz
import 'package:ogretmenim/ozellikler/profil/profil_ayarlari.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _seciliIndex = 0;

  @override
  Widget build(BuildContext context) {
    final dil = AppLocalizations.of(context)!;

    // Sayfa listesi
    final List<Widget> sayfalar = [
      const OzetSayfasi(), // 0: Özet
      const SiniflarSayfasi(), // 1: Sınıflar
      const DersProgramiSayfasi(), // 2: Ders Programı
      const ProfilAyarlariSayfasi(), // 3: Menü (Profil/Ayarlar) -> DÜZELTİLDİ
    ];

    return Scaffold(
      body: sayfalar[_seciliIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seciliIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _seciliIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: dil.ozet,
          ),
          NavigationDestination(
            icon: const Icon(Icons.class_outlined),
            selectedIcon: const Icon(Icons.class_),
            label: dil.siniflar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: dil.program,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline), // İkonu kişi yaptık
            selectedIcon: const Icon(Icons.person),
            label: dil.menu,
          ),
        ],
      ),
    );
  }
}
