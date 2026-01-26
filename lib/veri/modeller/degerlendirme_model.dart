class DegerlendirmeModel {
  final int? id;
  final int ogrenciId;
  final int sinifId;
  final String dersAdi;
  final String tarih;
  final double toplamPuan;

  // Detaylar: Hangi kriterden kaç puan aldı? (Örn: {1: 20.0, 2: 15.0})
  final Map<int, double> kriterPuanlari;

  DegerlendirmeModel({
    this.id,
    required this.ogrenciId,
    required this.sinifId,
    required this.dersAdi,
    required this.tarih,
    required this.toplamPuan,
    required this.kriterPuanlari,
  });

  // Veritabanına (SQLite) yazmak için Map'e çevirir (Ana Tablo İçin)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ogrenci_id': ogrenciId,
      'sinif_id': sinifId,
      'ders_adi': dersAdi,
      'tarih': tarih,
      'toplam_puan': toplamPuan,
    };
  }

  // Veritabanından okumak için (Listeleme yaparken)
  factory DegerlendirmeModel.fromMap(Map<String, dynamic> map) {
    return DegerlendirmeModel(
      id: map['id'],
      ogrenciId: map['ogrenci_id'],
      sinifId: map['sinif_id'],
      dersAdi: map['ders_adi'],
      tarih: map['tarih'],
      toplamPuan: (map['toplam_puan'] as num).toDouble(),
      kriterPuanlari:
          {}, // Detaylar genellikle ayrı bir sorguyla çekilir veya bu aşamada boş bırakılır
    );
  }
}
