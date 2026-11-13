# M4 — Modelos GLB originais com animação

## Objetivo

Substituir as personagens procedurais de `scripts/unit_visuals.gd` por **ficheiros de modelo 3D independentes**, sem introduzir dependências de rede no jogo.

## Recursos introduzidos

| Recurso | Conteúdo |
|---|---|
| `assets/models/warrior_animated.glb` | Guerreiro original com armadura, escudo, arma e rig articulado |
| `assets/models/settler_animated.glb` | Colono original com roupa de viagem, mochila e bastão |
| `tests/glb_import_smoke.gd` | Teste do importador Godot e dos clips |

Ambos os modelos são em **glTF binário 2.0 (GLB)**. As formas e materiais foram criados especialmente para Aurora: não incluem recursos copiados de Civilization VI.

### Animação

Cada GLB inclui 7 articulações de hierarquia (Hip, Chest, Head, Arm_L, Arm_R, Leg_L, Leg_R) e dois clips:
- `Idle`: movimentos discretos em repouso;
- `Walk`: rotação alternada de braços e pernas.

O rig utiliza **peças geométricas articuladas por nós**. Não é um personagem profissional com skin deformável ou rig de Blender completo. Este compromisso garante recursos GLB animados efetivamente importáveis no Godot e permite mais tarde substituir os modelos por arte de personagem de maior qualidade sem modificar as regras do jogo.

### Integração na partida

A intenção do M4 é que:
- A formação guerreira continue com quatro personagens, agora provenientes de instâncias GLB;
- Os colonos mantenham carroça e acompanhantes, com figuras GLB;
- A barra de vida, a seleção, o movimento, o combate e a gravação continuem independentes do modelo;
- O início de movimento ative `Walk` e o fim ative `Idle`.

### Testes de aceitação

1. `godot --headless --editor --path . --import --quit`: nenhum bloqueio de importação.
2. `godot --headless --path . --script res://tests/glb_import_smoke.gd`: duas cenas GLB, geometria e dois clips reconhecidos, modelos presentes no mapa.
3. Smoke tests existentes M0–M3.5 continuam a passar.
4. `tests/visual_capture.gd` produz `visual-m4.png` numa janela virtual em GitHub Actions.
5. Teste manual interativo a validar no computador antes de integrar em `main`.

## Editar os GLB no Blender

No Blender, selecionar **File → Import → glTF 2.0 (.glb/.gltf)**, abrir cada recurso, modificar geometria, materiais e animações e exportar como **glTF Binary (.glb)**. Manter a escala geral e, idealmente, os nomes `Idle` e `Walk`.

## Limitações

Estes são modelos de transição de arte, originais e de baixo número de polígonos. Falta melhorar anatomia, pesos e skinning esquelético, animação de combate e detalhes artísticos. O uso destes modelos **não torna o Aurora equivalente a Civilization VI**.
