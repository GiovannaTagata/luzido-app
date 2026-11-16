import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/receita_repository.dart';
import '../models/etapa.dart';
import '../models/receita.dart';
import 'observador_receita.dart';
import 'validacao.dart';

/// Camada de regras de negócio das receitas e do modo receita (RF02 e RF03).
///
/// Controla a ordem das etapas, o timer e a confirmação de temperatura.
/// Quando a receita termina, avisa os observadores (padrão Observer).
class ReceitaService extends ChangeNotifier {
  ReceitaService(this._repositorio);

  final ReceitaRepository? _repositorio;
  final List<ObservadorReceita> _observadores = [];

  List<ResumoReceita> _receitas = [];
  List<ResumoReceita> get receitas => List.unmodifiable(_receitas);

  // ---------- Estado do modo receita ----------
  Receita? _receitaAtual;
  int _indice = 0;
  bool _temperaturaConfirmada = false;
  int _segundosRestantes = 0;
  bool _timerRodando = false;
  bool _timerFinalizado = false;
  Timer? _timer;

  /// Chamado quando o timer chega a zero (a tela toca som e vibra).
  VoidCallback? aoTerminarTimer;

  Receita? get receitaAtual => _receitaAtual;
  int get indice => _indice;
  int get totalEtapas => _receitaAtual?.etapas.length ?? 0;
  bool get temperaturaConfirmada => _temperaturaConfirmada;
  int get segundosRestantes => _segundosRestantes;
  bool get timerRodando => _timerRodando;
  bool get timerFinalizado => _timerFinalizado;

  Etapa? get etapaAtual {
    final receita = _receitaAtual;
    if (receita == null || receita.etapas.isEmpty) return null;
    return receita.etapas[_indice];
  }

  bool get ehPrimeiraEtapa => _indice == 0;
  bool get ehUltimaEtapa => _indice == totalEtapas - 1;

  /// Nas etapas de temperatura, só pode avançar depois de confirmar.
  bool get podeAvancar {
    final etapa = etapaAtual;
    if (etapa == null) return false;
    if (etapa.tipo == TipoEtapa.temperatura) return _temperaturaConfirmada;
    return true;
  }

  void adicionarObservador(ObservadorReceita observador) {
    _observadores.add(observador);
  }

  // ---------- Cadastro e lista (RF02) ----------

  Future<void> carregar() async {
    final repositorio = _repositorio;
    if (repositorio == null) return;
    _receitas = await repositorio.listarResumo();
    notifyListeners();
  }

  Future<Receita?> buscar(int id) async {
    return _repositorio?.buscarCompleta(id);
  }

  Future<int> cadastrar(Receita receita) async {
    final repositorio = _repositorio;
    if (repositorio == null) {
      throw const ValidacaoException('Banco de dados indisponível.');
    }
    validarReceita(receita);
    if (await repositorio.existeNome(receita.nome.trim())) {
      throw const ValidacaoException('Já existe uma receita com esse nome.');
    }
    final id = await repositorio.inserir(receita);
    await carregar();
    return id;
  }

  Future<void> excluir(int id) async {
    await _repositorio?.excluir(id);
    await carregar();
  }

  /// Regras da receita definidas no modelo de dados.
  static void validarReceita(Receita receita) {
    if (receita.nome.trim().isEmpty) {
      throw const ValidacaoException('Informe o nome da receita.');
    }
    if (receita.rendimento <= 0) {
      throw const ValidacaoException('O rendimento deve ser maior que zero.');
    }
    if (receita.pesoVelaG <= 0) {
      throw const ValidacaoException('O peso da vela deve ser maior que zero.');
    }
    final fragrancia = receita.percentualFragrancia;
    if (fragrancia != null && (fragrancia < 0 || fragrancia > 15)) {
      throw const ValidacaoException('A fragrância deve ficar entre 0% e 15%.');
    }
    if (receita.etapas.isEmpty) {
      throw const ValidacaoException('Adicione pelo menos uma etapa.');
    }
    if (receita.itens.isEmpty) {
      throw const ValidacaoException('Adicione pelo menos um insumo.');
    }
    for (final etapa in receita.etapas) {
      if (etapa.descricao.trim().isEmpty) {
        throw const ValidacaoException('Toda etapa precisa de uma descrição.');
      }
      if (etapa.tipo == TipoEtapa.tempo &&
          (etapa.duracaoSegundos == null || etapa.duracaoSegundos! <= 0)) {
        throw const ValidacaoException('Informe a duração da etapa de tempo.');
      }
      if (etapa.tipo == TipoEtapa.temperatura && etapa.temperaturaAlvoC == null) {
        throw const ValidacaoException(
          'Informe a temperatura da etapa de temperatura.',
        );
      }
    }
    for (final item in receita.itens) {
      if (item.quantidadeUsada <= 0) {
        throw const ValidacaoException(
          'A quantidade de cada insumo deve ser maior que zero.',
        );
      }
    }
  }

