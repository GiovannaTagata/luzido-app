/// Material usado na produção das velas (cera, pavio, essência, corante,
/// pote ou embalagem) com a quantidade disponível no estoque.
class Insumo {
  const Insumo({
    this.id,
    required this.nome,
    required this.categoria,
    required this.unidade,
    required this.quantidadeAtual,
    this.estoqueMinimo,
  });

  static const categorias = [
    'cera',
    'pavio',
    'essencia',
    'corante',
    'pote',
    'embalagem',
  ];

  static const unidades = ['g', 'ml', 'un'];

  final int? id;
  final String nome;
  final String categoria;
  final String unidade;
  final double quantidadeAtual;
  final double? estoqueMinimo;

  /// Verdadeiro quando existe estoque mínimo e a quantidade ficou abaixo dele.
  bool get estoqueBaixo {
    final minimo = estoqueMinimo;
    return minimo != null && quantidadeAtual < minimo;
  }

  Insumo copyWith({
    int? id,
    String? nome,
    String? categoria,
    String? unidade,
    double? quantidadeAtual,
    double? estoqueMinimo,
  }) {
    return Insumo(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      categoria: categoria ?? this.categoria,
      unidade: unidade ?? this.unidade,
      quantidadeAtual: quantidadeAtual ?? this.quantidadeAtual,
      estoqueMinimo: estoqueMinimo ?? this.estoqueMinimo,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id_insumo': id,
      'nome': nome,
      'categoria': categoria,
      'unidade': unidade,
      'quantidade_atual': quantidadeAtual,
      'estoque_minimo': estoqueMinimo,
      'data_atualizacao': DateTime.now().toIso8601String(),
    };
  }

  factory Insumo.fromMap(Map<String, Object?> mapa) {
    return Insumo(
      id: mapa['id_insumo'] as int?,
      nome: mapa['nome'] as String,
      categoria: mapa['categoria'] as String,
      unidade: mapa['unidade'] as String,
      quantidadeAtual: (mapa['quantidade_atual'] as num).toDouble(),
      estoqueMinimo: (mapa['estoque_minimo'] as num?)?.toDouble(),
    );
  }
}
