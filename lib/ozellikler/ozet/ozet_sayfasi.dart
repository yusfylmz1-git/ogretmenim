import 'package:flutter/material.dart';
import 'package:ogretmenim/gen_l10n/app_localizations.dart';

class OzetSayfasi extends StatelessWidget {
  const OzetSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    final dil = AppLocalizations.of(context)!;
    final anaRenk = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          dil.ozet,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        backgroundColor: anaRenk,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dil.hosgeldin,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  dil.bugunDersProgramiBos,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
