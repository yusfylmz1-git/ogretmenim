import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class VeritabaniYardimcisi {
  static final VeritabaniYardimcisi instance = VeritabaniYardimcisi._init();
  static Database? _database;

  VeritabaniYardimcisi._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Veritabanı yapısı değiştiği için v2 ile temiz bir başlangıç yapıyoruz.
    _database = await _initDB('ogretmenim_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      // KRİTİK: İlişkisel veritabanı (Cascade Delete) desteğini her bağlantıda açıyoruz
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';

    // 1. SINIFLAR (Unique kuralı eklendi)
    await db.execute('''
      CREATE TABLE siniflar (
        id $idType,
        sinif_adi TEXT NOT NULL UNIQUE, 
        aciklama $textNullable,
        olusturulma_tarihi $textType
      )
    ''');

    // 2. ÖĞRENCİLER (ON DELETE CASCADE bağlandı)
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
        sinif_adi $textNullable,
        selected INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (sinif_id) REFERENCES siniflar (id) ON DELETE CASCADE
      )
    ''');

    // 3. DERSLER (Mevcut yapın korundu)
    await db.execute('''
      CREATE TABLE dersler (
        id $idType,
        doc_id $textNullable,
        ders_adi $textType,
        sinif $textType,
        gun $textType,
        ders_saati_index $intType,
        renk $intType,
        olusturulma_tarihi $textType
      )
    ''');

    // 4. DEĞERLENDİRME KRİTERLERİ (Rubrik altyapısı hazırlandı)
    await db.execute('''
      CREATE TABLE degerlendirme_kriterleri (
        id $idType,
        baslik $textType,
        max_puan $doubleType,
        varsayilan $intType DEFAULT 1
      )
    ''');

    await db.execute('''
      INSERT INTO degerlendirme_kriterleri (baslik, max_puan, varsayilan) VALUES 
      ('Derse Hazırlık (Araç-Gereç)', 20.0, 1),
      ('Derse Katılım / Etkinlik', 20.0, 1),
      ('Ödev / Sorumluluk', 20.0, 1),
      ('Ders İçi Tutum / Davranış', 20.0, 1),
      ('Konuyu Kavrama', 20.0, 1)
    ''');

    // 5. ANA DEĞERLENDİRME KAYDI
    await db.execute('''
      CREATE TABLE ogrenci_degerlendirmeleri (
        id $idType,
        doc_id $textNullable, 
        ogrenci_id $intType,
        sinif_id $intType,
        ders_adi $textType,
        tarih $textType,
        toplam_puan $doubleType,
        FOREIGN KEY (ogrenci_id) REFERENCES ogrenciler (id) ON DELETE CASCADE
      )
    ''');

    // 6. DEĞERLENDİRME DETAYLARI
    await db.execute('''
      CREATE TABLE degerlendirme_detaylari (
        id $idType,
        degerlendirme_id $intType,
        kriter_id $intType,
        verilen_puan $doubleType,
        FOREIGN KEY (degerlendirme_id) REFERENCES ogrenci_degerlendirmeleri (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- SINIF İŞLEMLERİ ---
  Future<int> sinifEkle(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(
      'siniflar',
      row,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> siniflariGetir() async {
    final db = await instance.database;
    return await db.query('siniflar', orderBy: 'id DESC');
  }

  Future<int> sinifSil(int id) async {
    final db = await instance.database;
    return await db.delete('siniflar', where: 'id = ?', whereArgs: [id]);
  }

  // --- ÖĞRENCİ İŞLEMLERİ ---
  Future<int> ogrenciEkle(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('ogrenciler', row);
  }

  Future<List<Map<String, dynamic>>> ogrencileriGetir(int sinifId) async {
    final db = await instance.database;
    return await db.query(
      'ogrenciler',
      where: 'sinif_id = ?',
      whereArgs: [sinifId],
      orderBy: 'numara ASC',
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

  // --- DERS İŞLEMLERİ ---
  Future<int> dersEkle(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('dersler', row);
  }

  Future<List<Map<String, dynamic>>> dersleriGetir() async {
    final db = await instance.database;
    return await db.query('dersler', orderBy: 'ders_saati_index ASC');
  }

  Future<int> dersSil(int id) async {
    final db = await instance.database;
    return await db.delete('dersler', where: 'id = ?', whereArgs: [id]);
  }

  // --- EKSİK OLAN METOT (Dersler Provider'ı için gerekli) ---
  Future<int> dersGuncelle(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update('dersler', row, where: 'id = ?', whereArgs: [id]);
  }

  // --- DERS İÇİ KATILIM İÇİN GEREKLİ SORGULAR ---

  // Bir öğrencinin geçmiş değerlendirmelerini çekmek için
  Future<List<Map<String, dynamic>>> ogrenciNotlariniGetir(
    int ogrenciId,
    String dersAdi,
  ) async {
    final db = await instance.database;
    return await db.query(
      'ogrenci_degerlendirmeleri',
      where: 'ogrenci_id = ? AND ders_adi = ?',
      whereArgs: [ogrenciId, dersAdi],
      orderBy: 'tarih DESC',
    );
  }
}
