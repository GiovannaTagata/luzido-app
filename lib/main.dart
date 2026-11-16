import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'data/dados_exemplo.dart';
import 'data/insumo_repository.dart';
import 'data/receita_repository.dart';
import 'services/estoque_service.dart';
import 'services/receita_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Camada de dados: banco SQLite local (funciona offline).
  final db = await AppDatabase.abrir();
  final insumoRepository = InsumoRepository(db);
  final receitaRepository = ReceitaRepository(db);
  await DadosExemplo.inserirSeVazio(insumoRepository, receitaRepository);

  // Camada de regras de negócio.
  final estoque = EstoqueService(insumoRepository);
  final receitas = ReceitaService(receitaRepository)
    // Observer: quando a receita termina, o estoque faz a baixa automática.
    ..adicionarObservador(estoque);

  await estoque.carregar();
  await receitas.carregar();

  runApp(LuzidoApp(estoque: estoque, receitas: receitas));
}
