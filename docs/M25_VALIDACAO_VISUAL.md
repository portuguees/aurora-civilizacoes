# M2.5 — Validação visual em Godot

## Objetivo

Melhorar a **legibilidade da partida no ecrã** antes de acrescentar mais regras.

## Melhorias integradas

- Modelos geométricos 3D originais de **cidades com casas e torre**, e muralhas quando a população chega a 3.
- **Colonização e exércitos reconhecíveis**: carroça do colono, quatro soldados em formação e bandeiras por civilização.
- Fronteiras 3D com **cores por civilização** num raio de dois hexágonos, e estradas entre cidades e distritos.
- Menor predominância do oceano, cores de bioma ajustadas e câmara estratégica mais aproximada.
- Interface corrigida: barras sem sobreposição; recursos reais; retirada de aviso desatualizado sobre M0.
- Teste de **captura real** com Godot 4.7.2 e Xvfb no GitHub Actions.

## Evidência reproduzível

O workflow `.github/workflows/godot-smoke.yml` executa quatro testes:
1. `tests/smoke.gd` — mapa, câmara e HUD;
2. `tests/game_smoke.gd` — colono, guerreiro, capital e turnos;
3. `tests/city_smoke.gd` — distritos, trabalhadores e gravação;
4. `tests/visual_capture.gd` — abre uma cena renderizada por Godot, funda a capital,
   conclui a construção da Academia, verifica cidade, guerreiros, estradas, fronteiras e HUD,
   e grava o ficheiro **`visual-m25.png`**.

O PNG é publicado como *artifact* do GitHub Actions (juntamente com os logs). A captura não é gerada por um modelo de imagens: é um frame produzido pelo motor Godot.

## Inspeção visual da captura

As primeiras imagens mostraram sobreposição da barra de turno com o título, um painel de M0 desatualizado e terreno muito pálido. Esses problemas foram corrigidos antes desta entrega.

Na imagem final os modelos da cidade e exército distinguem-se no centro do mapa, as fronteiras azuis identificam o território e a estrada liga o distrito à capital. **Ainda não há qualidade artística comparável a Civilization VI**: árvores, edifícios, personagens e água continuam representados por geometria simples sem animações. Isto é um passo de apresentação **pré-alfa**.

## Limitações a resolver nas próximas etapas

- Texturas, materiais, iluminação e animações originais com estilo artístico consistente;
- Imóveis/edifícios mais variados e animação de produção e combate;
- Terrenos mais naturais, costa suave e melhor leitura do relevo;
- Seleção e movimento com pathfinding (neste momento, um hexágono de cada vez);
- Árvore tecnológica real, diplomacia avançada, comércio, IA por objetivos e condições de vitória;
- Verificação manual de desempenho e ergonomia em Windows/macOS/Linux.

## Como experimentar

Seleciona no GitHub a branch `feat/m25-apresentacao-3d`, usa **Code → Download ZIP**, abre `project.godot` no Godot 4.7.2 e executa F5.

- `F`: fundar capital;
- `J`: próxima unidade;
- botão direito: mover uma casa adjacente;
- clica num distrito à direita e depois num hexágono válido;
- `E`: terminar turno;
- guardar/continuar: botões no painel.

Este marco permanece em *Pull Request* em rascunho até um teste manual interativo das imagens e controlos ser realizado.
