extends SceneTree
## M6: água costeira e estaleiros progressivos devem existir de verdade em 3D.
const DistrictRules = preload("res://scripts/district_rules.gd")


func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    push_error("M6: " + message)
    quit(1)


func _run() -> void:
    var scene: PackedScene = load("res://scenes/World.tscn")
    if scene == null:
        _fail("Cena principal não abriu")
        return
    var world: Node3D = scene.instantiate()
    root.add_child(world)
    await process_frame
    var coasts: Node3D = world.get_node_or_null("Terrain/Costas")
    if coasts == null or int(coasts.get_meta("coastline_edges", 0)) < 10:
        _fail("O mapa não tem linha costeira 3D válida")
        return
    for name in ["AguaRasa", "LinhasDeCosta"]:
        var mesh: Node = coasts.get_node_or_null(name)
        if mesh == null or not mesh is MeshInstance3D:
            _fail("Falta malha da costa: " + name)
            return
    var game: Node = world.get_node("Game")
    game.found_city()
    var city: Dictionary = game.get_selected_city()
    if city.is_empty():
        _fail("Capital não foi fundada")
        return
    var valid: Vector2i = Vector2i(-1, -1)
    for cell in world.tiles:
        if DistrictRules.can_place("market", cell, city, world.tiles, game.cities, game.districts):
            valid = cell
            break
    if valid.x < 0:
        _fail("Não se encontrou terreno para o Mercado")
        return
    if not game.choose_district("market") or not game.confirm_district(valid):
        _fail("Não foi possível colocar um estaleiro válido")
        return
    game.end_turn()
    var site_name: String = "ModelosDeJogo/Obra_%d" % int(city["id"])
    var site: Node = game.get_node_or_null(site_name)
    if site == null or site.get_node_or_null("ProgressoObra") == null:
        _fail("Obra em produção não tem estaleiro 3D")
        return
    var progress1: float = float(site.get_meta("progress_fraction", 0.0))
    if progress1 <= 0.0 or progress1 >= 1.0:
        _fail("O estaleiro não tem progresso intermédio válido")
        return
    game.end_turn()
    site = game.get_node_or_null(site_name)
    if site == null or float(site.get_meta("progress_fraction", 0.0)) <= progress1:
        _fail("O estaleiro não evoluiu com a produção")
        return
    for i in range(20):
        if city["project"] == "":
            break
        game.end_turn()
    if str(city["project"]) != "" or game.districts.size() != 1:
        _fail("A construção não concluiu dentro dos turnos previstos")
        return
    if game.get_node_or_null(site_name) != null:
        _fail("O estaleiro não desapareceu depois da obra")
        return
    var district: Dictionary = game.districts[0]
    if game.get_node_or_null("ModelosDeJogo/Distrito_%d_market" % int(district["id"])) == null:
        _fail("O edifício final 3D não substituiu o estaleiro")
        return
    print("M6_SMOKE_OK: costa, água rasa, estaleiro em progresso e mercado final 3D")
    quit(0)
