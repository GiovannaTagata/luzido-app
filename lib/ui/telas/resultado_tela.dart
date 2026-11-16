import 'package:flutter/material.dart';

import '../../services/estoque_service.dart';
import '../../util/formatacao.dart';
import '../tema.dart';
import '../widgets/alerta_card.dart';

/// Tela 3 — Receita concluída (RF04 e RF06): mostra o que foi descontado
/// do estoque e os alertas de estoque baixo.
class ResultadoTela extends StatelessWidget {
  const ResultadoTela({super.key, required this.resultado});

  static const irParaInventario = 'inventario';

  final ResultadoBaixa resultado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 8),
                    const Center(
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: CoresLuzido.verde,
                        child: Icon(Icons.check, color: Colors.white, size: 52),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Receita concluída!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Estoque atualizado',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: CoresLuzido.verde,
                      ),
                    ),
                    Text(
                      resultado.nomeReceita,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'O que foi descontado do estoque',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            for (final item in resultado.descontados)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.nome,
                                        style: const TextStyle(fontSize: 19),
                                      ),
                                    ),
                                    Text(
                                      '− ${formatarQuantidade(item.quantidade, item.unidade)}',
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (resultado.alertas.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      AlertaCard(
                        titulo: 'Atenção ao estoque',
                        textos: resultado.alertas,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(72, 64)),
                onPressed: () => Navigator.pop(context, irParaInventario),
                icon: const Icon(Icons.inventory_2),
                label: const Text('Ver inventário'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(72, 64)),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home),
                label: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
