extends SceneTree
## M7: pré-requisitos, economia, ataque e persistência de investigação.
const Tech = preload("res://scripts/technology_rules.gd")
const CityRules = preload("res://scripts/city_rules.gd")


func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    push_error("M7: " + message)
    quit(1)


func _run() -> void:
    var scene: PackedScene = load("res://scenes/World.tscn")
    if scene == null:
        _fail("Cena do jogo não carregou")
        return
    var world: Node3D = scene.instantiate()
    root.add_child(world)
    await process_frame
    var game: Node = world.get_node("Game")
    var ui: Node = world.get_node_or_null("GameUI/InterfaceDeJogo")
    if ui == null or ui.get_node_or_null("PainelInvestigacao") == null:
        _fail("Não existe painel de investigação na interface")
        return
    if ui.get_node_or_null("ArvoreTecnologica/") == null:
        _fail("Não existe janela de árvore tecnológica")
        return
    if game.choose_technology("writing") or game.choose_technology("commerce"):
        _fail("Tecnologia com pré-requisitos foi desbloqueada cedo demais")
        return
    if not game.choose_technology("agriculture"):
        _fail("A investigação inicial foi recusada")
        return
    game.found_city()
    var city: Dictionary = game.get_selected_city()
    if city.is_empty():
        _fail("Cidade não foi fundada")
        return
    game.end_turn()
    if int(game.research_progress.get("agriculture", 0)) <= 0:
        _fail("Os turnos não contribuem ciência para a investigação")
        return

    # Acelerar os restantes pontos para testar as regras sem executar 150 turnos.
    game._add_research(Tech.cost("agriculture"))
    if not game.researched.has("agriculture") or game.current_technology != "":
        _fail("A tecnologia de Agricultura não foi concluída")
        return
    var neutral: Dictionary = CityRules.evaluate(city, world.tiles, game.cities, game.districts)
    var improved: Dictionary = game.get_city_yields(city)
    if int(improved["food_surplus"]) != int(neutral["food_surplus"]) + 1:
        _fail("A Agricultura não melhora o rendimento alimentar")
        return
    if not game.choose_technology("writing"):
        _fail("A Escrita continua bloqueada após Agricultura")
        return
    game._add_research(4)
    var partial: int = int(game.research_progress["writing"])
    if not game.save_game():
        _fail("Não se conseguiu guardar a investigação em curso")
        return
    game._new_session()
    if not game.load_game() or game.current_technology != "writing":
        _fail("A investigação não foi restaurada")
        return
    if int(game.research_progress["writing"]) != partial or not game.researched.has("agriculture"):
        _fail("O progresso da investigação perdeu-se na gravação")
        return
    city = game.get_selected_city()
    game._add_research(Tech.cost("writing"))
    if not game.researched.has("writing"):
        _fail("A Escrita não foi desbloqueada")
        return
    if int(game.get_city_yields(city)["science"]) < int(CityRules.evaluate(city, world.tiles, game.cities, game.districts)["science"]) + 2:
        _fail("A Escrita não aumenta a ciência")
        return
    if not game.choose_technology("mining"):
        _fail("Não foi possível estudar Mineração")
        return
    game._add_research(Tech.cost("mining"))
    var after_mining: Dictionary = game.get_city_yields(city)
    if int(after_mining["production"]) < int(CityRules.evaluate(city, world.tiles, game.cities, game.districts)["production"]) + 2:
        _fail("A Mineração não aumenta a produção")
        return
    if not game.choose_technology("metallurgy"):
        _fail("A Metalurgia não foi desbloqueada após Mineração")
        return
    game._add_research(Tech.cost("metallurgy"))
    if int(game.technology_attack_bonus(0)) != 8 or int(game.technology_attack_bonus(1)) != 0:
        _fail("A Metalurgia não modifica corretamente o combate")
        return
    if not game.choose_technology("commerce"):
        _fail("O Comércio não desbloqueou após Escrita")
        return
    game._add_research(Tech.cost("commerce"))
    if int(game.get_city_yields(city)["gold"]) < int(CityRules.evaluate(city, world.tiles, game.cities, game.districts)["gold"]) + 3:
        _fail("O Comércio não aumenta o ouro")
        return
    if not game.choose_technology("engineering"):
        _fail("A Engenharia não desbloqueou com os pré-requisitos")
        return
    game._add_research(Tech.cost("engineering"))
    if game.researched.size() != 6:
        _fail("A árvore tecnológica não concluiu todas as seis tecnologias")
        return
    if not game.save_game() or not game.load_game() or game.researched.size() != 6:
        _fail("O arquivo não preservou as tecnologias concluídas")
        return
    print("M7_SMOKE_OK: seis tecnologias, pré-requisitos, rendimentos, combate e gravação")
    quit(0)
