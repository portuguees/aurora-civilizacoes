extends SceneTree
## M10: IA económica, condições científicas/culturais/económicas/militares e ecrã de vitória.

const Navigation = preload("res://scripts/hex_navigation.gd")
const VictoryRules = preload("res://scripts/victory_rules.gd")
const TechnologyRules = preload("res://scripts/technology_rules.gd")
const CivicRules = preload("res://scripts/civic_rules.gd")


func _initialize() -> void:
    call_deferred("_run")


func _fail(reason: String) -> void:
    push_error("M10: " + reason)
    quit(1)


func _run() -> void:
    var packed: PackedScene = load("res://scenes/World.tscn")
    if packed == null:
        _fail("Cena World não abriu")
        return
    var world: Node = packed.instantiate()
    root.add_child(world)
    await process_frame
    var game: Node = world.get_node("Game")
    var strategy: Node = world.get_node_or_null("GameUI/InterfaceDeJogo/PaineisEstrategia")
    if strategy == null or strategy.get_node_or_null("ObjetivosVitoria") == null:
        _fail("Ecrã de condições de vitória não existe")
        return
    game.found_city()
    for i in range(10):
        game.end_turn()
    if not game.rival_founded or game.city_count(1) == 0:
        _fail("A IA não fundou a sua capital")
        return
    var has_ai_plan: bool = false
    for city in game.cities:
        if int(city["owner"]) != 1:
            continue
        has_ai_plan = str(city.get("project", "")) != ""
        for built in game.districts:
            if int(built["city_id"]) == int(city["id"]):
                has_ai_plan = true
    if not has_ai_plan:
        _fail("A IA não escolheu nem construiu projetos económicos")
        return

    # Vitória científica verificável e fim de turnos.
    game.researched.clear()
    for key in TechnologyRules.ORDER:
        game.researched.append(key)
    game.accumulated_science = VictoryRules.SCIENCE_MIN
    game._evaluate_victory()
    if not game.game_over or game.victory_type != "science":
        _fail("Não foi obtida vitória científica")
        return
    var stopped: int = game.turns
    game.end_turn()
    if game.turns != stopped:
        _fail("A campanha não terminou após a vitória")
        return
    if not game.save_game() or not game.load_game() or not game.game_over or game.victory_type != "science":
        _fail("A vitória não foi persistida")
        return

    # Recomeçar para verificar via alternativa cultural.
    game._new_session()
    game.found_city()
    for i in range(9):
        game.end_turn()
    for key in CivicRules.ORDER:
        game.civics_completed.append(key)
    game.accumulated_culture = VictoryRules.CULTURE_MIN
    game._evaluate_victory()
    if not game.game_over or game.victory_type != "culture":
        _fail("Não foi obtida vitória cultural")
        return

    # Vitória económica só existe com relação pacífica e caravana ativa.
    game._new_session()
    game.found_city()
    for i in range(9):
        game.end_turn()
    game.treasury = VictoryRules.GOLD_MIN + 5
    game.diplomacy["trade_turns"] = 3
    game._evaluate_victory()
    if game.game_over:
        _fail("Vitória económica sem paz foi indevidamente aceite")
        return
    game.diplomacy["peace_turns"] = 4
    game._evaluate_victory()
    if not game.game_over or game.victory_type != "economic":
        _fail("Vitória económica em paz e com comércio falhou")
        return

    # Vitória militar: guarnição eliminada e guerreiro do jogador junto à capital.
    game._new_session()
    game.found_city()
    for i in range(9):
        game.end_turn()
    var capital: Dictionary = {}
    for city in game.cities:
        if int(city["owner"]) == 1:
            capital = city
            break
    if capital.is_empty():
        _fail("Não existe capital de Valdoria")
        return
    for unit in game.units.duplicate():
        if int(unit["owner"]) == 1:
            game.units.erase(unit)
    var warrior: Dictionary = {}
    for unit in game.units:
        if int(unit["owner"]) == 0 and str(unit["kind"]) == "warrior":
            warrior = unit
            break
    if warrior.is_empty():
        _fail("Não existe guerreiro para a captura")
        return
    var free: Vector2i = Vector2i(-1, -1)
    for cell in Navigation.neighbors(capital["coords"]):
        if world.tiles.has(cell) and Navigation.movement_cost(world.tiles[cell]) > 0:
            if game.unit_at(cell).is_empty():
                free = cell
                break
    if free.x < 0:
        _fail("Não existe passagem para a captura")
        return
    warrior["coords"] = free
    if not game.can_capture_rival():
        _fail("A capital desguarnecida não permite captura")
        return
    game.diplomacy["peace_turns"] = 3
    if game.can_capture_rival():
        _fail("Captura permitida durante tratado de paz")
        return
    game.diplomacy["peace_turns"] = 0
    if not game.capture_rival_capital():
        _fail("Captura do rival falhou")
        return
    if not game.game_over or game.victory_type != "military" or game.city_count(1) != 0:
        _fail("Vitória militar não foi declarada após conquista")
        return
    strategy.call("open_victory")
    if not strategy.get_node("ObjetivosVitoria").visible:
        _fail("Ecrã de vitória não abre")
        return
    print("M10_SMOKE_OK: IA com projetos, 4 vitórias, fim de turnos, captura e gravação")
    quit(0)
