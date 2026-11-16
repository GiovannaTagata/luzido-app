import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/estoque_service.dart';
import 'services/receita_service.dart';
import 'ui/tema.dart';
import 'ui/telas/inicio_tela.dart';

class LuzidoApp extends StatelessWidget {
  const LuzidoApp({
    super.key,
    required this.estoque,
    required this.receitas,
  });

  final EstoqueService estoque;
  final ReceitaService receitas;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<EstoqueService>.value(value: estoque),
        ChangeNotifierProvider<ReceitaService>.value(value: receitas),
      ],
      child: MaterialApp(
        title: 'Luzido',
        debugShowCheckedModeBanner: false,
        theme: temaLuzido(),
        home: const InicioTela(),
      ),
    );
  }
}
