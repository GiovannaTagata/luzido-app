import '../models/etapa.dart';
import '../models/insumo.dart';
import '../models/receita.dart';
import 'insumo_repository.dart';
import 'receita_repository.dart';

/// Cadastra dados fictícios na primeira vez que o app abre, para a Rita
/// conseguir testar o fluxo sem precisar cadastrar tudo antes.
class DadosExemplo {
  static Future<void> inserirSeVazio(
    InsumoRepository insumos,
    ReceitaRepository receitas,
  ) async {
    if ((await insumos.listar()).isNotEmpty) return;

    final idCera = await insumos.inserir(const Insumo(
      nome: 'Cera de soja',
      categoria: 'cera',
      unidade: 'g',
      quantidadeAtual: 5000,
      estoqueMinimo: 1500,
    ));
    final idEssencia = await insumos.inserir(const Insumo(
      nome: 'Essência de lavanda',
      categoria: 'essencia',
      unidade: 'ml',
      quantidadeAtual: 150,
      estoqueMinimo: 100,
    ));
    final idPavio = await insumos.inserir(const Insumo(
      nome: 'Pavio médio',
      categoria: 'pavio',
      unidade: 'un',
      quantidadeAtual: 9,
      estoqueMinimo: 5,
    ));
    final idPote = await insumos.inserir(const Insumo(
      nome: 'Pote de vidro 200 g',
      categoria: 'pote',
      unidade: 'un',
      quantidadeAtual: 20,
      estoqueMinimo: 6,
    ));

    await receitas.inserir(Receita(
      nome: 'Vela de lavanda 200 g',
      rendimento: 6,
      pesoVelaG: 200,
      percentualFragrancia: 8,
      etapas: const [
        Etapa(
          ordem: 1,
          descricao: 'Separe e pese a cera de soja',
          destaque: '1.200 g',
        ),
        Etapa(
          ordem: 2,
          descricao: 'Cole os pavios no centro dos potes',
          destaque: '6 pavios',
        ),
        Etapa(
          ordem: 3,
          descricao: 'Derreta a cera em banho-maria até chegar na temperatura',
          tipo: TipoEtapa.temperatura,
          temperaturaAlvoC: 85,
        ),
        Etapa(
          ordem: 4,
          descricao: 'Adicione a essência de lavanda e mexa',
          destaque: '96 ml',
          tipo: TipoEtapa.tempo,
          duracaoSegundos: 120,
        ),
        Etapa(
          ordem: 5,
          descricao: 'Espere a cera esfriar até a temperatura de despejo',
          tipo: TipoEtapa.temperatura,
          temperaturaAlvoC: 60,
        ),
        Etapa(
          ordem: 6,
          descricao: 'Despeje a cera devagar nos potes',
        ),
        Etapa(
          ordem: 7,
          descricao: 'Deixe as velas descansarem sem mexer',
          tipo: TipoEtapa.tempo,
          duracaoSegundos: 3600,
        ),
      ],
      itens: [
        ItemReceita(idInsumo: idCera, quantidadeUsada: 1200),
        ItemReceita(idInsumo: idEssencia, quantidadeUsada: 96),
        ItemReceita(idInsumo: idPavio, quantidadeUsada: 6),
        ItemReceita(idInsumo: idPote, quantidadeUsada: 6),
      ],
    ));
  }
}
