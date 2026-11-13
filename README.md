# AURORA — Civilizações

**Jogo original de estratégia 4X por turnos**, em Godot 4.7.2 (GDScript), inspirado nos princípios de exploração, expansão, desenvolvimento e conquista do género *Civilization*. Arte, nomes, interface e código próprios.

> **Estado atual:** a `main` contém apenas a estrutura e a documentação inicial. O projeto Godot está nas branches de desenvolvimento (M0 → M3.5); os testes automáticos do Godot 4.7.2 passaram nas últimas alterações, mas ainda falta avaliação manual numa sessão interativa. Trata-se de uma **pré-alfa**, não de uma versão comercial nem completa.

## Objetivo

Criar um mundo **3D estilizado com hexágonos**, com cidades visíveis, unidades reconhecíveis, produção por turnos, exploração, investigação, combate, IA e uma interface clara. O primeiro marco não é um jogo completo: é uma demonstração integrada de **30 turnos** que arranca, funciona e pode ser guardada.

## Ferramentas e estrutura pretendida

- **Godot 4.7.2**, GDScript, renderização GL Compatibility.
- **Blender → glTF/GLB** para modelos 3D originais e animados.
- `scenes/` — cenas; `scripts/` — lógica organizada por domínio; `assets/` — arte licenciada; `tests/` — testes automatizados; `docs/` — arquitetura e marcos.
- **GitHub Issues e Pull Requests** para desenvolver por etapas e preservar uma base conhecida.

## Jogar a versão em desenvolvimento (M3.5)

1. No GitHub, selecionar a branch `feat/m35-arte-mundo-vivo`, depois **Code → Download ZIP**.
2. Importar `project.godot` no **Godot 4.7.2** e executar **F5**.
3. **F** funda a capital com o colono; **J** seleciona a próxima unidade; **E** termina turno.
4. **Clique esquerdo** seleciona; **clique direito** define uma rota de movimento ou ataque a uma unidade rival.
5. Os percursos continuam nos turnos seguintes. O nevoeiro mostra apenas território descoberto.
6. Os botões do painel permitem construir distritos, produzir guerreiros, guardar e continuar a campanha.

Ver [M3.5 — Arte 3D e animações](docs/M35_ARTE_3D_ANIMACOES.md) e [M3 — Movimento, exploração e combate](docs/M3_MOVIMENTO_EXPLORACAO_COMBATE.md). Os relatórios e a captura real do Godot ficam nos artefactos da execução do GitHub Actions.

## Primeira tarefa

Substituir gradualmente os modelos procedurais por modelos 3D originais em GLB, com animações e testes de desempenho, **sem perder a simulação atual**. Os testes automatizados já executam o Godot; a validação manual interativa continua pendente. Não integrar a versão de desenvolvimento em `main` antes dessa revisão.

Consulta [o plano de desenvolvimento](docs/PLANO.md) e [os critérios de aceitação](docs/QUALIDADE.md).

## Trabalhar neste projeto

1. Criar uma branch curta a partir de `main`.
2. Alterar **um subsistema** e acrescentar um teste correspondente.
3. Abrir um Pull Request com capturas reais, instruções de teste e limitações conhecidas.
4. Integrar na `main` só depois de validar arranque, simulação e interface.

O código e os gráficos de *Sid Meier's Civilization* não são redistribuídos neste repositório. Os recursos de terceiros terão de ter licença documentada.
