import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ogretmenim/ozellikler/ogrenciler/ogrenciler_provider.dart';
import 'package:ogretmenim/veri/modeller/ogrenci_model.dart';
import 'package:ogretmenim/ozellikler/siniflar/siniflar_provider.dart';
import 'package:ogretmenim/cekirdek/araclar/bildirim_araci.dart';

class PdfOnizlemeSayfasi extends ConsumerStatefulWidget {
  final List<OgrenciModel> bulunanListe;
  final int sinifId;

  const PdfOnizlemeSayfasi({
    super.key,
    required this.bulunanListe,
    required this.sinifId,
  });

  @override
  ConsumerState<PdfOnizlemeSayfasi> createState() => _PdfOnizlemeSayfasiState();
}

class _PdfOnizlemeSayfasiState extends ConsumerState<PdfOnizlemeSayfasi> {
  late List<bool> secimler;
  late List<String> cinsiyetler;
  late List<bool> zatenVarListesi;

  @override
  void initState() {
    super.initState();

    final mevcutOgrenciler = ref.read(ogrencilerProvider);

    zatenVarListesi = [];
    secimler = [];
    cinsiyetler = [];

    for (var yeniOgrenci in widget.bulunanListe) {
      // Bu numara sınıfta var mı?
      bool varMi = mevcutOgrenciler.any((o) => o.numara == yeniOgrenci.numara);

      zatenVarListesi.add(varMi);
      secimler.add(!varMi); // Zaten varsa seçili gelmesin
      cinsiyetler.add(yeniOgrenci.cinsiyet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anaRenk = Theme.of(context).primaryColor;
    final sinifListesi = ref.watch(siniflarProvider);

    // HATA ÇÖZÜMÜ: sinifAdi değişkenini burada tanımlayıp aşağıda kullanacağız
    final sinifAdi = sinifListesi
        .firstWhere(
          (s) => s.id == widget.sinifId,
          orElse: () => sinifListesi.first,
        )
        .sinifAdi;

    int secilenSayisi = secimler.where((x) => x).length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Önizleme",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: anaRenk,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ÜST BİLGİ ALANI
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: anaRenk,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$secilenSayisi öğrenci eklenecek",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                // İŞTE BURADA KULLANDIK 👇
                Text(
                  "Sınıf: $sinifAdi | Toplam ${widget.bulunanListe.length} kişi bulundu.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // LİSTE
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.bulunanListe.length,
              itemBuilder: (context, index) {
                final ogrenci = widget.bulunanListe[index];
                final bool isSelected = secimler[index];
                final bool zatenVar = zatenVarListesi[index];
                final String cinsiyet = cinsiyetler[index];

                return GestureDetector(
                  onTap: () {
                    if (zatenVar) {
                      BildirimAraci.tepeHataGoster(
                        context,
                        "⚠️ Bu numara (${ogrenci.numara}) sınıfta zaten kayıtlı!",
                      );
                    } else {
                      setState(() {
                        secimler[index] = !secimler[index];
                      });
                    }
                  },
                  child: Opacity(
                    opacity: zatenVar ? 0.5 : 1.0,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: zatenVar ? Colors.grey.shade200 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        // Yeşil Çerçeve Efekti
                        border: Border.all(
                          color: isSelected
                              ? Colors.green
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // SOL TARAFTAKİ TİK İKONU
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: zatenVar
                                  ? Colors.grey
                                  : (isSelected
                                        ? Colors.green
                                        : Colors.grey.shade100),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              zatenVar ? Icons.lock : Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // ÖĞRENCİ BİLGİLERİ
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${ogrenci.ad} ${ogrenci.soyad}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: zatenVar
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      "No: ${ogrenci.numara}",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (zatenVar)
                                      const Text(
                                        "(KAYITLI)",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      )
                                    else
                                      GestureDetector(
                                        onTap: () {
                                          if (isSelected)
                                            setState(
                                              () => cinsiyetler[index] =
                                                  cinsiyet == 'Erkek'
                                                  ? 'Kız'
                                                  : 'Erkek',
                                            );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (cinsiyet == 'Erkek'
                                                        ? Colors.blue
                                                        : Colors.pink)
                                                    .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            cinsiyet,
                                            style: TextStyle(
                                              color: cinsiyet == 'Erkek'
                                                  ? Colors.blue
                                                  : Colors.pink,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // KAYDET BUTONU
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: secilenSayisi > 0 ? _listeyiKaydet : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: anaRenk,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save_alt, color: Colors.white),
                label: Text(
                  "$secilenSayisi Öğrenciyi Kaydet",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _listeyiKaydet() async {
    int sayac = 0;
    for (int i = 0; i < widget.bulunanListe.length; i++) {
      if (secimler[i] && !zatenVarListesi[i]) {
        final ogrenci = widget.bulunanListe[i].copyWith(
          cinsiyet: cinsiyetler[i],
        );
        await ref.read(ogrencilerProvider.notifier).ogrenciEkle(ogrenci);
        sayac++;
      }
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$sayac öğrenci eklendi! 🎉"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
