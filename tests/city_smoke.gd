extends SceneTree
## Smoke test M2: distâncias, trabalho da população, produção e modelos 3D.

const DistrictRules = preload("res://scripts/district_rules.gd")


func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    push_error(message)
    quit(1)


func _run() -> void:
    var packed: PackedScene = load("res://scenes/World.tscn")
    if packed == null:
        _fail("M2: World.tscn não carrega")
        return
    var world: Node = packed.instantiate()
    root.add_child(world)
    await process_frame
    var game: Node = world.get_node_or_null("Game")
    if game == null or not game.can_found():
        _fail("M2: o colono não consegue fundar a capital")
        return
    game.found_city()
    var city: Dictionary = game.get_selected_city()
    if city.is_empty():
        _fail("M2: a cidade não ficou selecionada")
        return
    var first_yields: Dictionary = game.get_city_yields(city)
    if int(first_yields["production"]) < 1 or first_yields["worked"].size() != 1:
        _fail("M2: parcelas trabalhadas não respeitam população 1")
        return

    var site: Vector2i = Vector2i(-1, -1)
    for cell in world.tiles:
        if DistrictRules.can_place("campus", cell, city, world.tiles, game.cities, game.districts):
            site = cell
            break
    if site.x < 0:
        _fail("M2: impossível colocar academia perto da capital")
        return
    if not game.choose_district("campus"):
        _fail("M2: interface não permite escolher a academia")
        return
    if not game.confirm_district(site):
        _fail("M2: colocar academia num hexágono válido falhou")
        return
    if str(city["project"]) != "campus":
        _fail("M2: a academia não ficou na fila de produção")
        return
    if game.districts.size() != 0:
        _fail("M2: academia construída imediatamente, sem produção")
        return
    if game.confirm_district(site):
        _fail("M2: a mesma construção foi aceite duas vezes")
        return

    var before: int = int(first_yields["science"])
    for i in range(35):
        if game.districts.size() > 0:
            break
        game.end_turn()
    if game.districts.size() != 1:
        _fail("M2: obra não foi concluída com produção")
        return
    var finished: Dictionary = game.districts[0]
    if str(finished["kind"]) != "campus" or finished["coords"] != site:
        _fail("M2: distrito construído na parcela errada")
        return
    var after: Dictionary = game.get_city_yields(city)
    if int(after["science"]) <= before:
        _fail("M2: academia não aumentou a ciência")
        return
    await process_frame
    var node_path: String = "ModelosDeJogo/Distrito_%d_campus" % int(finished["id"])
    if game.get_node_or_null(node_path) == null:
        _fail("M2: academia não está visível na cena 3D")
        return
    if game.choose_district("campus"):
        _fail("M2: foi permitida uma academia duplicada")
        return
    if game.placing_district != "":
        _fail("M2: a seleção da obra não foi limpa")
        return
    if game.city_count(1) != 1:
        _fail("M2: a civilização rival deixou de fundar cidade")
        return
    print("M2_SMOKE_OK: cidade, cidadãos, academia em hexágono, produção por turnos, +ciência, modelo 3D")
    quit(0)
