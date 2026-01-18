import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ogretmenim/ozellikler/ogrenciler/ogrenciler_provider.dart';
import 'package:ogretmenim/ozellikler/siniflar/siniflar_provider.dart';
import 'package:ogretmenim/veri/modeller/ogrenci_model.dart';
import 'package:ogretmenim/cekirdek/araclar/bildirim_araci.dart';
import 'excel_preview_edit_page.dart';

class OgrenciEkleSayfasi extends ConsumerStatefulWidget {
  final OgrenciModel? duzenlenecekOgrenci;
  final int? varsayilanSinifId;

  const OgrenciEkleSayfasi({
    super.key,
    this.duzenlenecekOgrenci,
    this.varsayilanSinifId,
  });

  @override
  ConsumerState<OgrenciEkleSayfasi> createState() => _OgrenciEkleSayfasiState();
}

class _OgrenciEkleSayfasiState extends ConsumerState<OgrenciEkleSayfasi> {
  final _formKey = GlobalKey<FormState>();

  late String _ad;
  String? _soyad;
  late String _numara;
  String _cinsiyet = 'Erkek';
  int? _seciliSinifId;
  File? _secilenFoto;

  // Excel işlemi sırasında butonu pasif yapmak için durum değişkeni
  bool _yukleniyor = false;

  @override
  void initState() {
    super.initState();
    final ogrenci = widget.duzenlenecekOgrenci;
    if (ogrenci != null) {
      _ad = ogrenci.ad;
      _soyad = ogrenci.soyad;
      _numara = ogrenci.numara;
      _cinsiyet = ogrenci.cinsiyet;
      _seciliSinifId = ogrenci.sinifId;
      if (ogrenci.fotoYolu != null) {
        _secilenFoto = File(ogrenci.fotoYolu!);
      }
    } else {
      _ad = '';
      _numara = '';
      _seciliSinifId = widget.varsayilanSinifId;
    }
  }

  Future<void> _fotoSec() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _secilenFoto = File(pickedFile.path);
      });
    }
  }

  // --- YENİ EKLENEN: EXCEL YÜKLEME FONKSİYONU ---
  Future<void> _exceldenYukle() async {
    // 1. Kontrol: Sınıf seçili mi?
    if (_seciliSinifId == null) {
      BildirimAraci.tepeHataGoster(context, "Lütfen önce sınıf seçiniz!");
      return;
    }
    // Sadece Excel önizleme/düzenleme sayfasına yönlendir
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExcelPreviewEditPage()),
    );
  }
  // -------------------------------------------------

  void _kaydet() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_seciliSinifId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lütfen bir sınıf seçin')));
        return;
      }

      // KONTROL: AYNI NUMARA VAR MI?
      bool numaraDegisti = widget.duzenlenecekOgrenci?.numara != _numara;
      bool yeniKayit = widget.duzenlenecekOgrenci == null;

      if (yeniKayit || numaraDegisti) {
        final mevcutOgrenciler = ref.read(ogrencilerProvider);
        final ayniNumaraliOgrenci = mevcutOgrenciler.any(
          (o) => o.numara == _numara && o.sinifId == _seciliSinifId,
        );

        if (ayniNumaraliOgrenci) {
          BildirimAraci.tepeHataGoster(
            context,
            "⚠️ $_numara numaralı öğrenci bu sınıfta zaten kayıtlı!",
          );
          return;
        }
      }

      final ogrenci = OgrenciModel(
        id: widget.duzenlenecekOgrenci?.id,
        ad: _ad,
        soyad: _soyad,
        numara: _numara,
        cinsiyet: _cinsiyet,
        sinifId: _seciliSinifId!,
        fotoYolu: _secilenFoto?.path ?? widget.duzenlenecekOgrenci?.fotoYolu,
      );

      if (widget.duzenlenecekOgrenci == null) {
        ref.read(ogrencilerProvider.notifier).ogrenciEkle(ogrenci);
      } else {
        ref.read(ogrencilerProvider.notifier).ogrenciGuncelle(ogrenci);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siniflar = ref.watch(siniflarProvider);
    final anaRenk = Theme.of(context).primaryColor;
    final duzenlemeModu = widget.duzenlenecekOgrenci != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(duzenlemeModu ? "Öğrenci Düzenle" : "Öğrenci Ekle"),
        centerTitle: true,
        backgroundColor: anaRenk,
        foregroundColor: Colors.white,
        actions: [
          // SADECE EKLEME MODUNDAYSA EXCEL BUTONUNU GÖSTER
          if (!duzenlemeModu)
            IconButton(
              onPressed: _yukleniyor ? null : _exceldenYukle,
              icon: _yukleniyor
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.upload_file), // Excel ikonu
              tooltip: "Excel'den Yükle",
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Bilgilendirme Kutusu
              if (!duzenlemeModu)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Excel ile toplu yükleme yapmak için sağ üstteki butonu kullanabilirsiniz.",
                        ),
                      ),
                    ],
                  ),
                ),

              // FOTOĞRAF ALANI
              GestureDetector(
                onTap: _fotoSec,
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
              const SizedBox(height: 8),
              Text(
                "Fotoğraf Ekle",
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 24),

              // AD SOYAD
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _ad,
                      decoration: InputDecoration(
                        labelText: "Ad",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Ad boş olamaz" : null,
                      onSaved: (value) => _ad = value!,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: _soyad,
                      decoration: InputDecoration(
                        labelText: "Soyad",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSaved: (value) => _soyad = value,
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // NUMARA
              TextFormField(
                initialValue: _numara,
                decoration: InputDecoration(
                  labelText: "Okul No",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.badge),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Numara boş olamaz" : null,
                onSaved: (value) => _numara = value!,
              ),
              const SizedBox(height: 16),

              // SINIF SEÇİMİ (Dropdown)
              DropdownButtonFormField<int>(
                value: _seciliSinifId,
                decoration: InputDecoration(
                  labelText: "Sınıf",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.class_),
                ),
                items: siniflar.map((sinif) {
                  return DropdownMenuItem(
                    value: sinif.id,
                    child: Text(sinif.sinifAdi),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _seciliSinifId = value;
                  });
                },
                validator: (value) => value == null ? 'Sınıf seçiniz' : null,
              ),
              const SizedBox(height: 16),

              // CİNSİYET SEÇİMİ
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Erkek"),
                      value: 'Erkek',
                      groupValue: _cinsiyet,
                      activeColor: Colors.blue,
                      onChanged: (value) => setState(() => _cinsiyet = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Kız"),
                      value: 'Kız',
                      groupValue: _cinsiyet,
                      activeColor: Colors.pink,
                      onChanged: (value) => setState(() => _cinsiyet = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // KAYDET BUTONU
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _kaydet,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: anaRenk,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    duzenlemeModu ? "Güncelle" : "Kaydet",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
