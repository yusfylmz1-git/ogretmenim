class PerformansModel {
  final int? id;
  final int ogrenciId;
  final String tarih; // YYYY-MM-DD formatında tutacağız
  final int kitap; // 0: Hayır, 1: Evet
  final int odev; // 0: Hayır, 1: Evet
  final int yildiz; // 1, 2 veya 3
  final int puan; // Hesaplanan toplam puan (0-100)

  PerformansModel({
    this.id,
    required this.ogrenciId,
    required this.tarih,
    required this.kitap,
    required this.odev,
    required this.yildiz,
    required this.puan,
  });

  // Veritabanından gelen veriyi (Map) Modele çevirir
  factory PerformansModel.fromMap(Map<String, dynamic> map) {
    return PerformansModel(
      id: map['id'],
      ogrenciId: map['ogrenci_id'],
      tarih: map['tarih'],
      kitap: map['kitap'],
      odev: map['odev'],
      yildiz: map['yildiz'],
      puan: map['puan'],
    );
  }

  // Modeli Veritabanına kaydedilecek hale (Map) çevirir
  // DÜZELTME BURADA YAPILDI: ID null ise map'e eklemiyoruz.
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'ogrenci_id': ogrenciId,
      'tarih': tarih,
      'kitap': kitap,
      'odev': odev,
      'yildiz': yildiz,
      'puan': puan,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  // Kopya oluşturmak için (State yönetimi için gerekli olacak)
  PerformansModel copyWith({
    int? id,
    int? ogrenciId,
    String? tarih,
    int? kitap,
    int? odev,
    int? yildiz,
    int? puan,
  }) {
    return PerformansModel(
      id: id ?? this.id,
      ogrenciId: ogrenciId ?? this.ogrenciId,
      tarih: tarih ?? this.tarih,
      kitap: kitap ?? this.kitap,
      odev: odev ?? this.odev,
      yildiz: yildiz ?? this.yildiz,
      puan: puan ?? this.puan,
    );
  }
}
