class SinifModel {
  final int? id;
  final String sinifAdi;
  final String? aciklama;
  final String? olusturulmaTarihi;

  SinifModel({
    this.id,
    required this.sinifAdi,
    this.aciklama,
    this.olusturulmaTarihi,
  });

  // Veritabanından gelen veriyi (Map) Dart nesnesine çevirir
  factory SinifModel.fromMap(Map<String, dynamic> map) {
    return SinifModel(
      id: map['id'],
      sinifAdi: map['sinif_adi'],
      aciklama: map['aciklama'],
      olusturulmaTarihi: map['olusturulma_tarihi'],
    );
  }

  // Dart nesnesini veritabanına kaydedilecek formata (Map) çevirir
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sinif_adi': sinifAdi,
      'aciklama': aciklama,
      'olusturulma_tarihi':
          olusturulmaTarihi ?? DateTime.now().toIso8601String(),
    };
  }
}
