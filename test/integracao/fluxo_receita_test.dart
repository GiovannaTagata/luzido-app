import 'package:flutter_test/flutter_test.dart';
import 'package:luzido/data/app_database.dart';
import 'package:luzido/data/dados_exemplo.dart';
import 'package:luzido/data/insumo_repository.dart';
import 'package:luzido/data/receita_repository.dart';
import 'package:luzido/models/etapa.dart';
import 'package:luzido/services/estoque_service.dart';
import 'package:luzido/services/receita_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Teste de integração do fluxo principal do MVP, passando por todas as
/// camadas (serviços + repositórios + banco SQLite):
/// abrir a receita -> seguir as etapas -> concluir -> estoque atualizado.
void main() {
  late Database db;
  late InsumoRepository insumoRepository;
  late EstoqueService estoque;
  late ReceitaService receitas;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await AppDatabase.abrir(
      fabrica: databaseFactoryFfi,
      caminho: inMemoryDatabasePath,
      instanciaUnica: false,
    );
    insumoRepository = InsumoRepository(db);
    final receitaRepository = ReceitaRepository(db);
    await DadosExemplo.inserirSeVazio(insumoRepository, receitaRepository);

    estoque = EstoqueService(insumoRepository);
    receitas = ReceitaService(receitaRepository)..adicionarObservador(estoque);
    await estoque.carregar();
    await receitas.carregar();
  });

  tearDown(() async {
    receitas.dispose();
    await db.close();
  });

  Future<double> quantidade(String nome) async {
    final lista = await insumoRepository.listar();
    return lista.firstWhere((i) => i.nome == nome).quantidadeAtual;
  }

  test('dados de exemplo são criados só uma vez', () async {
    await DadosExemplo.inserirSeVazio(insumoRepository, ReceitaRepository(db));
    expect(receitas.receitas, hasLength(1));
    expect(await insumoRepository.listar(), hasLength(4));
  });

  test('fluxo completo: seguir a receita e dar baixa automática', () async {
    final resumo = receitas.receitas.single;
    final receita = await receitas.buscar(resumo.id);
    expect(receita, isNotNull);

    // RF05: com o estoque inicial, tem tudo para a receita.
    expect(estoque.verificarDisponibilidade(receita!), isEmpty);

    // RF03: segue todas as etapas.
    receitas.iniciar(receita);
    while (!receitas.ehUltimaEtapa) {
      if (receitas.etapaAtual!.tipo == TipoEtapa.temperatura) {
        receitas.confirmarTemperatura();
      }
      receitas.avancar();
    }

    // RF04: ao concluir, o Observer dispara a baixa no estoque.
    await receitas.concluir();

    expect(await quantidade('Cera de soja'), 3800);
    expect(await quantidade('Essência de lavanda'), 54);
    expect(await quantidade('Pavio médio'), 3);
    expect(await quantidade('Pote de vidro 200 g'), 14);

    // RF06: alertas de estoque baixo no resultado.
    final resultado = estoque.ultimoResultado!;
    expect(resultado.nomeReceita, 'Vela de lavanda 200 g');
    expect(resultado.alertas, contains('Restam 3 un. de Pavio médio'));
    expect(estoque.insumosComEstoqueBaixo.map((i) => i.nome), contains('Pavio médio'));
  });

  test('sair da receita no meio não altera o estoque', () async {
    final receita = await receitas.buscar(receitas.receitas.single.id);
    receitas.iniciar(receita!);
    receitas.avancar();
    receitas.sair();

    expect(await quantidade('Cera de soja'), 5000);
    expect(estoque.ultimoResultado, isNull);
  });

  test('segundo lote mostra o que está faltando antes de começar', () async {
    final receita = await receitas.buscar(receitas.receitas.single.id);
    await estoque.darBaixa(receita!);

    final faltas = estoque.verificarDisponibilidade(receita);
    expect(faltas.map((f) => f.nome), containsAll(['Pavio médio', 'Essência de lavanda']));
  });
}
