# Luzido — app de receitas com timer e controle de estoque para velas aromáticas

MVP desenvolvido na disciplina de **Projeto de Software (Experiências Práticas I, II e III)** para a **Luzido**, microempresa de velas aromáticas artesanais da Rita de Cassia.

O app ajuda a Rita a seguir as receitas na cozinha, com as mãos sujas de cera, e mantém o estoque de insumos sempre atualizado.

## Problema
A produção era controlada de forma manual: receitas em um caderno, timer do celular difícil de usar com a mão suja e nenhum controle de estoque. Faltava material no meio da receita, a temperatura da essência às vezes ficava errada e as velas não saíam sempre iguais.

## Funcionalidades do MVP

| Requisito | Descrição | Prioridade |
|---|---|---|
| RF01 | Cadastro de insumos no inventário (cera, pavios, essências, corantes, potes e embalagens) | Obrigatório |
| RF02 | Cadastro de receitas com etapas em ordem e insumos usados | Obrigatório |
| RF03 | Modo receita em tela cheia, com timer de um toque e confirmação de temperatura | Obrigatório |
| RF04 | Baixa automática no estoque ao concluir a receita | Obrigatório |
| RF05 | Verificação antes de começar ("Você tem tudo para essa receita?") | Desejável |
| RF06 | Aviso de estoque baixo | Desejável |
| RNF01 | PIN local de 6 números guardado com hash PBKDF2 + salt | — |
| RNF04 | Acessibilidade: botões de 72 dp no modo receita, textos grandes, alertas com ícone + texto + cor e tela sempre ligada | — |

Ficam para uma próxima versão: custo por vela e preço sugerido, registro de lotes, lembrete de cura e backup.

## Tecnologias
- **Flutter / Dart** (padrão tecnológico principal)
- **provider** — liga as telas aos serviços
- **sqflite** — banco **SQLite local** (o app funciona 100% offline)
- **wakelock_plus** — mantém a tela ligada no modo receita
- **cryptography** — hash PBKDF2 do PIN
- **flutter_test** e **sqflite_common_ffi** — testes automatizados

## Arquitetura (monolítica em camadas)
```
lib/
├── main.dart            # monta as camadas e abre o app
├── app.dart             # MaterialApp + Providers
├── models/              # Insumo, Receita, Etapa, ItemReceita
├── data/                # camada de dados: SQLite e repositórios
├── services/            # regras de negócio: estoque, modo receita, PIN
├── ui/                  # telas e componentes visuais
└── util/                # formatação de números e tempo
```
Quando a receita é concluída, o `ReceitaService` avisa os observadores (padrão **Observer**) e o `EstoqueService` faz a baixa automática. Assim o modo receita não depende dos detalhes do estoque.

## Como rodar
```bash
flutter pub get
flutter create --platforms=android .   # gera a pasta android na primeira vez
flutter run
```

## Testes
```bash
flutter test --coverage
```
- `test/unit` — testes unitários (serviços, modelos, formatação e PIN)
- `test/integracao` — testes de integração com o banco SQLite em memória (fluxo completo da receita)
- `test/widget` — testes da tela do modo receita

## Integração Contínua
O workflow `.github/workflows/ci.yml` roda no GitHub Actions a cada push e Pull Request para a `main`:
1. análise estática (`flutter analyze`);
2. testes unitários, de widget e de integração com cobertura;
3. build do APK Android (guardado como artefato).

## Fluxo de trabalho
- Commits no padrão **Conventional Commits** (`feat:`, `fix:`, `test:`, `ci:`, `docs:`, `chore:`).
- Cada funcionalidade em uma branch própria, integrada à `main` por **Pull Request** com checklist de auto-revisão.
