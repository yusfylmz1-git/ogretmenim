import 'package:flutter/material.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart';

class ProgramAyarlariPaneli extends StatefulWidget {
  // Başlangıç değerlerini dışarıdan alıyoruz
  final TimeOfDay ilkDersSaati;
  final int dersSuresi;
  final int teneffusSuresi;
  final int gunlukDersSayisi;
  final bool ogleArasiVarMi;
  final int ogleArasiSuresi;

  // Değişiklikleri ana sayfaya bildiren fonksiyon (Callback)
  final Function(TimeOfDay, int, int, int, bool, int) onKaydet;

  const ProgramAyarlariPaneli({
    super.key,
    required this.ilkDersSaati,
    required this.dersSuresi,
    required this.teneffusSuresi,
    required this.gunlukDersSayisi,
    required this.ogleArasiVarMi,
    required this.ogleArasiSuresi,
    required this.onKaydet,
  });

  @override
  State<ProgramAyarlariPaneli> createState() => _ProgramAyarlariPaneliState();
}

class _ProgramAyarlariPaneliState extends State<ProgramAyarlariPaneli> {
  // Yerel değişkenler (Geçici değişiklikler burada tutulur)
  late TimeOfDay _ilkDersSaati;
  late int _dersSuresi;
  late int _teneffusSuresi;
  late int _gunlukDersSayisi;
  late bool _ogleArasiVarMi;
  late int _ogleArasiSuresi;

  @override
  void initState() {
    super.initState();
    // Gelen değerleri yerel değişkenlere kopyala
    _ilkDersSaati = widget.ilkDersSaati;
    _dersSuresi = widget.dersSuresi;
    _teneffusSuresi = widget.teneffusSuresi;
    _gunlukDersSayisi = widget.gunlukDersSayisi;
    _ogleArasiVarMi = widget.ogleArasiVarMi;
    _ogleArasiSuresi = widget.ogleArasiSuresi;
  }

  @override
  Widget build(BuildContext context) {
    final anaRenk = ProjeTemasi.anaRenk;

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

          // 1. İLK DERS SAATİ
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
                setState(() => _ilkDersSaati = picked);
              }
            },
          ),
          const Divider(),

          // 2. GÜNLÜK DERS SAYISI
          _ayarStepSecici(
            icon: Icons.format_list_numbered,
            baslik: "Günlük Ders Sayısı",
            deger: "$_gunlukDersSayisi",
            onLess: () {
              if (_gunlukDersSayisi > 1) setState(() => _gunlukDersSayisi--);
            },
            onAdd: () {
              if (_gunlukDersSayisi < 14) setState(() => _gunlukDersSayisi++);
            },
          ),
          const Divider(),

          // 3. DERS SÜRESİ
          _ayarStepSecici(
            icon: Icons.timer_outlined,
            baslik: "Ders Süresi",
            deger: "$_dersSuresi dk",
            onLess: () {
              if (_dersSuresi > 15) setState(() => _dersSuresi -= 5);
            },
            onAdd: () {
              if (_dersSuresi < 90) setState(() => _dersSuresi += 5);
            },
          ),
          const Divider(),

          // 4. TENEFFÜS SÜRESİ
          _ayarStepSecici(
            icon: Icons.coffee_outlined,
            baslik: "Teneffüs",
            deger: "$_teneffusSuresi dk",
            onLess: () {
              if (_teneffusSuresi > 0) setState(() => _teneffusSuresi -= 5);
            },
            onAdd: () {
              if (_teneffusSuresi < 60) setState(() => _teneffusSuresi += 5);
            },
          ),
          const Divider(),

          // 5. ÖĞLE ARASI
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
              setState(() => _ogleArasiVarMi = value);
            },
          ),

          // 6. ÖĞLE ARASI SÜRESİ
          if (_ogleArasiVarMi)
            _ayarStepSecici(
              icon: Icons.more_time,
              baslik: "Öğle Arası Süresi",
              deger: "$_ogleArasiSuresi dk",
              onLess: () {
                if (_ogleArasiSuresi > 15)
                  setState(() => _ogleArasiSuresi -= 5);
              },
              onAdd: () {
                if (_ogleArasiSuresi < 120)
                  setState(() => _ogleArasiSuresi += 5);
              },
            ),

          const SizedBox(height: 30),

          // KAYDET BUTONU
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                // Değerleri ana sayfaya geri gönderiyoruz
                widget.onKaydet(
                  _ilkDersSaati,
                  _dersSuresi,
                  _teneffusSuresi,
                  _gunlukDersSayisi,
                  _ogleArasiVarMi,
                  _ogleArasiSuresi,
                );
                Navigator.pop(context);
              },
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
  }

  // --- YARDIMCI WIDGETLAR (Sadece bu dosya içinde kullanılır) ---
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
                  child: const Icon(
                    Icons.remove,
                    size: 18,
                    color: Colors.black87,
                  ),
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
                  child: const Icon(Icons.add, size: 18, color: Colors.black87),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
