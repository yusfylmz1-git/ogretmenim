class SinavModel {
  final int? id;
  final String sinavAdi;
  final String sinif;
  final String ders;
  final DateTime tarih;
  final double ortalama;
  final int notGirilenOgrenciSayisi;

  SinavModel({
    this.id,
    required this.sinavAdi,
    required this.sinif,
    required this.ders,
    required this.tarih,
    this.ortalama = 0.0,
    this.notGirilenOgrenciSayisi = 0,
  });

  // Veritabanından gelen Map verisini Modele çevirir
  factory SinavModel.fromMap(Map<String, dynamic> map) {
    return SinavModel(
      id: map['id'],
      sinavAdi: map['sinav_adi'],
      sinif: map['sinif'],
      ders: map['ders'],
      tarih: DateTime.parse(map['tarih']),
      // Veritabanından int veya double gelebilir, güvenli dönüşüm yapıyoruz:
      ortalama: (map['ortalama'] is int)
          ? (map['ortalama'] as int).toDouble()
          : (map['ortalama'] as double? ?? 0.0),
      notGirilenOgrenciSayisi: map['not_sayisi'] ?? 0,
    );
  }

  // Modeli Veritabanına kaydetmek için Map'e çevirir
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sinav_adi': sinavAdi,
      'sinif': sinif,
      'ders': ders,
      'tarih': tarih.toIso8601String(),
      'ortalama': ortalama,
      'not_sayisi': notGirilenOgrenciSayisi,
    };
  }
}
