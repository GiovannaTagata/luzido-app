@Tags(['capturas'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luzido/data/app_database.dart';
import 'package:luzido/data/dados_exemplo.dart';
import 'package:luzido/data/insumo_repository.dart';
import 'package:luzido/data/receita_repository.dart';
import 'package:luzido/models/receita.dart';
import 'package:luzido/services/estoque_service.dart';
import 'package:luzido/services/receita_service.dart';
import 'package:luzido/ui/tema.dart';
import 'package:luzido/ui/telas/modo_receita_tela.dart';
import 'package:luzido/ui/telas/resultado_tela.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Gera capturas de tela (PNG) do app de verdade, com os dados de exemplo,
/// em tamanho de celular. Roda só no job "Capturas de tela" do CI:
///   flutter test --update-goldens --tags capturas test/capturas
///
/// As fontes Roboto e os ícones do Material são carregados da pasta do
/// Flutter, para o texto aparecer normal (sem isso o teste usa uma fonte
/// de blocos).
Future<void> carregarFontes() async {
  final raiz = Platform.environment['FLUTTER_ROOT'];
  if (raiz == null) return;
  final pasta = '$raiz/bin/cache/artifacts/material_fonts';

  Future<ByteData> ler(String nome) async {
    final bytes = File('$pasta/$nome').readAsBytesSync();
    return ByteData.view(bytes.buffer);
  }

  final roboto = FontLoader('Roboto');
  for (final nome in [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
  ]) {
    if (File('$pasta/$nome').existsSync()) roboto.addFont(ler(nome));
  }
  await roboto.load();

  if (File('$pasta/MaterialIcons-Regular.otf').existsSync()) {
    final icones = FontLoader('MaterialIcons')..addFont(ler('MaterialIcons-Regular.otf'));
    await icones.load();
  }
}

/// Simula um celular Android comum (1080 x 2340 pixels).
void configurarCelular(WidgetTester tester, {double escalaTexto = 1.0}) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  tester.platformDispatcher.textScaleFactorTestValue = escalaTexto;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

class Ambiente {
  late EstoqueService estoque;
  late ReceitaService receitas;
  late Receita lavanda;
}

/// Monta as camadas reais (SQLite em memória + repositórios + serviços).
Future<Ambiente> criarAmbiente(WidgetTester tester) async {
  final ambiente = Ambiente();
  await tester.runAsync(() async {
    await carregarFontes();
    sqfliteFfiInit();
    final db = await AppDatabase.abrir(
      fabrica: databaseFactoryFfi,
      caminho: inMemoryDatabasePath,
      instanciaUnica: false,
    );
    final insumos = InsumoRepository(db);
    final receitas = ReceitaRepository(db);
    await DadosExemplo.inserirSeVazio(insumos, receitas);
    ambiente.estoque = EstoqueService(insumos);
    ambiente.receitas = ReceitaService(receitas)..adicionarObservador(ambiente.estoque);
    await ambiente.estoque.carregar();
    await ambiente.receitas.carregar();
    ambiente.lavanda = (await ambiente.receitas.buscar(ambiente.receitas.receitas.single.id))!;
  });
  return ambiente;
}

Widget comProviders(Ambiente ambiente, Widget tela) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<EstoqueService>.value(value: ambiente.estoque),
      ChangeNotifierProvider<ReceitaService>.value(value: ambiente.receitas),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: temaLuzido(),
      home: tela,
    ),
  );
}

void main() {
  testWidgets('captura 1 - modo receita com timer', (tester) async {
    configurarCelular(tester);
    final ambiente = await criarAmbiente(tester);
    final servico = ambiente.receitas
      ..iniciar(ambiente.lavanda)
      ..avancar()
      ..avancar()
      ..confirmarTemperatura()
      ..avancar(); // etapa 4: adicionar a essência (timer de 2 minutos)

    await tester.pumpWidget(comProviders(ambiente, const ModoReceitaTela()));
    await tester.pumpAndSettle();
    expect(servico.indice, 3);

    await expectLater(find.byType(MaterialApp), matchesGoldenFile('imagens/captura1_modo_receita.png'));
  });

  testWidgets('captura 2 - receita concluída com a baixa e os alertas', (tester) async {
    configurarCelular(tester);
    final ambiente = await criarAmbiente(tester);
    late ResultadoBaixa resultado;
    await tester.runAsync(() async {
      resultado = await ambiente.estoque.darBaixa(ambiente.lavanda);
    });

    await tester.pumpWidget(comProviders(ambiente, ResultadoTela(resultado: resultado)));
    await tester.pumpAndSettle();

    await expectLater(find.byType(MaterialApp), matchesGoldenFile('imagens/captura2_resultado.png'));
  });

  testWidgets('captura 3 - acessibilidade: fonte do celular em 150%', (tester) async {
    configurarCelular(tester, escalaTexto: 1.5);
    final ambiente = await criarAmbiente(tester);
    ambiente.receitas
      ..iniciar(ambiente.lavanda)
      ..avancar()
      ..avancar(); // etapa 3: confirmar 85 °C

    await tester.pumpWidget(comProviders(ambiente, const ModoReceitaTela()));
    await tester.pumpAndSettle();

    await expectLater(find.byType(MaterialApp), matchesGoldenFile('imagens/captura3_acessibilidade_fonte_150.png'));
  });
}
