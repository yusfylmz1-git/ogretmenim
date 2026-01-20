import '../../main.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfilAyarlariSayfasi extends StatefulWidget {
  const ProfilAyarlariSayfasi({Key? key}) : super(key: key);

  @override
  State<ProfilAyarlariSayfasi> createState() => _ProfilAyarlariSayfasiState();
}

class _ProfilAyarlariSayfasiState extends State<ProfilAyarlariSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _bransController = TextEditingController();
  final _okulController = TextEditingController();
  final _mudurController = TextEditingController();

  String _secilenCinsiyet = 'Erkek';
  String? _fotografYolu;

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _bransController.dispose();
    _okulController.dispose();
    _mudurController.dispose();
    super.dispose();
  }

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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Fotoğraf Kaynağı',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.purple),
                ),
                title: const Text(
                  'Kamera ile çek',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _kameradanVeyaGaleridenAl(ImageSource.camera);
                },
              ),
              const Divider(indent: 70, endIndent: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.orange),
                ),
                title: const Text(
                  'Galeriden seç',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
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
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'ogretmen_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final yeniYol = '${appDir.path}/$fileName';
      await geciciDosya.copy(yeniYol);
      if (!mounted) return;
      setState(() {
        _fotografYolu = yeniYol;
      });
    } catch (e) {
      debugPrint("Kaydetme HATASI: $e");
    }
  }

  Future<void> _oturumuKapat() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthGate()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Profil Ayarları',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _secilenCinsiyet == 'Kadın'
                  ? [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)]
                  : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- ÜST PROFİL FOTOĞRAF ALANI ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _secilenCinsiyet == 'Kadın'
                      ? [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)]
                      : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Builder(
                        builder: (context) {
                          final user = FirebaseAuth.instance.currentUser;
                          final googlePhoto = user?.photoURL;
                          final mail = user?.email;
                          if (googlePhoto != null && googlePhoto.isNotEmpty) {
                            return CircleAvatar(
                              radius: 65,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: NetworkImage(googlePhoto),
                            );
                          } else if (_fotografYolu != null &&
                              File(_fotografYolu!).existsSync()) {
                            return CircleAvatar(
                              radius: 65,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: FileImage(File(_fotografYolu!)),
                            );
                          } else if (mail != null && mail.isNotEmpty) {
                            return CircleAvatar(
                              radius: 65,
                              backgroundColor: Colors.grey.shade200,
                              child: Text(
                                mail[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          } else {
                            return CircleAvatar(
                              radius: 65,
                              backgroundColor: Colors.grey.shade200,
                              child: Icon(
                                Icons.person,
                                size: 70,
                                color: Colors.grey.shade400,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _resimSecimPaneliniAc,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _secilenCinsiyet == 'Kadın'
                                ? const Color(0xFFD81B60)
                                : Colors.indigo,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
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

            // --- FORM ALANI ---
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // KİŞİSEL BİLGİLER KARTI
                      Container(
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
                            const Text(
                              "Kişisel Bilgiler",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF222222),
                              ),
                            ),
                            const SizedBox(height: 15),
                            _customTextField(
                              controller: _adController,
                              label: 'Ad',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 15),
                            _customTextField(
                              controller: _soyadController,
                              label: 'Soyad',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 15),
                            // Cinsiyet Seçimi
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
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
                                        items: ['Erkek', 'Kadın'].map((
                                          String value,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        onChanged: (newValue) {
                                          setState(() {
                                            _secilenCinsiyet = newValue!;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // MESLEKİ BİLGİLER KARTI
                      Container(
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
                            const Text(
                              "Mesleki Bilgiler",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF222222),
                              ),
                            ),
                            const SizedBox(height: 15),
                            _customTextField(
                              controller: _bransController,
                              label: 'Branş',
                              icon: Icons.work_outline,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty)
                                  return 'Branş gerekli';
                                if (value.length < 2)
                                  return 'Branş adı çok kısa';
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            _customTextField(
                              controller: _okulController,
                              label: 'Okul',
                              icon: Icons.school_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty)
                                  return 'Okul gerekli';
                                if (value.length < 2)
                                  return 'Okul adı çok kısa';
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            _customTextField(
                              controller: _mudurController,
                              label: 'Müdür',
                              icon: Icons.account_box_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty)
                                  return 'Müdür adı gerekli';
                                if (value.length < 2)
                                  return 'Müdür adı çok kısa';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // GİRİŞ YAPILAN MAİL
                      if (user != null) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.email, color: Colors.grey),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  user.email ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text(
                              'Oturumu Kapat',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _oturumuKapat,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // KAYDET BUTONU
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _secilenCinsiyet == 'Kadın'
                                ? const Color(0xFFD81B60)
                                : Colors.indigo,
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'KAYDET',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
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
          borderSide: BorderSide(
            color: _secilenCinsiyet == 'Kadın'
                ? const Color(0xFFD81B60)
                : Colors.indigo,
            width: 1.5,
          ),
        ),
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.trim().isEmpty) return '$label gerekli';
            if (value.length < 2) return '$label çok kısa';
            return null;
          },
    );
  }
}
