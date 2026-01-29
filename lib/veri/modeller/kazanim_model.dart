class KazanimModel {
  final int? id;
  final int sinif; // Excel Sütun D (5, 6, 7, 8)
  final String brans; // Excel Sütun C (Bilişim Teknolojileri)
  final String unite; // Excel Sütun E
  final String kazanim; // Excel Sütun F
  final int hafta; // Excel Sütun G
  final String dersTipi; // Excel Sütun B (Ders, Ara Tatil, Yarıyıl)

  KazanimModel({
    this.id,
    required this.sinif,
    required this.brans,
    required this.unite,
    required this.kazanim,
    required this.hafta,
    required this.dersTipi,
  });

  // Veritabanına yazmak için Map'e çevirme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sinif': sinif,
      'brans': brans,
      'unite': unite,
      'kazanim': kazanim,
      'hafta': hafta,
      'ders_tipi': dersTipi,
    };
  }

  // Veritabanından okumak için Map'ten Nesneye çevirme
  factory KazanimModel.fromMap(Map<String, dynamic> map) {
    return KazanimModel(
      id: map['id'],
      sinif: map['sinif'],
      brans: map['brans'],
      unite: map['unite'],
      kazanim: map['kazanim'],
      hafta: map['hafta'],
      dersTipi: map['ders_tipi'],
    );
  }
}
