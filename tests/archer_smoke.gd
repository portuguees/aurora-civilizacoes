extends SceneTree
const Nav = preload("res://scripts/hex_navigation.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("M13: " + message)
    quit(1)

func _run() -> void:
    var world: Node3D = load("res://scenes/World.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var game: Node = world.get_node("Game")
    game.found_city()
    if game.queue_unit("archer"):
        _fail("Arqueiros disponíveis sem Metalurgia")
        return
    game.researched.append("metallurgy")
    if not game.queue_unit("archer"):
        _fail("A capital não conseguiu produzir arqueiros")
        return
    var archer: Dictionary = {}
    for i in range(20):
        game.end_turn()
        for unit in game.units:
            if int(unit["owner"]) == 0 and str(unit["kind"]) == "archer":
                archer = unit
                break
        if not archer.is_empty():
            break
    if archer.is_empty() or Nav.movement_capacity("archer") != 2:
        _fail("Arqueiro não foi produzido com movimento adequado")
        return
    game.active_unit_id = int(archer["id"])
    var model: Node = game.get_node_or_null("ModelosDeJogo/Unidade_%d_archer" % int(archer["id"]))
    if model == null or model.get_node_or_null("Soldado_2/ImportedGLB") == null:
        _fail("Falta modelo 3D dos arqueiros")
        return
    var enemy_cell: Vector2i = Vector2i(-1, -1)
    for cell in world.tiles:
        if Nav.distance(archer["coords"], cell) == 2 and Nav.movement_cost(world.tiles[cell]) > 0:
            if game.unit_at(cell).is_empty():
                enemy_cell = cell
                break
    if enemy_cell.x < 0:
        _fail("Não há terreno para tiro a dois hexágonos")
        return
    game._spawn_unit(1, "warrior", enemy_cell)
    var defender: Dictionary = game.units.back()
    archer["move_points"] = 2
    var hp: int = int(archer["health"])
    if not game.issue_order(enemy_cell):
        _fail("O arqueiro não atacou a dois hexágonos")
        return
    if int(defender["health"]) >= 100 or int(archer["health"]) != hp:
        _fail("Ataque à distância não causou dano ou sofreu contra-ataque")
        return
    if int(archer["experience"]) != 1 or int(archer["move_points"]) != 0:
        _fail("Ataque não consumiu movimento/experiência")
        return
    if not game.save_game() or not game.load_game():
        _fail("Não se conseguiu guardar arqueiro")
        return
    archer = game.get_active()
    if str(archer.get("kind", "")) != "archer" or int(archer["experience"]) != 1:
        _fail("A gravação perdeu o arqueiro/experiência")
        return
    print("M13_SMOKE_OK: arqueiros, Metalurgia, alcance 2, sem contra-ataque e gravação")
    quit(0)
