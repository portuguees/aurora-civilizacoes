extends SceneTree
const WonderRules = preload("res://scripts/wonder_rules.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("M15: " + message)
    quit(1)

func _run() -> void:
    var world: Node3D = load("res://scenes/World.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var game: Node = world.get_node("Game")
    game.found_city()
    if game.queue_wonder("sky_observatory"):
        _fail("Observatório disponível sem Escrita")
        return
    game.researched.append("writing")
    var city: Dictionary = game.get_selected_city()
    var baseline: Dictionary = game.get_city_yields(city)
    if not game.queue_wonder("sky_observatory"):
        _fail("Observatório não iniciou após Escrita")
        return
    if game.queue_wonder("sky_observatory"):
        _fail("Maravilha duplicada em duas filas")
        return
    for i in range(40):
        if game.wonders.size() > 0:
            break
        game.end_turn()
    if game.wonders.size() != 1:
        _fail("A maravilha não foi construída")
        return
    var wonder: Dictionary = game.wonders[0]
    if str(wonder["kind"]) != "sky_observatory" or game.queue_wonder("sky_observatory"):
        _fail("Maravilha concluída não é única")
        return
    var improved: Dictionary = game.get_city_yields(city)
    if int(improved["science"]) != int(baseline["science"]) + 5:
        _fail("Observatório não aumentou ciência")
        return
    var model_name: String = "ModelosDeJogo/Maravilha_%d_sky_observatory" % int(wonder["id"])
    if game.get_node_or_null(model_name) == null:
        _fail("Maravilha 3D não apareceu no mapa")
        return
    if not game.save_game() or not game.load_game():
        _fail("Maravilha não foi guardada")
        return
    if game.wonders.size() != 1 or game.get_node_or_null(model_name) == null:
        _fail("Maravilha não foi restaurada")
        return
    # O segundo monumento tem custos e efeitos separados.
    game.researched.append("agriculture")
    if not game.queue_wonder("royal_gardens"):
        _fail("Jardins Reais não disponíveis")
        return
    for i in range(40):
        if game.wonders.size() >= 2:
            break
        game.end_turn()
    if game.wonders.size() != 2:
        _fail("Os Jardins Reais não ficaram construídos")
        return
    if int(game.get_city_yields(game.get_selected_city())["culture"]) < 1 + int(game.get_selected_city()["population"]) + 3:
        _fail("Maravilhas não aumentaram cultura")
        return
    print("M15_SMOKE_OK: maravilhas únicas, pré-requisitos, modelos 3D, bónus e persistência")
    quit(0)
