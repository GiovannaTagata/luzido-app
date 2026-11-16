import 'package:flutter/material.dart';

import '../../services/pin_service.dart';
import '../tema.dart';

/// Tela de PIN (RNF01). Na primeira vez a Rita cria um PIN de 6 números;
/// depois, o app pede o PIN ao abrir.
class PinTela extends StatefulWidget {
  const PinTela({super.key, required this.servico, required this.proximaTela});

  final PinService servico;
  final Widget proximaTela;

  @override
  State<PinTela> createState() => _PinTelaState();
}

class _PinTelaState extends State<PinTela> {
  String _digitado = '';
  String? _primeiroPin;
  bool? _temPin;
  bool _conferindo = false;
  String? _mensagem;

  @override
  void initState() {
    super.initState();
    widget.servico.temPin().then((tem) {
      if (mounted) setState(() => _temPin = tem);
    });
  }

  String get _titulo {
    if (_temPin == true) return 'Digite seu PIN';
    if (_primeiroPin == null) return 'Crie um PIN de 6 números';
    return 'Digite o PIN de novo para confirmar';
  }

  void _tocar(String digito) {
    if (_conferindo || _digitado.length >= 6) return;
    setState(() {
      _digitado += digito;
      _mensagem = null;
    });
    if (_digitado.length == 6) _concluir();
  }

  void _apagar() {
    if (_digitado.isEmpty) return;
    setState(() => _digitado = _digitado.substring(0, _digitado.length - 1));
  }

  Future<void> _concluir() async {
    setState(() => _conferindo = true);
    final navegador = Navigator.of(context);
    try {
      if (_temPin == true) {
        final certo = await widget.servico.verificar(_digitado);
        if (certo) {
          navegador.pushReplacement(
            MaterialPageRoute(builder: (_) => widget.proximaTela),
          );
          return;
        }
        _erro('PIN incorreto. Tente de novo.');
      } else if (_primeiroPin == null) {
        setState(() {
          _primeiroPin = _digitado;
          _digitado = '';
        });
      } else if (_primeiroPin == _digitado) {
        await widget.servico.definirPin(_digitado);
        navegador.pushReplacement(
          MaterialPageRoute(builder: (_) => widget.proximaTela),
        );
        return;
      } else {
        _primeiroPin = null;
        _erro('Os PINs não são iguais. Crie o PIN de novo.');
      }
    } on PinBloqueadoException catch (e) {
      _erro('Muitas tentativas. Aguarde ${e.segundosRestantes} segundos.');
    } finally {
      if (mounted) setState(() => _conferindo = false);
    }
  }

  void _erro(String texto) {
    if (!mounted) return;
    setState(() {
      _mensagem = texto;
      _digitado = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_temPin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.lock, size: 48, color: CoresLuzido.lilas),
              const SizedBox(height: 8),
              const Text(
                'LUZIDO',
                style: TextStyle(
                  fontSize: 18,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                  color: CoresLuzido.lilas,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Semantics(
                label: '${_digitado.length} de 6 números digitados',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 6; i++)
                      Container(
                        margin: const EdgeInsets.all(6),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _digitado.length ? CoresLuzido.lilas : Colors.transparent,
                          border: Border.all(color: CoresLuzido.lilas, width: 2),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 56,
                child: _mensagem == null
                    ? null
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _mensagem!,
                              style: const TextStyle(fontSize: 17, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
              ),
              const Spacer(),
              _Teclado(aoTocar: _tocar, aoApagar: _apagar),
            ],
          ),
        ),
      ),
    );
  }
}

/// Teclado numérico com botões grandes (72 dp).
class _Teclado extends StatelessWidget {
  const _Teclado({required this.aoTocar, required this.aoApagar});

  final ValueChanged<String> aoTocar;
  final VoidCallback aoApagar;

  Widget _botao(String texto) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 80,
        height: 72,
        child: OutlinedButton(
          onPressed: () => aoTocar(texto),
          child: Text(texto, style: const TextStyle(fontSize: 28)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final linha in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final d in linha) _botao(d)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 96),
            _botao('0'),
            Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: 80,
                height: 72,
                child: IconButton(
                  tooltip: 'Apagar',
                  iconSize: 32,
                  onPressed: aoApagar,
                  icon: const Icon(Icons.backspace_outlined),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
