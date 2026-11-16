import '../models/receita.dart';

/// Padrão Observer: quem implementa esta interface é avisado quando uma
/// receita é concluída no modo receita.
///
/// Assim o modo receita não precisa conhecer os detalhes do estoque
/// (baixo acoplamento). Na segunda versão, o registro de lotes também pode
/// "ouvir" este mesmo evento.
abstract class ObservadorReceita {
  Future<void> aoConcluirReceita(Receita receita);
}
