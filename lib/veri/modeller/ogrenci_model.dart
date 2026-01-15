class OgrenciModel {
  final int? id;
  final String ad;
  final String? soyad;
  final String numara;
  final int sinifId; // Hangi sınıfa ait olduğu
  final String cinsiyet; // 'Kiz' veya 'Erkek'
  final String? fotoYolu; // Fotoğrafın telefondaki adresi
  final String? olusturulmaTarihi;

  OgrenciModel({
    this.id,
    required this.ad,
    this.soyad,
    required this.numara,
    required this.sinifId,
    required this.cinsiyet,
    this.fotoYolu,
    this.olusturulmaTarihi,
  });

  // Veritabanından gelen veriyi (Map) Dart nesnesine çevirir
  factory OgrenciModel.fromMap(Map<String, dynamic> map) {
    return OgrenciModel(
      id: map['id'],
      ad: map['ad'],
      soyad: map['soyad'],
      numara: map['numara'],
      sinifId: map['sinif_id'],
      cinsiyet: map['cinsiyet'],
      fotoYolu: map['foto_yolu'],
      olusturulmaTarihi: map['olusturulma_tarihi'],
    );
  }

  // Dart nesnesini veritabanı formatına (Map) çevirir
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ad': ad,
      'soyad': soyad,
      'numara': numara,
      'sinif_id': sinifId,
      'cinsiyet': cinsiyet,
      'foto_yolu': fotoYolu,
      'olusturulma_tarihi':
          olusturulmaTarihi ?? DateTime.now().toIso8601String(),
    };
  }
}
