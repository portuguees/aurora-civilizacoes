extends SceneTree
const CityRules = preload("res://scripts/city_rules.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("M14: " + message)
    quit(1)

func _run() -> void:
    var world: Node3D = load("res://scenes/World.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var game: Node = world.get_node("Game")
    game.found_city()
    var city: Dictionary = game.get_selected_city()
    if game.choose_policy("militia") or game.choose_policy("agrarian"):
        _fail("Carta disponível sem pré-requisitos")
        return
    var normal: Dictionary = game.get_city_yields(city)
    game.civics_completed.append("oral_tradition")
    if not game.choose_policy("agrarian"):
        _fail("Política Colheitas recusada")
        return
    var agrarian: Dictionary = game.get_city_yields(city)
    if int(agrarian["food_surplus"]) != int(normal["food_surplus"]) + 1:
        _fail("Colheitas não acrescentou alimento (+1 político)")
        return
    game.civics_completed.append("common_law")
    if not game.choose_policy("administration"):
        _fail("Administração não desbloqueou")
        return
    var economy: Dictionary = game.get_city_yields(city)
    if int(economy["gold"]) != int(normal["gold"]) + 2:
        _fail("Bónus de ouro da Administração incorreto")
        return
    if int(economy["food_surplus"]) != int(normal["food_surplus"]):
        _fail("As duas cartas ficaram ativas ao mesmo tempo")
        return
    game.civics_completed.append("artisan_guilds")
    if not game.choose_policy("militia") or game.technology_attack_bonus(0) != 5:
        _fail("A Milícia não acrescentou força aos ataques")
        return
    if not game.save_game() or not game.load_game() or game.active_policy != "militia":
        _fail("Carta ativa não foi preservada")
        return
    if not game.choose_policy("") or game.technology_attack_bonus(0) != 0:
        _fail("Não foi possível retirar a carta")
        return
    var strategic: Node = world.get_node_or_null("GameUI/InterfaceDeJogo/PaineisEstrategia")
    if strategic == null or strategic.get_node_or_null("CivilizacoesCivicas/Conteudo/Coluna") == null:
        _fail("Painel de políticas desapareceu")
        return
    print("M14_SMOKE_OK: três políticas, pré-requisitos, bónus exclusivos e gravação")
    quit(0)
