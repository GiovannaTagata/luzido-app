import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/etapa.dart';
import '../../models/insumo.dart';
import '../../models/receita.dart';
import '../../services/estoque_service.dart';
import '../../services/receita_service.dart';
import '../../services/validacao.dart';
import '../../util/formatacao.dart';
import '../widgets/insumo_dialog.dart';

/// Cadastro de receita (RF02): dados da receita, etapas em ordem e insumos.
class CadastroReceitaTela extends StatefulWidget {
  const CadastroReceitaTela({super.key});

  @override
  State<CadastroReceitaTela> createState() => _CadastroReceitaTelaState();
}

class _CadastroReceitaTelaState extends State<CadastroReceitaTela> {
  final _nome = TextEditingController();
  final _rendimento = TextEditingController();
  final _peso = TextEditingController();
  final _fragrancia = TextEditingController();
  final List<Etapa> _etapas = [];
  final List<ItemReceita> _itens = [];
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    _rendimento.dispose();
    _peso.dispose();
    _fragrancia.dispose();
    super.dispose();
  }

  Future<void> _adicionarEtapa() async {
    final etapa = await showDialog<Etapa>(
      context: context,
      builder: (_) => const _EtapaDialog(),
    );
    if (etapa != null) setState(() => _etapas.add(etapa));
  }

  Future<void> _adicionarItem() async {
    final insumos = context.read<EstoqueService>().insumos;
    if (insumos.isEmpty) {
      _mensagem('Cadastre os insumos no inventário primeiro.');
      return;
    }
    final item = await showDialog<ItemReceita>(
      context: context,
      builder: (_) => _ItemDialog(insumos: insumos),
    );
    if (item == null || !mounted) return;
    if (_itens.any((i) => i.idInsumo == item.idInsumo)) {
      _mensagem('Esse insumo já está na receita.');
      return;
    }
    setState(() => _itens.add(item));
  }

  Future<void> _salvar() async {
    final servico = context.read<ReceitaService>();
    final navegador = Navigator.of(context);
    final receita = Receita(
      nome: _nome.text.trim(),
      rendimento: int.tryParse(_rendimento.text.trim()) ?? 0,
      pesoVelaG: lerNumero(_peso.text) ?? 0,
      percentualFragrancia: lerNumero(_fragrancia.text),
      etapas: [
        for (var i = 0; i < _etapas.length; i++)
          Etapa(
            ordem: i + 1,
            descricao: _etapas[i].descricao,
            destaque: _etapas[i].destaque,
            tipo: _etapas[i].tipo,
            duracaoSegundos: _etapas[i].duracaoSegundos,
            temperaturaAlvoC: _etapas[i].temperaturaAlvoC,
          ),
      ],
      itens: List.of(_itens),
    );

    setState(() => _salvando = true);
    try {
      await servico.cadastrar(receita);
      navegador.pop();
    } on ValidacaoException catch (e) {
      if (mounted) _mensagem(e.mensagem);
    } catch (_) {
      if (mounted) _mensagem('Não foi possível salvar a receita. Tente de novo.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto, style: const TextStyle(fontSize: 18))),
    );
  }

  String _descricaoTipo(Etapa e) {
    switch (e.tipo) {
      case TipoEtapa.tempo:
        return 'Timer de ${formatarTempo(e.duracaoSegundos ?? 0)}';
      case TipoEtapa.temperatura:
        return 'Confirmar ${formatarNumero(e.temperaturaAlvoC ?? 0)} °C';
      case TipoEtapa.simples:
        return 'Etapa simples';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova receita')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _nome,
            maxLength: 60,
            decoration: const InputDecoration(labelText: 'Nome (ex.: Vela de lavanda 200 g)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _rendimento,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Rendimento (quantas velas)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _peso,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Peso de cada vela (g)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fragrancia,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Fragrância em % (opcional)',
              helperText: 'Geralmente entre 6% e 10%',
            ),
          ),
          const SizedBox(height: 24),
          Text('Etapas', style: Theme.of(context).textTheme.titleLarge),
          for (var i = 0; i < _etapas.length; i++)
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(_etapas[i].descricao),
                subtitle: Text(_descricaoTipo(_etapas[i])),
                trailing: IconButton(
                  tooltip: 'Remover etapa',
                  icon: const Icon(Icons.delete),
                  onPressed: () => setState(() => _etapas.removeAt(i)),
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _adicionarEtapa,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar etapa'),
          ),
          const SizedBox(height: 24),
          Text('Insumos usados', style: Theme.of(context).textTheme.titleLarge),
          for (var i = 0; i < _itens.length; i++)
            Card(
              child: ListTile(
                title: Text(_itens[i].nomeInsumo),
                subtitle: Text(formatarQuantidade(_itens[i].quantidadeUsada, _itens[i].unidade)),
                trailing: IconButton(
                  tooltip: 'Remover insumo',
                  icon: const Icon(Icons.delete),
                  onPressed: () => setState(() => _itens.removeAt(i)),
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _adicionarItem,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar insumo'),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(72, 64)),
            onPressed: _salvando ? null : _salvar,
            icon: const Icon(Icons.save),
            label: const Text('Salvar receita'),
          ),
        ],
      ),
    );
  }
}

