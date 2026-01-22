import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ogretmenim/ozellikler/giris/ana_sayfa.dart';
import 'package:ogretmenim/gen_l10n/app_localizations.dart';
import 'package:ogretmenim/ozellikler/giris/giris_ekrani.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ogretmenim/cekirdek/tema/proje_sablonu.dart'; // Tema Sınıfı
import 'package:ogretmenim/cekirdek/yoneticiler/program_ayarlari.dart'; // YENİ: Program Ayarları

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows/Linux/MacOS için veritabanı ayarı
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Firebase.initializeApp();

  // --- AYARLARI YÜKLE ---
  // Uygulama başlamadan önce tema ve ders saatlerini hafızadan okuyoruz.
  await ProjeTemasi.temayiYukle();
  await ProgramAyarlari.ayarlariYukle();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Debug yazısını kaldırır
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AuthGate(),
      title: "Öğretmen Asistanı",
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return const AnaSayfa();
        } else {
          return const GirisEkrani();
        }
      },
    );
  }
}

// --- BURADAN AŞAĞISI EXCEL İŞLEMLERİ (Öğrenci Aktarımı İçin) ---

// Öğrenci veri modeli
class Student {
  final String number;
  final String name;
  final String surname;
  final String classroom;
  final String gender;
  bool selected;

  Student({
    required this.number,
    required this.name,
    required this.surname,
    required this.classroom,
    required this.gender,
    this.selected = false,
  });
}

// Excel'den veri çekip öni̇zleme ve sınıf listesine ekleme sayfası
class ExcelPreviewPage extends StatefulWidget {
  const ExcelPreviewPage({Key? key}) : super(key: key);

  @override
  State<ExcelPreviewPage> createState() => _ExcelPreviewPageState();
}

class _ExcelPreviewPageState extends State<ExcelPreviewPage> {
  List<Student> students = [];
  List<Student> classList = [];
  List<String> excelHeaders = [];
  Map<String, int> headerMapping = {};

  Map<String, List<String>> fieldKeywords = {
    'number': ['no', 'numara', 'öğrenci no', 'ogrenci no', 'id', 'tc', 's.no'],
    'name': [
      'ad',
      'isim',
      'adı',
      'adi',
      'name',
      'first',
      'isim soyisim',
      'isimsoyisim',
      'ad soyad',
      'adsoyad',
    ],
    'surname': ['soyad', 'soyadı', 'soyadi', 'surname', 'last'],
    'classroom': ['sınıf', 'sinif', 'class', 'grup', 'group', 'şube', 'sube'],
    'gender': ['cinsiyet', 'gender', 'erkek', 'kız', 'kiz', 'bay', 'bayan'],
  };

  void autoMapHeaders() {
    headerMapping.clear();
    for (var field in fieldKeywords.keys) {
      for (int i = 0; i < excelHeaders.length; i++) {
        String header = excelHeaders[i].toLowerCase().replaceAll(' ', '');
        for (var keyword in fieldKeywords[field]!) {
          if (header.contains(keyword.replaceAll(' ', ''))) {
            headerMapping[field] = i;
            break;
          }
        }
        if (headerMapping.containsKey(field)) break;
      }
    }
  }

  Future<void> pickAndReadExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null) {
      var bytes = File(result.files.single.path!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      List<Student> tempStudents = [];
      Set<String> usedNumbers = {};
      for (var table in excel.tables.keys) {
        var rows = excel.tables[table]!.rows;
        if (rows.isNotEmpty) {
          excelHeaders = rows.first
              .map((cell) => cell?.value.toString() ?? '')
              .toList();
          autoMapHeaders();
          for (var row in rows.skip(1)) {
            String number = headerMapping.containsKey('number')
                ? row[headerMapping['number']!]?.value.toString() ?? ''
                : '';
            String name = '';
            String surname = '';
            if (headerMapping.containsKey('name')) {
              var nameCell =
                  row[headerMapping['name']!]?.value.toString() ?? '';
              var parts = nameCell.split(RegExp(r'\s+'));
              if (parts.length > 1) {
                name = parts.sublist(0, parts.length - 1).join(' ');
                surname = parts.last;
              } else {
                name = nameCell;
              }
            }
            if (headerMapping.containsKey('surname') && surname.isEmpty) {
              surname = row[headerMapping['surname']!]?.value.toString() ?? '';
            }
            String classroom = headerMapping.containsKey('classroom')
                ? row[headerMapping['classroom']!]?.value.toString() ?? ''
                : '';
            String gender = headerMapping.containsKey('gender')
                ? row[headerMapping['gender']!]?.value.toString() ?? ''
                : '';
            if (number.isNotEmpty && !usedNumbers.contains(number)) {
              tempStudents.add(
                Student(
                  number: number,
                  name: name,
                  surname: surname,
                  classroom: classroom,
                  gender: gender,
                ),
              );
              usedNumbers.add(number);
            }
          }
        }
      }
      setState(() {
        students = tempStudents;
      });
    }
  }

  void addSelectedToClassList() {
    setState(() {
      for (var s in students.where((s) => s.selected)) {
        if (!classList.any((c) => c.number == s.number)) {
          classList.add(s);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Excel Önizleme ve Sınıf Listesi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickAndReadExcel,
              child: const Text('Excel Dosyası Seç'),
            ),
            const SizedBox(height: 16),
            students.isNotEmpty
                ? Expanded(
                    child: Column(
                      children: [
                        const Text('Önizleme'),
                        Expanded(
                          child: ListView(
                            children: [
                              DataTable(
                                columns: const [
                                  DataColumn(label: Text('Seç')),
                                  DataColumn(label: Text('No')),
                                  DataColumn(label: Text('Ad')),
                                  DataColumn(label: Text('Soyad')),
                                  DataColumn(label: Text('Sınıf')),
                                  DataColumn(label: Text('Cinsiyet')),
                                ],
                                rows: students
                                    .map(
                                      (student) => DataRow(
                                        cells: [
                                          DataCell(
                                            Checkbox(
                                              value: student.selected,
                                              onChanged: (val) {
                                                setState(() {
                                                  student.selected =
                                                      val ?? false;
                                                });
                                              },
                                            ),
                                          ),
                                          DataCell(Text(student.number)),
                                          DataCell(Text(student.name)),
                                          DataCell(Text(student.surname)),
                                          DataCell(Text(student.classroom)),
                                          DataCell(Text(student.gender)),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: addSelectedToClassList,
                          child: const Text('Seçilenleri Sınıf Listesine Ekle'),
                        ),
                        const SizedBox(height: 16),
                        const Text('Sınıf Listesi'),
                        Expanded(
                          child: ListView.builder(
                            itemCount: classList.length,
                            itemBuilder: (context, index) {
                              final student = classList[index];
                              return ListTile(
                                title: Text(
                                  '${student.name} ${student.surname}',
                                ),
                                subtitle: Text(
                                  'No: ${student.number} | Sınıf: ${student.classroom} | Cinsiyet: ${student.gender}',
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                : const Text('Henüz veri yok.'),
          ],
        ),
      ),
    );
  }
}
