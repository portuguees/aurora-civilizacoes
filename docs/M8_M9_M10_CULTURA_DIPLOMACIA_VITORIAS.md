# Aurora — M8, M9 e M10 · Três etapas estratégicas

**Projeto:** Aurora — Civilizações, Godot 4.7.2.  
**Branch:** `feat/m8-m10-cultura-diplomacia-vitorias`.  
**Base:** M7 com mapa 3D, cidade, distritos, tecnologia, exércitos e gravação.  
**Estado:** pré-alfa testada automaticamente no motor; avaliação manual em computador ainda por fazer.

## M8 · Cultura e governos

A cultura é gerada por cada cidade em função da população, a partir de `1 + população` por turno, mais bónus de instituições e governo. A cultura é acumulada no império e aplicada ao princípio cívico escolhido.

| Princípio | Custo | Pré-requisitos | Efeito |
|---|---:|---|---|
| Tradição Oral | 11 cultura | Nenhum | +1 cultura por cidade |
| Leis Comuns | 18 cultura | Tradição Oral | Desbloqueia Conselho |
| Guildas | 27 cultura | Tradição Oral | +2 produção por cidade |
| Património | 36 cultura | Leis Comuns | +2 cultura por cidade |
| Representação | 46 cultura | Guildas e Leis Comuns | Desbloqueia República |

Os três governos são **Clãs** (inicial), **Conselho** (+1 ouro, +1 cultura por cidade) e **República** (+2 ouro, +1 ciência e +1 cultura por cidade). O jogador escolhe o governo; só os desbloqueados estão disponíveis.

O sistema guarda princípios concluídos, opção selecionada, progresso por princípio, cultura acumulada e governo. Regras: `scripts/civic_rules.gd`; teste: `tests/civics_smoke.gd`.

## M9 · Diplomacia e comércio

Valdoria funda uma capital nos primeiros turnos; a partir daí o jogador pode contactar a rival através de um painel de diplomacia.

- **Enviar oferta** custa 25 ouro e melhora a relação em 24 pontos.
- **Negociar paz** requer uma relação não inferior a -5, custa 12 ouro e estabelece dez turnos de paz.
- **Caravana comercial** custa 12 ouro, exige paz e gera +5 ouro e +1 cultura por turno até oito turnos, ou até o tratado expirar.
- **Declarar guerra** termina a paz e interrompe as caravanas.
- Durante tratados de paz, os guerreiros **não podem atacar** unidades da outra civilização. A IA também respeita a paz.
- Um ataque do jogador em guerra prejudica as relações. O progresso e os acordos são guardados na campanha.

O comércio é **uma rota diplomática abstrata**, não uma carroça física que percorre o mapa. A diplomacia é bilateral com Valdoria, ainda não é um sistema mundial para muitas civilizações.

Regras: `scripts/diplomacy_rules.gd`; teste: `tests/diplomacy_smoke.gd`.

## M10 · Vitórias e decisões da IA

O Aurora passa a ter uma conclusão verificável para cada uma de quatro estratégias, disponível depois de fundar uma cidade e de atingir o turno 9:

| Vitória | Condição |
|---|---|
| Científica | Concluir as seis tecnologias e acumular pelo menos 145 de ciência |
| Cultural | Concluir os cinco princípios cívicos e acumular pelo menos 120 de cultura |
| Económica | Possuir pelo menos 290 ouro, estar em paz e manter uma caravana ativa |
| Militar | Capturar a capital rival após eliminar a sua guarnição e colocar um guerreiro num hexágono adjacente |

Na vitória, a partida mostra a condição cumprida e deixa de avançar turnos. O resultado e o turno ficam guardados, e podem voltar a ser mostrados ao carregar a campanha.

**IA rival:** depois de fundar Valdoria, a rival decide construir um Mercado e uma Academia em hexágonos válidos, e mais tarde desenvolve uma guarnição. A IA militar anterior continua a patrulhar, com ataques apenas quando não existe tratado de paz. Não se trata ainda de uma IA avançada com estratégia diplomática, pesquisa autónoma ou conquistas.

Regras: `scripts/victory_rules.gd` e `_rival_planning()` em `scripts/game.gd`; teste: `tests/victory_smoke.gd`.

## Controlos

- **F** fundar a capital; **J** selecionar a unidade seguinte; **E** terminar o turno.
- **T** abrir tecnologias; **C** abrir cultura e governos; **D** abrir diplomacia; **V** consultar vitórias; **Esc** fechar as janelas.
- Botão esquerdo do rato seleciona; botão direito move ou ataca.
- O painel da cidade continua a permitir distritos e melhorias em hexágonos, produção de guerreiros, gravação e continuação da campanha.

O módulo `scripts/strategic_ui.gd` cria os três novos painéis. Estes painéis não simulam ações: chamam as regras reais do núcleo do jogo.

## Validação e imagens

A pipeline executa os testes de M0 a M10 em **Godot 4.7.2**, incluindo a importação dos modelos GLB e as capturas gráficas anteriores. Os três novos testes cobrem:

1. Cultura por turnos, pré-requisitos cívicos, efeitos de Conselho/República e persistência;
2. Relações diplomáticas, custos de acordos, ouro/cultura das caravanas, bloqueio de combate em paz e gravação;
3. IA a construir, quatro condições de vitória, bloqueio dos turnos após a vitória, captura de Valdoria e persistência.

`tests/strategic_capture.gd` prepara situações de jogo **dentro do Godot** e produz os ficheiros `aurora_m8_mundo.png`, `aurora_m8_cultura.png`, `aurora_m9_diplomacia.png`, `aurora_m10_objetivos.png` e `aurora_m10_vitoria_cientifica.png`.

As capturas da vitória usam uma campanha **preparada pelo teste**, com os requisitos satisfeitos propositadamente. São imagens reais do motor, não fotografias de um percurso completo conseguido manualmente.

## Limitações prioritárias

- O sistema tem apenas uma civilização rival, o que limita a diplomacia.
- As caravanas não são unidades 3D com caminho no mapa.
- A IA rival executa regras económicas simples, não planeia eras, governos e todas as vitórias.
- O combate e as cidades têm gráficos 3D estilizados mas ainda longe de um jogo comercial completo.
- Falta testar desempenho, resolução, legibilidade e controlos manualmente num PC.

Os Pull Requests anteriores continuam encadeados em rascunho. **Não integrar em `main` antes de um teste manual dos controlos e da apresentação.**
