# Aurora — M3.5: paisagem 3D e animações de unidades

## Estado

Este marco é um **incremento visual pré-alfa** sobre M3. Não substitui a jogabilidade,
não altera as regras de combate e mantém o mesmo projeto Godot 4.7.2.

## Melhorias desta etapa

### Paisagem original
- Substituição das antigas árvores de uma única forma por **pinheiros em dois níveis,
  copas de árvore, troncos distintos e vegetação rasteira**.
- Novos rochedos, flores silvestres e reflexos de luz na água.
- Variações determinísticas por semente do mapa. A partida carregada mostra a
  mesma paisagem que antes da gravação.
- Apenas oito grupos `MultiMeshInstance3D` principais para representar a vegetação.
  Não se criam milhares de `Node3D` independentes.
- Paleta natural ajustada para favorecer a leitura de terreno, unidades e cidades.

### Unidades
- Personagens separados na formação militar, com pernas, braços, lança e escudo.
- Colonos com carroça e dois acompanhantes.
- **Animação procedural genuína em tempo real:** repouso, pequenos movimentos da
  formação, marcha e oscilação dos estandartes.
- A marcha acompanha o deslocamento entre hexágonos através do sistema de movimento
  já existente; o sistema de combate, PV e caminhos mantém-se independente.
- O teste automatizado verifica a **alteração efetiva de pose** durante a marcha.

### Cidades e distritos
- Centro urbano com praça pavimentada, escadarias, pórticos, torre de menagem,
  torres adicionais conforme a população e tochas emissivas.
- Os novos detalhes convivem com casas, muralhas e faixas de identificação anteriores.
- Distritos e melhorias têm agora letreiros 3D para identificação na câmara.

## Estrutura

| Ficheiro | Função |
|---|---|
| `scripts/terrain_art.gd` | Biomas 3D e instâncias agrupadas |
| `scripts/unit_motion.gd` | Movimento procedural das formações |
| `scripts/unit_visuals.gd` | Personagens 3D articulados |
| `scripts/city_details.gd` | Detalhes da cidade e evolução visual |
| `scripts/city_visuals.gd` | Integração arquitetónica |
| `scripts/district_visuals.gd` | Legendas dos distritos |
| `tests/art_smoke.gd` | Inspeção automática do mapa, arte e animação |
| `tests/visual_capture.gd` | Captura **real** do Godot a 1600 × 900 |

## Reproduzir a validação

```bash
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/game_smoke.gd
godot --headless --path . --script res://tests/city_smoke.gd
godot --headless --path . --script res://tests/military_smoke.gd
godot --headless --path . --script res://tests/art_smoke.gd
```

O GitHub Actions também executa uma sessão renderizada através de Xvfb e publica
`visual-m35.png` como artefacto do workflow. Essa imagem é um frame do jogo,
**não um conceito ou mockup produzido por IA**.

## Limitações e trabalho futuro

Esta atualização é um avanço de legibilidade e direção artística, **não** um pacote
de modelos comerciais. O mundo continua com geometria estilizada original produzida
pelo Godot, não com uma biblioteca completa de modelos GLB criados no Blender.

Para chegar a um nível visual mais próximo do que o utilizador pretende:

- [ ] Criar e importar modelos GLB originais de soldados, cavalos, carroças e edifícios;
- [ ] Animar personagens com rigs e `AnimationPlayer` (andar, atacar, fundar);
- [ ] Diferenciar classes de arquitetura por civilização e época;
- [ ] Criar sombras, relevo, água e transições costeiras mais naturais;
- [ ] Criar efeitos de construção, combate e desgaste;
- [ ] Rever UI/UX em 1280 × 720 e 1600 × 900;
- [ ] Medir FPS e memória em hardware de referência;
- [ ] Executar teste manual com rato/teclado no PC antes de integrar em `main`.

**Sem teste manual interativo, o PR permanece em rascunho.**
