extends SceneTree
## Galeria do jogo real: cada PNG é uma captura do motor Godot em execução.
## Algumas cenas são preparadas em testes (fundação, construção, combate, investigação).
## Não cria mockups nem modifica as regras da partida.

const DistrictRules = preload("res://scripts/district_rules.gd")
const Navigation = preload("res://scripts/hex_navigation.gd")


func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    push_error("GALERIA: " + message)
    quit(1)


func _shot(label: String) -> bool:
    for i in range(5):
        await process_frame
    RenderingServer.force_draw()
    await process_frame
    var image: Image = root.get_texture().get_image()
    if image == null or image.get_width() < 1200 or image.get_height() < 700:
        return false
    var err: Error = image.save_png("res://%s.png" % label)
    if err != OK:
        return false
    print("GALERIA_PRINT_OK: ", label, " ", image.get_width(), "x", image.get_height())
    return true


func _run() -> void:
    var packed: PackedScene = load("res://scenes/World.tscn")
    if packed == null:
        _fail("World.tscn não carregou")
        return
    var world: Node3D = packed.instantiate()
    root.add_child(world)
    await process_frame
    var game: Node = world.get_node("Game")
    var cam: Camera3D = world.get_node("CameraRig/Camera3D")
    var hud: Node = world.get_node("GameUI")
    if game == null or cam == null or hud == null:
        _fail("Partida, câmara ou interface ausentes")
        return

    var settler: Dictionary = game.get_active()
    world.rig.center_on(world.tiles[settler["coords"]]["position"])
    cam.size = 20.5
    if not await _shot("galeria_01_exploracao"):
        _fail("Captura 01 falhou")
        return

    if not game.can_found():
        _fail("Não foi possível fundar capital")
        return
    game.found_city()
    var city: Dictionary = game.get_selected_city()
    var center: Vector3 = world.tiles[city["coords"]]["position"]
    world.rig.center_on(center)
    cam.size = 12.5
    if not await _shot("galeria_02_capital_3d"):
        _fail("Captura 02 falhou")
        return

    # Estaleiro: construir um Mercado em terreno válido.
    var site: Vector2i = Vector2i(-1, -1)
    for cell in world.tiles:
        if DistrictRules.can_place("market", cell, city, world.tiles, game.cities, game.districts):
            site = cell
            break
    if site.x < 0 or not game.choose_district("market") or not game.confirm_district(site):
        _fail("Não foi possível preparar o estaleiro do Mercado")
        return
    if not game.choose_technology("agriculture"):
        _fail("Não foi possível escolher Agricultura")
        return
    game.end_turn()
    game.end_turn()
    var construction: Node = game.get_node_or_null("ModelosDeJogo/Obra_%d" % int(city["id"]))
    if construction == null:
        _fail("O estaleiro não apareceu no mapa")
        return
    world.rig.center_on(center.lerp(world.tiles[site]["position"], 0.40))
    cam.size = 15.5
    if not await _shot("galeria_03_estaleiro"):
        _fail("Captura 03 falhou")
        return

    for i in range(22):
        if str(city["project"]) == "":
            break
        game.end_turn()
    if game.districts.is_empty():
        _fail("O Mercado não concluiu")
        return
    world.rig.center_on(center.lerp(world.tiles[site]["position"], 0.40))
    cam.size = 15.5
    if not await _shot("galeria_04_distrito_concluido"):
        _fail("Captura 04 falhou")
        return

    # Em modo de inspeção, aproximar a câmara de uma faixa costeira visível.
    var coast: Vector2i = Vector2i(-1, -1)
    var score: int = 999999
    for cell in world.tiles:
        if not bool(world.tiles[cell]["water"]):
            continue
        var coast_near_land: bool = false
        for nearby in Navigation.neighbors(cell):
            if world.tiles.has(nearby) and not bool(world.tiles[nearby]["water"]):
                coast_near_land = true
                break
        if coast_near_land:
            var d: int = Navigation.distance(city["coords"], cell)
            if d < score:
                score = d
                coast = cell
    if coast.x >= 0:
        # O nevoeiro é ocultado apenas para fotografar a geometria costeira;
        # não altera a descoberta do jogador nem a gravação.
        var fog: Node3D = game.get_node("NevoeiroDaExploracao")
        fog.visible = false
        world.rig.center_on(world.tiles[coast]["position"])
        cam.size = 13.5
        if not await _shot("galeria_05_costa_3d"):
            _fail("Captura 05 falhou")
            return
        fog.visible = true

    # Confronto realmente simulado com danos e o efeito temporário ativo.
    game.next_player_unit()
    var warrior: Dictionary = game.get_active()
    if warrior.is_empty() or str(warrior["kind"]) != "warrior":
        _fail("O guerreiro não foi selecionado")
        return
    var enemy_cell: Vector2i = Vector2i(-1, -1)
    for cell in Navigation.neighbors(warrior["coords"]):
        if world.tiles.has(cell) and Navigation.movement_cost(world.tiles[cell]) > 0:
            if game.unit_at(cell).is_empty() and cell != site and cell != city["coords"]:
                enemy_cell = cell
                break
    if enemy_cell.x < 0:
        _fail("Não existe terreno livre para o confronto")
        return
    game._spawn_unit(1, "warrior", enemy_cell)
    warrior["move_points"] = 3
    if not game.issue_order(enemy_cell):
        _fail("Falhou o confronto simulado")
        return
    if game.get_node_or_null("CombateVisual/ImpactoCombate") == null:
        _fail("Efeito de combate 3D não foi instanciado")
        return
    world.rig.center_on(world.tiles[warrior["coords"]]["position"].lerp(world.tiles[enemy_cell]["position"], 0.50))
    cam.size = 13.5
    if not await _shot("galeria_06_combate_dano"):
        _fail("Captura 06 falhou")
        return

    # Janela tecnológica é a interface real, ativada no Godot.
    world.rig.center_on(center)
    cam.size = 19.0
    hud.call("_open_research")
    if not await _shot("galeria_07_tecnologias"):
        _fail("Captura 07 falhou")
        return
    hud.call("_close_research")

    cam.size = 22.0
    world.rig.center_on(center)
    if not await _shot("galeria_08_mundo_final"):
        _fail("Captura 08 falhou")
        return
    print("GALERIA_COMPLETA_OK: 8 prints do Aurora produzidos pelo Godot 4.7.2")
    quit(0)
