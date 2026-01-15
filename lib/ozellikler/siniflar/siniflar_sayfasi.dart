import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ogretmenim/gen_l10n/app_localizations.dart';
import 'package:ogretmenim/ozellikler/siniflar/siniflar_provider.dart';
import 'package:ogretmenim/ozellikler/ogrenciler/ogrenciler_sayfasi.dart';

class SiniflarSayfasi extends ConsumerWidget {
  const SiniflarSayfasi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dil = AppLocalizations.of(context)!;
    final sinifListesi = ref.watch(siniflarProvider);

    return Scaffold(
      appBar: AppBar(title: Text(dil.siniflar)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _sinifEkleDialogGoster(context, ref, dil),
        label: Text(dil.sinifEkle),
        icon: const Icon(Icons.add),
      ),
      body: sinifListesi.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.class_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    dil.sinifMevcutDegil,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sinifListesi.length,
              itemBuilder: (context, index) {
                final sinif = sinifListesi[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.1),
                      child: Text(
                        sinif.sinifAdi.isNotEmpty
                            ? sinif.sinifAdi[0].toUpperCase()
                            : "?",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      sinif.sinifAdi,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle:
                        sinif.aciklama != null && sinif.aciklama!.isNotEmpty
                        ? Text(sinif.aciklama!)
                        : null,
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      // Tıklanan sınıfı parametre olarak gönderiyoruz
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OgrencilerSayfasi(sinif: sinif),
                        ),
                      );
                    },
                    onLongPress: () {
                      _silmeOnayiGoster(context, ref, sinif.id!, dil);
                    },
                  ),
                );
              },
            ),
    );
  }

  // YARDIMCI: Girişi Formatla (5a -> 5-A, lab -> LAB)
  String _formatla(String giris) {
    final sayiMatch = RegExp(r'(\d+)').firstMatch(giris);
    final harfMatch = RegExp(r'([a-zA-ZğüşıöçĞÜŞİÖÇ]+)').firstMatch(giris);

    // Sadece hem sayı hem harf varsa araya tire koy (Örn: 5a -> 5-A)
    if (sayiMatch != null && harfMatch != null) {
      String sayi = sayiMatch.group(0)!;
      String harf = harfMatch.group(0)!.toUpperCase();
      return "$sayi-$harf";
    }

    // Yoksa (Örn: LAB, Müzik, 12) olduğu gibi büyük harf yap
    return giris.toUpperCase().trim();
  }

  void _sinifEkleDialogGoster(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations dil,
  ) {
    final adController = TextEditingController();
    final aciklamaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dil.sinifEkle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: adController,
              // 👇 YENİ: Maksimum 15 karakter (Örn: "Fen Bilgisi Lab" sığsın diye)
              maxLength: 15,
              decoration: InputDecoration(
                labelText: dil.sinifAdi,
                hintText: "Örn: 5-A, LAB",
                border: const OutlineInputBorder(),
                // 👇 YENİ: Karakter sayacını (0/15) gizler, temiz görünür
                counterText: "",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: aciklamaController,
              // Açıklama biraz daha uzun olabilir
              maxLength: 50,
              decoration: InputDecoration(
                labelText: dil.aciklama,
                border: const OutlineInputBorder(),
                counterText: "",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(dil.iptal),
          ),
          ElevatedButton(
            onPressed: () {
              if (adController.text.trim().isNotEmpty) {
                // Boşlukları sil ve formatla
                String formatliAd = _formatla(adController.text);

                ref
                    .read(siniflarProvider.notifier)
                    .sinifEkle(formatliAd, aciklamaController.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text(dil.kaydet),
          ),
        ],
      ),
    );
  }

  void _silmeOnayiGoster(
    BuildContext context,
    WidgetRef ref,
    int id,
    AppLocalizations dil,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dil.sinifSil),
        content: Text(dil.sinifSilOnay),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(dil.iptal),
          ),
          TextButton(
            onPressed: () {
              ref.read(siniflarProvider.notifier).sinifSil(id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(dil.sinifSil),
          ),
        ],
      ),
    );
  }
}
