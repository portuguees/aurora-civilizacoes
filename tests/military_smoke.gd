extends SceneTree
## Teste de integração M3: movimento por percurso, terreno, nevoeiro, combate e gravação.

const Nav = preload("res://scripts/hex_navigation.gd")


func _initialize() -> void:
    call_deferred("_run")


func _fail(what: String) -> void:
    push_error("M3: " + what)
    quit(1)


func _run() -> void:
    var packed: PackedScene = load("res://scenes/World.tscn")
    if packed == null:
        _fail("Cena World.tscn indisponível")
        return
    var world: Node3D = packed.instantiate()
    root.add_child(world)
    await process_frame
    var game: Node3D = world.get_node("Game")
    if game.unit_count() != 3 or game.discovered_count() == 0:
        _fail("Exército inicial ou descoberta de terreno ausente")
        return
    if game.discovered_count() >= world.tiles.size():
        _fail("Nevoeiro não esconde qualquer hexágono")
        return
    if game.get_node_or_null("NevoeiroDaExploracao/Exploracao/NevoeiroDesconhecido") == null:
        _fail("Não existe nevoeiro visual em MultiMesh")
        return
    if Nav.distance(Vector2i(4, 7), Vector2i(5, 7)) != 1:
        _fail("Distância hexagonal incorreta")
        return

    # Selecionar o guerreiro e encontrar um destino distante de terreno transitável.
    game.next_player_unit()
    var warrior: Dictionary = game.get_active()
    if str(warrior.get("kind", "")) != "warrior":
        _fail("O guerreiro inicial não é selecionável")
        return
    var start_cell: Vector2i = warrior["coords"]
    var initial_known: int = game.discovered_count()
    var target: Vector2i = Vector2i(-1, -1)
    var chosen: Array[Vector2i] = []
    for cell in world.tiles:
        var distance: int = Nav.distance(start_cell, cell)
        if distance < 5 or distance > 9:
            continue
        var path: Array[Vector2i] = Nav.path(world.tiles, game.units, start_cell, cell, int(warrior["id"]))
        if path.size() >= 5 and path.size() <= 12:
            target = cell
            chosen = path
            break
    if target.x < 0:
        _fail("Não se encontrou nenhum destino estratégico navegável")
        return
    if not game.issue_order(target):
        _fail("A ordem de movimento foi rejeitada")
        return
    if warrior["coords"] == start_cell or warrior["route"].is_empty():
        _fail("A unidade não iniciou um percurso de vários turnos")
        return
    if int(warrior["move_points"]) < 0:
        _fail("A unidade ficou com pontos de movimento negativos")
        return

    var remaining_route: int = warrior["route"].size()
    if not game.save_game():
        _fail("Não foi possível guardar uma rota pendente")
        return
    game._new_session()
    if not game.load_game():
        _fail("Não foi possível restaurar rota pendente")
        return
    warrior = game.get_active()
    if int(warrior.get("id", -1)) != 2 or warrior["route"].size() != remaining_route:
        _fail("A gravação perdeu a unidade ou o seu destino")
        return

    for i in range(18):
        if warrior["route"].is_empty():
            break
        game.end_turn()
    if warrior["coords"] != target or not warrior["route"].is_empty():
        _fail("O percurso automático não chegou ao destino")
        return
    if game.discovered_count() <= initial_known:
        _fail("Explorar novas parcelas não revelou mais território")
        return

    # Combate adjacente: um guerreiro com 100 PV não morre num único golpe.
    var adversary_cell: Vector2i = Vector2i(-1, -1)
    for cell in Nav.neighbors(warrior["coords"]):
        if world.tiles.has(cell) and Nav.movement_cost(world.tiles[cell]) > 0:
            if game.unit_at(cell).is_empty():
                adversary_cell = cell
                break
    if adversary_cell.x < 0:
        _fail("Não foi possível preparar uma batalha adjacente")
        return
    game._spawn_unit(1, "warrior", adversary_cell)
    var defender: Dictionary = game.units.back()
    warrior["move_points"] = 3
    warrior["moved"] = false
    if not game.issue_order(adversary_cell):
        _fail("O ataque militar foi recusado")
        return
    if int(defender["health"]) >= 100 or int(defender["health"]) <= 0:
        _fail("O combate não aplicou dano progressivo")
        return
    if int(warrior["health"]) >= 100:
        _fail("O contra-ataque não afetou os pontos de vida")
        return
    if int(warrior["move_points"]) != 0:
        _fail("Atacar não consumiu o movimento da unidade")
        return

    # A interface e o modelo têm de refletir saúde e descoberta.
    await process_frame
    var name: String = "ModelosDeJogo/Unidade_%d_warrior" % int(warrior["id"])
    var model: Node = game.get_node_or_null(name)
    if model == null or model.get_node_or_null("NomeUnidade") == null:
        _fail("O modelo 3D da unidade desapareceu depois do combate")
        return
    if game.get_node_or_null("NevoeiroDaExploracao/Exploracao") == null:
        _fail("O mapa perdeu o estado visual de descoberta")
        return
    print("M3_SMOKE_OK: A*, rotas entre turnos, nevoeiro, gravação e combate progressivo")
    quit(0)
