import 'package:flutter/material.dart';
import 'package:ogretmenim/gen_l10n/app_localizations.dart';

class DersProgramiSayfasi extends StatelessWidget {
  const DersProgramiSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    final dil = AppLocalizations.of(context)!;
    final anaRenk = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: anaRenk,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          toolbarHeight: 100,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 0,
              top: 12,
              bottom: 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    dil.program,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          centerTitle: false,
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
