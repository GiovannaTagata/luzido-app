import 'package:flutter_test/flutter_test.dart';
import 'package:luzido/data/app_database.dart';
import 'package:luzido/services/pin_service.dart';
import 'package:luzido/services/validacao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late PinService servico;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await AppDatabase.abrir(
      fabrica: databaseFactoryFfi,
      caminho: inMemoryDatabasePath,
      instanciaUnica: false,
    );
    // Poucas iterações só para o teste rodar rápido.
    servico = PinService(db, iteracoes: 1000);
  });

  tearDown(() async {
    await db.close();
  });

  group('RNF01 - PIN com hash', () {
    test('começa sem PIN e passa a ter depois de definir', () async {
      expect(await servico.temPin(), isFalse);
      await servico.definirPin('123456');
      expect(await servico.temPin(), isTrue);
    });

    test('o PIN não fica salvo em texto limpo no banco', () async {
      await servico.definirPin('123456');
      final linhas = await db.query('config');
      final valores = linhas.map((l) => l['valor'] as String).toList();

      expect(valores, hasLength(2)); // hash e salt
      for (final valor in valores) {
        expect(valor.contains('123456'), isFalse);
      }
    });

    test('aceita o PIN correto e recusa o errado', () async {
      await servico.definirPin('123456');
      expect(await servico.verificar('123456'), isTrue);
      expect(await servico.verificar('654321'), isFalse);
    });

    test('dois PINs iguais geram hashes diferentes (salt aleatório)', () async {
      await servico.definirPin('111111');
      final primeiro = (await db.query('config', where: 'chave = ?', whereArgs: ['pin_hash']))
          .first['valor'];
      await servico.definirPin('111111');
      final segundo = (await db.query('config', where: 'chave = ?', whereArgs: ['pin_hash']))
          .first['valor'];
      expect(primeiro, isNot(segundo));
    });

    test('recusa PIN que não tem 6 números', () async {
      await expectLater(servico.definirPin('12ab'), throwsA(isA<ValidacaoException>()));
      await expectLater(servico.definirPin('1234567'), throwsA(isA<ValidacaoException>()));
    });

    test('bloqueia depois de 5 tentativas erradas', () async {
      await servico.definirPin('123456');
      final agora = DateTime(2026, 11, 13, 10);
      for (var i = 0; i < 5; i++) {
        expect(await servico.verificar('000000', agora: agora), isFalse);
      }
      await expectLater(
        servico.verificar('123456', agora: agora.add(const Duration(seconds: 30))),
        throwsA(isA<PinBloqueadoException>()),
      );
      // Depois do tempo de bloqueio, volta a aceitar o PIN certo.
      expect(
        await servico.verificar('123456', agora: agora.add(const Duration(minutes: 2))),
        isTrue,
      );
    });
  });
}
