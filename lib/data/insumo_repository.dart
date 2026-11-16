import 'package:sqflite/sqflite.dart';

import '../models/insumo.dart';

/// Camada de dados: grava e consulta os insumos no SQLite.
/// Todas as consultas usam parâmetros (?) para evitar injeção de SQL.
class InsumoRepository {
  InsumoRepository(this._db);

  final Database _db;

  Future<List<Insumo>> listar() async {
    final linhas = await _db.query('insumo', orderBy: 'nome COLLATE NOCASE');
    return linhas.map(Insumo.fromMap).toList();
  }

  Future<Insumo?> buscarPorId(int id) async {
    final linhas = await _db.query(
      'insumo',
      where: 'id_insumo = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (linhas.isEmpty) return null;
    return Insumo.fromMap(linhas.first);
  }

  Future<bool> existeNome(String nome, {int? ignorarId}) async {
    final linhas = await _db.query(
      'insumo',
      columns: ['id_insumo'],
      where: 'nome = ? COLLATE NOCASE AND id_insumo != ?',
      whereArgs: [nome, ignorarId ?? -1],
      limit: 1,
    );
    return linhas.isNotEmpty;
  }

  Future<int> inserir(Insumo insumo) {
    final dados = insumo.toMap()..remove('id_insumo');
    return _db.insert('insumo', dados);
  }

  Future<void> atualizar(Insumo insumo) async {
    final dados = insumo.toMap()..remove('id_insumo');
    await _db.update(
      'insumo',
      dados,
      where: 'id_insumo = ?',
      whereArgs: [insumo.id],
    );
  }

  /// Verdadeiro se alguma receita usa o insumo (aí ele não pode ser excluído).
  Future<bool> estaEmUso(int id) async {
    final linhas = await _db.query(
      'receita_insumo',
      columns: ['id_insumo'],
      where: 'id_insumo = ?',
      whereArgs: [id],
      limit: 1,
    );
    return linhas.isNotEmpty;
  }

  Future<void> excluir(int id) async {
    await _db.delete('insumo', where: 'id_insumo = ?', whereArgs: [id]);
  }

  /// Grava as novas quantidades de vários insumos de uma vez, dentro de uma
  /// transação: ou atualiza todos, ou nenhum (não deixa o estoque pela metade).
  Future<void> salvarQuantidades(Map<int, double> novasQuantidades) async {
    final agora = DateTime.now().toIso8601String();
    await _db.transaction((txn) async {
      for (final entrada in novasQuantidades.entries) {
        await txn.update(
          'insumo',
          {'quantidade_atual': entrada.value, 'data_atualizacao': agora},
          where: 'id_insumo = ?',
          whereArgs: [entrada.key],
        );
      }
    });
  }
}
