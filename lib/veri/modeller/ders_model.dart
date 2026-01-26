import 'package:flutter/material.dart';

class DersModel {
  final int? id; // SQLite (Telefon) ID'si
  final String? docId; // Firebase (Bulut) ID'si
  final String dersAdi;
  final String sinif;
  final String gun;
  final int dersSaatiIndex;
  final Color renk;

  DersModel({
    this.id,
    this.docId,
    required this.dersAdi,
    required this.sinif,
    required this.gun,
    required this.dersSaatiIndex,
    required this.renk,
  });

  // Renk kodunu int olarak almak için yardımcı (Veritabanı için)
  int get renkValue => renk.value;

  // --- KRİTİK EKLENTİ: copyWith ---
  // Bu fonksiyon, bir dersin sadece istediğimiz kısmını değiştirip
  // yeni bir kopyasını oluşturur. Provider'da güncelleme yapmak için ŞARTTIR.
  DersModel copyWith({
    int? id,
    String? docId,
    String? dersAdi,
    String? sinif,
    String? gun,
    int? dersSaatiIndex,
    Color? renk,
  }) {
    return DersModel(
      id: id ?? this.id,
      docId: docId ?? this.docId,
      dersAdi: dersAdi ?? this.dersAdi,
      sinif: sinif ?? this.sinif,
      gun: gun ?? this.gun,
      dersSaatiIndex: dersSaatiIndex ?? this.dersSaatiIndex,
      renk: renk ?? this.renk,
    );
  }

  // Veritabanından gelen Map verisini Modele çevirir
  factory DersModel.fromMap(Map<String, dynamic> map, {String? firebaseId}) {
    return DersModel(
      id: map['id'],
      // Eğer dışarıdan firebaseId verilirse onu kullan, yoksa map'ten 'doc_id'yi oku
      docId: firebaseId ?? map['doc_id'],
      dersAdi: map['ders_adi'] ?? map['dersAdi'] ?? '',
      sinif: map['sinif'] ?? '',
      gun: map['gun'] ?? '',
      dersSaatiIndex: map['ders_saati_index'] ?? map['dersSaatiIndex'] ?? 0,
      renk: Color(map['renk'] ?? 0xFF2196F3),
    );
  }

  // Modeli Veritabanına (Map) çevirir
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doc_id': docId,
      'ders_adi': dersAdi,
      'sinif': sinif,
      'gun': gun,
      'ders_saati_index': dersSaatiIndex,
      'renk': renk.value,
      'olusturulma_tarihi': DateTime.now().toIso8601String(),
    };
  }
}
