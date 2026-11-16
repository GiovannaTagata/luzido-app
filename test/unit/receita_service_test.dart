import 'package:flutter_test/flutter_test.dart';
import 'package:luzido/models/etapa.dart';
import 'package:luzido/models/receita.dart';
import 'package:luzido/services/observador_receita.dart';
import 'package:luzido/services/receita_service.dart';
import 'package:luzido/services/validacao.dart';

/// Observador falso: só guarda as receitas que foram concluídas.
class ObservadorFalso implements ObservadorReceita {
  final List<String> concluidas = [];

  @override
  Future<void> aoConcluirReceita(Receita receita) async {
    concluidas.add(receita.nome);
  }
}

const receitaTeste = Receita(
  nome: 'Vela de teste',
  rendimento: 2,
  pesoVelaG: 100,
  etapas: [
    Etapa(ordem: 1, descricao: 'Pese a cera'),
    Etapa(
      ordem: 2,
      descricao: 'Derreta a cera',
      tipo: TipoEtapa.temperatura,
      temperaturaAlvoC: 85,
    ),
    Etapa(
      ordem: 3,
      descricao: 'Mexa a essência',
      tipo: TipoEtapa.tempo,
      duracaoSegundos: 3,
    ),
  ],
  itens: [ItemReceita(idInsumo: 1, quantidadeUsada: 200)],
);

void main() {
  late ReceitaService servico;

  setUp(() {
    servico = ReceitaService(null);
  });

  tearDown(() {
    servico.dispose();
  });

  group('RF03 - modo receita', () {
    test('começa na primeira etapa', () {
      servico.iniciar(receitaTeste);
      expect(servico.indice, 0);
      expect(servico.etapaAtual!.descricao, 'Pese a cera');
      expect(servico.ehPrimeiraEtapa, isTrue);
      expect(servico.totalEtapas, 3);
    });

    test('não avança na etapa de temperatura sem confirmar', () {
      servico.iniciar(receitaTeste);
      servico.avancar();

      expect(servico.etapaAtual!.tipo, TipoEtapa.temperatura);
      expect(servico.podeAvancar, isFalse);
      expect(() => servico.avancar(), throwsA(isA<ValidacaoException>()));
      expect(servico.indice, 1);
    });

    test('avança depois de confirmar a temperatura', () {
      servico.iniciar(receitaTeste);
      servico.avancar();
      servico.confirmarTemperatura();

      expect(servico.podeAvancar, isTrue);
      servico.avancar();
      expect(servico.indice, 2);
      // A confirmação não "vaza" para a próxima etapa.
      expect(servico.temperaturaConfirmada, isFalse);
    });

    test('voltar retorna para a etapa anterior', () {
      servico.iniciar(receitaTeste);
      servico.avancar();
      servico.voltar();
      expect(servico.indice, 0);
      servico.voltar();
      expect(servico.indice, 0);
    });

    test('timer conta até zero e avisa quando termina', () {
      var avisou = false;
      servico.aoTerminarTimer = () => avisou = true;
      servico.iniciar(receitaTeste);
      servico.avancar();
      servico.confirmarTemperatura();
      servico.avancar();

      expect(servico.segundosRestantes, 3);
      servico.iniciarTimer();
      expect(servico.timerRodando, isTrue);

      servico.tick();
      servico.tick();
      expect(servico.segundosRestantes, 1);
      expect(avisou, isFalse);

      servico.tick();
      expect(servico.segundosRestantes, 0);
      expect(servico.timerRodando, isFalse);
      expect(servico.timerFinalizado, isTrue);
      expect(avisou, isTrue);
    });

    test('pausar o timer para a contagem', () {
      servico.iniciar(receitaTeste);
      servico.avancar();
      servico.confirmarTemperatura();
      servico.avancar();
      servico.iniciarTimer();
      servico.pausarTimer();
      servico.tick();
      expect(servico.segundosRestantes, 3);
    });

    test('concluir avisa os observadores e sai do modo receita', () async {
      final observador = ObservadorFalso();
      servico.adicionarObservador(observador);
      servico.iniciar(receitaTeste);
      servico.avancar();
      servico.confirmarTemperatura();
      servico.avancar();

      await servico.concluir();

      expect(observador.concluidas, ['Vela de teste']);
      expect(servico.receitaAtual, isNull);
    });

    test('não conclui antes da última etapa', () async {
      final observador = ObservadorFalso();
      servico.adicionarObservador(observador);
      servico.iniciar(receitaTeste);

      await expectLater(servico.concluir(), throwsA(isA<ValidacaoException>()));
      expect(observador.concluidas, isEmpty);
    });
  });

  group('RF02 - validação da receita', () {
    test('aceita uma receita válida', () {
      expect(() => ReceitaService.validarReceita(receitaTeste), returnsNormally);
    });

    test('recusa receita sem etapas', () {
      const semEtapas = Receita(
        nome: 'Sem etapas',
        rendimento: 1,
        pesoVelaG: 100,
        itens: [ItemReceita(idInsumo: 1, quantidadeUsada: 10)],
      );
      expect(
        () => ReceitaService.validarReceita(semEtapas),
        throwsA(isA<ValidacaoException>()),
      );
    });

    test('recusa etapa de tempo sem duração', () {
      const semDuracao = Receita(
        nome: 'Sem duração',
        rendimento: 1,
        pesoVelaG: 100,
        etapas: [Etapa(ordem: 1, descricao: 'Mexa', tipo: TipoEtapa.tempo)],
        itens: [ItemReceita(idInsumo: 1, quantidadeUsada: 10)],
      );
      expect(
        () => ReceitaService.validarReceita(semDuracao),
        throwsA(isA<ValidacaoException>()),
      );
    });

    test('recusa fragrância acima de 15%', () {
      const muitaFragrancia = Receita(
        nome: 'Forte demais',
        rendimento: 1,
        pesoVelaG: 100,
        percentualFragrancia: 20,
        etapas: [Etapa(ordem: 1, descricao: 'Pese')],
        itens: [ItemReceita(idInsumo: 1, quantidadeUsada: 10)],
      );
      expect(
        () => ReceitaService.validarReceita(muitaFragrancia),
        throwsA(isA<ValidacaoException>()),
      );
    });
  });
}
