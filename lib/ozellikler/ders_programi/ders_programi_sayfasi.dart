import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ogretmenim/ozellikler/profil/profil_ayarlari.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/ozellikler/siniflar/siniflar_sayfasi.dart';
import 'package:ogretmenim/veri/modeller/ders_model.dart';

class DersProgramiSayfasi extends StatefulWidget {
  const DersProgramiSayfasi({super.key});

  @override
  State<DersProgramiSayfasi> createState() => _DersProgramiSayfasiState();
}

class _DersProgramiSayfasiState extends State<DersProgramiSayfasi> {
  DateTime _secilenTarih = DateTime.now();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<String> _kayitliSiniflar = [];

  // --- AYAR DEĞİŞKENLERİ ---
  TimeOfDay _ilkDersSaati = const TimeOfDay(hour: 08, minute: 00);
  int _dersSuresi = 40;
  int _teneffusSuresi = 10;
  int _gunlukDersSayisi = 8;
  bool _ogleArasiVarMi = false;
  int _ogleArasiSuresi = 45;

  // --- PANEL DEĞİŞKENLERİ ---
  final TextEditingController _dersAdiController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _secilenSinif;
  String _secilenGun = "Pazartesi";
  String _secilenDersSaati = "1. Ders";
  Color _secilenRenk = Colors.blue;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _siniflariGetir();
  }

  void _siniflariGetir() {
    User? user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('siniflar')
          .orderBy('ad')
          .snapshots()
          .listen((snapshot) {
            if (mounted) {
              setState(() {
                _kayitliSiniflar = snapshot.docs
                    .map((doc) => doc['ad'].toString())
                    .toList();
              });
            }
          });
    }
  }

  // --- FIREBASE İŞLEMLERİ ---
  Future<void> _dersKaydet({String? docId}) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // "1. Ders" -> 0 index'ine çevir
    int index = int.parse(_secilenDersSaati.split('.')[0]) - 1;

    Map<String, dynamic> dersVerisi = {
      'dersAdi': _dersAdiController.text,
      'sinif': _secilenSinif,
      'gun': _secilenGun,
      'dersSaatiIndex': index,
      'renk': _secilenRenk.value,
    };

    if (docId == null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dersler')
          .add(dersVerisi);
    } else {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dersler')
          .doc(docId)
          .update(dersVerisi);
    }
  }

  Future<void> _dersSil(String docId) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('dersler')
        .doc(docId)
        .delete();
  }

  // --- SAAT HESAPLAMA ---
  String _saatAraligiHesapla(int dersIndex) {
    int baslangicDakika = _ilkDersSaati.hour * 60 + _ilkDersSaati.minute;
    int gecenSure = dersIndex * (_dersSuresi + _teneffusSuresi);
    int dersBaslamaDakikasi = baslangicDakika + gecenSure;
    int dersBitisDakikasi = dersBaslamaDakikasi + _dersSuresi;
    return "${_dkToSaat(dersBaslamaDakikasi)} - ${_dkToSaat(dersBitisDakikasi)}";
  }

  String _dkToSaat(int toplamDakika) {
    int saat = (toplamDakika ~/ 60) % 24;
    int dakika = toplamDakika % 60;
    return "${saat.toString().padLeft(2, '0')}:${dakika.toString().padLeft(2, '0')}";
  }

  // --- YUKARIDAN İNEN ÖZEL UYARI ---
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

  // --- DERS EKLEME/DÜZENLEME PANELİ ---
  void _dersIslemPaneliniAc({
    DersModel? duzenlenecekDers,
    required List<DersModel> mevcutDersler,
  }) {
    final anaRenk = ProjeTemasi.anaRenk;
    final bool duzenlemeModu = duzenlenecekDers != null;

    if (duzenlemeModu) {
      _dersAdiController.text = duzenlenecekDers.dersAdi;
      _secilenSinif = duzenlenecekDers.sinif;
      _secilenGun = duzenlenecekDers.gun;
      _secilenDersSaati = "${duzenlenecekDers.dersSaatiIndex + 1}. Ders";
      _secilenRenk = Color(duzenlenecekDers.renkValue);
    } else {
      _dersAdiController.clear();
      _secilenSinif = null;
      // HER ZAMAN PAZARTESİ BAŞLASIN
      _secilenGun = "Pazartesi";
      _secilenDersSaati = "1. Ders";
      _secilenRenk = Colors.blue;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStatePanel) {
          List<DropdownMenuItem<String>> sinifItems = _kayitliSiniflar
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
                    style: TextStyle(
                      color: anaRenk,
                      fontWeight: FontWeight.bold,
                    ),
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
                      duzenlemeModu ? "Dersi Düzenle" : "Ders Programı Girişi",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: anaRenk,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _dersAdiController,
                      maxLength: 20,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp("[a-zA-ZğüşıöçĞÜŞİÖÇ0-9 ]"),
                        ),
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) => newValue.copyWith(
                            text: newValue.text.toUpperCase(),
                          ),
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
                      onChanged: (val) {
                        if (val == "YENI_SINIF_EKLE") {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SiniflarSayfasi(),
                            ),
                          ).then((_) => setState(() {}));
                        } else {
                          setStatePanel(() => _secilenSinif = val);
                        }
                      },
                      validator: (val) => val == null ? "Sınıf seçiniz" : null,
                    ),
                    const SizedBox(height: 15),

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
                            onChanged: (val) =>
                                setStatePanel(() => _secilenGun = val!),
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
                                      _gunlukDersSayisi,
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
                                setStatePanel(() => _secilenDersSaati = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

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
                                  onTap: () =>
                                      setStatePanel(() => _secilenRenk = color),
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

                            // ÇAKIŞMA KONTROLÜ
                            bool cakisma = mevcutDersler.any(
                              (d) =>
                                  d.gun == _secilenGun &&
                                  d.dersSaatiIndex == secilenIndex &&
                                  d.id != duzenlenecekDers?.id,
                            );

                            if (cakisma) {
                              // DÜZELTME: Navigator.pop KALDIRILDI! Panel kapanmayacak.

                              // DÜZELTME: 0. Ders yerine direkt metni gösteriyoruz
                              _yukaridanUyariGoster(
                                "$_secilenGun günü $_secilenDersSaati saatinde zaten bir ders var!",
                              );
                              return; // Kaydetme, çık.
                            }

                            // Firebase'e Kaydet
                            _dersKaydet(docId: duzenlenecekDers?.id);

                            // Sadece başarılı olursa kapat
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          duzenlenecekDers != null ? "GÜNCELLE" : "DERSİ EKLE",
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
          );
        },
      ),
    );
  }

  void _dersSilmeOnayi(DersModel ders) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Dersi Sil",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text("'${ders.dersAdi}' dersini silmek istiyor musunuz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İPTAL"),
          ),
          TextButton(
            onPressed: () {
              _dersSil(ders.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Ders silindi"),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text("SİL", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- GÜNCELLENMİŞ PROFİL BAŞLIĞI ---
  Widget _profilBaslikWidget(BuildContext context, String baslik) {
    final user = FirebaseAuth.instance.currentUser;
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfilAyarlariSayfasi(),
              ),
            ).then((_) {
              setState(() {});
            });
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
          baslik,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _ustAksiyonButonu(BuildContext context, List<DersModel> tumDersler) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, left: 5.0),
      child: Material(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _dersIslemPaneliniAc(mevcutDersler: tumDersler),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: const Row(
              children: [
                Icon(Icons.add_rounded, color: Color(0xFF1E293B), size: 18),
                SizedBox(width: 4),
                Text(
                  "EKLE",
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _beyazPanelGunSecimi(Color anaRenk) {
    return SizedBox(
      height: 75,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          DateTime bugun = DateTime.now();
          DateTime haftaBasi = bugun.subtract(
            Duration(days: bugun.weekday - 1),
          );
          DateTime gun = haftaBasi.add(Duration(days: index));
          bool secili =
              gun.day == _secilenTarih.day && gun.month == _secilenTarih.month;
          return GestureDetector(
            onTap: () => setState(() => _secilenTarih = gun),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: secili ? 65 : 55,
              decoration: BoxDecoration(
                color: secili ? anaRenk : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                boxShadow: secili
                    ? [
                        BoxShadow(
                          color: anaRenk.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', 'tr_TR').format(gun).substring(0, 1),
                    style: TextStyle(
                      color: secili ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    gun.day.toString(),
                    style: TextStyle(
                      color: secili ? Colors.white : Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- AYARLAR PANELİ (Eski kodlar korundu) ---
  void _ayarlarPaneliniAc() {
    final anaRenk = ProjeTemasi.anaRenk;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(25, 15, 25, 25),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 25),
                const Text(
                  "Program Ayarları",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _ayarListTile(
                  icon: Icons.access_time,
                  baslik: "İlk Ders",
                  deger: _ilkDersSaati.format(context),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: _ilkDersSaati,
                    );
                    if (picked != null) {
                      setModalState(() => _ilkDersSaati = picked);
                      setState(() => _ilkDersSaati = picked);
                    }
                  },
                ),
                const Divider(),
                _ayarStepSecici(
                  icon: Icons.format_list_numbered,
                  baslik: "Günlük Ders",
                  deger: "$_gunlukDersSayisi",
                  onLess: () {
                    if (_gunlukDersSayisi > 1) {
                      setModalState(() => _gunlukDersSayisi--);
                      setState(() {});
                    }
                  },
                  onAdd: () {
                    if (_gunlukDersSayisi < 14) {
                      setModalState(() => _gunlukDersSayisi++);
                      setState(() {});
                    }
                  },
                ),
                const Divider(),
                _ayarStepSecici(
                  icon: Icons.timer_outlined,
                  baslik: "Ders Süresi",
                  deger: "$_dersSuresi dk",
                  onLess: () {
                    if (_dersSuresi > 15) {
                      setModalState(() => _dersSuresi -= 5);
                      setState(() {});
                    }
                  },
                  onAdd: () {
                    if (_dersSuresi < 90) {
                      setModalState(() => _dersSuresi += 5);
                      setState(() {});
                    }
                  },
                ),
                const Divider(),
                _ayarStepSecici(
                  icon: Icons.coffee_outlined,
                  baslik: "Teneffüs",
                  deger: "$_teneffusSuresi dk",
                  onLess: () {
                    if (_teneffusSuresi > 0) {
                      setModalState(() => _teneffusSuresi -= 5);
                      setState(() {});
                    }
                  },
                  onAdd: () {
                    if (_teneffusSuresi < 60) {
                      setModalState(() => _teneffusSuresi += 5);
                      setState(() {});
                    }
                  },
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(Icons.restaurant, color: anaRenk),
                  title: const Text(
                    "Öğle Arası Var mı?",
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                  value: _ogleArasiVarMi,
                  activeColor: anaRenk,
                  onChanged: (bool value) {
                    setModalState(() => _ogleArasiVarMi = value);
                    setState(() => _ogleArasiVarMi = value);
                  },
                ),
                if (_ogleArasiVarMi)
                  _ayarStepSecici(
                    icon: Icons.more_time,
                    baslik: "Öğle Arası Süresi",
                    deger: "$_ogleArasiSuresi dk",
                    onLess: () {
                      if (_ogleArasiSuresi > 15) {
                        setModalState(() => _ogleArasiSuresi -= 5);
                        setState(() {});
                      }
                    },
                    onAdd: () {
                      if (_ogleArasiSuresi < 120) {
                        setModalState(() => _ogleArasiSuresi += 5);
                        setState(() {});
                      }
                    },
                  ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: anaRenk,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "AYARLARI KAYDET",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final anaRenk = ProjeTemasi.anaRenk;
    final user = _auth.currentUser;

    if (user == null) return const Center(child: Text("Giriş Yapmalısınız"));

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dersler')
          .snapshots(),
      builder: (context, snapshot) {
        List<DersModel> tumDersler = [];
        if (snapshot.hasData) {
          tumDersler = snapshot.data!.docs
              .map(
                (doc) => DersModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        }

        String gunIsmi = DateFormat('EEEE', 'tr_TR').format(_secilenTarih);
        var bugunkuDersler = tumDersler.where((d) => d.gun == gunIsmi).toList();
        bugunkuDersler.sort(
          (a, b) => a.dersSaatiIndex.compareTo(b.dersSaatiIndex),
        );

        return ProjeSayfaSablonu(
          baslikWidget: _profilBaslikWidget(context, "Ders Programım"),
          aksiyonlar: [
            IconButton(
              onPressed: _ayarlarPaneliniAc,
              icon: const Icon(
                Icons.tune_rounded,
                color: Color(0xFF1E293B),
                size: 24,
              ),
              tooltip: "Saat Ayarları",
            ),
            _ustAksiyonButonu(
              context,
              tumDersler,
            ), // Tüm dersleri çakışma kontrolü için gönder
          ],
          icerik: ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 80),
            children: [
              _beyazPanelGunSecimi(anaRenk),
              const SizedBox(height: 20),
              bugunkuDersler.isEmpty
                  ? _bosDersUyarisi()
                  : _dersListesiView(bugunkuDersler, tumDersler),
            ],
          ),
        );
      },
    );
  }

  Widget _bosDersUyarisi() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.event_note, size: 60, color: Colors.grey.shade200),
          const SizedBox(height: 15),
          Text(
            "Bu gün için ders eklenmemiş.",
            style: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dersListesiView(List<DersModel> dersler, List<DersModel> tumDersler) {
    return Column(
      children: dersler.map((ders) {
        String saatAraligi = _saatAraligiHesapla(ders.dersSaatiIndex);
        return _dersKarti(
          (ders.dersSaatiIndex + 1).toString(),
          ders.dersAdi,
          saatAraligi,
          ders.sinif,
          Color(ders.renkValue),
          ders,
          tumDersler,
        );
      }).toList(),
    );
  }

  Widget _dersKarti(
    String sira,
    String ders,
    String saat,
    String sinif,
    Color renk,
    DersModel model,
    List<DersModel> tumDersler,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: renk.withOpacity(0.1),
            child: Text(
              sira,
              style: TextStyle(color: renk, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ders,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "$saat • $sinif",
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            onSelected: (value) {
              if (value == 'duzenle') {
                _dersIslemPaneliniAc(
                  duzenlenecekDers: model,
                  mevcutDersler: tumDersler,
                );
              } else if (value == 'sil') {
                _dersSilmeOnayi(model);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'duzenle',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                    SizedBox(width: 10),
                    Text("Düzenle"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sil',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text("Sil"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ayarListTile({
    required IconData icon,
    required String baslik,
    required String deger,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: ProjeTemasi.anaRenk),
      title: Text(
        baslik,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ProjeTemasi.anaRenk.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          deger,
          style: TextStyle(
            color: ProjeTemasi.anaRenk,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _ayarStepSecici({
    required IconData icon,
    required String baslik,
    required String deger,
    required VoidCallback onLess,
    required VoidCallback onAdd,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: ProjeTemasi.anaRenk),
          const SizedBox(width: 15),
          Text(
            baslik,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          const Spacer(),
          Row(
            children: [
              InkWell(
                onTap: onLess,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(Icons.remove, size: 18),
                ),
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text(
                  deger,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              InkWell(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(Icons.add, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
