import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

// 👇 DİL DESTEĞİ İÇİN GEREKLİ KÜTÜPHANELER
import 'package:ogretmenim/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:ogretmenim/ozellikler/giris/ana_sayfa.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Masaüstü platformları için sqflite_common_ffi başlatılıyor
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await initializeDateFormatting('tr_TR', null);
  runApp(const ProviderScope(child: OgretmenimUygulamasi()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AnaSayfa()),
    GoRoute(
      path: '/excel-preview',
      builder: (context, state) => const ExcelPreviewPage(),
    ),
  ],
);

// Öğrenci veri modeli
class Student {
  final String number; // Öğrenci no
  final String name;
  final String surname;
  final String classroom; // Sınıf (5-A gibi)
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

  // Otomatik başlık eşleştirme
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
    print('Excel başlıkları: $excelHeaders');
    for (var field in fieldKeywords.keys) {
      for (int i = 0; i < excelHeaders.length; i++) {
        String header = excelHeaders[i].toLowerCase().replaceAll(' ', '');
        for (var keyword in fieldKeywords[field]!) {
          if (header.contains(keyword.replaceAll(' ', ''))) {
            headerMapping[field] = i;
            print('Eşleşen başlık: $field -> ${excelHeaders[i]} (index $i)');
            break;
          }
        }
        if (headerMapping.containsKey(field)) break;
      }
    }
    print('Header mapping sonucu: $headerMapping');
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
          print('Toplam veri satırı: ${rows.length - 1}');
          for (var row in rows.skip(1)) {
            print(
              'Satır: ${row.map((c) => c?.value.toString() ?? '').toList()}',
            );
            String number = headerMapping.containsKey('number')
                ? row[headerMapping['number']!]?.value.toString() ?? ''
                : '';
            String name = '';
            String surname = '';
            if (headerMapping.containsKey('name')) {
              var nameCell =
                  row[headerMapping['name']!]?.value.toString() ?? '';
              // isim soyisim birleşik ise ayır
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
            print(
              'Çekilen: no=$number, ad=$name, soyad=$surname, sınıf=$classroom, cinsiyet=$gender',
            );
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
      print('Toplam öğrenci: ${tempStudents.length}');
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

class OgretmenimUygulamasi extends StatelessWidget {
  const OgretmenimUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    // 👇 ARADIĞIN KISIM BURASI
    return MaterialApp.router(
      title: 'Öğretmenim Asistanı',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: GoogleFonts.roboto().fontFamily,
      ),

      // 👇 EKLEMEN GEREKEN DİL AYARLARI BURADA
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'), // Türkçe
        Locale('en'), // İngilizce
      ],
      locale: const Locale('tr'), // Uygulama Türkçe açılsın
    );
  }
}
