import 'package:flutter_test/flutter_test.dart';
import 'package:luzido/data/app_database.dart';
import 'package:luzido/data/insumo_repository.dart';
import 'package:luzido/data/receita_repository.dart';
import 'package:luzido/models/etapa.dart';
import 'package:luzido/models/insumo.dart';
import 'package:luzido/models/receita.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Testes de integração com a camada de dados: usam o SQLite de verdade
/// (em memória), com as mesmas tabelas do app.
void main() {
  late Database db;
  late InsumoRepository insumos;
  late ReceitaRepository receitas;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await AppDatabase.abrir(
      fabrica: databaseFactoryFfi,
      caminho: inMemoryDatabasePath,
      instanciaUnica: false,
    );
    insumos = InsumoRepository(db);
    receitas = ReceitaRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> criarCera() => insumos.inserir(const Insumo(
        nome: 'Cera de soja',
        categoria: 'cera',
        unidade: 'g',
        quantidadeAtual: 1000,
      ));

  test('grava e lê um insumo', () async {
    final id = await criarCera();
    final lido = await insumos.buscarPorId(id);

    expect(lido, isNotNull);
    expect(lido!.nome, 'Cera de soja');
    expect(lido.quantidadeAtual, 1000);
  });

  test('o banco não aceita nome de insumo repetido', () async {
    await criarCera();
    await expectLater(criarCera(), throwsA(isA<DatabaseException>()));
  });

  test('o banco não aceita quantidade negativa', () async {
    await expectLater(
      insumos.inserir(const Insumo(
        nome: 'Pavio',
        categoria: 'pavio',
        unidade: 'un',
        quantidadeAtual: -1,
      )),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('nome com aspas e comando SQL é salvo só como texto', () async {
    const nomeEstranho = "Cera'); DELETE FROM insumo; --";
    await insumos.inserir(const Insumo(
      nome: nomeEstranho,
      categoria: 'cera',
      unidade: 'g',
      quantidadeAtual: 10,
    ));
    await criarCera();

    final lista = await insumos.listar();
    expect(lista, hasLength(2));
    expect(lista.map((i) => i.nome), contains(nomeEstranho));
  });

  test('salva receita com etapas em ordem e insumos', () async {
    final idCera = await criarCera();
    final idReceita = await receitas.inserir(Receita(
      nome: 'Vela simples',
      rendimento: 4,
      pesoVelaG: 150,
      etapas: const [
        Etapa(ordem: 2, descricao: 'Derreta', tipo: TipoEtapa.temperatura, temperaturaAlvoC: 85),
        Etapa(ordem: 1, descricao: 'Pese'),
      ],
      itens: [ItemReceita(idInsumo: idCera, quantidadeUsada: 600)],
    ));

    final completa = await receitas.buscarCompleta(idReceita);
    expect(completa!.etapas.map((e) => e.descricao), ['Pese', 'Derreta']);
    expect(completa.etapas[1].temperaturaAlvoC, 85);
    expect(completa.itens.single.nomeInsumo, 'Cera de soja');
    expect(completa.itens.single.quantidadeUsada, 600);

    final resumo = await receitas.listarResumo();
    expect(resumo.single.totalEtapas, 2);
  });

  test('excluir receita apaga etapas e itens, mas mantém o insumo', () async {
    final idCera = await criarCera();
    final idReceita = await receitas.inserir(Receita(
      nome: 'Vela para apagar',
      rendimento: 1,
      pesoVelaG: 100,
      etapas: const [Etapa(ordem: 1, descricao: 'Pese')],
      itens: [ItemReceita(idInsumo: idCera, quantidadeUsada: 100)],
    ));
    expect(await insumos.estaEmUso(idCera), isTrue);

    await receitas.excluir(idReceita);

    expect(await db.query('etapa'), isEmpty);
    expect(await db.query('receita_insumo'), isEmpty);
    expect(await insumos.buscarPorId(idCera), isNotNull);
    expect(await insumos.estaEmUso(idCera), isFalse);
  });

  test('salvarQuantidades atualiza vários insumos de uma vez', () async {
    final idCera = await criarCera();
    final idPavio = await insumos.inserir(const Insumo(
      nome: 'Pavio',
      categoria: 'pavio',
      unidade: 'un',
      quantidadeAtual: 10,
    ));

    await insumos.salvarQuantidades({idCera: 400, idPavio: 4});

    expect((await insumos.buscarPorId(idCera))!.quantidadeAtual, 400);
    expect((await insumos.buscarPorId(idPavio))!.quantidadeAtual, 4);
  });
}
