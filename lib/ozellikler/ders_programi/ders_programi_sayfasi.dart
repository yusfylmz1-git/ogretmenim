import 'package:flutter/material.dart';
import 'package:ogretmenim/gen_l10n/app_localizations.dart';

class DersProgramiSayfasi extends StatelessWidget {
  const DersProgramiSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    final dil = AppLocalizations.of(context)!;
    final anaRenk = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          dil.program,
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
      body: Center(
        child: Text(
          dil.bugunDersProgramiBos,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
