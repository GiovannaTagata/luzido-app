import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/insumo.dart';
import '../../services/estoque_service.dart';
import '../../services/receita_service.dart';
import '../../services/validacao.dart';
import '../../util/formatacao.dart';
import '../tema.dart';
import '../widgets/alerta_card.dart';
import '../widgets/insumo_dialog.dart';
import 'cadastro_receita_tela.dart';
import 'modo_receita_tela.dart';
import 'resultado_tela.dart';

/// Tela 1 — Início: lista de receitas e acesso ao inventário.
class InicioTela extends StatefulWidget {
  const InicioTela({super.key});

  @override
  State<InicioTela> createState() => _InicioTelaState();
}

class _InicioTelaState extends State<InicioTela> {
  int _aba = 0; // 0 = Receitas, 1 = Inventário

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto, style: const TextStyle(fontSize: 18))),
    );
  }

  /// RF05 — antes de começar, confere se tem material suficiente.
  Future<void> _comecar(int idReceita) async {
    final receitas = context.read<ReceitaService>();
    final estoque = context.read<EstoqueService>();
    final navegador = Navigator.of(context);

    final receita = await receitas.buscar(idReceita);
    if (receita == null || !mounted) return;

    final faltas = estoque.verificarDisponibilidade(receita);
    if (faltas.isNotEmpty) {
      final continuar = await showDialog<bool>(
        context: context,
        builder: (contexto) => AlertDialog(
          title: const Text('Você tem tudo para essa receita?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final falta in faltas)
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.red, size: 30),
                  title: Text(
                    falta.mensagem,
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contexto, false),
              child: const Text('Voltar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(contexto, true),
              child: const Text('Começar mesmo assim'),
            ),
          ],
        ),
      );
      if (continuar != true) return;
    }

    try {
      receitas.iniciar(receita);
    } on ValidacaoException catch (e) {
      if (mounted) _mensagem(e.mensagem);
      return;
    }

    final escolha = await navegador.push<String>(
      MaterialPageRoute(builder: (_) => const ModoReceitaTela()),
    );
    await receitas.carregar();
    if (mounted && escolha == ResultadoTela.irParaInventario) {
      setState(() => _aba = 1);
    }
  }

  void _aoTocarBotaoNovo() {
    if (_aba == 0) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CadastroReceitaTela()),
      );
    } else {
      _novoInsumo();
    }
  }

  Future<void> _novoInsumo() async {
    final estoque = context.read<EstoqueService>();
    final insumo = await showDialog<Insumo>(
      context: context,
      builder: (_) => const InsumoDialog(),
    );
    if (insumo == null) return;
    try {
      await estoque.cadastrar(insumo);
    } on ValidacaoException catch (e) {
      if (mounted) _mensagem(e.mensagem);
    }
  }

  Future<void> _editarInsumo(Insumo atual) async {
    final estoque = context.read<EstoqueService>();
    final insumo = await showDialog<Insumo>(
      context: context,
      builder: (_) => InsumoDialog(inicial: atual),
    );
    if (insumo == null) return;
    try {
      await estoque.editar(insumo);
    } on ValidacaoException catch (e) {
      if (mounted) _mensagem(e.mensagem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estoque = context.watch<EstoqueService>();
    final baixos = estoque.insumosComEstoqueBaixo;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LUZIDO',
              style: TextStyle(
                fontSize: 15,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: CoresLuzido.lilas,
              ),
            ),
            Text(
              _aba == 0 ? 'Minhas receitas' : 'Inventário',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: _BotaoAba(
                    texto: 'Receitas',
                    icone: Icons.menu_book,
                    selecionado: _aba == 0,
                    aoTocar: () => setState(() => _aba = 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BotaoAba(
                    texto: 'Inventário',
                    icone: Icons.inventory_2,
                    selecionado: _aba == 1,
                    aoTocar: () => setState(() => _aba = 1),
                  ),
                ),
              ],
            ),
          ),
          if (baixos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: InkWell(
                onTap: () => setState(() => _aba = 1),
                child: AlertaCard(
                  textos: [
                    baixos.length == 1
                        ? 'Atenção: 1 insumo com estoque baixo'
                        : 'Atenção: ${baixos.length} insumos com estoque baixo',
                  ],
                ),
              ),
            ),
          Expanded(
            child: _aba == 0
                ? _ListaReceitas(aoComecar: _comecar)
                : _ListaInventario(aoEditar: _editarInsumo),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _aoTocarBotaoNovo,
        icon: const Icon(Icons.add),
        label: Text(
          _aba == 0 ? 'Nova receita' : 'Novo insumo',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class _BotaoAba extends StatelessWidget {
  const _BotaoAba({
    required this.texto,
    required this.icone,
    required this.selecionado,
    required this.aoTocar,
  });

  final String texto;
  final IconData icone;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final conteudo = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icone),
        const SizedBox(width: 8),
        Text(texto),
      ],
    );
    return Semantics(
      selected: selecionado,
      button: true,
      child: selecionado
          ? FilledButton(onPressed: aoTocar, child: conteudo)
          : OutlinedButton(onPressed: aoTocar, child: conteudo),
    );
  }
}

class _ListaReceitas extends StatelessWidget {
  const _ListaReceitas({required this.aoComecar});

  final Future<void> Function(int idReceita) aoComecar;

  @override
  Widget build(BuildContext context) {
    final receitas = context.watch<ReceitaService>().receitas;
    if (receitas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhuma receita ainda. Toque em "Nova receita" para cadastrar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: receitas.length,
      itemBuilder: (context, i) {
        final r = receitas[i];
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.nome,
                        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rende ${r.rendimento} velas · ${r.totalEtapas} etapas',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(118, 60)),
                  onPressed: () => aoComecar(r.id),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Começar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ListaInventario extends StatelessWidget {
  const _ListaInventario({required this.aoEditar});

  final Future<void> Function(Insumo insumo) aoEditar;

  @override
  Widget build(BuildContext context) {
    final insumos = context.watch<EstoqueService>().insumos;
    if (insumos.isEmpty) {
      return const Center(
        child: Text('Nenhum insumo cadastrado.', style: TextStyle(fontSize: 18)),
      );
    }
    // Insumos com estoque baixo aparecem primeiro.
    final ordenados = [...insumos]
      ..sort((a, b) {
        if (a.estoqueBaixo == b.estoqueBaixo) return 0;
        return a.estoqueBaixo ? -1 : 1;
      });
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: ordenados.length,
      itemBuilder: (context, i) {
        final insumo = ordenados[i];
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            minVerticalPadding: 14,
            onTap: () => aoEditar(insumo),
            title: Text(
              insumo.nome,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            subtitle: insumo.estoqueBaixo
                ? const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: CoresLuzido.laranja),
                      SizedBox(width: 4),
                      Text(
                        'Estoque baixo',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF7A3A00),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Text(nomesCategorias[insumo.categoria] ?? insumo.categoria),
            trailing: Text(
              formatarQuantidade(insumo.quantidadeAtual, insumo.unidade),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
