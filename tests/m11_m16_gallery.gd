extends SceneTree
## Seis situações representativas, capturadas diretamente no Godot 4.7.2.
## Algumas unidades e condições são preparadas pelo teste para fotografar mecânicas.

const DistrictRules = preload("res://scripts/district_rules.gd")
const Nav = preload("res://scripts/hex_navigation.gd")


func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    push_error("GALERIA M11-M16: " + message)
    quit(1)


func _shot(filename: String) -> bool:
    for i in range(5):
        await process_frame
    RenderingServer.force_draw()
    await process_frame
    var img: Image = root.get_texture().get_image()
    if img == null or img.get_width() < 1200 or img.get_height() < 700:
        return false
    if img.save_png("res://%s.png" % filename) != OK:
        return false
    print("SIX_PRINT_OK: ", filename, " ", img.get_width(), "x", img.get_height())
    return true


func _run() -> void:
    var packed: PackedScene = load("res://scenes/World.tscn")
    if packed == null:
        _fail("A cena principal não abriu")
        return
    var world: Node3D = packed.instantiate()
    root.add_child(world)
    await process_frame
    var game: Node = world.get_node("Game")
    var camera: Camera3D = world.get_node("CameraRig/Camera3D")
    var strategy: Node = world.get_node_or_null("GameUI/InterfaceDeJogo/PaineisEstrategia")
    if game == null or strategy == null:
        _fail("Não se encontrou jogo ou painel")
        return

    # M11: depositos de recursos visíveis em todo o mundo.
    var best: Vector2i = Vector2i(-1, -1)
    for cell in world.tiles:
        if str(world.tiles[cell].get("resource", "")) in ["iron", "wheat", "horses"]:
            best = cell
            break
    if best.x < 0:
        _fail("Não existem recursos visuais")
        return
    var fog: Node = game.get_node("NevoeiroDaExploracao")
    fog.visible = false
    world.rig.center_on(world.tiles[best]["position"])
    camera.size = 18.0
    if not await _shot("six_01_recursos"):
        _fail("Print M11 falhou")
        return
    fog.visible = true

    # M12: cenário com quinta erguida por um construtor com cargas.
    if not game.can_found():
        _fail("O colono inicial não pode fundar")
        return
    game.found_city()
    var city: Dictionary = game.get_selected_city()
    var farm: Vector2i = Vector2i(-1, -1)
    for cell in world.tiles:
        if DistrictRules.can_place("farm", cell, city, world.tiles, game.cities, game.districts) and game.unit_at(cell).is_empty():
            farm = cell
            break
    if farm.x < 0:
        _fail("Não se encontrou parcela agrícola")
        return
    game._spawn_unit(0, "builder", farm)
    var builder: Dictionary = game.units.back()
    game.active_unit_id = int(builder["id"])
    if not game.builder_improve("farm"):
        _fail("A quinta não foi criada pelo construtor")
        return
    world.rig.center_on(world.tiles[city["coords"]]["position"].lerp(world.tiles[farm]["position"], 0.50))
    camera.size = 14.5
    if not await _shot("six_02_construtores"):
        _fail("Print M12 falhou")
        return

    # M13: arqueiro a disparar a dois hexágonos, com dano real e visual.
    var origin: Vector2i = city["coords"]
    if not game.unit_at(origin).is_empty():
        for alternative in Nav.neighbors(origin):
            if world.tiles.has(alternative) and Nav.movement_cost(world.tiles[alternative]) > 0:
                if game.unit_at(alternative).is_empty():
                    origin = alternative
                    break
    game._spawn_unit(0, "archer", origin)
    var archer: Dictionary = game.units.back()
    var target: Vector2i = Vector2i(-1, -1)
    for cell in world.tiles:
        if Nav.distance(origin, cell) == 2 and Nav.movement_cost(world.tiles[cell]) > 0:
            if game.unit_at(cell).is_empty():
                target = cell
                break
    if target.x < 0:
        _fail("Arqueiro sem alvo a dois hexágonos")
        return
    game._spawn_unit(1, "warrior", target)
    game.active_unit_id = int(archer["id"])
    game._draw_models()
    if not game.issue_order(target):
        _fail("O disparo a dois hexágonos falhou")
        return
    world.rig.center_on(world.tiles[origin]["position"].lerp(world.tiles[target]["position"], 0.48))
    camera.size = 15.0
    if not await _shot("six_03_arqueiros"):
        _fail("Print M13 falhou")
        return

    # M14: política económica realmente selecionada dentro do painel.
    game.civics_completed.append("oral_tradition")
    game.civics_completed.append("common_law")
    if not game.choose_policy("administration"):
        _fail("Política Administração não foi ativada")
        return
    world.rig.center_on(world.tiles[city["coords"]]["position"])
    camera.size = 21.0
    strategy.call("open_civics")
    if not await _shot("six_04_politicas"):
        _fail("Print M14 falhou")
        return
    strategy.call("close_all")

    # M15: construção verdadeira por turnos do Observatório.
    game.researched.append("writing")
    game.selected_city_id = int(city["id"])
    if not game.queue_wonder("sky_observatory"):
        _fail("Observatório não entrou na fila")
        return
    for i in range(40):
        if not game.wonders.is_empty():
            break
        game.end_turn()
    if game.wonders.is_empty():
        _fail("O Observatório não foi concluído")
        return
    world.rig.center_on(world.tiles[city["coords"]]["position"])
    camera.size = 14.5
    if not await _shot("six_05_maravilhas"):
        _fail("Print M15 falhou")
        return

    # M16: demonstrar no painel a mudança de objetivo da IA.
    var enemy_city: Dictionary = {}
    for candidate in game.cities:
        if int(candidate["owner"]) == game.RIVAL:
            enemy_city = candidate
            break
    if enemy_city.is_empty():
        _fail("Valdoria não tem capital")
        return
    var threatened: Vector2i = Vector2i(-1, -1)
    for cell in world.tiles:
        if Nav.distance(cell, enemy_city["coords"]) >= 2 and Nav.distance(cell, enemy_city["coords"]) <= 3:
            if Nav.movement_cost(world.tiles[cell]) > 0 and game.unit_at(cell).is_empty():
                threatened = cell
                break
    if threatened.x < 0:
        _fail("Sem local para aproximar a formação")
        return
    var player_warrior: Dictionary = {}
    for unit in game.units:
        if int(unit["owner"]) == game.PLAYER and str(unit["kind"]) == "warrior":
            player_warrior = unit
            break
    if player_warrior.is_empty():
        _fail("Não existe guerreiro para testar a ameaça")
        return
    player_warrior["coords"] = threatened
    game.diplomacy["peace_turns"] = 0
    enemy_city["project"] = ""
    enemy_city["site"] = Vector2i(-1, -1)
    game._rival_planning()
    if str(enemy_city["project"]) != "archer":
        _fail("IA não reagiu com um arqueiro")
        return
    game._draw_models()
    game.state_changed.emit()
    world.rig.center_on(world.tiles[enemy_city["coords"]]["position"])
    camera.size = 18.5
    strategy.call("open_diplomacy")
    if not await _shot("six_06_ia_reativa"):
        _fail("Print M16 falhou")
        return
    print("SIX_GALLERY_OK: seis capturas originais do Godot M11-M16")
    quit(0)
