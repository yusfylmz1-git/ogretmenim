class OgrenciModel {
  final int? id;
  final String ad;
  final String? soyad;
  final String numara;
  final int sinifId; // Hangi sınıfa ait olduğu
  final String cinsiyet; // 'Kiz' veya 'Erkek'
  final String? fotoYolu; // Fotoğrafın telefondaki adresi
  final String? olusturulmaTarihi;
  final String? sinifAdi; // Düzenli sınıf adı (ör. 5-A)
  final bool selected;

  OgrenciModel({
    this.id,
    required this.ad,
    this.soyad,
    required this.numara,
    required this.sinifId,
    required this.cinsiyet,
    this.fotoYolu,
    this.olusturulmaTarihi,
    this.sinifAdi,
    this.selected = false,
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
      sinifAdi: map['sinif_adi'],
      selected: (map['selected'] is int)
          ? (map['selected'] == 1)
          : (map['selected'] ?? false),
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
      'sinif_adi': sinifAdi,
      'selected': selected ? 1 : 0, // SQLite uyumlu: bool -> int
    };
  }

  OgrenciModel copyWith({
    int? id,
    String? ad,
    String? soyad,
    String? numara,
    int? sinifId,
    String? cinsiyet,
    String? fotoYolu,
    String? olusturulmaTarihi,
    String? sinifAdi,
    bool? selected,
  }) {
    return OgrenciModel(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      soyad: soyad ?? this.soyad,
      numara: numara ?? this.numara,
      sinifId: sinifId ?? this.sinifId,
      cinsiyet: cinsiyet ?? this.cinsiyet,
      fotoYolu: fotoYolu ?? this.fotoYolu,
      olusturulmaTarihi: olusturulmaTarihi ?? this.olusturulmaTarihi,
      sinifAdi: sinifAdi ?? this.sinifAdi,
      selected: selected ?? this.selected,
    );
  }
}
