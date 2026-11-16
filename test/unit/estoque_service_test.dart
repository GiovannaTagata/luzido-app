import 'package:flutter_test/flutter_test.dart';
import 'package:luzido/data/insumo_repository.dart';
import 'package:luzido/models/insumo.dart';
import 'package:luzido/models/receita.dart';
import 'package:luzido/services/estoque_service.dart';
import 'package:luzido/services/validacao.dart';

/// Repositório falso, em memória, para testar só as regras do serviço
/// (teste unitário, sem banco de dados).
class InsumoRepositoryFalso implements InsumoRepository {
  final Map<int, Insumo> dados = {};
  final Set<int> emUso = {};
  int _proximoId = 1;

  @override
  Future<List<Insumo>> listar() async => dados.values.toList();

  @override
  Future<Insumo?> buscarPorId(int id) async => dados[id];

  @override
  Future<bool> existeNome(String nome, {int? ignorarId}) async => dados.values
      .any((i) => i.nome.toLowerCase() == nome.toLowerCase() && i.id != ignorarId);

  @override
  Future<int> inserir(Insumo insumo) async {
    final id = _proximoId++;
    dados[id] = insumo.copyWith(id: id);
    return id;
  }

  @override
  Future<void> atualizar(Insumo insumo) async {
    dados[insumo.id!] = insumo;
  }

  @override
  Future<bool> estaEmUso(int id) async => emUso.contains(id);

  @override
  Future<void> excluir(int id) async {
    dados.remove(id);
  }

  @override
  Future<void> salvarQuantidades(Map<int, double> novasQuantidades) async {
    novasQuantidades.forEach((id, qtd) {
      dados[id] = dados[id]!.copyWith(quantidadeAtual: qtd);
    });
  }
}

