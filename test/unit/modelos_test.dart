import 'package:flutter_test/flutter_test.dart';
import 'package:luzido/models/etapa.dart';
import 'package:luzido/models/insumo.dart';
import 'package:luzido/models/receita.dart';

void main() {
  group('Insumo', () {
    test('converte para Map e volta sem perder dados', () {
      const original = Insumo(
        id: 3,
        nome: 'Pavio médio',
        categoria: 'pavio',
        unidade: 'un',
        quantidadeAtual: 9,
        estoqueMinimo: 5,
      );
      final copia = Insumo.fromMap(original.toMap());

      expect(copia.id, 3);
      expect(copia.nome, 'Pavio médio');
      expect(copia.quantidadeAtual, 9);
      expect(copia.estoqueMinimo, 5);
    });

    test('estoqueBaixo só é verdadeiro abaixo do mínimo', () {
      const base = Insumo(
        nome: 'Cera',
        categoria: 'cera',
        unidade: 'g',
        quantidadeAtual: 100,
        estoqueMinimo: 100,
      );
      expect(base.estoqueBaixo, isFalse);
      expect(base.copyWith(quantidadeAtual: 99).estoqueBaixo, isTrue);

      const semMinimo = Insumo(nome: 'Pote', categoria: 'pote', unidade: 'un', quantidadeAtual: 0);
      expect(semMinimo.estoqueBaixo, isFalse);
    });
  });

  group('Etapa', () {
    test('guarda o tipo como texto e lê de volta', () {
      const etapa = Etapa(
        ordem: 2,
        descricao: 'Derreta a cera',
        tipo: TipoEtapa.temperatura,
        temperaturaAlvoC: 85,
      );
      final mapa = etapa.toMap();
      expect(mapa['tipo'], 'temperatura');

      final lida = Etapa.fromMap(mapa);
      expect(lida.tipo, TipoEtapa.temperatura);
      expect(lida.temperaturaAlvoC, 85);
    });
  });

  group('Receita', () {
    test('fromMap recebe as etapas e os itens', () {
      final receita = Receita.fromMap(
        {
          'id_receita': 1,
          'nome': 'Vela de lavanda 200 g',
          'rendimento': 6,
          'peso_vela_g': 200,
          'percentual_fragrancia': 8,
          'observacoes': null,
        },
        etapas: const [Etapa(ordem: 1, descricao: 'Pese a cera')],
        itens: const [ItemReceita(idInsumo: 1, quantidadeUsada: 1200)],
      );

      expect(receita.pesoVelaG, 200);
      expect(receita.percentualFragrancia, 8);
      expect(receita.etapas, hasLength(1));
      expect(receita.itens.single.quantidadeUsada, 1200);
    });
  });
}
