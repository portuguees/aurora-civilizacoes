# Aurora — seis etapas integradas M11–M16

**Motor:** Godot 4.7.2 / GDScript / 3D.  
**Branch:** `feat/m11-m16-recursos-construtores-arqueiros-politicas-maravilhas-ia`  
**Base:** M10, sem perder as funcionalidades de M0–M10.  
**Estado:** pré-alfa. Os testes automáticos **não substituem** uma sessão manual interativa.

## M11 — Recursos naturais com rendimentos reais

O mapa gera, deterministicamente segundo a semente, cinco recursos: **Trigo** (+2 alimento), **Ferro** (+2 produção), **Cavalos** (+1 alimento e +1 produção), **Madeira** (+1 produção) e **Peixe** (+2 alimento). Cada recurso só surge num bioma compatível. Estes valores são somados ao rendimento da parcela **quando a cidade a trabalha**; não são uma receita global gratuita.

Os depósitos são identificados por pequenos marcos 3D em cinco grupos `MultiMesh`, para evitar objetos por recurso. Regerar o mesmo mapa preserva a localização e os tipos.  
**Arquivos:** `scripts/resource_rules.gd`, `scripts/resource_visuals.gd`, `scripts/city_rules.gd`, `scripts/world.gd`.  
**Teste:** `tests/resource_smoke.gd`.

## M12 — Unidade Construtor com duas cargas

O jogador pode produzir um **Construtor** por 16 unidades de produção. Move-se até dois pontos por turno. Ao selecionar o construtor num hexágono permitido, pode erguer imediatamente uma **Quinta** (planícies/pradarias) ou **Mina** (colina), consumindo uma carga e o movimento desse turno. Após duas melhorias, o construtor é consumido.

As Quintas e Minas continuam a contar como melhorias reais de cidade na economia; as construídas por construtor não exigem nova fila de produção. A posição do construtor, as cargas e as melhorias sobrevivem à gravação.  
**Comando:** produzir **CONSTRUTOR** no painel; selecionar a unidade na parcela e escolher **CONSTRUIR QUINTA** ou **EXTRAIR NA MINA**.  
**Teste:** `tests/builder_smoke.gd`.

## M13 — Arqueiros e combate à distância

A **Metalurgia** desbloqueia a produção de Arqueiros por 20 unidades de produção. Movem-se dois pontos por turno e atacam inimigos a **até dois hexágonos**, sem receber contra-ataque imediato. O dano é calculado com defesa de colinas/florestas; o combate continua a permitir progressão de pontos de vida e efeitos visuais da etapa M5. Os arqueiros têm uma formação 3D com três personagens e arcos geométricos.

Os ataques consomem o movimento, concedem uma unidade de experiência e são guardados. A IA pode escolher produzir arqueiros para defender a capital.  
**Limite atual:** não existe ainda simulação balística nem linha de visão detalhada por obstáculos, e a IA não segue a mesma árvore tecnológica do jogador.  
**Teste:** `tests/archer_smoke.gd`.

## M14 — Cartas de políticas de governo

Depois de desbloquear os princípios cívicos respetivos, o jogador pode escolher **uma política ativa de cada vez**:
- **Colheitas** (Tradição Oral): +1 alimento por cidade;
- **Administração** (Leis Comuns): +2 ouro por cidade;
- **Milícia** (Guildas): +5 dano nos ataques das suas tropas.

A troca é imediata, não permite acumular as três políticas e a seleção é guardada. As cartas aparecem no painel **C — Cultura e Governo**.  
**Arquivos:** `scripts/policy_rules.gd`, `scripts/strategic_ui.gd`.  
**Teste:** `tests/policy_smoke.gd`.

## M15 — Duas maravilhas 3D únicas

As cidades podem dedicar a sua produção a duas maravilhas originais, cada uma **única no mundo**:
- **Observatório Celeste**: 62 produção, requer Escrita, +5 ciência e +1 cultura por turno na cidade que o construiu;
- **Jardins Reais**: 54 produção, requer Agricultura, +3 alimento e +2 cultura por turno na cidade.

São projetos reais com custos, duração e condições de investigação. Depois da conclusão, aparece um monumento 3D original no hexágono urbano. Não é possível começar outra cópia da mesma maravilha. Ambos os monumentos e os bónus sobrevivem à gravação.  
**Arquivos:** `scripts/wonder_rules.gd`, `scripts/wonder_visuals.gd`.  
**Teste:** `tests/wonder_smoke.gd`.

## M16 — IA que adapta prioridades

Valdoria compara a situação diplomática e a proximidade dos soldados do jogador. Em tempos de **paz**, tenta construir Mercados e Academias e investir em melhorias produtivas. Quando há **ameaça militar próxima** e não há tratado de paz, prioriza **arqueiros de defesa**, guerreiros e quartéis. O objetivo atual já aparece no painel de Diplomacia.

A decisão não é apenas uma mensagem: gera projetos na fila de produção real de Valdoria, que podem terminar em unidades e distritos existentes no mapa.  
**Limite atual:** IA por regras e prioridades, **não** uma IA comparável à de um 4X comercial completo.  
**Arquivo:** `scripts/rival_ai_rules.gd`; teste: `tests/ai_strategy_smoke.gd`.

## Validação automática

O GitHub Actions executa o Godot 4.7.2, importa o projeto e testa toda a cadeia M0–M16, com seis novos testes:

```bash
godot --headless --path . --script res://tests/resource_smoke.gd
godot --headless --path . --script res://tests/builder_smoke.gd
godot --headless --path . --script res://tests/archer_smoke.gd
godot --headless --path . --script res://tests/policy_smoke.gd
godot --headless --path . --script res://tests/wonder_smoke.gd
godot --headless --path . --script res://tests/ai_strategy_smoke.gd
```

O teste `tests/m11_m16_gallery.gd` também cria seis **capturas reais do Godot** a 1600 × 900, uma por etapa. Algumas condições (posição das unidades, tecnologias e ameaça rival) são **preparadas pelo teste** para poder fotografar uma funcionalidade concreta; não representam uma partida completa conseguida manualmente.

## Próximas limitações a resolver

- Revisão manual interativa no PC (câmara, HUD, atalhos, legibilidade e desempenho);
- Refinamento dos modelos de construtores, arqueiros e maravilhas em Blender/GLB;
- Construção e melhoria de estradas, cavalaria, batalha à distância com linha de visão;
- Uma IA que pesquise tecnologias e siga exatamente as mesmas regras do jogador;
- Mais civilizações, diplomacia multilateral, comércio físico e eras históricas.

**Não integrar na main** antes de validar manualmente a experiência e a apresentação.
