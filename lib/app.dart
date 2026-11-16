import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/estoque_service.dart';
import 'services/pin_service.dart';
import 'services/receita_service.dart';
import 'ui/tema.dart';
import 'ui/telas/inicio_tela.dart';
import 'ui/telas/pin_tela.dart';

class LuzidoApp extends StatelessWidget {
  const LuzidoApp({
    super.key,
    required this.estoque,
    required this.receitas,
    this.pin,
  });

  final EstoqueService estoque;
  final ReceitaService receitas;

  /// Se for null (por exemplo nos testes), o app abre direto na tela inicial.
  final PinService? pin;

  @override
  Widget build(BuildContext context) {
    final pinService = pin;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<EstoqueService>.value(value: estoque),
        ChangeNotifierProvider<ReceitaService>.value(value: receitas),
      ],
      child: MaterialApp(
        title: 'Luzido',
        debugShowCheckedModeBanner: false,
        theme: temaLuzido(),
        home: pinService == null
            ? const InicioTela()
            : PinTela(servico: pinService, proximaTela: const InicioTela()),
      ),
    );
  }
}