void main() {
  late InsumoRepositoryFalso repositorio;
  late EstoqueService servico;
  late int idCera;
  late int idPavio;
  late int idEssencia;

  Receita receitaLavanda() => Receita(
        nome: 'Vela de lavanda 200 g',
        rendimento: 6,
        pesoVelaG: 200,
        itens: [
          ItemReceita(idInsumo: idCera, quantidadeUsada: 1200),
          ItemReceita(idInsumo: idEssencia, quantidadeUsada: 96),
          ItemReceita(idInsumo: idPavio, quantidadeUsada: 6),
        ],
      );

  setUp(() async {
    repositorio = InsumoRepositoryFalso();
    idCera = await repositorio.inserir(const Insumo(
      nome: 'Cera de soja',
      categoria: 'cera',
      unidade: 'g',
      quantidadeAtual: 5000,
      estoqueMinimo: 1500,
    ));
    idEssencia = await repositorio.inserir(const Insumo(
      nome: 'Essência de lavanda',
      categoria: 'essencia',
      unidade: 'ml',
      quantidadeAtual: 150,
      estoqueMinimo: 100,
    ));
    idPavio = await repositorio.inserir(const Insumo(
      nome: 'Pavio médio',
      categoria: 'pavio',
      unidade: 'un',
      quantidadeAtual: 9,
      estoqueMinimo: 5,
    ));
    servico = EstoqueService(repositorio);
    await servico.carregar();
  });

  group('RF04 - baixa automática', () {
    test('desconta do estoque a quantidade usada na receita', () async {
      final resultado = await servico.darBaixa(receitaLavanda());

      expect(repositorio.dados[idCera]!.quantidadeAtual, 3800);
      expect(repositorio.dados[idEssencia]!.quantidadeAtual, 54);
      expect(repositorio.dados[idPavio]!.quantidadeAtual, 3);
      expect(resultado.descontados, hasLength(3));
      expect(servico.ultimoResultado, same(resultado));
    });

    test('mostra alerta de estoque baixo e de "acaba no próximo lote"', () async {
      final resultado = await servico.darBaixa(receitaLavanda());

      expect(resultado.alertas, contains('Restam 3 un. de Pavio médio'));
      expect(resultado.alertas, contains('Essência de lavanda acaba no próximo lote'));
      // A cera continua acima do mínimo, então não gera alerta.
      expect(resultado.alertas.any((a) => a.contains('Cera de soja')), isFalse);
    });

    test('nenhuma quantidade fica negativa', () async {
      await servico.darBaixa(receitaLavanda());
      final resultado = await servico.darBaixa(receitaLavanda());

      expect(repositorio.dados[idPavio]!.quantidadeAtual, 0);
      expect(repositorio.dados[idEssencia]!.quantidadeAtual, 0);
      expect(resultado.alertas, contains('Pavio médio ficou zerado: faltaram 3 un.'));
    });

    test('funciona como observador da receita (padrão Observer)', () async {
      await servico.aoConcluirReceita(receitaLavanda());
      expect(repositorio.dados[idCera]!.quantidadeAtual, 3800);
    });
  });

  group('RF05 - verificar antes de começar', () {
    test('não aponta faltas quando tem tudo', () {
      expect(servico.verificarDisponibilidade(receitaLavanda()), isEmpty);
    });

    test('aponta o que está faltando', () async {
      await servico.darBaixa(receitaLavanda());
      final faltas = servico.verificarDisponibilidade(receitaLavanda());

      expect(faltas.map((f) => f.nome), containsAll(['Pavio médio', 'Essência de lavanda']));
      final pavio = faltas.firstWhere((f) => f.nome == 'Pavio médio');
      expect(pavio.falta, 3);
      expect(pavio.mensagem, 'Faltam 3 un. de Pavio médio');
    });
  });

  group('RF01 - cadastro de insumos', () {
    test('cadastra um insumo válido', () async {
      await servico.cadastrar(const Insumo(
        nome: 'Pote de vidro',
        categoria: 'pote',
        unidade: 'un',
        quantidadeAtual: 20,
      ));
      expect(servico.insumos.map((i) => i.nome), contains('Pote de vidro'));
    });

    test('não aceita quantidade negativa', () {
      expect(
        () => servico.cadastrar(const Insumo(
          nome: 'Corante azul',
          categoria: 'corante',
          unidade: 'ml',
          quantidadeAtual: -5,
        )),
        throwsA(isA<ValidacaoException>()),
      );
    });

    test('não aceita nome vazio nem nome repetido', () async {
      await expectLater(
        servico.cadastrar(const Insumo(
          nome: '  ',
          categoria: 'cera',
          unidade: 'g',
          quantidadeAtual: 1,
        )),
        throwsA(isA<ValidacaoException>()),
      );
      await expectLater(
        servico.cadastrar(const Insumo(
          nome: 'cera de soja',
          categoria: 'cera',
          unidade: 'g',
          quantidadeAtual: 1,
        )),
        throwsA(isA<ValidacaoException>()),
      );
    });

    test('não exclui insumo usado em receita', () async {
      repositorio.emUso.add(idCera);
      await expectLater(servico.excluir(idCera), throwsA(isA<ValidacaoException>()));
      expect(repositorio.dados.containsKey(idCera), isTrue);
    });

    test('registrar compra soma no estoque (ajuste da 2ª validação)', () async {
      await servico.registrarCompra(idPavio, 20);
      expect(repositorio.dados[idPavio]!.quantidadeAtual, 29);
      expect(servico.insumos.firstWhere((i) => i.id == idPavio).quantidadeAtual, 29);
    });

    test('registrar compra não aceita zero nem número negativo', () async {
      await expectLater(servico.registrarCompra(idPavio, 0), throwsA(isA<ValidacaoException>()));
      await expectLater(servico.registrarCompra(idPavio, -3), throwsA(isA<ValidacaoException>()));
      expect(repositorio.dados[idPavio]!.quantidadeAtual, 9);
    });

    test('lista insumos com estoque baixo', () async {
      await servico.darBaixa(receitaLavanda());
      expect(
        servico.insumosComEstoqueBaixo.map((i) => i.nome),
        containsAll(['Pavio médio', 'Essência de lavanda']),
      );
    });
  });
}
