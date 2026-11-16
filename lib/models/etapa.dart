/// Tipos de etapa da receita.
/// - simples: só uma instrução;
/// - tempo: mostra um timer;
/// - temperatura: exige confirmar a temperatura antes de avançar.
enum TipoEtapa { simples, tempo, temperatura }

/// Um passo da receita, mostrado em tela cheia no modo receita.
class Etapa {
  const Etapa({
    this.id,
    this.idReceita,
    required this.ordem,
    required this.descricao,
    this.destaque,
    this.tipo = TipoEtapa.simples,
    this.duracaoSegundos,
    this.temperaturaAlvoC,
  });

  final int? id;
  final int? idReceita;
  final int ordem;
  final String descricao;

  /// Texto mostrado em destaque, por exemplo a quantidade: "96 ml".
  final String? destaque;
  final TipoEtapa tipo;
  final int? duracaoSegundos;
  final double? temperaturaAlvoC;

  Map<String, Object?> toMap() {
    return {
      'id_etapa': id,
      'id_receita': idReceita,
      'ordem': ordem,
      'descricao': descricao,
      'destaque': destaque,
      'tipo': tipo.name,
      'duracao_segundos': duracaoSegundos,
      'temperatura_alvo_c': temperaturaAlvoC,
    };
  }

  factory Etapa.fromMap(Map<String, Object?> mapa) {
    return Etapa(
      id: mapa['id_etapa'] as int?,
      idReceita: mapa['id_receita'] as int?,
      ordem: mapa['ordem'] as int,
      descricao: mapa['descricao'] as String,
      destaque: mapa['destaque'] as String?,
      tipo: TipoEtapa.values.byName(mapa['tipo'] as String),
      duracaoSegundos: mapa['duracao_segundos'] as int?,
      temperaturaAlvoC: (mapa['temperatura_alvo_c'] as num?)?.toDouble(),
    );
  }
}
