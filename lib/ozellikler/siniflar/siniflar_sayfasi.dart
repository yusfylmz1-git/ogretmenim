import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ogretmenim/gen_l10n/app_localizations.dart';
import 'package:ogretmenim/ozellikler/siniflar/siniflar_provider.dart';
import 'package:ogretmenim/ozellikler/ogrenciler/ogrenciler_sayfasi.dart';
import 'package:ogretmenim/veri/modeller/sinif_model.dart';

class SiniflarSayfasi extends ConsumerStatefulWidget {
  const SiniflarSayfasi({super.key});

  @override
  ConsumerState<SiniflarSayfasi> createState() => _SiniflarSayfasiState();
}

class _SiniflarSayfasiState extends ConsumerState<SiniflarSayfasi> {
  // Renk Paleti
  final List<Color> _kartRenkleri = [
    const Color(0xFF7B61FF), // Mor
    const Color(0xFFFF8B66), // Turuncu
    const Color(0xFFD96FF8), // Açık Mor
    const Color(0xFFF25A7F), // Pembe
    const Color(0xFF63C6FF), // Mavi
  ];

  @override
  Widget build(BuildContext context) {
    final dil = AppLocalizations.of(context)!;
    final tumSiniflar = ref.watch(siniflarProvider);
    final anaRenk = Theme.of(context).primaryColor;

    // --- GRUPLAMA VE SIRALAMA ---
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
    // ----------------------------

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: anaRenk,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          toolbarHeight: 100,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 0,
              top: 12,
              bottom: 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    dil.siniflar,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () => _sinifIslemMenusuAc(context, dil, null),
                    tooltip: dil.sinifEkle,
                  ),
                ),
              ],
            ),
          ),
          centerTitle: false,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(20.0),
            child: SizedBox(),
          ),
        ),
      ),

      backgroundColor: Colors.grey.shade50,

      // FloatingActionButton'ı (Alttaki yuvarlak buton) KALDIRDIK ❌
      body: tumSiniflar.isEmpty
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
              // Üstten biraz daha boşluk bıraktık (top: 20)
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
              itemCount: siraliGruplar.length,
              itemBuilder: (context, index) {
                String grupAdi = siraliGruplar[index];
                List<SinifModel> oGrubunSiniflari =
                    gruplanmisSiniflar[grupAdi]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GRUP BAŞLIĞI
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: anaRenk.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              grupAdi,
                              style: TextStyle(
                                color: anaRenk,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "$grupAdi. Şubeler",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "${oGrubunSiniflari.length} Sınıf",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // KARTLAR
                    ...oGrubunSiniflari.map((sinif) {
                      final renkIndex = sinif.id! % _kartRenkleri.length;
                      final renk = _kartRenkleri[renkIndex];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OgrencilerSayfasi(sinif: sinif),
                            ),
                          );
                        },
                        child: Container(
                          height: 75,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade100,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                decoration: BoxDecoration(
                                  color: renk,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sinif.sinifAdi,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (sinif.aciklama != null &&
                                        sinif.aciklama!.isNotEmpty)
                                      Text(
                                        sinif.aciklama!,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _sinifIslemMenusuAc(
                                      context,
                                      dil,
                                      sinif,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _silmeOnayiGoster(
                                      context,
                                      sinif.id!,
                                      dil,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
    );
  }

  // --- Yardımcı Metodlar (Değişmedi ama kopyalamak için ekledim) ---
  void _sinifIslemMenusuAc(
    BuildContext context,
    AppLocalizations dil,
    SinifModel? duzenlenecekSinif,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                duzenlemeModu ? "Sınıfı Düzenle" : dil.sinifEkle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: adController,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: dil.sinifAdi,
                  hintText: "Örn: 5a, 5-A, LAB",
                  prefixIcon: const Icon(Icons.class_),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  counterText: "",
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: aciklamaController,
                maxLength: 30,
                decoration: InputDecoration(
                  labelText: dil.aciklama,
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  counterText: "",
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (adController.text.isNotEmpty) {
                      String formatliAd = _formatla(adController.text);

                      final mevcutListe = ref.read(siniflarProvider);
                      bool isimVarMi = mevcutListe.any(
                        (s) =>
                            s.sinifAdi == formatliAd &&
                            (duzenlemeModu
                                ? s.id != duzenlenecekSinif.id
                                : true),
                      );

                      if (isimVarMi) {
                        _tepedenHataGoster(
                          context,
                          "⚠️ $formatliAd sınıfı zaten mevcut!",
                        );
                        return;
                      }

                      if (duzenlemeModu) {
                        final guncelSinif = SinifModel(
                          id: duzenlenecekSinif.id,
                          sinifAdi: formatliAd,
                          aciklama: aciklamaController.text.trim(),
                        );
                        ref
                            .read(siniflarProvider.notifier)
                            .sinifGuncelle(guncelSinif);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Sınıf güncellendi")),
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
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    duzenlemeModu ? "GÜNCELLE" : dil.kaydet,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  void _tepedenHataGoster(BuildContext context, String mesaj) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Hata",
      barrierColor: Colors.black12,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(top: 60, left: 20, right: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.redAccent.shade100,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mesaj,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, -1),
            end: const Offset(0, 0),
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack)),
          child: child,
        );
      },
    );
  }

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

  void _silmeOnayiGoster(BuildContext context, int id, AppLocalizations dil) {
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
