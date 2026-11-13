extends SceneTree
const Resources = preload("res://scripts/resource_rules.gd")
const CityRules = preload("res://scripts/city_rules.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("M11: " + message)
    quit(1)

func _run() -> void:
    var world: Node3D = load("res://scenes/World.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var counts: Dictionary = Resources.count(world.tiles)
    var total: int = 0
    var kinds: int = 0
    for kind in Resources.NAMES:
        var number: int = int(counts[kind])
        total += number
        if number > 0:
            kinds += 1
            if world.get_node_or_null("Terrain/Recursos/Deposito_%s" % kind) == null:
                _fail("Recurso com rendimento mas sem modelo 3D: " + str(kind))
                return
    if total < 12 or kinds < 3:
        _fail("Distribuição insuficiente ou pouco diversa: " + str(counts))
        return
    var sample_cell: Vector2i = Vector2i(-1, -1)
    var sample_kind: String = ""
    for cell in world.tiles:
        if str(world.tiles[cell].get("resource", "")) != "":
            sample_cell = cell
            sample_kind = str(world.tiles[cell]["resource"])
            break
    if sample_cell.x < 0:
        _fail("Nenhum recurso de exemplo")
        return
    var enriched: Dictionary = CityRules.tile_yields(world.tiles[sample_cell])
    var ordinary: Dictionary = world.tiles[sample_cell].duplicate()
    ordinary["resource"] = ""
    var baseline: Dictionary = CityRules.tile_yields(ordinary)
    var bonus: Dictionary = Resources.bonus(sample_kind)
    if int(enriched["food"]) - int(baseline["food"]) != int(bonus["food"]):
        _fail("O recurso não alterou alimento corretamente")
        return
    if int(enriched["production"]) - int(baseline["production"]) != int(bonus["production"]):
        _fail("O recurso não alterou produção corretamente")
        return
    var initial_seed: int = int(world.seed_value)
    world.regenerate(initial_seed)
    if Resources.count(world.tiles) != counts or str(world.tiles[sample_cell]["resource"]) != sample_kind:
        _fail("Recursos mudaram ao regenerar o mesmo mapa")
        return
    print("M11_SMOKE_OK: cinco recursos, modelos 3D, rendimentos e seed determinística")
    quit(0)
