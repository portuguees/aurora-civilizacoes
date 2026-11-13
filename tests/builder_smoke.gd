extends SceneTree
const DistrictRules = preload("res://scripts/district_rules.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("M12: " + message)
    quit(1)

func _run() -> void:
    var world: Node3D = load("res://scenes/World.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var game: Node = world.get_node("Game")
    game.found_city()
    if not game.queue_unit("builder"):
        _fail("A capital não iniciou produção de construtor")
        return
    var worker: Dictionary = {}
    for i in range(18):
        game.end_turn()
        for unit in game.units:
            if int(unit["owner"]) == 0 and str(unit["kind"]) == "builder":
                worker = unit
                break
        if not worker.is_empty():
            break
    if worker.is_empty() or int(worker["charges"]) != 2:
        _fail("O construtor não surgiu com duas cargas")
        return
    var worker_id: int = int(worker["id"])
    game.active_unit_id = worker_id
    var city: Dictionary = game.get_selected_city()
    var farm: Vector2i = Vector2i(-1, -1)
    for cell in world.tiles:
        if DistrictRules.can_place("farm", cell, city, world.tiles, game.cities, game.districts) and game.unit_at(cell).is_empty():
            farm = cell
            break
    if farm.x < 0:
        _fail("Não se encontrou parcela agrícola válida")
        return
    worker["coords"] = farm
    worker["move_points"] = 2
    game._draw_models()
    if not game.builder_can_improve("farm") or not game.builder_improve("farm"):
        _fail("Construtor não conseguiu erguer Quinta")
        return
    if int(worker["charges"]) != 1 or game.districts.size() != 1:
        _fail("Quinta não gastou exatamente uma carga")
        return
    if not game.save_game():
        _fail("Construtor não foi guardado")
        return
    game._new_session()
    if not game.load_game():
        _fail("Construtor não foi restaurado")
        return
    worker = game.get_active()
    if worker.is_empty() or str(worker["kind"]) != "builder" or int(worker["charges"]) != 1:
        _fail("Cargas perdidas na gravação")
        return
    game.end_turn()
    city = game.get_selected_city()
    var next_farm: Vector2i = Vector2i(-1, -1)
    for cell in world.tiles:
        if DistrictRules.can_place("farm", cell, city, world.tiles, game.cities, game.districts) and game.unit_at(cell).is_empty():
            next_farm = cell
            break
    if next_farm.x >= 0:
        worker["coords"] = next_farm
        worker["move_points"] = 2
        if not game.builder_improve("farm"):
            _fail("Segunda carga não funcionou")
            return
        if game.units.has(worker) or game.districts.size() != 2:
            _fail("Construtor não se consumiu após duas melhorias")
            return
    print("M12_SMOKE_OK: produção, melhorias, cargas, modelos 3D e gravação")
    quit(0)
