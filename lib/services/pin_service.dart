import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:sqflite/sqflite.dart';

import 'validacao.dart';

/// Erro quando a usuária errou o PIN muitas vezes seguidas.
class PinBloqueadoException extends ValidacaoException {
  const PinBloqueadoException(this.segundosRestantes)
      : super('Muitas tentativas. Aguarde um pouco e tente de novo.');

  final int segundosRestantes;
}

/// RNF01 — PIN local para proteger o app.
///
/// O PIN NUNCA é guardado em texto limpo (nem com MD5 ou SHA-1).
/// Guardamos só o resultado do PBKDF2 (HMAC-SHA256) com um salt aleatório.
/// O hash é de mão única: para conferir, calculamos o hash do PIN digitado
/// e comparamos com o que está salvo.
class PinService {
  PinService(
    this._db, {
    this.iteracoes = 100000,
    this.maxTentativas = 5,
    this.tempoBloqueio = const Duration(minutes: 1),
  });

  static const _chaveHash = 'pin_hash';
  static const _chaveSalt = 'pin_salt';

  final Database _db;
  final int iteracoes;
  final int maxTentativas;
  final Duration tempoBloqueio;

  int _tentativasErradas = 0;
  DateTime? _bloqueadoAte;

  int get tentativasErradas => _tentativasErradas;

  Future<bool> temPin() async {
    return (await _ler(_chaveHash)) != null;
  }

  Future<void> definirPin(String pin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw const ValidacaoException('O PIN deve ter 6 números.');
    }
    final salt = _gerarSalt();
    final hash = await _calcularHash(pin, salt);
    await _gravar(_chaveSalt, base64Encode(salt));
    await _gravar(_chaveHash, base64Encode(hash));
    _tentativasErradas = 0;
    _bloqueadoAte = null;
  }

  /// Confere o PIN. Depois de [maxTentativas] erros seguidos, bloqueia novas
  /// tentativas por [tempoBloqueio].
  Future<bool> verificar(String pin, {DateTime? agora}) async {
    final momento = agora ?? DateTime.now();
    final bloqueio = _bloqueadoAte;
    if (bloqueio != null && momento.isBefore(bloqueio)) {
      throw PinBloqueadoException(bloqueio.difference(momento).inSeconds + 1);
    }

    final hashSalvo = await _ler(_chaveHash);
    final saltSalvo = await _ler(_chaveSalt);
    if (hashSalvo == null || saltSalvo == null) return false;

    final calculado = await _calcularHash(pin, base64Decode(saltSalvo));
    final correto = _iguais(calculado, base64Decode(hashSalvo));

    if (correto) {
      _tentativasErradas = 0;
      _bloqueadoAte = null;
    } else {
      _tentativasErradas++;
      if (_tentativasErradas >= maxTentativas) {
        _bloqueadoAte = momento.add(tempoBloqueio);
        _tentativasErradas = 0;
      }
    }
    return correto;
  }

  Future<List<int>> _calcularHash(String pin, List<int> salt) async {
    final algoritmo = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iteracoes,
      bits: 256,
    );
    final chave = await algoritmo.deriveKeyFromPassword(
      password: pin,
      nonce: salt,
    );
    return chave.extractBytes();
  }

  List<int> _gerarSalt() {
    final aleatorio = Random.secure();
    return List<int>.generate(16, (_) => aleatorio.nextInt(256));
  }

  /// Compara em tempo constante (não para no primeiro byte diferente).
  bool _iguais(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diferenca = 0;
    for (var i = 0; i < a.length; i++) {
      diferenca |= a[i] ^ b[i];
    }
    return diferenca == 0;
  }

  Future<String?> _ler(String chave) async {
    final linhas = await _db.query(
      'config',
      columns: ['valor'],
      where: 'chave = ?',
      whereArgs: [chave],
      limit: 1,
    );
    if (linhas.isEmpty) return null;
    return linhas.first['valor'] as String;
  }

  Future<void> _gravar(String chave, String valor) async {
    await _db.insert(
      'config',
      {'chave': chave, 'valor': valor},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
