import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ogretmenim/gen_l10n/app_localizations.dart';
import 'package:ogretmenim/ozellikler/ogrenciler/ogrenciler_provider.dart';
import 'package:ogretmenim/ozellikler/siniflar/siniflar_provider.dart';
import 'package:ogretmenim/veri/modeller/ogrenci_model.dart';

class OgrenciEkleSayfasi extends ConsumerStatefulWidget {
  final int? varsayilanSinifId;
  final OgrenciModel? duzenlenecekOgrenci;

  const OgrenciEkleSayfasi({
    super.key,
    this.varsayilanSinifId,
    this.duzenlenecekOgrenci,
  });

  @override
  ConsumerState<OgrenciEkleSayfasi> createState() => _OgrenciEkleSayfasiState();
}

class _OgrenciEkleSayfasiState extends ConsumerState<OgrenciEkleSayfasi> {
  final _formKey = GlobalKey<FormState>();

  // Kontrolcüler
  late TextEditingController adController;
  late TextEditingController soyadController;
  late TextEditingController noController;

  String secilenCinsiyet = 'Erkek';
  int? secilenSinifId;
  File? _secilenFoto;
  final ImagePicker _picker = ImagePicker();

  bool _duzenlemeModu = false;

  @override
  void initState() {
    super.initState();

    _duzenlemeModu = widget.duzenlenecekOgrenci != null;

    adController = TextEditingController(
      text: widget.duzenlenecekOgrenci?.ad ?? '',
    );
    soyadController = TextEditingController(
      text: widget.duzenlenecekOgrenci?.soyad ?? '',
    );
    noController = TextEditingController(
      text: widget.duzenlenecekOgrenci?.numara ?? '',
    );

    if (_duzenlemeModu) {
      secilenCinsiyet = widget.duzenlenecekOgrenci!.cinsiyet;
      secilenSinifId = widget.duzenlenecekOgrenci!.sinifId;
      if (widget.duzenlenecekOgrenci!.fotoYolu != null) {
        _secilenFoto = File(widget.duzenlenecekOgrenci!.fotoYolu!);
      }
    } else {
      secilenSinifId = widget.varsayilanSinifId;
    }
  }

  @override
  void dispose() {
    adController.dispose();
    soyadController.dispose();
    noController.dispose();
    super.dispose();
  }

