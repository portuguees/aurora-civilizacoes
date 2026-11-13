extends SceneTree
const Nav = preload("res://scripts/hex_navigation.gd")
const AI = preload("res://scripts/rival_ai_rules.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("M16: " + message)
    quit(1)

func _run() -> void:
    var world: Node3D = load("res://scenes/World.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var game: Node = world.get_node("Game")
    game.found_city()
    game.end_turn()
    game.end_turn()
    if game.city_count(1) != 1:
        _fail("Valdoria não fundou capital")
        return
    var rival_city: Dictionary = {}
    for city in game.cities:
        if int(city["owner"]) == 1:
            rival_city = city
            break
    if rival_city.is_empty():
        _fail("Capital rival ausente")
        return
    var economic: Dictionary = AI.choose(game, rival_city)
    if str(economic["kind"]) != "market":
        _fail("Rival não dá prioridade inicial à economia: " + str(economic))
        return
    game.diplomacy["peace_turns"] = 8
    var peaceful: Dictionary = AI.choose(game, rival_city)
    if str(peaceful["kind"]) != "market":
        _fail("Rival não desenvolve Mercado durante paz")
        return
    var warrior: Dictionary = {}
    for unit in game.units:
        if int(unit["owner"]) == 0 and str(unit["kind"]) == "warrior":
            warrior = unit
            break
    if warrior.is_empty():
        _fail("Guerreiro para ameaça não existe")
        return
    var threat_cell: Vector2i = Vector2i(-1, -1)
    for cell in world.tiles:
        if Nav.distance(cell, rival_city["coords"]) >= 2 and Nav.distance(cell, rival_city["coords"]) <= 3 and Nav.movement_cost(world.tiles[cell]) > 0:
            if game.unit_at(cell).is_empty():
                threat_cell = cell
                break
    if threat_cell.x < 0:
        _fail("Não se encontrou terreno para ameaça diplomática")
        return
    warrior["coords"] = threat_cell
    game.diplomacy["peace_turns"] = 0
    var defensive: Dictionary = AI.choose(game, rival_city)
    if str(defensive["kind"]) != "archer":
        _fail("Rival não reage à aproximação hostil com arqueiros: " + str(defensive))
        return
    rival_city["project"] = ""
    rival_city["site"] = Vector2i(-1, -1)
    game._rival_planning()
    if str(rival_city["project"]) != "archer" or not str(game.rival_goal).contains("arqueiros"):
        _fail("A decisão militar não foi executada na produção real")
        return
    game._draw_models()
    var produced: bool = false
    for i in range(15):
        game.end_turn()
        for unit in game.units:
            if int(unit["owner"]) == 1 and str(unit["kind"]) == "archer":
                produced = true
                break
        if produced:
            break
    if not produced:
        _fail("A IA não produziu um arqueiro")
        return
    if not game.save_game() or not game.load_game():
        _fail("O estado da IA não foi guardado")
        return
    if str(game.rival_goal) == "":
        _fail("O objetivo estratégico perdeu-se na gravação")
        return
    print("M16_SMOKE_OK: rival económico em paz, reação militar, arqueiros e gravação")
    quit(0)
