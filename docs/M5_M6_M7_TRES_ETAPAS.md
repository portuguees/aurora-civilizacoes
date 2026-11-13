# Aurora — M5 + M6 + M7 (três etapas integradas)

**Motor:** Godot 4.7.2, GDScript, GL Compatibility.  
**Base:** M4 com unidades GLB, nevoeiro, IA militar, produção de cidades, gravação e distritos.  
**Estado:** pré-alfa, testes automáticos no Godot. Teste interativo manual ainda pendente.

## M5 — Combate que se vê

- Ataques continuam a aplicar pontos de vida e defesa do terreno conforme M3.
- Cada confronto que o jogador consegue ver cria um efeito 3D temporário:
  - Onda de impacto à volta do hexágono;
  - 9 fragmentos de impacto com dispersão;
  - Número de dano flutuante, igual ao dano calculado no combate;
  - Avanço de ataque dos soldados e retorno à animação Idle;
  - Destruição automática dos efeitos após ~0,72 segundos.
- A simulação regista o efeito e a cena reconstrói-o **depois** de aplicar o combate.
- Efeitos não são gravados nem alteram o cálculo de saúde/defesa.

**Teste:** `tests/combat_fx_smoke.gd` confirma dano, número, onda, partículas e limpeza.

## M6 — Linha costeira e construção visível

- `scripts/coast_art.gd` gera duas malhas de baixo custo:
  - Água rasa nas parcelas de água adjacentes a terra;
  - Linha de espuma ao longo das arestas costeiras.
- Não existe um `Node3D` por hexágono costeiro; agrupamos a geometria por superfície.
- `scripts/construction_visuals.gd` mostra o **estaleiro 3D** no local de cada distrito/quinta/mina encomendado:
  - Plataforma, pilares e travessas;
  - Alvenaria que cresce proporcionalmente à produção;
  - Letreiro com percentagem da obra;
  - O estaleiro desaparece após a conclusão, substituído pelo edifício definitivo.
- A construção mantém os custos, adjacências e regras anteriores.

**Teste:** `tests/coast_construction_smoke.gd` confirma costa, estaleiro progressivo e Mercado concluído.

## M7 — Primeira árvore tecnológica real

| Tecnologia | Custo ciência | Pré-requisitos | Efeito |
|---|---:|---|---|
| Agricultura | 12 | — | +1 alimento por cidade |
| Mineração | 14 | — | +2 produção por cidade |
| Escrita | 24 | Agricultura | +2 ciência por cidade |
| Metalurgia | 29 | Mineração | +8 força ao atacar com guerreiros |
| Comércio | 31 | Escrita | +3 ouro por cidade |
| Engenharia | 48 | Mineração e Escrita | +2 produção por cidade |

- O jogador escolhe **Investigar** na interface ou carrega em **T**.
- A árvore mostra as tecnologias concluídas, disponíveis e bloqueadas por pré-requisitos.
- Os turnos acumulam ciência **real**, produzida pelas cidades.
- O progresso de uma tecnologia é mantido caso o jogador mude temporariamente de investigação.
- Os efeitos são usados pelos sistemas reais de economia e combate.
- A gravação guarda descobertas, investigação atual e progresso de cada tecnologia.
- Gravações M2/M3/M4 continuam a ser aceites (novos campos opcionais com valores padrão).

**Teste:** `tests/technology_smoke.gd` confirma pré-requisitos, progresso por turno, todos os seis efeitos e persistência.

## Controlo do jogo

- **F** fundar capital com o colono selecionado;
- **J** próxima unidade;
- **E** terminar turno;
- **T** abrir árvore tecnológica; **Esc** fechar;
- **Clique esquerdo** selecionar; **clique direito** mover/atacar;
- Painel de cidades: escolher edifício, clicar no hexágono dourado e terminar turnos;
- **Guardar/Continuar campanha** no painel à direita.

## Testes e imagens reais

O GitHub Actions executa o Godot 4.7.2 para todos os marcos M0 → M7, incluindo:
```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/combat_fx_smoke.gd
godot --headless --path . --script res://tests/coast_construction_smoke.gd
godot --headless --path . --script res://tests/technology_smoke.gd
```

O script `tests/visual_capture.gd` abre o jogo real numa janela virtual e produz:
- `visual-m7-mundo.png`: capital, exércitos, fronteiras, mar e investigação no HUD;
- `visual-m7-tecnologias.png`: janela de árvore tecnológica dentro do jogo.

**As capturas são do Godot, não representações geradas por IA.** Os resultados dos testes e PNG ficam nos artefactos do workflow.

## Limitações conhecidas

- Os modelos GLB são de baixo número de polígonos e ainda precisam de artesanato/rigs avançados;
- Efeitos de ataque são animados proceduralmente, sem sequências esqueléticas de combate;
- A linha de espuma costeira é estilizada, ainda não é água realista com ondas e reflexos físicos;
- Apenas seis tecnologias iniciais; faltam eras, governos, cultura, diplomacia e IA estratégica avançada;
- A experiência ainda não equivale em escala nem polimento a Civilization VI;
- Falta avaliar controlos, legibilidade e desempenho numa sessão manual em PC.

**Não integrar em `main` antes de validação manual.** Este trabalho usa um único projeto com três marcos testáveis, e não três ZIPs independentes.
