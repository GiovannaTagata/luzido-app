import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Abre o banco SQLite local (fica dentro do celular, funciona sem internet)
/// e cria as tabelas na primeira vez.
class AppDatabase {
  static const versao = 1;
  static const nomeArquivo = 'luzido.db';

  /// [fabrica] e [caminho] podem ser trocados nos testes para usar um banco
  /// em memória (sqflite_common_ffi).
  static Future<Database> abrir({
    DatabaseFactory? fabrica,
    String? caminho,
    bool instanciaUnica = true,
  }) async {
    if (fabrica == null) {
      // Uso normal no celular.
      final caminhoFinal = caminho ?? join(await getDatabasesPath(), nomeArquivo);
      return openDatabase(
        caminhoFinal,
        version: versao,
        singleInstance: instanciaUnica,
        onConfigure: _configurar,
        onCreate: _criar,
      );
    }
    // Uso nos testes (por exemplo com sqflite_common_ffi).
    return fabrica.openDatabase(
      caminho ?? inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: versao,
        singleInstance: instanciaUnica,
        onConfigure: _configurar,
        onCreate: _criar,
      ),
    );
  }

  /// Liga as chaves estrangeiras (necessário para o ON DELETE CASCADE).
  static Future<void> _configurar(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _criar(Database db, int versao) async {
    await criarTabelas(db);
  }

  /// Cria as tabelas do modelo de dados definido na Experiência Prática 2.
  /// Cada comando é executado separado porque o SQLite roda um por vez.
  static Future<void> criarTabelas(Database db) async {
    await db.execute('''
      CREATE TABLE insumo (
        id_insumo INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL UNIQUE,
        categoria TEXT NOT NULL,
        unidade TEXT NOT NULL,
        quantidade_atual REAL NOT NULL CHECK (quantidade_atual >= 0),
        estoque_minimo REAL,
        data_atualizacao TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE receita (
        id_receita INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL UNIQUE,
        rendimento INTEGER NOT NULL CHECK (rendimento > 0),
        peso_vela_g REAL NOT NULL CHECK (peso_vela_g > 0),
        percentual_fragrancia REAL,
        observacoes TEXT,
        data_criacao TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE etapa (
        id_etapa INTEGER PRIMARY KEY AUTOINCREMENT,
        id_receita INTEGER NOT NULL REFERENCES receita(id_receita) ON DELETE CASCADE,
        ordem INTEGER NOT NULL,
        descricao TEXT NOT NULL,
        destaque TEXT,
        tipo TEXT NOT NULL CHECK (tipo IN ('simples', 'tempo', 'temperatura')),
        duracao_segundos INTEGER,
        temperatura_alvo_c REAL,
        UNIQUE (id_receita, ordem)
      )
    ''');

    await db.execute('''
      CREATE TABLE receita_insumo (
        id_receita INTEGER NOT NULL REFERENCES receita(id_receita) ON DELETE CASCADE,
        id_insumo INTEGER NOT NULL REFERENCES insumo(id_insumo) ON DELETE RESTRICT,
        quantidade_usada REAL NOT NULL CHECK (quantidade_usada > 0),
        PRIMARY KEY (id_receita, id_insumo)
      )
    ''');

    await db.execute('''
      CREATE TABLE config (
        chave TEXT PRIMARY KEY,
        valor TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_etapa_receita ON etapa(id_receita)');
  }
}
