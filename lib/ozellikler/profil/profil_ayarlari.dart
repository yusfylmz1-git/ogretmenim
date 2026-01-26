import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';
import 'package:ogretmenim/modeller/profil_model.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilAyarlariSayfasi extends StatefulWidget {
  const ProfilAyarlariSayfasi({Key? key}) : super(key: key);

  @override
  State<ProfilAyarlariSayfasi> createState() => _ProfilAyarlariSayfasiState();
}

class _ProfilAyarlariSayfasiState extends State<ProfilAyarlariSayfasi> {
  // --- FOTOĞRAF YÜKLEME ---
  Future<String?> _fotoYukleVeUrlAl(File dosya) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final ref = FirebaseStorage.instance.ref().child(
        'profil_fotolari/${user.uid}.jpg',
      );
      await ref.putFile(dosya);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Foto yükleme hatası: $e');
      return null;
    }
  }

  ProfilModel? _profilModel;
  final _formKey = GlobalKey<FormState>();

  // Controller'lar
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _bransController = TextEditingController();
  final _okulController = TextEditingController();
  final _mudurController = TextEditingController();

  String _secilenCinsiyet = 'Erkek';
  String? _fotografYolu;
  bool _yukleniyor = false;

  @override
  void initState() {
    super.initState();
    _verileriHibritGetir();
  }

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _bransController.dispose();
    _okulController.dispose();
    _mudurController.dispose();
    super.dispose();
  }

  // --- ZIRHLI VALIDASYON MOTORU ---
  String? _guvenliDenetleyici(
    String? value,
    String alanAdi, {
    bool sadeceHarf = false,
    bool zorunlu = true,
    int maxKarakter = 30,
  }) {
    final veri = value?.trim() ?? "";

    // 1. Boşluk Kontrolü
    if (zorunlu && veri.isEmpty) {
      return '$alanAdi boş bırakılamaz';
    }

    // 2. Minimum Uzunluk
    if (veri.isNotEmpty && veri.length < 2) {
      return '$alanAdi en az 2 karakter olmalıdır';
    }

    // 3. Maksimum Uzunluk
    if (veri.length > maxKarakter) {
      return '$alanAdi en fazla $maxKarakter karakter olabilir';
    }

    // 4. Sadece Harf ve Türkçe Karakter Kontrolü (Regex)
    if (sadeceHarf && veri.isNotEmpty) {
      // Rakam ve Özel Karakterleri (.,!-_ vb) yasaklar, sadece harf ve boşluk
      final harfRegExp = RegExp(r"^[a-zA-ZçÇğĞıİöÖşŞüÜ\s]+$");
      if (!harfRegExp.hasMatch(veri)) {
        return '$alanAdi sadece harf içermelidir';
      }
    }

    return null;
  }

  // --- HİBRİT VERİ ÇEKME (LOCAL + FIREBASE) ---
  Future<void> _verileriHibritGetir() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _profilModel = ProfilModel(uid: user.uid);

    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _adController.text = prefs.getString('profil_ad') ?? '';
        _soyadController.text = prefs.getString('profil_soyad') ?? '';
        _bransController.text = prefs.getString('profil_brans') ?? '';
        _okulController.text = prefs.getString('profil_okul') ?? '';
        _mudurController.text = prefs.getString('profil_mudur') ?? '';
        _secilenCinsiyet = prefs.getString('profil_cinsiyet') ?? 'Erkek';
        _fotografYolu = prefs.getString('profil_foto');
      });
      ProjeTemasi.temayiDegistir(_secilenCinsiyet == 'Erkek');
    }

    try {
      await _profilModel!.verileriFirestoredanYukle();
      if (mounted) {
        setState(() {
          _adController.text = _profilModel!.ad ?? _adController.text;
          _soyadController.text = _profilModel!.soyad ?? _soyadController.text;
          _bransController.text = _profilModel!.brans ?? _bransController.text;
          _okulController.text = _profilModel!.okul ?? _okulController.text;
          _mudurController.text = _profilModel!.mudur ?? _mudurController.text;
          _secilenCinsiyet = _profilModel!.cinsiyet ?? _secilenCinsiyet;
          if (_profilModel!.fotoUrl != null)
            _fotografYolu = _profilModel!.fotoUrl;
        });

        await prefs.setString('profil_ad', _adController.text);
        await prefs.setString('profil_soyad', _soyadController.text);
        await prefs.setString('profil_brans', _bransController.text);
        await prefs.setString('profil_okul', _okulController.text);
        await prefs.setString('profil_mudur', _mudurController.text);
        await prefs.setString('profil_cinsiyet', _secilenCinsiyet);
        if (_fotografYolu != null)
          await prefs.setString('profil_foto', _fotografYolu!);
      }
    } catch (e) {
      debugPrint("Firebase veri çekme hatası: $e");
    }
  }

  // --- HİBRİT KAYDETME (LOCAL + FIREBASE) ---
  Future<void> _profilKaydet() async {
    // Klavye kapat
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() => _yukleniyor = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // 1. Önce Yerele Kaydet
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profil_ad', _adController.text.trim());
          await prefs.setString('profil_soyad', _soyadController.text.trim());
          await prefs.setString('profil_brans', _bransController.text.trim());
          await prefs.setString('profil_okul', _okulController.text.trim());
          await prefs.setString('profil_mudur', _mudurController.text.trim());
          await prefs.setString('profil_cinsiyet', _secilenCinsiyet);
          if (_fotografYolu != null) {
            await prefs.setString('profil_foto', _fotografYolu!);
          }

          // Model içindeki yerel veriyi güncelle (Senkronizasyon için)
          _profilModel!.ad = _adController.text.trim();
          _profilModel!.soyad = _soyadController.text.trim();
          _profilModel!.brans = _bransController.text.trim();
          _profilModel!.okul = _okulController.text.trim();
          _profilModel!.mudur = _mudurController.text.trim();
          _profilModel!.cinsiyet = _secilenCinsiyet;
          _profilModel!.fotoUrl = _fotografYolu;

          // 2. Sonra Firebase'e Kaydet
          await _profilModel!.verileriFirestoreaKaydet(
            ad: _adController.text.trim(),
            soyad: _soyadController.text.trim(),
            brans: _bransController.text.trim(),
            okul: _okulController.text.trim(),
            mudur: _mudurController.text.trim(),
            cinsiyet: _secilenCinsiyet,
            fotoUrl: _fotografYolu,
          );

          await ProjeTemasi.temayiDegistir(_secilenCinsiyet == 'Erkek');

          if (!mounted) return;
          setState(() {});

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bilgiler cihaza ve buluta doğrulandı ve kaydedildi!',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bağlantı hatası, sadece cihaza kaydedildi.'),
          ),
        );
      } finally {
        if (mounted) setState(() => _yukleniyor = false);
      }
    }
  }

  // --- RESİM İŞLEMLERİ ---
  Future<void> _resimSecimPaneliniAc() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.purple),
                title: const Text('Kamera ile çek'),
                onTap: () {
                  Navigator.pop(ctx);
                  _kameradanVeyaGaleridenAl(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.orange),
                title: const Text('Galeriden seç'),
                onTap: () {
                  Navigator.pop(ctx);
                  _kameradanVeyaGaleridenAl(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _kameradanVeyaGaleridenAl(ImageSource kaynak) async {
    try {
      final picker = ImagePicker();
      final XFile? secilenXFile = await picker.pickImage(
        source: kaynak,
        imageQuality: 50,
      );
      if (secilenXFile == null) return;
      await _resmiKaliciKaydet(File(secilenXFile.path));
    } catch (e) {
      debugPrint("HATA: $e");
    }
  }

  Future<void> _resmiKaliciKaydet(File geciciDosya) async {
    try {
      final url = await _fotoYukleVeUrlAl(geciciDosya);
      if (url != null) {
        if (!mounted) return;
        setState(() {
          _fotografYolu = url;
        });
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            'ogretmen_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final yeniYol = '${appDir.path}/$fileName';
        await geciciDosya.copy(yeniYol);
        if (!mounted) return;
        setState(() {
          _fotografYolu = yeniYol;
        });
      }
    } catch (e) {
      debugPrint("Kaydetme HATASI: $e");
    }
  }

  Future<void> _oturumuKapat() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final gradyan = ProjeTemasi.gradyanRenkleri;
    final anaRenk = ProjeTemasi.anaRenk;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: gradyan,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: _buildAvatar(user),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _resimSecimPaneliniAc,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: anaRenk,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () {
                  // KRİTİK HATA ÇÖZÜMÜ: Eğer geri gidecek yer yoksa ana sayfaya yönlendirir
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                },
              ),
              title: const Text(
                'Profil Ayarları',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ],
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Form(
              key: _formKey,
              autovalidateMode:
                  AutovalidateMode.onUserInteraction, // Yazarken denetle
              child: Column(
                children: [
                  _bilgiKarti("Kişisel Bilgiler", [
                    _customTextField(
                      controller: _adController,
                      label: 'Ad',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          _guvenliDenetleyici(v, "Ad", sadeceHarf: true),
                    ),
                    const SizedBox(height: 15),
                    _customTextField(
                      controller: _soyadController,
                      label: 'Soyad',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          _guvenliDenetleyici(v, "Soyad", sadeceHarf: true),
                    ),
                    const SizedBox(height: 15),
                    _cinsiyetSecici(),
                  ]),
                  const SizedBox(height: 20),
                  _bilgiKarti("Mesleki Bilgiler", [
                    _customTextField(
                      controller: _bransController,
                      label: 'Branş (İsteğe Bağlı)',
                      icon: Icons.work_outline,
                      validator: (v) =>
                          _guvenliDenetleyici(v, "Branş", zorunlu: false),
                    ),
                    const SizedBox(height: 15),
                    _customTextField(
                      controller: _okulController,
                      label: 'Okul (İsteğe Bağlı)',
                      icon: Icons.school_outlined,
                      validator: (v) => _guvenliDenetleyici(
                        v,
                        "Okul",
                        zorunlu: false,
                        maxKarakter: 50,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _customTextField(
                      controller: _mudurController,
                      label: 'Müdür (İsteğe Bağlı)',
                      icon: Icons.account_box_outlined,
                      validator: (v) => _guvenliDenetleyici(
                        v,
                        "Müdür",
                        zorunlu: false,
                        maxKarakter: 50,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 25),
                  if (user != null) ...[
                    _emailBilgisi(user.email ?? ''),
                    const SizedBox(height: 16),
                    _oturumuKapatButonu(),
                    const SizedBox(height: 16),
                  ],
                  _kaydetButonu(anaRenk),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- YARDIMCI WIDGETLAR ---

  Widget _buildAvatar(User? user) {
    final googlePhoto = user?.photoURL;
    if (googlePhoto != null && googlePhoto.isNotEmpty) {
      return CircleAvatar(
        radius: 65,
        backgroundImage: NetworkImage(googlePhoto),
      );
    } else if (_fotografYolu != null && _fotografYolu!.startsWith('http')) {
      return CircleAvatar(
        radius: 65,
        backgroundImage: NetworkImage(_fotografYolu!),
      );
    } else if (_fotografYolu != null && File(_fotografYolu!).existsSync()) {
      return CircleAvatar(
        radius: 65,
        backgroundImage: FileImage(File(_fotografYolu!)),
      );
    } else {
      return CircleAvatar(
        radius: 65,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: 70, color: Colors.grey.shade400),
      );
    }
  }

  Widget _bilgiKarti(String baslik, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            baslik,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _cinsiyetSecici() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.wc, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _secilenCinsiyet,
                isExpanded: true,
                items: ['Erkek', 'Kadın']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) async {
                  if (val != null) {
                    if (val != _secilenCinsiyet) {
                      await ProjeTemasi.temayiDegistir(val == 'Erkek');
                    }
                    setState(() {
                      _secilenCinsiyet = val;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emailBilgisi(String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.email, color: Colors.grey),
          const SizedBox(width: 10),
          Text(
            email,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _oturumuKapatButonu() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          'Oturumu Kapat',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _oturumuKapat,
      ),
    );
  }

  Widget _kaydetButonu(Color anaRenk) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _yukleniyor ? null : _profilKaydet,
        style: ElevatedButton.styleFrom(
          backgroundColor: anaRenk,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _yukleniyor
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'KAYDET',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _customTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator, // Form seviyesinde denetim için bu önemli
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ProjeTemasi.anaRenk, width: 1.5),
        ),
      ),
    );
  }
}
