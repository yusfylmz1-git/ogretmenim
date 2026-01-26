class OgrenciModel {
  final int? id; // SQLite için yerel ID (Sayısal)
  final String? docId; // YENİ: Firebase Doküman ID'si (Metin)
  final String ad;
  final String? soyad;
  final String numara;
  final int sinifId;
  final String cinsiyet; // 'Kiz' veya 'Erkek'
  final String? fotoYolu;
  final String? olusturulmaTarihi;
  final String? sinifAdi;
  final bool selected;

  OgrenciModel({
    this.id,
    this.docId, // YENİ
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
  factory OgrenciModel.fromMap(Map<String, dynamic> map, {String? firebaseId}) {
    return OgrenciModel(
      id: map['id'], // SQLite'dan geliyorsa burası doludur
      docId: firebaseId, // Firebase'den geliyorsa burayı biz doldururuz
      ad: map['ad'] ?? '',
      soyad: map['soyad'] ?? '',
      numara: map['numara']?.toString() ?? '',
      sinifId: map['sinif_id'] ?? 0,
      cinsiyet: map['cinsiyet'] ?? 'Erkek',
      fotoYolu:
          map['foto_yolu'] ??
          map['fotoUrl'], // Hem senin eski ismini hem Firebase ismini desteklesin
      olusturulmaTarihi: map['olusturulma_tarihi'],
      sinifAdi: map['sinif_adi'] ?? map['sinif'],
      selected: (map['selected'] is int)
          ? (map['selected'] == 1)
          : (map['selected'] ?? false),
    );
  }

  // Dart nesnesini veritabanı formatına (Map) çevirir
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      // docId'yi SQLite'a kaydetmeye gerek yok, o Firebase için.
      'ad': ad,
      'soyad': soyad,
      'numara': numara,
      'sinif_id': sinifId,
      'cinsiyet': cinsiyet,
      'foto_yolu': fotoYolu,
      'olusturulma_tarihi':
          olusturulmaTarihi ?? DateTime.now().toIso8601String(),
      'sinif_adi': sinifAdi,
      'selected': selected ? 1 : 0,
    };
  }

  OgrenciModel copyWith({
    int? id,
    String? docId,
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
      docId: docId ?? this.docId,
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