class _EtapaDialog extends StatefulWidget {
  const _EtapaDialog();

  @override
  State<_EtapaDialog> createState() => _EtapaDialogState();
}

class _EtapaDialogState extends State<_EtapaDialog> {
  final _descricao = TextEditingController();
  final _destaque = TextEditingController();
  final _minutos = TextEditingController();
  final _temperatura = TextEditingController();
  TipoEtapa _tipo = TipoEtapa.simples;
  String? _erro;

  @override
  void dispose() {
    _descricao.dispose();
    _destaque.dispose();
    _minutos.dispose();
    _temperatura.dispose();
    super.dispose();
  }

  void _ok() {
    if (_descricao.text.trim().isEmpty) {
      setState(() => _erro = 'Escreva o que deve ser feito nesta etapa.');
      return;
    }
    int? segundos;
    double? temperatura;
    if (_tipo == TipoEtapa.tempo) {
      final minutos = lerNumero(_minutos.text);
      if (minutos == null || minutos <= 0) {
        setState(() => _erro = 'Informe a duração em minutos.');
        return;
      }
      segundos = (minutos * 60).round();
    }
    if (_tipo == TipoEtapa.temperatura) {
      temperatura = lerNumero(_temperatura.text);
      if (temperatura == null) {
        setState(() => _erro = 'Informe a temperatura em °C.');
        return;
      }
    }
    Navigator.pop(
      context,
      Etapa(
        ordem: 0,
        descricao: _descricao.text.trim(),
        destaque: _destaque.text.trim().isEmpty ? null : _destaque.text.trim(),
        tipo: _tipo,
        duracaoSegundos: segundos,
        temperaturaAlvoC: temperatura,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova etapa'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _descricao,
              decoration: const InputDecoration(labelText: 'O que fazer'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _destaque,
              decoration: const InputDecoration(
                labelText: 'Destaque (opcional)',
                helperText: 'Ex.: 96 ml',
              ),
            ),
            const SizedBox(height: 12),
            const Text('Tipo da etapa'),
            DropdownButton<TipoEtapa>(
              isExpanded: true,
              value: _tipo,
              items: const [
                DropdownMenuItem(value: TipoEtapa.simples, child: Text('Simples')),
                DropdownMenuItem(value: TipoEtapa.tempo, child: Text('Com timer')),
                DropdownMenuItem(
                  value: TipoEtapa.temperatura,
                  child: Text('Confirmar temperatura'),
                ),
              ],
              onChanged: (v) => setState(() => _tipo = v ?? _tipo),
            ),
            if (_tipo == TipoEtapa.tempo)
              TextField(
                controller: _minutos,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Duração (minutos)'),
              ),
            if (_tipo == TipoEtapa.temperatura)
              TextField(
                controller: _temperatura,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Temperatura alvo (°C)'),
              ),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_erro!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _ok, child: const Text('Adicionar')),
      ],
    );
  }
}

class _ItemDialog extends StatefulWidget {
  const _ItemDialog({required this.insumos});

  final List<Insumo> insumos;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final _quantidade = TextEditingController();
  late Insumo _escolhido = widget.insumos.first;
  String? _erro;

  @override
  void dispose() {
    _quantidade.dispose();
    super.dispose();
  }

  void _ok() {
    final quantidade = lerNumero(_quantidade.text);
    if (quantidade == null || quantidade <= 0) {
      setState(() => _erro = 'Informe a quantidade. Use só números maiores que zero.');
      return;
    }
    Navigator.pop(
      context,
      ItemReceita(
        idInsumo: _escolhido.id!,
        quantidadeUsada: quantidade,
        nomeInsumo: _escolhido.nome,
        unidade: _escolhido.unidade,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar insumo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButton<int>(
            isExpanded: true,
            value: _escolhido.id,
            items: [
              for (final i in widget.insumos)
                DropdownMenuItem(value: i.id, child: Text(i.nome)),
            ],
            onChanged: (id) => setState(() {
              _escolhido = widget.insumos.firstWhere((i) => i.id == id);
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantidade,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Quantidade usada (${_escolhido.unidade})',
            ),
          ),
          if (_erro != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_erro!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _ok, child: const Text('Adicionar')),
      ],
    );
  }
}
