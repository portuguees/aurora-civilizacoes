# M3 — Movimento, exploração e combate por turnos

**Branch:** `feat/m3-movimento-combate-exploracao`  
**Motor:** Godot 4.7.2 / GDScript / 3D Compatibility

## Sistemas implementados

### Ordens e navegação
- Clica com o **botão esquerdo** numa unidade para a selecionar.
- Clica com o **botão direito** num terreno distante para calcular a rota A*.
- As rotas contornam água, montanhas e unidades bloqueadoras.
- Estradas e cidades ainda são *visuais*; não concedem desconto de movimento.
- Planícies e pradarias custam 1 ponto; florestas e colinas custam 2.
- Colonos têm 2 pontos de movimento por turno; guerreiros têm 3.
- A rota é percorrida automaticamente no turno seguinte quando não há pontos suficientes.
- Os hexágonos da rota aparecem marcados a azul-ciano.

### Exploração
- A visão dos jogadores descobre hexágonos em torno das unidades e cidades.
- O resto do mapa fica sob nevoeiro; hexágonos descobertos mas fora da visão ficam sombreados.
- O minimapa apresenta apenas o território descoberto.
- Unidades inimigas fora da visão do jogador não são desenhadas na cena 3D.
- O nevoeiro utiliza `MultiMeshInstance3D`, não milhares de objetos independentes.

### Combate
- Guerreiros podem atacar uma unidade rival adjacente com o botão direito.
- Ataques retiram pontos de vida, com defesa adicional em colinas e florestas.
- Há contra-ataque de guerreiros sobreviventes.
- O ataque consome o movimento da unidade no turno.
- Barras de saúde 3D acompanham os soldados e a HUD mostra os PV da unidade selecionada.
- **Não há** ainda captura de cidades, experiência, combate à distância, cerco ou animações completas de batalha.

### IA rival (primeira versão)
- A civilização rival funda capital, recruta unidades e patrulha até 3 hexágonos em torno da cidade.
- Se o jogador aproxima soldados da patrulha, a IA pode contra-atacar.
- Ainda **não é IA estratégica completa**: não planeia diplomacia, economia avançada ou conquistas.

### Gravação
- A gravação mantém: turno, seed do mundo, unidades, cidades, distritos,
  pontos de vida, movimento restante, caminhos pendentes, alvos de combate
  e hexágonos explorados.
- Os dados de gravações M2 continuam a ser lidos, atribuindo padrões aos novos campos.

## Como testar no computador

1. Abrir a branch do GitHub e escolher **Code → Download ZIP**.
2. Importar `project.godot` no Godot 4.7.2; executar **F5**.
3. **F** funda a capital com o colono; **J** seleciona o guerreiro; **E** termina turno.
4. Com o guerreiro selecionado, clicar com botão direito num hexágono distante.
5. Terminar turnos: ele continua a seguir o caminho enquanto tiver terreno acessível.
6. Aproximar-se de uma unidade inimiga e dar ordem de ataque por clique direito.
7. Guardar e continuar para confirmar que o destino e os PV são preservados.

## Evidência automática

O workflow `.github/workflows/godot-smoke.yml` executa:

- `tests/smoke.gd` (M0: mapa, câmara e HUD);
- `tests/game_smoke.gd` (M1: colonos, guerreiros, fundação e turnos);
- `tests/city_smoke.gd` (M2: cidades, distritos, construção, gravação);
- `tests/military_smoke.gd` (M3: caminhos A*, persistência, descoberta e combate);
- `tests/visual_capture.gd` (M3: **screenshot real** do motor Godot em X virtual).

Os logs e o PNG `visual-m3.png` ficam disponíveis nos artefactos do GitHub Actions. A execução headless valida regras mas não garante, isoladamente, boa apresentação.

## Critérios para integrar na main

- [ ] Todos os testes automáticos M0–M3 e a captura real passam.
- [ ] Captura revista para verificar legibilidade de modelos, nevoeiro e HUD.
- [ ] Teste manual interativo de comandos e apresentação no computador.
- [ ] Atualização do README e do plano de desenvolvimento sem prometer uma versão comercial completa.

## Limitações conhecidas

Os modelos continuam maioritariamente geométricos: falta criar/importar ficheiros GLB licenciados com materiais, animações, vegetação mais natural e variantes de arquitetura. A IA ainda é simples. As fronteiras e estradas são representações visuais e não impõem regras políticas ou bónus. Ainda faltam tecnologia, cultura, diplomacia, comércio e várias condições de vitória.

Este é um **marco incremental pré-alfa** sobre M2.5, não um novo ZIP nem uma versão completa de Civilization VI.
