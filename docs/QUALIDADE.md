# Critérios de qualidade e testes

## Testes mínimos obrigatórios

| Teste | Requisito | Evidência |
|---|---|---|
| Arranque | `project.godot` importa e cena principal abre sem erros fatais | Log de Godot |
| Unidades | Colono e guerreiro próprios estão no modelo e são **visíveis** no ecrã | Estado + captura |
| HUD | Ouro, ciência, produção e fim de turno estão visíveis | Captura |
| Fundação | Uma cidade fundada consome o colono e cria um centro urbano | Assert sobre o estado |
| Produção | Projeto avança por turno e produz 1 unidade/edifício | Assert |
| Movimento | Unidade gasta movimento e respeita limites por turno | Assert |
| Exploração | Nevoeiro revela hexágonos com visibilidade consistente | Assert |
| Gravação | Partida restaurada tem mesmo turno, cidades, unidades, projetos e recursos | Comparação de estados |
| Robustez | Erros de qualquer módulo não deixam a partida apenas com mapa silencioso | Diagnóstico visível |
| Desempenho | FPS e memória medidos em hardware de referência | Métricas |

## Não aceitar
- Logs não executados apresentados como testes que passaram.
- Funcionalidades descritas no README que não existem na build.
- Regressões escondidas: mapa visível com todas as unidades desaparecidas.
- Mudanças de 3D para 2D sem decisão explícita do projeto.
- Promessas de equivalência a um produto comercial sem evidência.

## Estado real

Em 2026-11-12 a **estrutura do repositório foi iniciada**, mas o jogo **ainda não está importado**. Logo **nenhum teste de execução foi realizado neste repositório**. É proibido marcar testes de jogo como aprovados até haver `project.godot` e uma execução real do Godot.
