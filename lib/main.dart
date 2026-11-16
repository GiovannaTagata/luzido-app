import 'package:flutter/material.dart';

void main() {
  runApp(const LuzidoApp());
}

/// Primeira versão: só a estrutura do app.
/// As telas serão adicionadas nas próximas etapas do desenvolvimento.
class LuzidoApp extends StatelessWidget {
  const LuzidoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Luzido',
      home: Scaffold(
        body: Center(
          child: Text('Luzido', style: TextStyle(fontSize: 32)),
        ),
      ),
    );
  }
}
