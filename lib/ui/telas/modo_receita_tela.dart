import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/etapa.dart';
import '../../services/estoque_service.dart';
import '../../services/receita_service.dart';
import '../../services/validacao.dart';
import '../../util/formatacao.dart';
import '../tema.dart';
import 'resultado_tela.dart';

/// Tela 2 — Modo receita (RF03): uma etapa por vez, em tela cheia,
/// com timer de um toque e confirmação de temperatura.
class ModoReceitaTela extends StatefulWidget {
  const ModoReceitaTela({super.key});

  @override
  State<ModoReceitaTela> createState() => _ModoReceitaTelaState();
}

class _ModoReceitaTelaState extends State<ModoReceitaTela> {
  late final ReceitaService _servico;

  @override
  void initState() {
    super.initState();
    _servico = context.read<ReceitaService>();
    _servico.aoTerminarTimer = _avisarFimDoTimer;
    _manterTelaLigada(true);
  }

  @override
  void dispose() {
    _servico.aoTerminarTimer = null;
    _manterTelaLigada(false);
    super.dispose();
  }

  /// Mantém a tela sempre ligada enquanto o modo receita estiver aberto.
  Future<void> _manterTelaLigada(bool ligar) async {
    try {
      if (ligar) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // Em alguns aparelhos (ou nos testes) o recurso não está disponível.
    }
  }

  void _avisarFimDoTimer() {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.vibrate();
    _mostrarMensagem('Tempo esgotado!');
  }

  void _mostrarMensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto, style: const TextStyle(fontSize: 18)),
      ));
  }

  Future<void> _sair() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Deseja sair da receita?'),
        content: const Text(
          'O progresso desta receita será perdido e o estoque não será alterado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Continuar na receita'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      _servico.sair();
      Navigator.of(context).pop();
    }
  }

  void _avancar() {
    try {
      _servico.avancar();
    } on ValidacaoException catch (e) {
      _mostrarMensagem(e.mensagem);
    }
  }

  /// Ajuste da 1ª rodada de validação: na primeira vez a Rita tocou em
  /// "Concluir receita" sem querer. Agora o app pede confirmação e mostra
  /// o que vai ser descontado do estoque.
  Future<bool> _confirmarConclusao() async {
    final itens = _servico.receitaAtual?.itens ?? const [];
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Concluir a receita?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'O estoque será atualizado:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            for (final item in itens)
              Text(
                '• ${item.nomeInsumo}: − ${formatarQuantidade(item.quantidadeUsada, item.unidade)}',
                style: const TextStyle(fontSize: 18),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Concluir e atualizar estoque'),
          ),
        ],
      ),
    );
    return confirmar == true;
  }

  Future<void> _concluir() async {
    if (!await _confirmarConclusao() || !mounted) return;
    final estoque = context.read<EstoqueService>();
    final navegador = Navigator.of(context);
    try {
      await _servico.concluir();
    } on ValidacaoException catch (e) {
      _mostrarMensagem(e.mensagem);
      return;
    } catch (_) {
      _mostrarMensagem('Não foi possível atualizar o estoque. Tente de novo.');
      return;
    }
    final resultado = estoque.ultimoResultado;
    if (resultado == null) return;
    final escolha = await navegador.push<String>(
      MaterialPageRoute(builder: (_) => ResultadoTela(resultado: resultado)),
    );
    navegador.pop(escolha);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReceitaService>(
      builder: (context, servico, _) {
        final etapa = servico.etapaAtual;
        final receita = servico.receitaAtual;
        if (etapa == null || receita == null) {
          return const Scaffold(body: SizedBox.shrink());
        }
        final total = servico.totalEtapas;
        final numero = servico.indice + 1;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _sair();
          },
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 72,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MODO RECEITA',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 2,
                      color: CoresLuzido.lilas,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(receita.nome, style: const TextStyle(fontSize: 20)),
                ],
              ),
              actions: [
                IconButton(
                  iconSize: 32,
                  tooltip: 'Sair da receita',
                  onPressed: _sair,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Etapa $numero de $total',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: CoresLuzido.lilas,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: numero / total,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CartaoEtapa(etapa: etapa),
                            const SizedBox(height: 16),
                            if (etapa.tipo == TipoEtapa.tempo)
                              _BlocoTimer(servico: servico),
                            if (etapa.tipo == TipoEtapa.temperatura)
                              _BlocoTemperatura(servico: servico, etapa: etapa),
                          ],
                        ),
                      ),
                    ),
                    if (!servico.podeAvancar)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: CoresLuzido.laranja, size: 28),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Confirme a temperatura para avançar',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          flex: 10,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(72, 76),
                              textStyle: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: servico.ehPrimeiraEtapa ? null : servico.voltar,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Voltar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 13,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(72, 76),
                              textStyle: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: servico.podeAvancar
                                ? () {
                                    if (servico.ehUltimaEtapa) {
                                      _concluir();
                                    } else {
                                      _avancar();
                                    }
                                  }
                                : null,
                            icon: Icon(
                              servico.ehUltimaEtapa ? Icons.check : Icons.arrow_forward,
                            ),
                            label: Text(
                              servico.ehUltimaEtapa ? 'Concluir receita' : 'Avançar',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CartaoEtapa extends StatelessWidget {
  const _CartaoEtapa({required this.etapa});

  final Etapa etapa;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              etapa.descricao,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            if (etapa.destaque != null && etapa.destaque!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                etapa.destaque!,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: CoresLuzido.lilas,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BlocoTimer extends StatelessWidget {
  const _BlocoTimer({required this.servico});

  final ReceitaService servico;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          formatarTempo(servico.segundosRestantes),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(72, 76)),
                onPressed: servico.timerRodando ? servico.pausarTimer : servico.iniciarTimer,
                icon: Icon(servico.timerRodando ? Icons.pause : Icons.play_arrow, size: 32),
                label: Text(servico.timerRodando ? 'Pausar timer' : 'Iniciar timer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(72, 76)),
                onPressed: servico.adicionarMinuto,
                child: const Text('+1 min'),
              ),
            ),
          ],
        ),
        if (servico.timerFinalizado)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.alarm_on, color: CoresLuzido.verde, size: 32),
                SizedBox(width: 8),
                Text(
                  'Tempo esgotado!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: CoresLuzido.verde,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BlocoTemperatura extends StatelessWidget {
  const _BlocoTemperatura({required this.servico, required this.etapa});

  final ReceitaService servico;
  final Etapa etapa;

  @override
  Widget build(BuildContext context) {
    final temperatura = formatarNumero(etapa.temperaturaAlvoC ?? 0);
    final confirmada = servico.temperaturaConfirmada;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EC),
        border: Border.all(color: CoresLuzido.laranja, width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Temperatura alvo: $temperatura °C',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7A3A00),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: CoresLuzido.verde,
              minimumSize: const Size(72, 76),
              textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            onPressed: confirmada ? null : servico.confirmarTemperatura,
            icon: Icon(confirmada ? Icons.check_circle : Icons.thermostat, size: 30),
            label: Text(confirmada ? 'Temperatura confirmada' : 'Confirmar $temperatura °C'),
          ),
        ],
      ),
    );
  }
}
