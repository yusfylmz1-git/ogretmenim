import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class VeritabaniYardimcisi {
  static final VeritabaniYardimcisi instance = VeritabaniYardimcisi._init();
  static Database? _database;

  VeritabaniYardimcisi._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ogretmenim.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Versiyonu değiştirmedik ama tablo ekledik.
    // Lütfen kodu kaydettikten sonra uygulamayı silip tekrar yükle.
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';

    // 1. SINIFLAR TABLOSU
    await db.execute('''
      CREATE TABLE siniflar (
        id $idType,
        sinif_adi $textType,
        aciklama $textNullable,
        olusturulma_tarihi $textType
      )
    ''');

    // 2. ÖĞRENCİLER TABLOSU (YENİ) 👇
    await db.execute('''
      CREATE TABLE ogrenciler (
        id $idType,
        ad $textType,
        soyad $textNullable,
        numara $textType,
        sinif_id $intType,
        cinsiyet $textType,
        foto_yolu $textNullable,
        olusturulma_tarihi $textType,
        FOREIGN KEY (sinif_id) REFERENCES siniflar (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- SINIF İŞLEMLERİ ---

  Future<int> sinifEkle(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('siniflar', row);
  }

  Future<List<Map<String, dynamic>>> siniflariGetir() async {
    final db = await instance.database;
    return await db.query('siniflar', orderBy: 'id DESC');
  }

  Future<int> sinifSil(int id) async {
    final db = await instance.database;
    // Önce bu sınıfa ait öğrencileri siliyoruz (Temizlik)
    await db.delete('ogrenciler', where: 'sinif_id = ?', whereArgs: [id]);
    return await db.delete('siniflar', where: 'id = ?', whereArgs: [id]);
  }

  // --- ÖĞRENCİ İŞLEMLERİ (YENİ) 👇 ---

  Future<int> ogrenciEkle(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('ogrenciler', row);
  }

  // Belirli bir sınıftaki öğrencileri getirir
  Future<List<Map<String, dynamic>>> ogrencileriGetir(int sinifId) async {
    final db = await instance.database;
    return await db.query(
      'ogrenciler',
      where: 'sinif_id = ?',
      whereArgs: [sinifId],
      orderBy: 'numara ASC', // Numaraya göre sırala
    );
  }

  Future<int> ogrenciSil(int id) async {
    final db = await instance.database;
    return await db.delete('ogrenciler', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> ogrenciGuncelle(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update('ogrenciler', row, where: 'id = ?', whereArgs: [id]);
  }
}
