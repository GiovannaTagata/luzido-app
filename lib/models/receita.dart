import 'etapa.dart';

/// Quanto de um insumo a receita usa (tabela de ligação receita_insumo).
class ItemReceita {
  const ItemReceita({
    required this.idInsumo,
    required this.quantidadeUsada,
    this.nomeInsumo = '',
    this.unidade = '',
  });

  final int idInsumo;
  final double quantidadeUsada;

  /// Preenchidos na consulta (JOIN com a tabela insumo), só para exibição.
  final String nomeInsumo;
  final String unidade;
}

/// Receita de vela com as etapas e os insumos usados.
class Receita {
  const Receita({
    this.id,
    required this.nome,
    required this.rendimento,
    required this.pesoVelaG,
    this.percentualFragrancia,
    this.observacoes,
    this.etapas = const [],
    this.itens = const [],
  });

  final int? id;
  final String nome;

  /// Quantidade de velas que a receita produz.
  final int rendimento;
  final double pesoVelaG;
  final double? percentualFragrancia;
  final String? observacoes;
  final List<Etapa> etapas;
  final List<ItemReceita> itens;

  Map<String, Object?> toMap() {
    return {
      'id_receita': id,
      'nome': nome,
      'rendimento': rendimento,
      'peso_vela_g': pesoVelaG,
      'percentual_fragrancia': percentualFragrancia,
      'observacoes': observacoes,
      'data_criacao': DateTime.now().toIso8601String(),
    };
  }

  factory Receita.fromMap(
    Map<String, Object?> mapa, {
    List<Etapa> etapas = const [],
    List<ItemReceita> itens = const [],
  }) {
    return Receita(
      id: mapa['id_receita'] as int?,
      nome: mapa['nome'] as String,
      rendimento: mapa['rendimento'] as int,
      pesoVelaG: (mapa['peso_vela_g'] as num).toDouble(),
      percentualFragrancia: (mapa['percentual_fragrancia'] as num?)?.toDouble(),
      observacoes: mapa['observacoes'] as String?,
      etapas: etapas,
      itens: itens,
    );
  }
}

/// Dados resumidos para a lista da tela inicial (carregamento leve).
class ResumoReceita {
  const ResumoReceita({
    required this.id,
    required this.nome,
    required this.rendimento,
    required this.pesoVelaG,
    required this.totalEtapas,
  });

  final int id;
  final String nome;
  final int rendimento;
  final double pesoVelaG;
  final int totalEtapas;
}
