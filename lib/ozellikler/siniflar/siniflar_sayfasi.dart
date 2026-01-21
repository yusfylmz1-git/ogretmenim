import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ogretmenim/gen_l10n/app_localizations.dart';
import 'package:ogretmenim/ozellikler/siniflar/siniflar_provider.dart';
import 'package:ogretmenim/ozellikler/ogrenciler/ogrenciler_sayfasi.dart';
import 'package:ogretmenim/ozellikler/profil/profil_ayarlari.dart';
import 'package:ogretmenim/veri/modeller/sinif_model.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';

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
    final tumSiniflar = ref.watch(siniflarProvider);
    final anaRenk = ProjeTemasi.anaRenk;

    Map<String, List<SinifModel>> gruplanmisSiniflar = {};
    tumSiniflar.sort((a, b) => a.sinifAdi.compareTo(b.sinifAdi));

    for (var sinif in tumSiniflar) {
      String grupAdi = sinif.sinifAdi.split('-')[0];
      if (!gruplanmisSiniflar.containsKey(grupAdi)) {
        gruplanmisSiniflar[grupAdi] = [];
      }
      gruplanmisSiniflar[grupAdi]!.add(sinif);
    }

    var siraliGruplar = gruplanmisSiniflar.keys.toList();
    siraliGruplar.sort((a, b) {
      int? s1 = int.tryParse(a);
      int? s2 = int.tryParse(b);
      if (s1 != null && s2 != null) return s1.compareTo(s2);
      return a.compareTo(b);
    });

    return ProjeSayfaSablonu(
      // --- ÖZET SAYFASIYLA EŞİTLENMİŞ PROFİL ALANI ---
      baslikWidget: _profilBaslikWidget(context, dil),
      aksiyonlar: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Material(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _sinifIslemPaneli(context, dil, null, tumSiniflar),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
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
        ),
      ],
      icerik: tumSiniflar.isEmpty
          ? _bosDurumWidget(dil)
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // ÖZET SAYFASIYLA AYNI PADDING (Üstten 20px)
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
              itemCount: siraliGruplar.length,
              itemBuilder: (context, index) {
                String grupAdi = siraliGruplar[index];
                List<SinifModel> oGrubunSiniflari =
                    gruplanmisSiniflar[grupAdi]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _grupBasligi(grupAdi, oGrubunSiniflari.length, anaRenk),
                    ...oGrubunSiniflari.map(
                      (sinif) =>
                          _modernSinifKarti(sinif, context, dil, tumSiniflar),
                    ),
                    const SizedBox(height: 5),
                  ],
                );
              },
            ),
    );
  }

  // --- SOL ÜST PROFİL ALANI (Özet Sayfasıyla Birebir Hizalandı) ---
  Widget _profilBaslikWidget(BuildContext context, AppLocalizations dil) {
    final user = FirebaseAuth.instance.currentUser;
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfilAyarlariSayfasi(),
            ),
          ),
          child: CircleAvatar(
            radius: 22, // Sabitlendi
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

  void _sinifIslemPaneli(
    BuildContext context,
    AppLocalizations dil,
    SinifModel? duzenlenecekSinif,
    List<SinifModel> mevcutSiniflar,
  ) {
    final bool duzenlemeModu = duzenlenecekSinif != null;
    final adController = TextEditingController(
      text: duzenlenecekSinif?.sinifAdi ?? "",
    );
    final aciklamaController = TextEditingController(
      text: duzenlenecekSinif?.aciklama ?? "",
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
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 15,
                ),
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
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 15,
                ),
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
                  elevation: 0,
                ),
                onPressed: () {
                  if (adController.text.isNotEmpty) {
                    String formatliAd = _formatla(adController.text);
                    bool varMi = mevcutSiniflar.any(
                      (s) =>
                          s.sinifAdi == formatliAd &&
                          s.id != duzenlenecekSinif?.id,
                    );
                    if (varMi) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Bu sınıf zaten mevcut!"),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      if (duzenlemeModu) {
                        ref
                            .read(siniflarProvider.notifier)
                            .sinifGuncelle(
                              SinifModel(
                                id: duzenlenecekSinif.id,
                                sinifAdi: formatliAd,
                                aciklama: aciklamaController.text.trim(),
                              ),
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

  Widget _modernSinifKarti(
    SinifModel sinif,
    BuildContext context,
    AppLocalizations dil,
    List<SinifModel> liste,
  ) {
    final renk = _kartRenkleri[sinif.id! % _kartRenkleri.length];
    return Container(
      height: 70,
      margin: const EdgeInsets.only(bottom: 10),
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
              onPressed: () => _sinifIslemPaneli(context, dil, sinif, liste),
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
              ref.read(siniflarProvider.notifier).sinifSil(sinif.id!);
              Navigator.pop(context);
            },
            child: const Text("SİL", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _grupBasligi(String grupAdi, int sayi, Color anaRenk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5),
      child: Row(
        children: [
          Text(
            "$grupAdi. Şubeler",
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
