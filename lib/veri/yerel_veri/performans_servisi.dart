import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:ogretmenim/veri/modeller/performans_model.dart';

class PerformansServisi {
  static final PerformansServisi _instance = PerformansServisi._internal();
  static Database? _database;

  PerformansServisi._internal();

  factory PerformansServisi() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Veritabanı ismini v4 yapalım ki tertemiz sayfa açılsın
    String path = join(await getDatabasesPath(), 'ogretmen_asistani_v4.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // UNIQUE(ogrenci_id, tarih) sayesinde aynı güne mükerrer kayıt engellenir
    await db.execute('''
      CREATE TABLE IF NOT EXISTS performanslar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ogrenci_id INTEGER NOT NULL,
        tarih TEXT NOT NULL,
        kitap INTEGER NOT NULL,
        odev INTEGER NOT NULL,
        yildiz INTEGER NOT NULL,
        puan INTEGER NOT NULL,
        UNIQUE(ogrenci_id, tarih)
      )
    ''');
  }

  // --- KAYIT İŞLEMİ (GÜNCELLENMİŞ) ---
  // Artık 'update' kullanmıyoruz. Bu yöntem varsa günceller, yoksa ekler.
  Future<void> performansKaydet(PerformansModel model) async {
    final db = await database;
    try {
      await db.insert(
        'performanslar',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace, // Sihirli kısım burası
      );
    } catch (e) {
      if (kDebugMode) print("Kayıt Hatası: $e");
      rethrow;
    }
  }

  // Toplu Kayıt (Hızlı Doldur İçin)
  Future<void> topluPerformansKaydet(List<PerformansModel> liste) async {
    final db = await database;
    try {
      final batch = db.batch();
      for (var model in liste) {
        batch.insert(
          'performanslar',
          model.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      if (kDebugMode) print("Toplu Kayıt Hatası: $e");
      rethrow;
    }
  }

  Future<List<PerformansModel>> gunlukListeyiGetir(String tarih) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'performanslar',
      where: 'tarih = ?',
      whereArgs: [tarih],
    );
    return List.generate(maps.length, (i) => PerformansModel.fromMap(maps[i]));
  }
}
