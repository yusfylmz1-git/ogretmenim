import 'package:flutter/material.dart';

class DersModel {
  final String id;
  final String dersAdi;
  final String sinif;
  final String gun;
  final int dersSaatiIndex;
  final Color renk;

  DersModel({
    required this.id,
    required this.dersAdi,
    required this.sinif,
    required this.gun,
    required this.dersSaatiIndex,
    required this.renk,
  });

  // HATA ALDIĞIN YER BURASI: renkValue getter'ı ekliyoruz
  int get renkValue => renk.value;

  // HATA ALDIĞIN 2. YER: fromMap metodunu ekliyoruz
  factory DersModel.fromMap(Map<String, dynamic> map, String id) {
    return DersModel(
      id: id,
      dersAdi: map['dersAdi'] ?? '',
      sinif: map['sinif'] ?? '',
      gun: map['gun'] ?? '',
      dersSaatiIndex: map['dersSaatiIndex'] ?? 0,
      renk: Color(map['renk'] ?? 0xFF2196F3),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dersAdi': dersAdi,
      'sinif': sinif,
      'gun': gun,
      'dersSaatiIndex': dersSaatiIndex,
      'renk': renk.value,
    };
  }
}
