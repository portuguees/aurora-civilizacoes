# Plano mestre — Aurora 4X

**Princípio:** desenvolvimento contínuo de **um único projeto**. Cada marco precisa de critérios verificáveis; não repetir os ZIPs V1–V18 como se fossem versões estáveis.

## M0 — Recuperar um projeto 3D que abre
- Importar a base visual 3D do mapa Aurora V8, preservando assets e licenças.
- Fixar versão Godot e renderizador GL Compatibility.
- Confirmar a importação no editor e o arranque `--headless --quit-after 60` sem erros fatais.
- Guardar captura da partida **dentro do Godot**, não mockup.

**Aceitação:** cena principal renderizada e câmara navegável, minimapa e HUD do mapa identificáveis.

## M1 — Primeiros 30 turnos
- Começar com colono e guerreiro **visíveis**, selecionáveis e com comandos.
- Fundar uma cidade e mostrar o centro urbano e a faixa de nome/população.
- Um projeto de produção por cidade, concluído em N turnos.
- Investigação com escolhas e efeitos de desbloqueio.
- Exploração com nevoeiro de guerra, fim de turno e IA rival básica.
- Guardar e retomar partida sem perder unidades, projetos e turnos.

**Aceitação:** um teste automático reproduz o turno 1, funda cidade, avança até 30, guarda e restaura; um teste manual com capturas documenta a HUD e modelos visíveis.

## M2 — Cidades visíveis e distritos verdadeiros
- Habitantes trabalham parcelas do território em função da população.
- Custos e tempos de produção, consumo alimentar e crescimento.
- Distritos colocados por clique em hexágonos válidos; adjacências e visual próprio.
- Quintas, minas, serrarias e estradas **mudam o mapa e a economia**.

**Aceitação:** construir dois distritos altera indicadores e modelos, e funciona após gravação.

## M3 — Combate tático e arte de qualidade
- Movimento por caminho, custos de terreno, alcance, defesa e previsões de combate.
- Unidades com silhuetas reconhecíveis em 3D e animações; seleção clara.
- IA considera território, capacidade militar e objetivos.

**Aceitação:** batalha de 10 turnos automatizada sem estados inválidos e com feedback visual claro.

## M4 — Impérios ricos e várias estratégias
- Mais civilizações, diplomacia, comércio, governos e tecnologias.
- Cidades-estado, maravilhas e múltiplas vitórias.
- Melhorar IA, equilíbrio, acessibilidade e desempenho.

**Aceitação:** campanhas distintas podem ser concluídas com estratégias diversas.

## Regras de desenvolvimento
1. **Nenhum marco é dado como concluído por revisão estática apenas.**
2. Desenvolvimento em branches + Pull Requests; `main` permanece estável.
3. Não usar arte ou código comercial de Civilization; referências são usadas para estudar princípios de design.
4. Cada sistema deve ser testável isoladamente, com dados reprodutíveis e sementes fixas.
5. Capturas e vídeos de validação são do **jogo real**, não imagens promocionais geradas.
