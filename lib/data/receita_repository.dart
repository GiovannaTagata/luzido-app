import 'package:sqflite/sqflite.dart';

import '../models/etapa.dart';
import '../models/receita.dart';

/// Camada de dados: grava e consulta receitas, etapas e a tabela de ligação
/// receita_insumo.
class ReceitaRepository {
  ReceitaRepository(this._db);

  final Database _db;

  /// Lista leve para a tela inicial: só nome, rendimento e total de etapas.
  Future<List<ResumoReceita>> listarResumo() async {
    final linhas = await _db.rawQuery('''
      SELECT r.id_receita, r.nome, r.rendimento, r.peso_vela_g,
             (SELECT COUNT(*) FROM etapa e WHERE e.id_receita = r.id_receita) AS total_etapas
      FROM receita r
      ORDER BY r.nome COLLATE NOCASE
    ''');
    return linhas
        .map(
          (m) => ResumoReceita(
            id: m['id_receita'] as int,
            nome: m['nome'] as String,
            rendimento: m['rendimento'] as int,
            pesoVelaG: (m['peso_vela_g'] as num).toDouble(),
            totalEtapas: m['total_etapas'] as int,
          ),
        )
        .toList();
  }

  /// Busca a receita completa, com etapas em ordem e os insumos usados.
  Future<Receita?> buscarCompleta(int id) async {
    final linhas = await _db.query(
      'receita',
      where: 'id_receita = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (linhas.isEmpty) return null;

    final linhasEtapas = await _db.query(
      'etapa',
      where: 'id_receita = ?',
      whereArgs: [id],
      orderBy: 'ordem',
    );

    final linhasItens = await _db.rawQuery('''
      SELECT ri.id_insumo, ri.quantidade_usada, i.nome, i.unidade
      FROM receita_insumo ri
      JOIN insumo i ON i.id_insumo = ri.id_insumo
      WHERE ri.id_receita = ?
      ORDER BY i.nome COLLATE NOCASE
    ''', [id]);

    return Receita.fromMap(
      linhas.first,
      etapas: linhasEtapas.map(Etapa.fromMap).toList(),
      itens: linhasItens
          .map(
            (m) => ItemReceita(
              idInsumo: m['id_insumo'] as int,
              quantidadeUsada: (m['quantidade_usada'] as num).toDouble(),
              nomeInsumo: m['nome'] as String,
              unidade: m['unidade'] as String,
            ),
          )
          .toList(),
    );
  }

  Future<bool> existeNome(String nome) async {
    final linhas = await _db.query(
      'receita',
      columns: ['id_receita'],
      where: 'nome = ? COLLATE NOCASE',
      whereArgs: [nome],
      limit: 1,
    );
    return linhas.isNotEmpty;
  }

  /// Salva a receita com as etapas e os insumos em uma única transação.
  Future<int> inserir(Receita receita) async {
    return _db.transaction((txn) async {
      final dados = receita.toMap()..remove('id_receita');
      final idReceita = await txn.insert('receita', dados);

      for (final etapa in receita.etapas) {
        final dadosEtapa = etapa.toMap()
          ..remove('id_etapa')
          ..['id_receita'] = idReceita;
        await txn.insert('etapa', dadosEtapa);
      }

      for (final item in receita.itens) {
        await txn.insert('receita_insumo', {
          'id_receita': idReceita,
          'id_insumo': item.idInsumo,
          'quantidade_usada': item.quantidadeUsada,
        });
      }
      return idReceita;
    });
  }

  /// Exclui a receita. As etapas e os itens são apagados junto (ON DELETE
  /// CASCADE), mas os insumos continuam no inventário.
  Future<void> excluir(int id) async {
    await _db.delete('receita', where: 'id_receita = ?', whereArgs: [id]);
  }
}
