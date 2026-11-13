extends SceneTree
## M5: o resultado do combate deve estar visível e não alterar os PV calculados.

const Navigation = preload("res://scripts/hex_navigation.gd")


func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    push_error("M5: " + message)
    quit(1)


func _run() -> void:
    var packed: PackedScene = load("res://scenes/World.tscn")
    if packed == null:
        _fail("Cena não abriu")
        return
    var world: Node3D = packed.instantiate()
    root.add_child(world)
    await process_frame
    var game: Node = world.get_node("Game")
    game.next_player_unit()
    var warrior: Dictionary = game.get_active()
    if str(warrior.get("kind", "")) != "warrior":
        _fail("Guerreiro não selecionável")
        return
    var enemy_cell: Vector2i = Vector2i(-1, -1)
    for cell in Navigation.neighbors(warrior["coords"]):
        if world.tiles.has(cell) and Navigation.movement_cost(world.tiles[cell]) > 0:
            if game.unit_at(cell).is_empty():
                enemy_cell = cell
                break
    if enemy_cell.x < 0:
        _fail("Não foi possível posicionar o adversário")
        return
    game._spawn_unit(1, "warrior", enemy_cell)
    var defender: Dictionary = game.units.back()
    var expected: int = 32 if str(world.tiles[enemy_cell]["biome"]) not in ["forest", "hills"] else 25
    if not game.issue_order(enemy_cell):
        _fail("Ordem de ataque falhou")
        return
    if int(defender["health"]) != 100 - expected:
        _fail("O efeito visual alterou a matemática dos PV")
        return
    var fx: Node = game.get_node_or_null("CombateVisual/ImpactoCombate")
    if fx == null:
        _fail("Não existe impacto 3D visível após o ataque")
        return
    var damage_label: Node = fx.get_node_or_null("DanoVisivel")
    if damage_label == null or str(damage_label.text) != "-%d" % expected:
        _fail("O dano mostrado não corresponde ao dano real")
        return
    if fx.get_node_or_null("OndaImpacto") == null:
        _fail("Falta a onda visual do impacto")
        return
    if fx.get_node_or_null("Faisca_8") == null:
        _fail("Faltam os efeitos de impacto")
        return
    fx._process(0.80)
    await process_frame
    if is_instance_valid(fx):
        _fail("O efeito temporário não foi destruído depois do combate")
        return
    print("M5_SMOKE_OK: ataque, impacto, dano flutuante, partículas e limpeza")
    quit(0)
