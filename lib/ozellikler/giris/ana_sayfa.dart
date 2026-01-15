import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ogretmenim/gen_l10n/app_localizations.dart';
// 👇 1. DEĞİŞİKLİK BURADA: Yeni sayfayı import ettik
import 'package:ogretmenim/ozellikler/siniflar/siniflar_sayfasi.dart';

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
      const MerkezSayfa(), // 0: Özet
      const SiniflarSayfasi(), // 1: 👇 2. DEĞİŞİKLİK BURADA: SınıflarSayfasi eklendi
      Center(child: Text(dil.program)), // 2: Program (Sonra yapılacak)
      Center(child: Text(dil.menu)), // 3: Menü
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
          NavigationDestination(icon: const Icon(Icons.menu), label: dil.menu),
        ],
      ),
    );
  }
}

class MerkezSayfa extends StatelessWidget {
  const MerkezSayfa({super.key});

  @override
  Widget build(BuildContext context) {
    final dil = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          dil.uygulamaBasligi,
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dil.hosgeldin,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  dil.bugunDersProgramiBos,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
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