  Future<void> _fotoSec(ImageSource kaynak) async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: kaynak,
        imageQuality: 80,
      );
      if (foto != null) {
        setState(() {
          _secilenFoto = File(foto.path);
        });
      }
    } catch (e) {
      debugPrint("Hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final dil = AppLocalizations.of(context)!;
    final sinifListesi = ref.watch(siniflarProvider);
    final anaRenk = Theme.of(context).primaryColor;

    String baslik = _duzenlemeModu ? "Öğrenci Düzenle" : dil.ogrenciEkle;

    // Çerçeve Tasarımı
    BoxDecoration cerceveDekorasyonu;
    if (secilenCinsiyet == 'Kız') {
      cerceveDekorasyonu = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.pinkAccent.shade100, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      );
    } else {
      cerceveDekorasyonu = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blueAccent.shade100, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(baslik),
        centerTitle: true,
        backgroundColor: anaRenk,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // FOTOĞRAF ALANI
              GestureDetector(
                onTap: () => _fotoSecimMenusuGoster(context),
                child: Container(
                  decoration: cerceveDekorasyonu,
                  padding: const EdgeInsets.all(4),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _secilenFoto != null
                        ? FileImage(_secilenFoto!)
                        : null,
                    child: _secilenFoto == null
                        ? Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.grey.shade400,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dil.fotografSec,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 24),

              // SINIF SEÇİMİ
              DropdownButtonFormField<int>(
                value: secilenSinifId,
                decoration: _inputDecoration(dil.siniflar, Icons.bookmark),
                items: sinifListesi.map((sinif) {
                  return DropdownMenuItem(
                    value: sinif.id,
                    child: Text(sinif.sinifAdi),
                  );
                }).toList(),
                onChanged: (value) => setState(() => secilenSinifId = value),
                validator: (value) =>
                    value == null ? "Sınıf seçimi zorunludur" : null,
              ),
              const SizedBox(height: 16),

              // AD ALANI
              TextFormField(
                controller: adController,
                maxLength: 20,
                decoration: _inputDecoration(dil.ad, Icons.person),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return "Ad boş olamaz";
                  if (value.length < 2) return "En az 2 harf giriniz";
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // SOYAD ALANI
              TextFormField(
                controller: soyadController,
                maxLength: 20,
                decoration: _inputDecoration(dil.soyad, Icons.person_outline),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return "Soyad boş olamaz";
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // NUMARA ALANI
              TextFormField(
                controller: noController,
                maxLength: 6,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  dil.numara,
                  Icons.format_list_numbered,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return "Numara giriniz";
                  if (!RegExp(r'^[0-9]+$').hasMatch(value))
                    return "Sadece rakam giriniz";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // CİNSİYET
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRadio(dil.erkek, 'Erkek', anaRenk),
                  const SizedBox(width: 20),
                  _buildRadio(dil.kiz, 'Kız', anaRenk),
                ],
              ),
              const SizedBox(height: 32),

              // BUTONLAR
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: anaRenk),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(dil.iptal, style: TextStyle(color: anaRenk)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _kaydet(sayfayiKapat: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: anaRenk,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _duzenlemeModu ? "GÜNCELLE" : dil.kaydet,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),

              // Kaydet ve Yeniden Ekle
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _kaydet(sayfayiKapat: false),
                icon: Icon(Icons.playlist_add, color: anaRenk),
                label: Text(
                  "Kaydet ve Yeniden Ekle",
                  style: TextStyle(color: anaRenk, fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey.shade600),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      counterText: "",
    );
  }

  Widget _buildRadio(String label, String value, Color renk) {
    return GestureDetector(
      onTap: () => setState(() => secilenCinsiyet = value),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: secilenCinsiyet,
            activeColor: (value == 'Kız') ? Colors.pink : Colors.blue,
            onChanged: (val) => setState(() => secilenCinsiyet = val!),
          ),
          Text(
            label,
            style: TextStyle(
              color: secilenCinsiyet == value
                  ? ((value == 'Kız') ? Colors.pink : Colors.blue)
                  : Colors.black,
              fontWeight: secilenCinsiyet == value
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _fotoSecimMenusuGoster(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(context);
                _fotoSec(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Fotoğraf Çek'),
              onTap: () {
                Navigator.pop(context);
                _fotoSec(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _kaydet({required bool sayfayiKapat}) {
    if (_formKey.currentState!.validate()) {
      final ogrenci = OgrenciModel(
        id: _duzenlemeModu ? widget.duzenlenecekOgrenci?.id : null,
        ad: adController.text.trim(),
        soyad: soyadController.text.trim(),
        numara: noController.text.trim(),
        cinsiyet: secilenCinsiyet,
        sinifId: secilenSinifId!,
        fotoYolu: _secilenFoto?.path,
      );

      if (_duzenlemeModu && widget.duzenlenecekOgrenci != null) {
        ref.read(ogrencilerProvider.notifier).ogrenciGuncelle(ogrenci);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Öğrenci güncellendi")));
      } else {
        ref.read(ogrencilerProvider.notifier).ogrenciEkle(ogrenci);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${ogrenci.ad} başarıyla eklendi!")),
        );
      }

      if (sayfayiKapat) {
        Navigator.pop(context);
      } else {
        _formuSifirla();
      }
    }
  }

  void _formuSifirla() {
    adController.clear();
    soyadController.clear();
    noController.clear();
    setState(() {
      _secilenFoto = null;
      secilenCinsiyet = 'Erkek';
      _duzenlemeModu = false;
    });
  }
}
