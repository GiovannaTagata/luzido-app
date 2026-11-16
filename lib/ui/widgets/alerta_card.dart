import 'package:flutter/material.dart';

import '../tema.dart';

/// Alerta que não depende só da cor: tem ícone, texto e cor (RNF04).
class AlertaCard extends StatelessWidget {
  const AlertaCard({super.key, required this.textos, this.titulo});

  final String? titulo;
  final List<String> textos;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Alerta',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CoresLuzido.laranjaClaro,
          border: Border.all(color: CoresLuzido.laranja, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (titulo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: CoresLuzido.laranja, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        titulo!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7A3A00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            for (final texto in textos)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: CoresLuzido.laranja, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        texto,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5C2C00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
