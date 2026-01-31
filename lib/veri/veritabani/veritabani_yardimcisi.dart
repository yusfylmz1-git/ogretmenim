import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class VeritabaniYardimcisi {
  static final VeritabaniYardimcisi instance = VeritabaniYardimcisi._init();
  static Database? _database;

  VeritabaniYardimcisi._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ogretmenim_v14.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.rawQuery('PRAGMA journal_mode = WAL');
      },
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';

    // 1. SINIFLAR
    await db.execute('''
      CREATE TABLE siniflar (
        id $idType,
        sinif_adi TEXT NOT NULL UNIQUE, 
        aciklama $textNullable,
        olusturulma_tarihi $textType
      )
    ''');

    // 2. ÖĞRENCİLER
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

    // 3. DERSLER
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

    // 4. DEĞERLENDİRME KRİTERLERİ
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

    // 7. PERFORMANS TABLOSU
    await db.execute('''
      CREATE TABLE performans (
        id $idType,
        ogrenci_id $intType, 
        tarih $textType,
        kitap $intType DEFAULT 0,
        odev $intType DEFAULT 0,
        yildiz $intType DEFAULT 1,
        puan $intType DEFAULT 0,
        FOREIGN KEY (ogrenci_id) REFERENCES ogrenciler (id) ON DELETE CASCADE
      )
    ''');

    // 8. SİSTEM AYARLARI
    await db.execute('''
      CREATE TABLE sistem_ayarlari (
        anahtar TEXT PRIMARY KEY,
        deger TEXT
      )
    ''');

    await db.execute(
      "INSERT OR IGNORE INTO sistem_ayarlari (anahtar, deger) VALUES ('egitim_baslangic', '2025-09-08')",
    );

    // 9. KAZANIMLAR
    await db.execute('''
      CREATE TABLE kazanimlar (
        id $idType,
        sinif $intType,
        brans $textType,
        unite $textType,
        kazanim $textType,
        hafta $intType,
        ders_tipi $textType
      )
    ''');

    // 10. SINAVLAR
    await db.execute('''
      CREATE TABLE sinavlar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sinav_adi TEXT NOT NULL,
        sinif TEXT NOT NULL,
        ders TEXT NOT NULL,
        tarih TEXT NOT NULL,
        ortalama REAL,
        not_sayisi INTEGER,
        sinav_tipi TEXT DEFAULT 'klasik',
        soru_sayisi INTEGER DEFAULT 0,
        soru_puanlari TEXT
      )
    ''');

    // 11. SINAV NOTLARI
    await db.execute('''
      CREATE TABLE sinav_notlari (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sinav_id INTEGER NOT NULL,
        ogrenci_id INTEGER NOT NULL,
        ogrenci_ad_soyad TEXT,
        notu INTEGER,
        toplam_not REAL,
        soru_bazli_notlar TEXT,
        FOREIGN KEY (sinav_id) REFERENCES sinavlar (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- SINAV İŞLEMLERİ ---

  Future<int> sinavEkle(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('sinavlar', row);
  }

  Future<List<Map<String, dynamic>>> sinavlariGetir() async {
    final db = await instance.database;

    try {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sinavlar_tarih ON sinavlar(tarih DESC)',
      );
    } catch (e) {
      print("⚠️ Index hatası: $e");
    }

    return await db.query('sinavlar', orderBy: 'tarih DESC');
  }

  Future<int> sinavSil(int id) async {
    final db = await instance.database;
    await db.delete('sinav_notlari', where: 'sinav_id = ?', whereArgs: [id]);
    return await db.delete('sinavlar', where: 'id = ?', whereArgs: [id]);
  }

  // --- MEVCUT SINAVI GÜNCELLEME ---
  Future<void> sinavGuncelle({
    required int sinavId,
    required Map<String, dynamic> sinavBilgileri,
    required List<Map<String, dynamic>> yeniNotlar,
  }) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      await txn.update(
        'sinavlar',
        sinavBilgileri,
        where: 'id = ?',
        whereArgs: [sinavId],
      );
      await txn.delete(
        'sinav_notlari',
        where: 'sinav_id = ?',
        whereArgs: [sinavId],
      );

      for (var not in yeniNotlar) {
        final notVerisi = Map<String, dynamic>.from(not);
        notVerisi['sinav_id'] = sinavId;
        await txn.insert('sinav_notlari', notVerisi);
      }
    });
  }

  Future<Map<String, dynamic>?> sinavGetirById(int id) async {
    final db = await instance.database;
    final results = await db.query(
      'sinavlar',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) return results.first;
    return null;
  }

  Future<void> sinavVeNotlariTopluKaydet({
    required Map<String, dynamic> sinavMap,
    required List<Map<String, dynamic>> notlarListesi,
  }) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      final sinavId = await txn.insert('sinavlar', sinavMap);
      for (var not in notlarListesi) {
        final yeniNot = Map<String, dynamic>.from(not);
        yeniNot['sinav_id'] = sinavId;
        await txn.insert('sinav_notlari', yeniNot);
      }
    });
  }

  // --- NOT İŞLEMLERİ (GÜNCELLENEN KISIM) ---

  Future<void> notKaydet(Map<String, dynamic> row) async {
    final db = await instance.database;
    final varMi = await db.query(
      'sinav_notlari',
      where: 'sinav_id = ? AND ogrenci_id = ?',
      whereArgs: [row['sinav_id'], row['ogrenci_id']],
    );

    if (varMi.isNotEmpty) {
      await db.update(
        'sinav_notlari',
        row,
        where: 'sinav_id = ? AND ogrenci_id = ?',
        whereArgs: [row['sinav_id'], row['ogrenci_id']],
      );
    } else {
      await db.insert('sinav_notlari', row);
    }
  }

  // 🔥 DÜZELTME BURADA: Artık öğrencilerden numarayı da çekiyor (JOIN işlemi)
  Future<List<Map<String, dynamic>>> notlariGetir(int sinavId) async {
    final db = await instance.database;
    // rawQuery ile iki tabloyu birleştiriyoruz: notlar + ogrenciler(numara)
    return await db.rawQuery(
      '''
      SELECT sinav_notlari.*, ogrenciler.numara 
      FROM sinav_notlari 
      LEFT JOIN ogrenciler ON sinav_notlari.ogrenci_id = ogrenciler.id 
      WHERE sinav_notlari.sinav_id = ?
      ORDER BY sinav_notlari.notu DESC
    ''',
      [sinavId],
    );
  }

  // --- DİĞER STANDART İŞLEMLER ---

  Future<void> kazanimlariTemizle() async {
    final db = await instance.database;
    await db.delete('kazanimlar');
  }

  Future<void> topluKazanimEkle(
    List<Map<String, dynamic>> kazanimListesi,
  ) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      for (var kazanim in kazanimListesi) {
        await txn.insert('kazanimlar', kazanim);
      }
    });
  }

  Future<List<Map<String, dynamic>>> planlariGetir(
    int sinif,
    String brans,
  ) async {
    final db = await instance.database;
    return await db.query(
      'kazanimlar',
      where: 'sinif = ? AND brans = ?',
      whereArgs: [sinif, brans],
      orderBy: 'hafta ASC',
    );
  }

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

  Future<Map<String, dynamic>?> ogrenciGetir(int id) async {
    final db = await instance.database;
    final maps = await db.query('ogrenciler', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return maps.first;
    return null;
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

  Future<int> dersGuncelle(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update('dersler', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> performansEkle(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(
      'performans',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> performanslariGetir() async {
    final db = await instance.database;
    return await db.query('performans');
  }

  Future<int> performansGuncelle(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update('performans', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> gunlukPerformanslariGetir(
    String tarih,
  ) async {
    final db = await instance.database;
    return await db.query('performans', where: 'tarih = ?', whereArgs: [tarih]);
  }

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

  Future<void> ayarKaydet(String anahtar, String deger) async {
    final db = await instance.database;
    await db.insert('sistem_ayarlari', {
      'anahtar': anahtar,
      'deger': deger,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> ayarGetir(String anahtar) async {
    final db = await instance.database;
    final maps = await db.query(
      'sistem_ayarlari',
      columns: ['deger'],
      where: 'anahtar = ?',
      whereArgs: [anahtar],
    );
    if (maps.isNotEmpty) return maps.first['deger'] as String;
    return null;
  }
}
