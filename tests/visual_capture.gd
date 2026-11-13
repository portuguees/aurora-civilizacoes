extends SceneTree
## Teste de apresentação executado num servidor X virtual (xvfb), sem --headless.
## Captura um frame do Godot com a capital, um distrito, fronteiras e HUD.

const DistrictRules = preload("res://scripts/district_rules.gd")
const Navigation = preload("res://scripts/hex_navigation.gd")


func _initialize() -> void:
    call_deferred("_capture")


func _fail(message: String) -> void:
    push_error(message)
    quit(1)


func _capture() -> void:
    var packed: PackedScene = load("res://scenes/World.tscn")
    if packed == null:
        _fail("VISUAL: a cena não existe")
        return
    var world: Node3D = packed.instantiate()
    root.add_child(world)
    await process_frame
    var game: Node3D = world.get_node("Game")
    if not game.can_found():
        _fail("VISUAL: o colono não pode fundar")
        return
    game.found_city()
    var city: Dictionary = game.get_selected_city()
    var campus: Vector2i = Vector2i(-1, -1)
    for cell in world.tiles:
        if DistrictRules.can_place("campus", cell, city, world.tiles, game.cities, game.districts):
            campus = cell
            break
    if campus.x < 0 or not game.choose_district("campus") or not game.confirm_district(campus):
        _fail("VISUAL: a Academia não foi colocada")
        return
    for i in range(25):
        game.end_turn()
    if game.districts.is_empty():
        _fail("VISUAL: o distrito não concluiu a construção")
        return
    # Preparar uma situação visual controlada de combate adjacente.
    game.next_player_unit()
    var warrior: Dictionary = game.get_active()
    if warrior.is_empty() or str(warrior["kind"]) != "warrior":
        _fail("VISUAL: não foi possível selecionar os guerreiros")
        return
    var rival_spot: Vector2i = Vector2i(-1, -1)
    for cell in Navigation.neighbors(warrior["coords"]):
        if world.tiles.has(cell) and Navigation.movement_cost(world.tiles[cell]) > 0:
            if game.unit_at(cell).is_empty() and cell != city["coords"] and cell != campus:
                rival_spot = cell
                break
    if rival_spot.x < 0:
        _fail("VISUAL: não existe local para o confronto")
        return
    game._spawn_unit(1, "warrior", rival_spot)
    warrior["move_points"] = 3
    if not game.issue_order(rival_spot):
        _fail("VISUAL: confronto militar recusado")
        return
    if int(warrior["health"]) >= 100:
        _fail("VISUAL: a barra de vida não foi atualizada")
        return
    world.rig.center_on(world.tiles[city["coords"]]["position"])
    var cam: Camera3D = world.get_node("CameraRig/Camera3D")
    cam.size = 20.5

    var unit_model: Node = game.get_node_or_null("ModelosDeJogo/Unidade_2_warrior")
    var city_model: Node = game.get_node_or_null("ModelosDeJogo/Cidade_%d" % int(city["id"]))
    var borders: Node = game.get_node_or_null("EstradasEFronteiras/InfraestruturaImperial/Fronteira_0")
    var roads: Node = game.get_node_or_null("EstradasEFronteiras/InfraestruturaImperial/Estradas")
    if unit_model == null or city_model == null or borders == null or roads == null:
        _fail("VISUAL: faltam guerreiros, cidade, fronteiras ou estradas")
        return
    if city_model.get_node_or_null("FaixaCidade") == null:
        _fail("VISUAL: a cidade está sem faixa de identificação")
        return
    if city_model.get_node_or_null("Arquitetura") == null:
        _fail("VISUAL: os detalhes arquitetónicos M3.5 não foram carregados")
        return
    var forest: Node = world.get_node_or_null("Terrain/Florestas/PinheirosBase")
    if forest == null:
        _fail("VISUAL: floresta detalhada M3.5 ausente")
        return
    if unit_model.get_node_or_null("NomeUnidade") == null:
        _fail("VISUAL: os guerreiros estão sem faixa de identificação")
        return

    for i in range(16):
        await process_frame
    RenderingServer.force_draw()
    await process_frame
    var frame: Image = root.get_texture().get_image()
    if frame == null or frame.get_width() < 700 or frame.get_height() < 400:
        _fail("VISUAL: não foi possível obter uma imagem do jogo")
        return
    var output: String = "res://visual-m35.png"
    if frame.save_png(output) != OK:
        _fail("VISUAL: não foi possível escrever a captura PNG")
        return
    print("M35_VISUAL_OK: cena renderizada ", frame.get_width(), "x", frame.get_height(), "; cidade, combate, barras de vida, nevoeiro, estradas e HUD")
    quit(0)
