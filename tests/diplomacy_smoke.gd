extends SceneTree
## M9: encontro, oferta, paz, caravana, bloqueio de ataques e gravação.

const Navigation = preload("res://scripts/hex_navigation.gd")


func _initialize() -> void:
    call_deferred("_run")


func _fail(reason: String) -> void:
    push_error("M9: " + reason)
    quit(1)


func _run() -> void:
    var packed: PackedScene = load("res://scenes/World.tscn")
    if packed == null:
        _fail("World não abriu")
        return
    var world: Node = packed.instantiate()
    root.add_child(world)
    await process_frame
    var game: Node = world.get_node("Game")
    var strategy: Node = world.get_node_or_null("GameUI/InterfaceDeJogo/PaineisEstrategia")
    if strategy == null or strategy.get_node_or_null("DiplomaciaComercio") == null:
        _fail("Painel diplomático inexistente")
        return
    if game.has_contact() or game.can_trade():
        _fail("Contacto com rival antes de fundar capitais")
        return
    game.found_city()
    for i in range(2):
        game.end_turn()
    if not game.has_contact() or game.city_count(1) != 1:
        _fail("Rival não fundou capital para diplomacia")
        return
    if game.negotiate_peace() or game.start_trade():
        _fail("Aceitou tratado ou caravana sem requisitos")
        return
    var treasury_before: int = int(game.treasury)
    if not game.send_gift() or int(game.treasury) != treasury_before - 25:
        _fail("Oferta de 25 ouro não funcionou")
        return
    if int(game.diplomacy["relations"]) < 0:
        _fail("Relações não melhoraram")
        return
    if not game.negotiate_peace() or not game.is_at_peace():
        _fail("Tratado de paz não foi aceite")
        return
    if not game.start_trade() or int(game.diplomacy["trade_turns"]) <= 0:
        _fail("Caravana não ficou ativa")
        return
    var gold_before: int = int(game.treasury)
    var culture_before: int = int(game.accumulated_culture)
    var city: Dictionary = game.get_selected_city()
    var income: int = int(game.get_city_yields(city)["gold"])
    game.end_turn()
    if int(game.treasury) != gold_before + income + 5:
        _fail("A caravana não adicionou 5 ouro ao rendimento real")
        return
    if int(game.accumulated_culture) < culture_before + 1:
        _fail("A caravana não deu intercâmbio cultural")
        return

    game.next_player_unit()
    var warrior: Dictionary = game.get_active()
    if str(warrior.get("kind", "")) != "warrior":
        _fail("Guerreiro não selecionável")
        return
    var cell: Vector2i = Vector2i(-1, -1)
    for neighbor in Navigation.neighbors(warrior["coords"]):
        if world.tiles.has(neighbor) and Navigation.movement_cost(world.tiles[neighbor]) > 0:
            if game.unit_at(neighbor).is_empty():
                cell = neighbor
                break
    if cell.x < 0:
        _fail("Não existe local para confronto adjacente")
        return
    game._spawn_unit(1, "warrior", cell)
    var rival: Dictionary = game.units.back()
    warrior["move_points"] = 3
    if game.issue_order(cell) or int(rival["health"]) != 100:
        _fail("O tratado não bloqueou o ataque")
        return
    var remaining: int = int(game.diplomacy["trade_turns"])
    if not game.save_game() or not game.load_game():
        _fail("Gravação/restauro diplomático falhou")
        return
    if not game.is_at_peace() or int(game.diplomacy["trade_turns"]) != remaining:
        _fail("Paz ou caravana perderam-se na gravação")
        return
    warrior = game.get_active()
    if not game.declare_war() or game.is_at_peace() or int(game.diplomacy["trade_turns"]) != 0:
        _fail("Declaração de guerra não terminou os acordos")
        return
    warrior["move_points"] = 3
    if not game.issue_order(cell):
        _fail("Ataque não voltou a ser permitido após declaração de guerra")
        return
    if int(rival["health"]) >= 100:
        _fail("Inimigo não sofreu dano após retomar guerra")
        return
    strategy.call("open_diplomacy")
    if not strategy.get_node("DiplomaciaComercio").visible:
        _fail("Janela diplomática não abre")
        return
    print("M9_SMOKE_OK: encontro, oferta, paz, caravana, combate bloqueado e persistência")
    quit(0)
