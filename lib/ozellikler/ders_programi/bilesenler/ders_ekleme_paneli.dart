import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/veri/modeller/ders_model.dart';
import 'package:ogretmenim/ozellikler/siniflar/siniflar_sayfasi.dart';

class DersEklemePaneli extends StatefulWidget {
  // GÜNCELLEME: İsimleri değiştirdik ve yeni parametre ekledik
  final Function(DersModel) onDersKaydet;
  final List<DersModel> mevcutDersler;
  final int gunlukDersSayisi;
  final List<String> mevcutSiniflar;
  final DersModel? duzenlenecekDers; // YENİ: Düzenleme için

  const DersEklemePaneli({
    super.key,
    required this.onDersKaydet,
    required this.mevcutDersler,
    required this.gunlukDersSayisi,
    required this.mevcutSiniflar,
    this.duzenlenecekDers, // Opsiyonel
  });

  @override
  State<DersEklemePaneli> createState() => _DersEklemePaneliState();
}

class _DersEklemePaneliState extends State<DersEklemePaneli> {
  final TextEditingController _dersAdiController = TextEditingController();
  final TextEditingController _sinifController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _secilenSinif;
  String _secilenGun = "Pazartesi";
  String _secilenDersSaati = "1. Ders";
  Color _secilenRenk = Colors.blue;

  List<String> _islenmisSinifListesi = [];

  @override
  void initState() {
    super.initState();
    _listeyiHazirla();
    _verileriDoldur(); // YENİ: Otomatik doldurma
  }

  void _listeyiHazirla() {
    _islenmisSinifListesi = widget.mevcutSiniflar.toSet().toList();
    _islenmisSinifListesi.sort((a, b) {
      final regExp = RegExp(r'^(\d+)');
      final matchA = regExp.firstMatch(a);
      final matchB = regExp.firstMatch(b);
      if (matchA != null && matchB != null) {
        int numA = int.parse(matchA.group(1)!);
        int numB = int.parse(matchB.group(1)!);
        if (numA != numB) return numA.compareTo(numB);
      }
      return a.compareTo(b);
    });
  }

  // --- FORM DOLDURMA (GÜNCELLEME MODU İÇİN) ---
  void _verileriDoldur() {
    if (widget.duzenlenecekDers != null) {
      final ders = widget.duzenlenecekDers!;

      _dersAdiController.text = ders.dersAdi;
      _secilenGun = ders.gun;
      _secilenRenk = ders.renk;
      _secilenDersSaati = "${ders.dersSaatiIndex + 1}. Ders";

      if (_islenmisSinifListesi.contains(ders.sinif)) {
        _secilenSinif = ders.sinif;
        _sinifController.text = ders.sinif;
      } else {
        _secilenSinif = null;
        _sinifController.text = "";
      }
    } else {
      if (_secilenSinif != null &&
          !_islenmisSinifListesi.contains(_secilenSinif)) {
        _secilenSinif = null;
        _sinifController.text = "";
      }
    }
  }

  void _yukaridanUyariGoster(String mesaj) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Uyarı",
      barrierDismissible: true,
      barrierColor: Colors.black12,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(top: 60, left: 20, right: 20),
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
                          "Dikkat!",
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

  Future<void> _sinifSecimPaneliniAc() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Sınıf Seçiniz",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _islenmisSinifListesi.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _islenmisSinifListesi.length) {
                      return ListTile(
                        leading: Icon(
                          Icons.add_circle_outline,
                          color: ProjeTemasi.anaRenk,
                        ),
                        title: Text(
                          "Yeni Sınıf Ekle",
                          style: TextStyle(
                            color: ProjeTemasi.anaRenk,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _sinifEkleSayfasinaGit();
                        },
                      );
                    }
                    final sinif = _islenmisSinifListesi[index];
                    return ListTile(
                      title: Text(sinif),
                      trailing: _secilenSinif == sinif
                          ? Icon(Icons.check_circle, color: ProjeTemasi.anaRenk)
                          : null,
                      onTap: () {
                        setState(() {
                          _secilenSinif = sinif;
                          _sinifController.text = sinif;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final anaRenk = ProjeTemasi.anaRenk;
    final bool duzenlemeModu = widget.duzenlenecekDers != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
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
                  duzenlemeModu ? "Dersi Düzenle" : "Ders Programı Girişi",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: anaRenk,
                  ),
                ),
                const SizedBox(height: 20),

                // DERS ADI
                TextFormField(
                  controller: _dersAdiController,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.characters,
                  scrollPadding: const EdgeInsets.only(bottom: 100),
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
                  textInputAction: TextInputAction.done,
                  onEditingComplete: () => FocusScope.of(context).unfocus(),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? "Ders adı gerekli"
                      : null,
                ),
                const SizedBox(height: 15),

                // SINIF SEÇİMİ
                TextFormField(
                  controller: _sinifController,
                  readOnly: true,
                  onTap: _sinifSecimPaneliniAc,
                  decoration: InputDecoration(
                    labelText: "Sınıf",
                    prefixIcon: Icon(Icons.class_, color: anaRenk),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? "Sınıf seçiniz" : null,
                ),
                const SizedBox(height: 15),

                // GÜN VE SAAT
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _secilenGun,
                        isExpanded: true,
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
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          FocusScope.of(context).unfocus();
                          setState(() => _secilenGun = val!);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _secilenDersSaati,
                        isExpanded: true,
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
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          FocusScope.of(context).unfocus();
                          setState(() => _secilenDersSaati = val!);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // RENK SEÇİMİ
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
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                setState(() => _secilenRenk = color);
                              },
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

                // KAYDET BUTONU
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
                      FocusScope.of(context).unfocus();
                      if (_formKey.currentState!.validate()) {
                        int secilenIndex =
                            int.parse(_secilenDersSaati.split('.')[0]) - 1;

                        // ÇAKIŞMA KONTROLÜ (Güncelleme modunda kendisini sayma!)
                        bool cakismaVar = widget.mevcutDersler.any((ders) {
                          if (duzenlemeModu &&
                              ders.id == widget.duzenlenecekDers!.id) {
                            return false;
                          }
                          return ders.gun == _secilenGun &&
                              ders.dersSaatiIndex == secilenIndex;
                        });

                        if (cakismaVar) {
                          _yukaridanUyariGoster(
                            "$_secilenGun günü $_secilenDersSaati saatinde zaten bir ders var!",
                          );
                          return;
                        }

                        final sonDers = DersModel(
                          id: widget
                              .duzenlenecekDers
                              ?.id, // Varsa ID koru (Güncelleme)
                          docId: widget
                              .duzenlenecekDers
                              ?.docId, // Varsa Firebase ID koru
                          dersAdi: _dersAdiController.text,
                          sinif: _secilenSinif!,
                          gun: _secilenGun,
                          dersSaatiIndex: secilenIndex,
                          renk: _secilenRenk,
                        );

                        widget.onDersKaydet(sonDers); // Geriye gönder
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      duzenlemeModu ? "DERSİ GÜNCELLE" : "DERSİ EKLE",
                      style: const TextStyle(
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
      ),
    );
  }
}
