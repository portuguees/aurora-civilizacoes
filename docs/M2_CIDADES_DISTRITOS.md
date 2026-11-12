# M2 — Cidades, distritos e economia por turnos

Esta branch acrescenta ao núcleo M1 uma economia de cidades e distritos colocados em hexágonos.

## O que está implementado

- **População:** cada habitante trabalha uma parcela da cidade (até raio 2); os rendimentos dependem dos biomas.
- **Alimentação:** cada habitante consome 2 alimentos; excedentes acumulados permitem crescer. A habitação limita o crescimento.
- **Prioridades:** equilibrado, alimentos ou produção alteram a escolha de parcelas.
- **Produção:** guerreiros e distritos utilizam a produção da cidade ao longo de vários turnos.
- **Distritos:** Academia (ciência), Mercado (ouro), Oficinas (produção), Quartel e Porto (bónus costeiros).
- **Melhorias:** Quinta (alimentos) e Mina (produção); todas ocupam um hexágono válido dentro de 2 hexágonos da cidade.
- **Adjacência:** Academias recebem ciência de montanhas; Oficinas recebem produção de colinas.
- **Apresentação:** modelos 3D originais por tipo de distrito; marcadores **verdes** de parcelas trabalhadas e **dourados** de locais válidos.
- **Gravação:** o estado da campanha é guardado em `user://aurora_campanha.json`, incluindo unidades, cidades, distritos, recursos, progressos e semente do mapa.

## Como usar no Godot 4.7.2

1. Importar `project.godot` e iniciar com **F5**.
2. Selecionar o colono e carregar em **F** para fundar a capital.
3. No painel à direita, escolher **Academia** ou outro distrito.
4. Clicar num dos hexágonos dourados; a construção entra na fila da cidade.
5. Terminar turnos com **E**; quando a produção for suficiente, o edifício aparece no hexágono.
6. Trocar a prioridade dos cidadãos para obter mais alimentação ou produção.
7. Usar **Guardar Campanha** e **Continuar Campanha**.

## Teste real do motor

```bash
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/game_smoke.gd
godot --headless --path . --script res://tests/city_smoke.gd
```

O último teste verifica fundação, atribuição de parcelas, colocação, produção progressiva, ciência da Academia, modelo 3D, marcadores e persistência da partida.

## Limitações atuais

Esta é uma **etapa jogável e testável**, não um jogo equivalente a Civilization VI. Modelos geométricos são provisórios. Ainda faltam uma economia diplomática completa, caminhos de movimento, várias civilizações inteligentes, pesquisa extensa, animações e uma apresentação artística uniforme. As capturas de ecrã e validação manual em janela precisam de ser realizadas antes da integração em `main`.
