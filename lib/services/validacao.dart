/// Erro de validação com uma mensagem simples, em português, que pode ser
/// mostrada direto para a usuária (sem detalhes técnicos).
class ValidacaoException implements Exception {
  const ValidacaoException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}
