import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/veri/veritabani/veritabani_yardimcisi.dart';
import 'package:ogretmenim/main.dart';

class AdminPaneliSayfasi extends StatefulWidget {
  const AdminPaneliSayfasi({super.key});

  @override
  State<AdminPaneliSayfasi> createState() => _AdminPaneliSayfasiState();
}

class _AdminPaneliSayfasiState extends State<AdminPaneliSayfasi> {
  // --- STATE DEĞİŞKENLERİ ---
  DateTime? _okulBaslangic;
  DateTime? _okulBitis;

  DateTime? _araTatil1; // KASIM
  DateTime? _yariyilBaslangic;
  DateTime? _yariyilBitis;
  DateTime? _araTatil2; // NİSAN

  // --- YENİ: BAYRAMLAR (OPSİYONEL) ---
  DateTime? _ramazanBayrami;
  DateTime? _kurbanBayrami;

  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _ayarlariYukle();
  }

  Future<void> _ayarlariYukle() async {
    final db = VeritabaniYardimcisi.instance;

    final bas = await db.ayarGetir('egitim_baslangic');
    final bit = await db.ayarGetir('egitim_bitis');
    final at1 = await db.ayarGetir('ara_tatil1');
    final yb = await db.ayarGetir('yariyil_baslangic');
    final ybt = await db.ayarGetir('yariyil_bitis');
    final at2 = await db.ayarGetir('ara_tatil2');

    // Bayramları Çek
    final ramazan = await db.ayarGetir('tatil_ramazan');
    final kurban = await db.ayarGetir('tatil_kurban');

    if (mounted) {
      setState(() {
        if (bas != null) _okulBaslangic = DateTime.tryParse(bas);
        if (bit != null) _okulBitis = DateTime.tryParse(bit);
        if (at1 != null) _araTatil1 = DateTime.tryParse(at1);
        if (yb != null) _yariyilBaslangic = DateTime.tryParse(yb);
        if (ybt != null) _yariyilBitis = DateTime.tryParse(ybt);
        if (at2 != null) _araTatil2 = DateTime.tryParse(at2);

        // Bayramlar
        if (ramazan != null) _ramazanBayrami = DateTime.tryParse(ramazan);
        if (kurban != null) _kurbanBayrami = DateTime.tryParse(kurban);

        _yukleniyor = false;
      });
    }
  }

  Future<void> _kaydet() async {
    if (_okulBaslangic == null || _okulBitis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Okul başlangıç ve bitiş tarihleri zorunludur."),
        ),
      );
      return;
    }

    setState(() => _yukleniyor = true);

    final db = VeritabaniYardimcisi.instance;
    final format = DateFormat('yyyy-MM-dd');

    await db.ayarKaydet('egitim_baslangic', format.format(_okulBaslangic!));
    await db.ayarKaydet('egitim_bitis', format.format(_okulBitis!));

    if (_araTatil1 != null)
      await db.ayarKaydet('ara_tatil1', format.format(_araTatil1!));
    if (_yariyilBaslangic != null)
      await db.ayarKaydet(
        'yariyil_baslangic',
        format.format(_yariyilBaslangic!),
      );
    if (_yariyilBitis != null)
      await db.ayarKaydet('yariyil_bitis', format.format(_yariyilBitis!));
    if (_araTatil2 != null)
      await db.ayarKaydet('ara_tatil2', format.format(_araTatil2!));

    // Bayramları Kaydet (Varsa kaydet, yoksa boşalt - burada basitçe üzerine yazıyoruz)
    if (_ramazanBayrami != null) {
      await db.ayarKaydet('tatil_ramazan', format.format(_ramazanBayrami!));
    } else {
      // Silmek için özel bir fonksiyon yoksa, 'null' string olarak kaydedebiliriz veya
      // veritabanı yapımızda silme desteği ekleyebiliriz. Şimdilik üzerine yazıyoruz.
      // Eğer kullanıcı sildiyse ve kaydet'e bastıysa, eski kaydın kalmaması için:
      // await db.ayarSil('tatil_ramazan'); // Eğer ayarSil metodu varsa.
      // Yoksa, Kazanımlar sayfasında null kontrolü yaptığımız için sorun olmaz ama veri kirliliği olur.
      // En basit çözüm: Boş string kaydetmek ve okurken kontrol etmek.
      await db.ayarKaydet('tatil_ramazan', '');
    }

    if (_kurbanBayrami != null) {
      await db.ayarKaydet('tatil_kurban', format.format(_kurbanBayrami!));
    } else {
      await db.ayarKaydet('tatil_kurban', '');
    }

    if (mounted) {
      setState(() => _yukleniyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Ayarlar kaydedildi!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _cikisYap() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OturumKapisi()),
        (route) => false,
      );
    }
  }

  Future<void> _tarihSec(BuildContext context, String tur) async {
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF10B981),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );

    if (secilen != null) {
      setState(() {
        if (tur == 'baslangic') _okulBaslangic = secilen;
        if (tur == 'bitis') _okulBitis = secilen;
        if (tur == 'ara1') _araTatil1 = secilen;
        if (tur == 'yariyil_bas') _yariyilBaslangic = secilen;
        if (tur == 'yariyil_bit') _yariyilBitis = secilen;
        if (tur == 'ara2') _araTatil2 = secilen;

        // Bayramlar
        if (tur == 'ramazan') _ramazanBayrami = secilen;
        if (tur == 'kurban') _kurbanBayrami = secilen;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProjeSayfaSablonu(
      baslikWidget: const Text(
        "Yönetici Paneli 🛠️",
        style: TextStyle(
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      icerik: _yukleniyor
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBilgiKarti(),
                  const SizedBox(height: 25),

                  const Text(
                    "Akademik Takvim",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTarihSecici(
                          baslik: "Açılış",
                          tarih: _okulBaslangic,
                          onTap: () => _tarihSec(context, 'baslangic'),
                          ikon: Icons.school_rounded,
                          kucukMu: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTarihSecici(
                          baslik: "Kapanış",
                          tarih: _okulBitis,
                          onTap: () => _tarihSec(context, 'bitis'),
                          ikon: Icons.celebration_rounded,
                          renk: Colors.red,
                          kucukMu: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildTarihSecici(
                    baslik: "1. Ara Tatil (Kasım)",
                    tarih: _araTatil1,
                    onTap: () => _tarihSec(context, 'ara1'),
                    ikon: Icons.nature_people_rounded,
                    renk: Colors.orange,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTarihSecici(
                          baslik: "Sömestr Baş.",
                          tarih: _yariyilBaslangic,
                          onTap: () => _tarihSec(context, 'yariyil_bas'),
                          ikon: Icons.snowing,
                          renk: Colors.blue,
                          kucukMu: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTarihSecici(
                          baslik: "Sömestr Bit.",
                          tarih: _yariyilBitis,
                          onTap: () => _tarihSec(context, 'yariyil_bit'),
                          ikon: Icons.sunny_snowing,
                          renk: Colors.blue,
                          kucukMu: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildTarihSecici(
                    baslik: "2. Ara Tatil (Nisan)",
                    tarih: _araTatil2,
                    onTap: () => _tarihSec(context, 'ara2'),
                    ikon: Icons.park_rounded,
                    renk: Colors.green,
                  ),

                  const SizedBox(height: 25),
                  const Divider(),
                  const SizedBox(height: 10),

                  const Text(
                    "Dini Bayramlar (Opsiyonel)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const Text(
                    "Eğer bayram eğitim haftasına denk geliyorsa seçiniz.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),

                  // RAMAZAN BAYRAMI
                  _buildBayramSecici(
                    baslik: "Ramazan Bayramı",
                    tarih: _ramazanBayrami,
                    onTap: () => _tarihSec(context, 'ramazan'),
                    onSil: () => setState(() => _ramazanBayrami = null),
                    renk: Colors.purple,
                  ),

                  const SizedBox(height: 15),

                  // KURBAN BAYRAMI
                  _buildBayramSecici(
                    baslik: "Kurban Bayramı",
                    tarih: _kurbanBayrami,
                    onTap: () => _tarihSec(context, 'kurban'),
                    onSil: () => setState(() => _kurbanBayrami = null),
                    renk: Colors.purple,
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _kaydet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "AYARLARI KAYDET",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // --- ÇIKIŞ YAP BUTONU EKLENDİ ---
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton.icon(
                      onPressed: _cikisYap,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade300,
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text("Oturumu Kapat"),
                    ),
                  ),

                  // ---------------------------------
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // --- WIDGETLAR ---

  Widget _buildBayramSecici({
    required String baslik,
    DateTime? tarih,
    required VoidCallback onTap,
    required VoidCallback onSil,
    Color renk = Colors.purple,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: renk.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.mosque_rounded, color: renk, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    baslik,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tarih != null
                        ? DateFormat('d MMM yyyy', 'tr_TR').format(tarih)
                        : "Seçiniz (Opsiyonel)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: tarih != null
                          ? const Color(0xFF1E293B)
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (tarih != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: onSil,
              )
            else
              Icon(
                Icons.edit_calendar_rounded,
                size: 20,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarihSecici({
    required String baslik,
    DateTime? tarih,
    required VoidCallback onTap,
    IconData ikon = Icons.calendar_today,
    Color renk = const Color(0xFF10B981),
    bool kucukMu = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (!kucukMu)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(right: 15),
                decoration: BoxDecoration(
                  color: renk.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(ikon, color: renk, size: 24),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    baslik,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tarih != null
                        ? DateFormat('d MMM yyyy', 'tr_TR').format(tarih)
                        : "Seçiniz",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: tarih != null
                          ? const Color(0xFF1E293B)
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (!kucukMu)
              Icon(
                Icons.edit_calendar_rounded,
                size: 20,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBilgiKarti() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.blue.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Akademik takvimi eksiksiz giriniz. Bayramlar hafta içine denk geliyorsa seçiniz, aksi takdirde boş bırakabilirsiniz.",
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
