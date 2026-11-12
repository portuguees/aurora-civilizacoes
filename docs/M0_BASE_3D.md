# M0 — Primeira base 3D reproduzível

O projeto nesta branch contém um **mapa de terreno 3D original**, com hexágonos,
florestas em MultiMesh, rochas, iluminação, mar, câmara ortográfica e HUD do mapa.

Esta implementação é **nova** e inspirada na linguagem de paisagem da V8;
**não é uma importação pixel a pixel da V8**. As texturas PNG e o `world.gd`
da V8 continuam apenas nos ZIPs históricos da conversa, até uma migração
com inspeção e validação. Reutilizar os ficheiros antigos sem teste seria
voltar aos problemas identificados nas versões V13–V17.

## O que existe agora
- `project.godot` e cena `scenes/World.tscn`.
- Gerador 3D determinístico por semente; água, continentes, biomas.
- Materiais `StandardMaterial3D` e renderização GL Compatibility.
- Vegetação e rochas com `MultiMeshInstance3D`.
- Câmara de estratégia com zoom e arrastamento.
- HUD sempre visível e minimapa; seleção de hexágono com clique.
- Teste de arranque em `tests/smoke.gd`.
- GitHub Actions para executar o motor Godot 4.7.2.

## O que ainda NÃO existe
Colonos, guerreiros, cidades, turnos, economia, inteligência artificial e
combate. Esses são objetivos do **M1/M2/M3**; a interface identifica este
marco explicitamente para não confundir o jogador.

## Como testar
1. Importar `project.godot` no Godot 4.7.2.
2. F5 para abrir o mapa 3D.
3. WASD, roda do rato e arrastamento pelo botão do meio.
4. Clicar nos hexágonos e usar **R** para gerar um novo mundo.

## Teste automático
```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/smoke.gd
```
Esperado: `M0_SMOKE_OK`. Sem execução real, não marcar este marco como aprovado.
