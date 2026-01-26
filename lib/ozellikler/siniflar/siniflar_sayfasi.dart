import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ogretmenim/gen_l10n/app_localizations.dart';
import 'package:ogretmenim/ozellikler/ogrenciler/ogrenciler_sayfasi.dart';
import 'package:ogretmenim/ozellikler/profil/profil_ayarlari.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/veri/modeller/sinif_model.dart';
import 'siniflar_provider.dart';

class SiniflarSayfasi extends ConsumerStatefulWidget {
  const SiniflarSayfasi({super.key});

  @override
  ConsumerState<SiniflarSayfasi> createState() => _SiniflarSayfasiState();
}

class _SiniflarSayfasiState extends ConsumerState<SiniflarSayfasi> {
  final List<Color> _kartRenkleri = [
    const Color(0xFF7B61FF),
    const Color(0xFFFF8B66),
    const Color(0xFFD96FF8),
    const Color(0xFFF25A7F),
    const Color(0xFF63C6FF),
  ];

  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Sayfa açılırken verileri tazeleyelim (Garanti olsun)
    Future.microtask(() {
      ref.read(siniflarProvider.notifier).siniflariYukle();
    });
  }

  // --- FORMATLAMA ---
  String _formatla(String giris) {
    String islenen = giris.replaceAll(
      RegExp(r'[^a-zA-Z0-9ğüşıöçĞÜŞİÖÇ]+'),
      '-',
    );
    islenen = islenen.replaceAllMapped(
      RegExp(r'(\d)([a-zA-ZğüşıöçĞÜŞİÖÇ])'),
      (match) => '${match.group(1)}-${match.group(2)}',
    );
    if (islenen.startsWith('-')) islenen = islenen.substring(1);
    if (islenen.endsWith('-'))
      islenen = islenen.substring(0, islenen.length - 1);
    return islenen.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dil = AppLocalizations.of(context)!;
    final anaRenk = ProjeTemasi.anaRenk;
    final user = _auth.currentUser;

    // YERELDEN VERİYİ DİNLİYORUZ (HİBRİT)
    final sinifListesi = ref.watch(siniflarProvider);

    return ProjeSayfaSablonu(
      baslikWidget: _profilBaslikWidget(context, dil, user),
      aksiyonlar: [_ekleButonu(context, dil)],
      icerik: sinifListesi.isEmpty
          ? _bosDurumWidget(dil)
          : ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
              children: _gruplanmisListeyiOlustur(sinifListesi, anaRenk, dil),
            ),
    );
  }

  // --- LİSTE OLUŞTURUCU (GÜNCELLENDİ: SIRALAMA EKLENDİ) ---
  List<Widget> _gruplanmisListeyiOlustur(
    List<SinifModel> tumSiniflar,
    Color anaRenk,
    AppLocalizations dil,
  ) {
    Map<String, List<SinifModel>> gruplar = {};

    for (var sinif in tumSiniflar) {
      String grupAdi = sinif.sinifAdi.split('-')[0];
      if (!gruplar.containsKey(grupAdi)) {
        gruplar[grupAdi] = [];
      }
      gruplar[grupAdi]!.add(sinif);
    }

    // 1. Grupları (5, 6, 7...) Sırala
    var siraliGruplar = gruplar.keys.toList();
    siraliGruplar.sort((a, b) {
      int? s1 = int.tryParse(a);
      int? s2 = int.tryParse(b);
      if (s1 != null && s2 != null) return s1.compareTo(s2);
      return a.compareTo(b);
    });

    List<Widget> widgetListesi = [];
    int globalIndex = 0;

    for (var grupAdi in siraliGruplar) {
      var siniflar = gruplar[grupAdi]!;

      // 2. Şubeleri (A, B, C...) Kendi İçinde Sırala
      siniflar.sort((a, b) => a.sinifAdi.compareTo(b.sinifAdi));

      widgetListesi.add(_grupBasligi(grupAdi, siniflar.length, anaRenk));

      for (var sinif in siniflar) {
        widgetListesi.add(_modernSinifKarti(sinif, context, dil, globalIndex));
        widgetListesi.add(const SizedBox(height: 10)); // Kartlar arası boşluk
        globalIndex++;
      }
    }
    return widgetListesi;
  }

  // --- YARDIMCI WIDGETLAR ---

  Widget _modernSinifKarti(
    SinifModel sinif,
    BuildContext context,
    AppLocalizations dil,
    int index,
  ) {
    final renk = _kartRenkleri[index % _kartRenkleri.length];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OgrencilerSayfasi(sinif: sinif),
          ),
        ),
        borderRadius: BorderRadius.circular(15),
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: renk,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                sinif.sinifAdi,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.edit_note_rounded,
                color: Colors.blueGrey,
                size: 24,
              ),
              onPressed: () => _sinifIslemPaneli(context, dil, sinif),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: Colors.redAccent,
                size: 22,
              ),
              onPressed: () => _modernSilmeOnayi(context, sinif),
            ),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }

  void _sinifIslemPaneli(
    BuildContext context,
    AppLocalizations dil,
    SinifModel? sinif,
  ) {
    final bool duzenlemeModu = sinif != null;
    final adController = TextEditingController(text: sinif?.sinifAdi ?? "");
    final aciklamaController = TextEditingController(
      text: sinif?.aciklama ?? "",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 15,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              duzenlemeModu ? "Sınıfı Düzenle" : dil.sinifEkle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: adController,
              autofocus: true,
              maxLength: 10,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: dil.sinifAdi,
                prefixIcon: const Icon(Icons.class_rounded, size: 20),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterText: "",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: aciklamaController,
              maxLength: 30,
              decoration: InputDecoration(
                labelText: dil.aciklama,
                prefixIcon: const Icon(Icons.description_rounded, size: 20),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterText: "",
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProjeTemasi.anaRenk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (adController.text.isNotEmpty) {
                    String formatliAd = _formatla(adController.text);
                    if (duzenlemeModu) {
                      ref
                          .read(siniflarProvider.notifier)
                          .sinifGuncelle(
                            sinif.id!,
                            sinif.sinifAdi,
                            formatliAd,
                            aciklamaController.text.trim(),
                          );
                    } else {
                      ref
                          .read(siniflarProvider.notifier)
                          .sinifEkle(
                            formatliAd,
                            aciklamaController.text.trim(),
                          );
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  duzenlemeModu ? "GÜNCELLE" : dil.kaydet,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _modernSilmeOnayi(BuildContext context, SinifModel sinif) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          sinif.sinifAdi,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Bu sınıf silinecek. Onaylıyor musunuz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İPTAL"),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(siniflarProvider.notifier)
                  .sinifSil(sinif.id!, sinif.sinifAdi);
              Navigator.pop(context);
            },
            child: const Text("SİL", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _ekleButonu(BuildContext context, AppLocalizations dil) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Material(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _sinifIslemPaneli(context, dil, null),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF1E293B),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  dil.sinifEkle.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profilBaslikWidget(
    BuildContext context,
    AppLocalizations dil,
    User? user,
  ) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfilAyarlariSayfasi(),
              ),
            ).then((_) => setState(() {}));
          },
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            backgroundImage: (user?.photoURL != null)
                ? NetworkImage(user!.photoURL!)
                : null,
            child: (user?.photoURL == null)
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          dil.siniflar,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _grupBasligi(String grupAdi, int sayi, Color anaRenk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5),
      child: Row(
        children: [
          Text(
            "$grupAdi. Sınıflar",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const Spacer(),
          Text(
            "$sayi Sınıf",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _bosDurumWidget(AppLocalizations dil) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.class_outlined, size: 60, color: Colors.grey.shade200),
          const SizedBox(height: 10),
          Text(
            dil.sinifMevcutDegil,
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