  // ---------- Modo receita (RF03) ----------

  void iniciar(Receita receita) {
    if (receita.etapas.isEmpty) {
      throw const ValidacaoException('Esta receita não tem etapas.');
    }
    _receitaAtual = receita;
    _indice = 0;
    _prepararEtapa();
    notifyListeners();
  }

  void confirmarTemperatura() {
    _temperaturaConfirmada = true;
    notifyListeners();
  }

  void iniciarTimer() {
    final etapa = etapaAtual;
    if (etapa == null || etapa.tipo != TipoEtapa.tempo || _timerRodando) return;
    if (_segundosRestantes <= 0) {
      _segundosRestantes = etapa.duracaoSegundos ?? 0;
    }
    _timerRodando = true;
    _timerFinalizado = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    notifyListeners();
  }

  void pausarTimer() {
    _timer?.cancel();
    _timerRodando = false;
    notifyListeners();
  }

  /// Ajuste da 1ª rodada de validação: a Rita pediu um botão "+1 min"
  /// porque às vezes a cera precisa de um pouco mais de tempo.
  void adicionarMinuto() {
    final etapa = etapaAtual;
    if (etapa == null || etapa.tipo != TipoEtapa.tempo) return;
    _segundosRestantes += 60;
    _timerFinalizado = false;
    notifyListeners();
  }

  /// Avança o timer em um segundo. É chamado pelo Timer.periodic e pode ser
  /// chamado direto nos testes.
  @visibleForTesting
  void tick() {
    if (!_timerRodando) return;
    _segundosRestantes--;
    if (_segundosRestantes <= 0) {
      _segundosRestantes = 0;
      _timer?.cancel();
      _timerRodando = false;
      _timerFinalizado = true;
      aoTerminarTimer?.call();
    }
    notifyListeners();
  }

  void avancar() {
    if (!podeAvancar) {
      throw const ValidacaoException('Confirme a temperatura para avançar.');
    }
    if (ehUltimaEtapa) return;
    _indice++;
    _prepararEtapa();
    notifyListeners();
  }

  void voltar() {
    if (ehPrimeiraEtapa) return;
    _indice--;
    _prepararEtapa();
    notifyListeners();
  }

  /// Conclui a receita e avisa os observadores (o estoque faz a baixa).
  Future<void> concluir() async {
    final receita = _receitaAtual;
    if (receita == null) {
      throw const ValidacaoException('Nenhuma receita em andamento.');
    }
    if (!ehUltimaEtapa) {
      throw const ValidacaoException('Termine todas as etapas antes de concluir.');
    }
    if (!podeAvancar) {
      throw const ValidacaoException('Confirme a temperatura para concluir.');
    }
    for (final observador in _observadores) {
      await observador.aoConcluirReceita(receita);
    }
    sair();
  }

  /// Sai do modo receita sem dar baixa no estoque.
  void sair() {
    _timer?.cancel();
    _receitaAtual = null;
    _indice = 0;
    _temperaturaConfirmada = false;
    _segundosRestantes = 0;
    _timerRodando = false;
    _timerFinalizado = false;
    notifyListeners();
  }

  void _prepararEtapa() {
    _timer?.cancel();
    _temperaturaConfirmada = false;
    _timerRodando = false;
    _timerFinalizado = false;
    _segundosRestantes = etapaAtual?.duracaoSegundos ?? 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
