import 'package:flutter_test/flutter_test.dart';
import 'package:luzido/util/formatacao.dart';

void main() {
  group('formatarNumero', () {
    test('coloca ponto nos milhares', () {
      expect(formatarNumero(1200), '1.200');
      expect(formatarNumero(1234567), '1.234.567');
    });

    test('não mostra ",0" em números inteiros', () {
      expect(formatarNumero(96), '96');
      expect(formatarNumero(0), '0');
    });

    test('usa vírgula e uma casa decimal', () {
      expect(formatarNumero(96.5), '96,5');
      expect(formatarNumero(2.25), '2,3');
    });

    test('mantém o sinal negativo', () {
      expect(formatarNumero(-400), '-400');
    });
  });

  group('formatarQuantidade', () {
    test('junta o número com a unidade', () {
      expect(formatarQuantidade(1200, 'g'), '1.200 g');
      expect(formatarQuantidade(96, 'ml'), '96 ml');
      expect(formatarQuantidade(6, 'un'), '6 un.');
    });
  });

  group('formatarTempo', () {
    test('mostra minutos e segundos com dois dígitos', () {
      expect(formatarTempo(125), '02:05');
      expect(formatarTempo(0), '00:00');
      expect(formatarTempo(600), '10:00');
    });

    test('não mostra tempo negativo', () {
      expect(formatarTempo(-5), '00:00');
    });
  });
}
