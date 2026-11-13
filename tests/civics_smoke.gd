extends SceneTree
## M8: cultura por turno, pré-requisitos, governos, economia e gravação.

const CivicRules = preload("res://scripts/civic_rules.gd")
const CityRules = preload("res://scripts/city_rules.gd")


func _initialize() -> void:
    call_deferred("_run")


func _fail(reason: String) -> void:
    push_error("M8: " + reason)
    quit(1)


func _run() -> void:
    var world_scene: PackedScene = load("res://scenes/World.tscn")
    if world_scene == null:
        _fail("World não abriu")
        return
    var world: Node = world_scene.instantiate()
    root.add_child(world)
    await process_frame
    var game: Node = world.get_node("Game")
    var strategy: Node = world.get_node_or_null("GameUI/InterfaceDeJogo/PaineisEstrategia")
    if strategy == null or strategy.get_node_or_null("CivilizacoesCivicas") == null:
        _fail("Painel de cultura não existe na partida")
        return
    if game.choose_civic("representation") or game.choose_government("republic"):
        _fail("O jogo permite uma instituição sem pré-requisitos")
        return
    if not game.can_found():
        _fail("Colono não pode fundar")
        return
    game.found_city()
    var city: Dictionary = game.get_selected_city()
    if not game.choose_civic("oral_tradition"):
        _fail("Não é possível selecionar Tradição Oral")
        return
    game.end_turn()
    if int(game.civic_progress.get("oral_tradition", 0)) < 1 or game.accumulated_culture < 1:
        _fail("A cidade não gera cultura real")
        return
    game._add_culture(12)
    if not game.civics_completed.has("oral_tradition"):
        _fail("Tradição Oral não foi concluída")
        return
    if int(game.get_city_yields(city)["culture"]) != 1 + int(city["population"]) + 1:
        _fail("Bónus da Tradição Oral não foi aplicado")
        return
    if not game.choose_civic("common_law"):
        _fail("Leis Comuns não desbloqueou")
        return
    game._add_culture(4)
    var progress: int = int(game.civic_progress["common_law"])
    if not game.save_game():
        _fail("Falha a guardar princípios cívicos")
        return
    game._new_session()
    if not game.load_game():
        _fail("Falha a restaurar princípios cívicos")
        return
    if game.current_civic != "common_law" or int(game.civic_progress["common_law"]) != progress:
        _fail("Progresso cultural não sobreviveu à gravação")
        return
    game._add_culture(18)
    if not game.choose_government("council"):
        _fail("Conselho não desbloqueou após Leis Comuns")
        return
    city = game.get_selected_city()
    var neutral: Dictionary = CityRules.evaluate(city, world.tiles, game.cities, game.districts)
    var council: Dictionary = game.get_city_yields(city)
    if int(council["gold"]) < int(neutral["gold"]) + 1 or int(council["culture"]) != 1 + int(city["population"]) + 1 + 1:
        _fail("Governo Conselho não aplicou bónus económico")
        return
    if not game.choose_civic("artisan_guilds"):
        _fail("Guildas indisponíveis com os pré-requisitos")
        return
    game._add_culture(27)
    if not game.choose_civic("heritage"):
        _fail("Património indisponível")
        return
    game._add_culture(36)
    if not game.choose_civic("representation"):
        _fail("Representação não desbloqueou com Leis Comuns e Guildas")
        return
    game._add_culture(46)
    if not game.choose_government("republic"):
        _fail("República não desbloqueou após Representação")
        return
    var republic: Dictionary = game.get_city_yields(city)
    if int(republic["science"]) != int(neutral["science"]) + 1:
        _fail("Bónus científico da República errado")
        return
    if int(republic["gold"]) != int(neutral["gold"]) + 2:
        _fail("Bónus comercial da República errado")
        return
    if int(republic["production"]) != int(neutral["production"]) + 2:
        _fail("Guildas não aumenta produção")
        return
    if game.civics_completed.size() != 5:
        _fail("Árvore de cinco princípios não foi concluída")
        return
    if not game.save_game() or not game.load_game() or game.government != "republic":
        _fail("Governo não foi guardado")
        return
    strategy.call("open_civics")
    if not strategy.get_node("CivilizacoesCivicas").visible:
        _fail("Janela da cultura não abre")
        return
    print("M8_SMOKE_OK: cultura por turnos, 5 princípios, 3 governos, bónus e gravação")
    quit(0)
