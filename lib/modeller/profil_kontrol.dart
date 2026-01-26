import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> profilEksikMi(String uid) async {
  final doc = await FirebaseFirestore.instance
      .collection('teachers')
      .doc(uid)
      .get();
  if (!doc.exists) return true;
  final data = doc.data() as Map<String, dynamic>;
  final ad = data['ad'] ?? '';
  final soyad = data['soyad'] ?? '';
  return ad.isEmpty || soyad.isEmpty;
}
