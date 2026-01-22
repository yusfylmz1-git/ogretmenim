import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/veri/modeller/ders_model.dart';
import 'package:ogretmenim/ozellikler/siniflar/siniflar_sayfasi.dart';

class DersEklemePaneli extends StatefulWidget {
  final Function(DersModel) onDersEkle;
  final List<DersModel> mevcutDersler;
  final int gunlukDersSayisi;
  final List<String> mevcutSiniflar;

  const DersEklemePaneli({
    super.key,
    required this.onDersEkle,
    required this.mevcutDersler,
    required this.gunlukDersSayisi,
    required this.mevcutSiniflar,
  });

  @override
  State<DersEklemePaneli> createState() => _DersEklemePaneliState();
}

class _DersEklemePaneliState extends State<DersEklemePaneli> {
  final TextEditingController _dersAdiController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _secilenSinif;
  String _secilenGun = "Pazartesi";
  String _secilenDersSaati = "1. Ders"; // Varsayılan
  Color _secilenRenk = Colors.blue;

  // --- GARANTİ YUKARIDAN GELEN UYARI ---
  void _yukaridanUyariGoster(String mesaj) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Uyarı",
      barrierDismissible: true,
      barrierColor: Colors.black12, // Arka planı hafif karart
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.topCenter, // TEPEDE GÖSTER
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(
                top: 60,
                left: 20,
                right: 20,
              ), // StatusBar boşluğu
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Ders Çakışması!",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mesaj,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, -1),
            end: const Offset(0, 0),
          ).animate(anim),
          child: child,
        );
      },
    );
  }

  void _sinifEkleSayfasinaGit() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SiniflarSayfasi()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final anaRenk = ProjeTemasi.anaRenk;

    List<DropdownMenuItem<String>> sinifItems = widget.mevcutSiniflar
        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
        .toList();

    sinifItems.add(
      DropdownMenuItem(
        value: "YENI_SINIF_EKLE",
        child: Row(
          children: [
            Icon(Icons.add_circle_outline, color: anaRenk, size: 20),
            const SizedBox(width: 8),
            Text(
              "Sınıf Ekle",
              style: TextStyle(color: anaRenk, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Form(
          key: _formKey,
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
              const SizedBox(height: 20),
              Text(
                "Ders Programı Girişi",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: anaRenk,
                ),
              ),
              const SizedBox(height: 20),

              // 1. DERS ADI
              TextFormField(
                controller: _dersAdiController,
                maxLength: 20,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp("[a-zA-ZğüşıöçĞÜŞİÖÇ0-9 ]"),
                  ),
                  TextInputFormatter.withFunction(
                    (oldValue, newValue) =>
                        newValue.copyWith(text: newValue.text.toUpperCase()),
                  ),
                ],
                decoration: InputDecoration(
                  labelText: "Ders Adı",
                  counterText: "",
                  prefixIcon: Icon(Icons.book, color: anaRenk),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? "Ders adı gerekli"
                    : null,
              ),
              const SizedBox(height: 15),

              // 2. SINIF
              DropdownButtonFormField<String>(
                value: _secilenSinif,
                decoration: InputDecoration(
                  labelText: "Sınıf",
                  prefixIcon: Icon(Icons.class_, color: anaRenk),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: sinifItems,
                onChanged: (val) => val == "YENI_SINIF_EKLE"
                    ? _sinifEkleSayfasinaGit()
                    : setState(() => _secilenSinif = val),
                validator: (val) => val == null ? "Sınıf seçiniz" : null,
              ),
              const SizedBox(height: 15),

              // 3. GÜN VE SAAT
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _secilenGun,
                      decoration: InputDecoration(
                        labelText: "Gün",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      items:
                          [
                                "Pazartesi",
                                "Salı",
                                "Çarşamba",
                                "Perşembe",
                                "Cuma",
                                "Cumartesi",
                                "Pazar",
                              ]
                              .map(
                                (g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(
                                    g,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (val) => setState(() => _secilenGun = val!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _secilenDersSaati,
                      decoration: InputDecoration(
                        labelText: "Ders Saati",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      items:
                          List.generate(
                                widget.gunlukDersSayisi,
                                (index) => "${index + 1}. Ders",
                              )
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (val) =>
                          setState(() => _secilenDersSaati = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. RENK
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children:
                    [
                          Colors.blue,
                          Colors.green,
                          Colors.orange,
                          Colors.purple,
                          Colors.red,
                        ]
                        .map(
                          (color) => GestureDetector(
                            onTap: () => setState(() => _secilenRenk = color),
                            child: CircleAvatar(
                              backgroundColor: color,
                              radius: 18,
                              child: _secilenRenk == color
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 25),

              // 5. KAYDET BUTONU
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: anaRenk,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      int secilenIndex =
                          int.parse(_secilenDersSaati.split('.')[0]) - 1;

                      // --- ÇAKIŞMA KONTROLÜ ---
                      bool cakismaVar = widget.mevcutDersler.any(
                        (ders) =>
                            ders.gun == _secilenGun &&
                            ders.dersSaatiIndex == secilenIndex,
                      );

                      if (cakismaVar) {
                        Navigator.pop(context); // Paneli kapat

                        // DÜZELTME: Artık 0 değil, direkt seçtiğin "1. Ders" yazısını yazacak.
                        _yukaridanUyariGoster(
                          "$_secilenGun günü $_secilenDersSaati saatinde zaten bir ders var!",
                        );
                        return;
                      }

                      final yeniDers = DersModel(
                        id: DateTime.now().toString(),
                        dersAdi: _dersAdiController.text,
                        sinif: _secilenSinif!,
                        gun: _secilenGun,
                        dersSaatiIndex: secilenIndex,
                        renk: _secilenRenk,
                      );

                      widget.onDersEkle(yeniDers);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    "DERSİ EKLE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
