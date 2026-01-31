class SinavAnaliz {
  final int? id;
  final String sinavAdi;
  final String sinif;
  final String ders;
  final DateTime tarih;
  final double ortalama;
  final int notSayisi;

  // 🔥 YENİ EKLENEN VE GÜNCELLENEN ALANLAR
  final String sinavTipi;
  final int soruSayisi;
  final String? soruPuanlari; // Eksik olan buydu ("10,20,5..." stringi)

  SinavAnaliz({
    this.id,
    required this.sinavAdi,
    required this.sinif,
    required this.ders,
    required this.tarih,
    this.ortalama = 0.0,
    this.notSayisi = 0,
    this.sinavTipi = 'klasik',
    this.soruSayisi = 0,
    this.soruPuanlari,
  });

  // 🔥 GÜVENLİ DÖNÜŞTÜRME - TÜM EDGE CASE'LERİ YÖNETİR
  factory SinavAnaliz.fromMap(Map<String, dynamic> map) {
    // Debug için log (Gerekirse açılabilir)
    // print("🔄 Model Dönüştürme: ${map['sinav_adi']}");

    return SinavAnaliz(
      id: map['id'] as int?,
      sinavAdi: (map['sinav_adi'] ?? '').toString(),
      sinif: (map['sinif'] ?? '').toString(),
      ders: (map['ders'] ?? '').toString(),

      // Tarih dönüşümü - Güvenli
      tarih: _parseTarih(map['tarih']),

      // Ortalama - null ve tip güvenliği
      ortalama: _parseDouble(map['ortalama']),

      // Not sayısı - null ve tip güvenliği
      notSayisi: _parseInt(map['not_sayisi']),

      // Sınav tipi
      sinavTipi: (map['sinav_tipi'] ?? 'klasik').toString(),

      // Soru sayısı
      soruSayisi: _parseInt(map['soru_sayisi']),

      // Soru Puanları (Nullable string)
      soruPuanlari: map['soru_puanlari'] as String?,
    );
  }

  // Yardımcı metodlar - Güvenli dönüşüm
  static DateTime _parseTarih(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    // print("⚠️ Geçersiz tarih: $value, varsayılan kullanılıyor");
    return DateTime.now();
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    // print("⚠️ Geçersiz double: $value");
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    // print("⚠️ Geçersiz int: $value");
    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sinav_adi': sinavAdi,
      'sinif': sinif,
      'ders': ders,
      'tarih': tarih.toIso8601String(),
      'ortalama': ortalama,
      'not_sayisi': notSayisi,
      'sinav_tipi': sinavTipi,
      'soru_sayisi': soruSayisi,
      'soru_puanlari': soruPuanlari,
    };
  }

  @override
  String toString() {
    return 'SinavAnaliz(id: $id, sinavAdi: $sinavAdi, sinif: $sinif, tarih: $tarih, tip: $sinavTipi)';
  }
}
