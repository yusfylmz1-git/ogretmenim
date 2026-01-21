import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ogretmenim/ozellikler/profil/profil_ayarlari.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';

class DersProgramiSayfasi extends StatefulWidget {
  const DersProgramiSayfasi({super.key});

  @override
  State<DersProgramiSayfasi> createState() => _DersProgramiSayfasiState();
}

class _DersProgramiSayfasiState extends State<DersProgramiSayfasi> {
  DateTime _secilenTarih = DateTime.now();

  // --- AYAR DEĞİŞKENLERİ (Artık hepsi kullanılıyor, hata vermeyecek) ---
  TimeOfDay _ilkDersSaati = const TimeOfDay(hour: 08, minute: 00);
  int _dersSuresi = 40;
  int _teneffusSuresi = 10;
  int _gunlukDersSayisi = 8;
  bool _ogleArasiVarMi = false;
  int _ogleArasiSuresi = 45;

  // --- DERS EKLEME PANELİ DEĞİŞKENLERİ ---
  final TextEditingController _dersAdiController = TextEditingController();
  String? _secilenSinif;
  String? _secilenGun = "Pazartesi";
  String? _secilenDersSaati = "1. Ders";
  Color _secilenRenk = Colors.blue;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
  }

  // ==================================================
  // 1. DERS EKLEME PANELİ (SENİN MAVİ TASARIMIN)
  // ==================================================
  void _dersEklemePaneliniAc() {
    final anaRenk = ProjeTemasi.anaRenk;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Klavye açılınca ekranı yukarı iter
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        // Renk seçimi anlık değişsin diye
        builder: (context, setStatePanel) {
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

                  // DERS ADI
                  TextField(
                    controller: _dersAdiController,
                    decoration: InputDecoration(
                      labelText: "Ders Adı",
                      prefixIcon: Icon(Icons.book, color: anaRenk),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // SINIF
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
                    items: ["5-A", "6-B", "7-C", "8-D"]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) =>
                        setStatePanel(() => _secilenSinif = val),
                  ),
                  const SizedBox(height: 15),

                  // GÜN VE SAAT
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
                              setStatePanel(() => _secilenGun = val),
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
                              setStatePanel(() => _secilenDersSaati = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // RENK SEÇİMİ
                  const Text(
                    "Renk:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children:
                        [
                          Colors.blue,
                          Colors.green,
                          Colors.orange,
                          Colors.purple,
                          Colors.red,
                        ].map((color) {
                          return GestureDetector(
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
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 25),

                  // EKLE BUTONU
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "DERS EKLE",
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
          );
        },
      ),
    );
  }

  // ==================================================
  // 2. AYARLAR PANELİ (Unused Errors Çözüldü)
  // ==================================================
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
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(35),
                topRight: Radius.circular(35),
              ),
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

                // İLK DERS
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

                // DERS SÜRESİ
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

                // TENEFFÜS SÜRESİ
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

                // ÖĞLE ARASI (Hata veren _ogleArasiVarMi burada kullanılıyor)
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

                // ÖĞLE ARASI SÜRESİ (Hata veren _ogleArasiSuresi burada kullanılıyor)
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

  // ==================================================
  // 3. ANA EKRAN YAPISI (Kırmızı Ekran Hatası Çözüldü)
  // ==================================================
  @override
  Widget build(BuildContext context) {
    final anaRenk = ProjeTemasi.anaRenk;

    return ProjeSayfaSablonu(
      baslikWidget: _profilBaslikWidget(context, "Ders Programım"),
      // Butona Ders Ekleme Panelini bağladık
      aksiyonlar: [_ustAksiyonButonu(context)],
      icerik: ListView(
        // BU İKİ SATIR KIRMIZI EKRAN HATASINI ÇÖZER:
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(16, 15, 16, 80),
        children: [
          _beyazPanelGunSecimi(anaRenk),
          const SizedBox(height: 25),
          _belirginAyarKarti(anaRenk),
          const SizedBox(height: 15),
          _dersListesiView(),
        ],
      ),
    );
  }

  // --- YARDIMCI WIDGETLAR ---

  Widget _profilBaslikWidget(BuildContext context, String baslik) {
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

  Widget _ustAksiyonButonu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _dersEklemePaneliniAc, // Ders Ekleme Paneli Buradan Açılıyor
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

  Widget _belirginAyarKarti(Color anaRenk) {
    return InkWell(
      onTap: _ayarlarPaneliniAc, // Ayarlar Paneli Buradan Açılıyor
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.settings_outlined, color: anaRenk, size: 22),
            const SizedBox(width: 15),
            const Expanded(
              child: Text(
                "Ders Giriş-Çıkış Saatlerini Ayarla",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _dersListesiView() {
    return Column(
      children: [
        _dersKarti(
          "1",
          "Bilişim Teknolojileri",
          "08:00 - 08:40",
          "5/B",
          Colors.blue,
        ),
        _dersKarti(
          "2",
          "Yazılım Uygulamaları",
          "08:50 - 09:30",
          "6/A",
          Colors.indigo,
        ),
      ],
    );
  }

  Widget _dersKarti(
    String sira,
    String ders,
    String saat,
    String sinif,
    Color renk,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10),
        ],
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ders,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  "$saat • $sinif",
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert, color: Colors.grey),
        ],
      ),
    );
  }

  // Panel Yardımcıları
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
              _kucukButon(Icons.remove, onLess),
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text(
                  deger,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              _kucukButon(Icons.add, onAdd),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kucukButon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }
}
