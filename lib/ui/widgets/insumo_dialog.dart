import 'package:flutter/material.dart';

import '../../models/insumo.dart';

/// Converte o texto digitado em número, aceitando vírgula ou ponto.
double? lerNumero(String texto) {
  final limpo = texto.trim().replaceAll(',', '.');
  if (limpo.isEmpty) return null;
  return double.tryParse(limpo);
}

const nomesCategorias = {
  'cera': 'Cera',
  'pavio': 'Pavio',
  'essencia': 'Essência',
  'corante': 'Corante',
  'pote': 'Pote',
  'embalagem': 'Embalagem',
};

const nomesUnidades = {
  'g': 'gramas (g)',
  'ml': 'mililitros (ml)',
  'un': 'unidades (un.)',
};

/// Formulário para cadastrar ou editar um insumo (RF01).
/// Devolve o [Insumo] preenchido, ou null se a usuária cancelar.
class InsumoDialog extends StatefulWidget {
  const InsumoDialog({super.key, this.inicial});

  final Insumo? inicial;

  @override
  State<InsumoDialog> createState() => _InsumoDialogState();
}

class _InsumoDialogState extends State<InsumoDialog> {
  late final TextEditingController _nome;
  late final TextEditingController _quantidade;
  late final TextEditingController _minimo;
  late String _categoria;
  late String _unidade;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final inicial = widget.inicial;
    _nome = TextEditingController(text: inicial?.nome ?? '');
    _quantidade = TextEditingController(
      text: inicial == null ? '' : _texto(inicial.quantidadeAtual),
    );
    _minimo = TextEditingController(
      text: inicial?.estoqueMinimo == null ? '' : _texto(inicial!.estoqueMinimo!),
    );
    _categoria = inicial?.categoria ?? 'cera';
    _unidade = inicial?.unidade ?? 'g';
  }

  String _texto(double valor) {
    return valor == valor.roundToDouble()
        ? valor.toInt().toString()
        : valor.toString().replaceAll('.', ',');
  }

  @override
  void dispose() {
    _nome.dispose();
    _quantidade.dispose();
    _minimo.dispose();
    super.dispose();
  }

  void _salvar() {
    final quantidade = lerNumero(_quantidade.text);
    if (_nome.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o nome do insumo.');
      return;
    }
    if (quantidade == null || quantidade < 0) {
      setState(() => _erro = 'Informe a quantidade. Use só números maiores ou iguais a zero.');
      return;
    }
    final minimo = lerNumero(_minimo.text);
    Navigator.pop(
      context,
      Insumo(
        id: widget.inicial?.id,
        nome: _nome.text.trim(),
        categoria: _categoria,
        unidade: _unidade,
        quantidadeAtual: quantidade,
        estoqueMinimo: minimo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.inicial == null ? 'Novo insumo' : 'Editar insumo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nome,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Nome (ex.: Pavio médio)'),
            ),
            const SizedBox(height: 8),
            const Text('Categoria'),
            DropdownButton<String>(
              isExpanded: true,
              value: _categoria,
              items: [
                for (final c in Insumo.categorias)
                  DropdownMenuItem(value: c, child: Text(nomesCategorias[c] ?? c)),
              ],
              onChanged: (v) => setState(() => _categoria = v ?? _categoria),
            ),
            const SizedBox(height: 8),
            const Text('Unidade'),
            DropdownButton<String>(
              isExpanded: true,
              value: _unidade,
              items: [
                for (final u in Insumo.unidades)
                  DropdownMenuItem(value: u, child: Text(nomesUnidades[u] ?? u)),
              ],
              onChanged: (v) => setState(() => _unidade = v ?? _unidade),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantidade,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Quantidade em estoque'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _minimo,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Estoque mínimo (opcional)',
                helperText: 'Abaixo disso o app mostra um aviso',
              ),
            ),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(child: Text(_erro!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}
