/// Funções para mostrar números no padrão brasileiro.

/// Formata uma quantidade com a unidade, por exemplo:
/// 1200 g -> "1.200 g", 96.5 ml -> "96,5 ml", 6 un -> "6 un."
String formatarQuantidade(double valor, String unidade) {
  final texto = formatarNumero(valor);
  if (unidade == 'un') {
    return '$texto un.';
  }
  return '$texto $unidade';
}

/// Formata um número com ponto nos milhares e vírgula nos decimais.
/// Mostra no máximo uma casa decimal e esconde o ",0".
String formatarNumero(double valor) {
  final negativo = valor < 0;
  final arredondado = (valor.abs() * 10).round() / 10;
  final parteInteira = arredondado.truncate();
  final decimal = ((arredondado - parteInteira) * 10).round();

  final digitos = parteInteira.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    final posicaoDoFim = digitos.length - i;
    buffer.write(digitos[i]);
    if (posicaoDoFim > 1 && posicaoDoFim % 3 == 1) {
      buffer.write('.');
    }
  }

  var resultado = buffer.toString();
  if (decimal != 0) {
    resultado = '$resultado,$decimal';
  }
  return negativo ? '-$resultado' : resultado;
}

/// Formata segundos no formato do timer: 125 -> "02:05".
String formatarTempo(int segundos) {
  final s = segundos < 0 ? 0 : segundos;
  final minutos = (s ~/ 60).toString().padLeft(2, '0');
  final resto = (s % 60).toString().padLeft(2, '0');
  return '$minutos:$resto';
}
