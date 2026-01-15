import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ogretmenim/gen_l10n/app_localizations.dart';
import 'package:ogretmenim/ozellikler/ogrenciler/ogrenci_ekle_sayfasi.dart';
import 'package:ogretmenim/ozellikler/ogrenciler/ogrenciler_provider.dart';
import 'package:ogretmenim/veri/modeller/sinif_model.dart';

class OgrencilerSayfasi extends ConsumerStatefulWidget {
  final SinifModel sinif;

  const OgrencilerSayfasi({super.key, required this.sinif});

  @override
  ConsumerState<OgrencilerSayfasi> createState() => _OgrencilerSayfasiState();
}

class _OgrencilerSayfasiState extends ConsumerState<OgrencilerSayfasi> {
  // Arama için gerekli değişkenler
  bool _aramaModu = false; // Arama kutusu açık mı?
  final TextEditingController _aramaController = TextEditingController();
  String _aramaMetni = ""; // Filtreleme için kullanılacak metin

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ogrencilerProvider.notifier).ogrencileriYukle(widget.sinif.id!);
    });

    // Arama kutusuna yazılanları dinle
    _aramaController.addListener(() {
      setState(() {
        _aramaMetni = _aramaController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dil = AppLocalizations.of(context)!;
    final tumOgrenciler = ref.watch(ogrencilerProvider); // Tüm liste
    final anaRenk = Theme.of(context).primaryColor;

    // --- FİLTRELEME MANTIĞI ---
    // Eğer arama metni boşsa hepsini göster, doluysa filtrele
    final goruntulenenListe = _aramaMetni.isEmpty
        ? tumOgrenciler
        : tumOgrenciler.where((ogrenci) {
            final adSoyad = "${ogrenci.ad} ${ogrenci.soyad ?? ''}"
                .toLowerCase();
            final numara = ogrenci.numara.toLowerCase();
            return adSoyad.contains(_aramaMetni) ||
                numara.contains(_aramaMetni);
          }).toList();

    // İstatistikler (Filtrelenmiş listeye göre değil, TÜM listeye göre olmalı)
    final int toplamOgrenci = tumOgrenciler.length;
    final int kizSayisi = tumOgrenciler
        .where((o) => o.cinsiyet == 'Kız')
        .length;
    final int erkekSayisi = tumOgrenciler
        .where((o) => o.cinsiyet == 'Erkek')
        .length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // 👇 ARAMA MODUNA GÖRE BAŞLIK DEĞİŞİR 👇
        title: _aramaModu
            ? TextField(
                controller: _aramaController,
                autofocus: true, // Açılınca direkt klavye gelsin
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Öğrenci Ara...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : Text(widget.sinif.sinifAdi),

        centerTitle: true,
        backgroundColor: anaRenk,
        foregroundColor: Colors.white,
        elevation: 0,

        // Geri butonu davranışı
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (_aramaModu) {
              // Arama modundaysak önce aramayı kapat
              setState(() {
                _aramaModu = false;
                _aramaMetni = "";
                _aramaController.clear();
              });
            } else {
              // Değilsek sayfadan çık
              Navigator.pop(context);
            }
          },
        ),

        actions: [
          // 👇 ARAMA BUTONU 👇
          IconButton(
            icon: Icon(_aramaModu ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_aramaModu) {
                  // Kapatırken temizle
                  _aramaModu = false;
                  _aramaMetni = "";
                  _aramaController.clear();
                } else {
                  // Aç
                  _aramaModu = true;
                }
              });
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _eklemeSecenekleriniGoster(context),
        backgroundColor: anaRenk,
        label: Text(
          dil.ogrenciEkle,
          style: const TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.person_add, color: Colors.white),
      ),

      body: Column(
        children: [
          // 1. İSTATİSTİK KARTI (Arama yaparken gizlemek istersen if(!_aramaModu) içine alabilirsin)
          if (!_aramaModu) // Arama yaparken kalabalık yapmasın diye gizledim, istersen bu satırı sil.
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [anaRenk, anaRenk.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: anaRenk.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _istatistikKutusu(
                    "Toplam",
                    toplamOgrenci.toString(),
                    Colors.white,
                  ),
                  _istatistikKutusuIconlu(
                    Icons.male,
                    erkekSayisi.toString(),
                    Colors.blue.shade100,
                  ),
                  _istatistikKutusuIconlu(
                    Icons.female,
                    kizSayisi.toString(),
                    Colors.pink.shade100,
                  ),
                ],
              ),
            ),

          // 2. ÖĞRENCİ LİSTESİ (Filtrelenmiş Liste)
          Expanded(
            child: goruntulenenListe.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _aramaMetni.isEmpty
                              ? Icons.school_outlined
                              : Icons
                                    .search_off, // Arama sonucu boşsa farklı ikon
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _aramaMetni.isEmpty
                              ? dil.ogrenciMevcutDegil
                              : "Sonuç bulunamadı.",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
                    itemCount: goruntulenenListe.length,
                    itemBuilder: (context, index) {
                      final ogrenci =
                          goruntulenenListe[index]; // Filtrelenmiş listeden al
                      final bool isKiz = ogrenci.cinsiyet == 'Kız';

                      final renk = isKiz ? Colors.pink : Colors.blue;
                      final arkaPlan = isKiz
                          ? Colors.pink.shade50
                          : Colors.blue.shade50;
                      final cerceve = isKiz
                          ? Colors.pink.shade100
                          : Colors.blue.shade100;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: arkaPlan,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cerceve, width: 1.5),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: SizedBox(
                            width: 55,
                            height: 55,
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.white,
                                    backgroundImage: ogrenci.fotoYolu != null
                                        ? FileImage(File(ogrenci.fotoYolu!))
                                        : null,
                                    child: ogrenci.fotoYolu == null
                                        ? Icon(
                                            isKiz ? Icons.female : Icons.male,
                                            color: renk.withOpacity(0.5),
                                            size: 28,
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: renk,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      // Filtreleme yapıldığı için sıra numarasını listedeki index'e göre veriyoruz
                                      "${index + 1}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          title: Text(
                            "${ogrenci.ad} ${ogrenci.soyad ?? ''}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.badge,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "No: ${ogrenci.numara}",
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red.shade400,
                            onPressed: () =>
                                _silmeOnayiGoster(context, ogrenci.id!, dil),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OgrenciEkleSayfasi(
                                  duzenlenecekOgrenci: ogrenci,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _istatistikKutusu(String baslik, String sayi, Color renk) {
    return Column(
      children: [
        Text(
          baslik,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            sayi,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _istatistikKutusuIconlu(
    IconData icon,
    String sayi,
    Color arkaPlanRengi,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: arkaPlanRengi.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Text(
            sayi,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }

  void _eklemeSecenekleriniGoster(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Elle Ekle'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OgrenciEkleSayfasi(
                          varsayilanSinifId: widget.sinif.id,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.orange,
                  ),
                  title: const Text('PDF\'ten Çek (e-Okul)'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("PDF modülü bir sonraki adımda!"),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _silmeOnayiGoster(
    BuildContext context,
    int ogrenciId,
    AppLocalizations dil,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dil.ogrenciSil),
        content: Text(dil.ogrenciSilOnay),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(dil.iptal),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(ogrencilerProvider.notifier)
                  .ogrenciSil(ogrenciId, widget.sinif.id!);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(dil.ogrenciSil),
          ),
        ],
      ),
    );
  }
}
