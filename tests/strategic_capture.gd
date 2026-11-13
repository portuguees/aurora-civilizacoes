extends SceneTree
## Quatro capturas reais Godot M8–M10. Estados preparados por testes.
## São frames do motor, não mockups nem imagens geradas por IA.

const VictoryRules = preload("res://scripts/victory_rules.gd")
const TechnologyRules = preload("res://scripts/technology_rules.gd")


func _initialize() -> void:
    call_deferred("_run")


func _fail(reason: String) -> void:
    push_error("M8-M10 VISUAL: " + reason)
    quit(1)


func _shot(filename: String) -> bool:
    for i in range(7):
        await process_frame
    RenderingServer.force_draw()
    await process_frame
    var captured: Image = root.get_texture().get_image()
    if captured == null or captured.get_width() < 1200:
        return false
    if captured.save_png("res://%s.png" % filename) != OK:
        return false
    print("M8_M10_PRINT_OK: ", filename, " ", captured.get_width(), "x", captured.get_height())
    return true


func _run() -> void:
    var packed: PackedScene = load("res://scenes/World.tscn")
    if packed == null:
        _fail("A cena não carregou")
        return
    var world: Node3D = packed.instantiate()
    root.add_child(world)
    await process_frame
    var game: Node = world.get_node_or_null("Game")
    var strategy: Node = world.get_node_or_null("GameUI/InterfaceDeJogo/PaineisEstrategia")
    if game == null or strategy == null:
        _fail("Jogo ou painéis estratégicos ausentes")
        return
    if not game.can_found():
        _fail("Não é possível fundar capital")
        return
    game.found_city()
    var city: Dictionary = game.get_selected_city()
    world.rig.center_on(world.tiles[city["coords"]]["position"])
    var camera: Camera3D = world.get_node("CameraRig/Camera3D")
    camera.size = 23.0
    if not game.choose_civic("oral_tradition") or not game.choose_technology("agriculture"):
        _fail("Não foi possível escolher pesquisa e princípios cívicos")
        return
    for i in range(11):
        game.end_turn()
    if game.city_count(1) < 1:
        _fail("A IA não fundou Valdoria")
        return
    if not game.civics_completed.has("oral_tradition"):
        game._add_culture(11)
    if not game.choose_civic("common_law"):
        _fail("Não foi possível avançar os princípios")
        return
    game._add_culture(18)
    if not game.choose_government("council"):
        _fail("Não foi possível instaurar Conselho")
        return
    if not await _shot("aurora_m8_mundo"):
        _fail("Captura do mundo M8 falhou")
        return

    strategy.call("open_civics")
    if not strategy.get_node("CivilizacoesCivicas").visible or not await _shot("aurora_m8_cultura"):
        _fail("Painel M8 não abriu ou não foi capturado")
        return
    strategy.call("close_all")

    if not game.send_gift() or not game.negotiate_peace() or not game.start_trade():
        _fail("Diplomacia M9 não conseguiu estabelecer caravana")
        return
    strategy.call("open_diplomacy")
    if not strategy.get_node("DiplomaciaComercio").visible or not await _shot("aurora_m9_diplomacia"):
        _fail("Painel M9 não abriu ou não foi capturado")
        return
    strategy.call("close_all")

    strategy.call("open_victory")
    if not strategy.get_node("ObjetivosVitoria").visible or not await _shot("aurora_m10_objetivos"):
        _fail("Painel M10 não abriu ou não foi capturado")
        return
    strategy.call("close_all")

    game.researched.clear()
    for tech in TechnologyRules.ORDER:
        game.researched.append(tech)
    game.accumulated_science = VictoryRules.SCIENCE_MIN
    game._evaluate_victory()
    game.state_changed.emit()
    if not game.game_over or game.victory_type != "science":
        _fail("A vitória científica não foi declarada")
        return
    if not await _shot("aurora_m10_vitoria_cientifica"):
        _fail("Captura de vitória real não foi criada")
        return

    print("M8_M10_VISUAL_OK: 5 capturas reais (mundo, civismo, diplomacia, objetivos, vitória)")
    quit(0)
