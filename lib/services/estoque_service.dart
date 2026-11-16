import 'package:flutter/foundation.dart';

import '../data/insumo_repository.dart';
import '../models/insumo.dart';
import '../models/receita.dart';
import '../util/formatacao.dart';
import 'observador_receita.dart';
import 'validacao.dart';

/// Um insumo que foi descontado do estoque na baixa.
class ItemDescontado {
  const ItemDescontado({
    required this.nome,
    required this.quantidade,
    required this.unidade,
  });

  final String nome;
  final double quantidade;
  final String unidade;
}

/// Um insumo que não tem quantidade suficiente para a receita.
class FaltaInsumo {
  const FaltaInsumo({
    required this.nome,
    required this.falta,
    required this.unidade,
  });

  final String nome;
  final double falta;
  final String unidade;

  String get mensagem => 'Faltam ${formatarQuantidade(falta, unidade)} de $nome';
}

/// Resultado mostrado na tela "Receita concluída".
class ResultadoBaixa {
  const ResultadoBaixa({
    required this.nomeReceita,
    required this.descontados,
    required this.alertas,
  });

  final String nomeReceita;
  final List<ItemDescontado> descontados;
  final List<String> alertas;
}

/// Camada de regras de negócio do inventário (RF01, RF04, RF05 e RF06).
///
/// Também é um [ObservadorReceita]: quando o modo receita avisa que a receita
/// foi concluída, este serviço faz a baixa automática no estoque.
class EstoqueService extends ChangeNotifier implements ObservadorReceita {
  EstoqueService(this._repositorio);

  final InsumoRepository _repositorio;

  List<Insumo> _insumos = [];
  ResultadoBaixa? _ultimoResultado;

  List<Insumo> get insumos => List.unmodifiable(_insumos);
  ResultadoBaixa? get ultimoResultado => _ultimoResultado;

  List<Insumo> get insumosComEstoqueBaixo =>
      _insumos.where((i) => i.estoqueBaixo).toList();

  Future<void> carregar() async {
    _insumos = await _repositorio.listar();
    notifyListeners();
  }

  /// RF01 — cadastra um insumo depois de validar os dados.
  Future<void> cadastrar(Insumo insumo) async {
    await _validar(insumo);
    await _repositorio.inserir(insumo);
    await carregar();
  }

  /// RF01 — edita um insumo existente.
  Future<void> editar(Insumo insumo) async {
    if (insumo.id == null) {
      throw const ValidacaoException('Insumo não encontrado.');
    }
    await _validar(insumo);
    await _repositorio.atualizar(insumo);
    await carregar();
  }

  Future<void> excluir(int id) async {
    if (await _repositorio.estaEmUso(id)) {
      throw const ValidacaoException(
        'Este insumo é usado em uma receita e não pode ser excluído.',
      );
    }
    await _repositorio.excluir(id);
    await carregar();
  }

  Future<void> _validar(Insumo insumo) async {
    final nome = insumo.nome.trim();
    if (nome.isEmpty) {
      throw const ValidacaoException('Informe o nome do insumo.');
    }
    if (nome.length > 60) {
      throw const ValidacaoException('O nome pode ter no máximo 60 letras.');
    }
    if (!Insumo.categorias.contains(insumo.categoria)) {
      throw const ValidacaoException('Escolha uma categoria da lista.');
    }
    if (!Insumo.unidades.contains(insumo.unidade)) {
      throw const ValidacaoException('Escolha a unidade: g, ml ou un.');
    }
    if (insumo.quantidadeAtual < 0) {
      throw const ValidacaoException(
        'Informe a quantidade. Use só números maiores ou iguais a zero.',
      );
    }
    final minimo = insumo.estoqueMinimo;
    if (minimo != null && minimo < 0) {
      throw const ValidacaoException('O estoque mínimo não pode ser negativo.');
    }
    if (await _repositorio.existeNome(nome, ignorarId: insumo.id)) {
      throw const ValidacaoException('Já existe um insumo com esse nome.');
    }
  }

  /// RF05 — confere, antes de começar, se há material suficiente.
  /// Devolve a lista do que está faltando (vazia se tiver tudo).
  List<FaltaInsumo> verificarDisponibilidade(Receita receita) {
    final faltas = <FaltaInsumo>[];
    for (final item in receita.itens) {
      final insumo = _buscar(item.idInsumo);
      final disponivel = insumo?.quantidadeAtual ?? 0;
      if (disponivel < item.quantidadeUsada) {
        faltas.add(
          FaltaInsumo(
            nome: insumo?.nome ?? item.nomeInsumo,
            falta: item.quantidadeUsada - disponivel,
            unidade: insumo?.unidade ?? item.unidade,
          ),
        );
      }
    }
    return faltas;
  }

  /// RF04 — desconta do estoque o que a receita usou.
  /// Nenhuma quantidade fica negativa: se faltar, o insumo fica com zero
  /// e aparece um aviso.
  Future<ResultadoBaixa> darBaixa(Receita receita) async {
    await carregar();

    final novasQuantidades = <int, double>{};
    final descontados = <ItemDescontado>[];
    final alertas = <String>[];

    for (final item in receita.itens) {
      final insumo = _buscar(item.idInsumo);
      if (insumo == null || insumo.id == null) continue;

      var nova = insumo.quantidadeAtual - item.quantidadeUsada;
      if (nova < 0) {
        alertas.add(
          '${insumo.nome} ficou zerado: faltaram '
          '${formatarQuantidade(-nova, insumo.unidade)}',
        );
        nova = 0;
      }

      novasQuantidades[insumo.id!] = nova;
      descontados.add(
        ItemDescontado(
          nome: insumo.nome,
          quantidade: insumo.quantidadeAtual - nova,
          unidade: insumo.unidade,
        ),
      );

      final depois = insumo.copyWith(quantidadeAtual: nova);
      if (nova > 0 && depois.estoqueBaixo) {
        alertas.add('Restam ${formatarQuantidade(nova, insumo.unidade)} de ${insumo.nome}');
      }
      if (nova > 0 && nova < item.quantidadeUsada) {
        alertas.add('${insumo.nome} acaba no próximo lote');
      }
    }

    await _repositorio.salvarQuantidades(novasQuantidades);
    await carregar();

    final resultado = ResultadoBaixa(
      nomeReceita: receita.nome,
      descontados: descontados,
      alertas: alertas,
    );
    _ultimoResultado = resultado;
    notifyListeners();
    return resultado;
  }

  /// Chamado pelo modo receita (padrão Observer) quando a receita termina.
  @override
  Future<void> aoConcluirReceita(Receita receita) async {
    await darBaixa(receita);
  }

  Insumo? _buscar(int id) {
    for (final insumo in _insumos) {
      if (insumo.id == id) return insumo;
    }
    return null;
  }
}
