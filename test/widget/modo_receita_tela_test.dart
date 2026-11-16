import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luzido/models/etapa.dart';
import 'package:luzido/models/receita.dart';
import 'package:luzido/services/receita_service.dart';
import 'package:luzido/ui/tema.dart';
import 'package:luzido/ui/telas/modo_receita_tela.dart';
import 'package:provider/provider.dart';

const receitaTeste = Receita(
  nome: 'Vela de lavanda 200 g',
  rendimento: 6,
  pesoVelaG: 200,
  etapas: [
    Etapa(ordem: 1, descricao: 'Pese a cera', destaque: '1.200 g'),
    Etapa(
      ordem: 2,
      descricao: 'Derreta a cera',
      tipo: TipoEtapa.temperatura,
      temperaturaAlvoC: 85,
    ),
    Etapa(
      ordem: 3,
      descricao: 'Adicione a essência de lavanda e mexa',
      destaque: '96 ml',
      tipo: TipoEtapa.tempo,
      duracaoSegundos: 120,
    ),
  ],
);

Future<ReceitaService> abrirTela(WidgetTester tester) async {
  final servico = ReceitaService(null)..iniciar(receitaTeste);
  await tester.pumpWidget(
    ChangeNotifierProvider<ReceitaService>.value(
      value: servico,
      child: MaterialApp(theme: temaLuzido(), home: const ModoReceitaTela()),
    ),
  );
  return servico;
}

void main() {
  testWidgets('mostra a etapa, o destaque e o progresso', (tester) async {
    await abrirTela(tester);

    expect(find.text('Etapa 1 de 3'), findsOneWidget);
    expect(find.text('Pese a cera'), findsOneWidget);
    expect(find.text('1.200 g'), findsOneWidget);
    expect(find.text('Avançar'), findsOneWidget);
  });

  testWidgets('botão Avançar fica desativado até confirmar a temperatura', (tester) async {
    await abrirTela(tester);
    await tester.tap(find.text('Avançar'));
    await tester.pump();

    expect(find.text('Etapa 2 de 3'), findsOneWidget);
    expect(find.text('Confirmar 85 °C'), findsOneWidget);
    expect(find.text('Confirme a temperatura para avançar'), findsOneWidget);

    final avancar = tester.widget<ButtonStyleButton>(
      find.ancestor(of: find.text('Avançar'), matching: find.bySubtype<ButtonStyleButton>()),
    );
    expect(avancar.onPressed, isNull);

    await tester.tap(find.text('Confirmar 85 °C'));
    await tester.pump();

    expect(find.text('Temperatura confirmada'), findsOneWidget);
    expect(find.text('Confirme a temperatura para avançar'), findsNothing);
  });

  testWidgets('etapa de tempo mostra o timer e, na última, o botão Concluir', (tester) async {
    final servico = await abrirTela(tester);
    servico.avancar();
    servico.confirmarTemperatura();
    servico.avancar();
    await tester.pump();

    expect(find.text('02:00'), findsOneWidget);
    expect(find.text('Iniciar timer'), findsOneWidget);
    expect(find.text('Concluir receita'), findsOneWidget);
  });

  testWidgets('botões principais têm pelo menos 72 dp de altura (RNF04)', (tester) async {
    await abrirTela(tester);
    final tamanho = tester.getSize(
      find.ancestor(of: find.text('Avançar'), matching: find.bySubtype<ButtonStyleButton>()),
    );
    expect(tamanho.height, greaterThanOrEqualTo(72));
  });
}
