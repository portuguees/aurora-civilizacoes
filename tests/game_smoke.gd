extends SceneTree
## M1: teste de integração real (Godot) do primeiro ciclo estratégico.

func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    push_error(message)
    quit(1)


func _run() -> void:
    var packed: PackedScene = load("res://scenes/World.tscn")
    if packed == null:
        _fail("M1: cena não foi carregada")
        return
    var world: Node = packed.instantiate()
    root.add_child(world)
    await process_frame
    var game: Node = world.get_node_or_null("Game")
    var ui: Node = world.get_node_or_null("GameUI/InterfaceDeJogo")
    if game == null or ui == null:
        _fail("M1: Game ou interface de jogo ausente")
        return
    if not game.has_starting_units() or game.unit_count() < 3:
        _fail("M1: colono e guerreiro não foram inicializados")
        return
    if game.get_node_or_null("ModelosDeJogo/Unidade_1_settler") == null:
        _fail("M1: modelo 3D do colono não existe")
        return
    if game.get_node_or_null("ModelosDeJogo/Unidade_2_warrior") == null:
        _fail("M1: modelo 3D do guerreiro não existe")
        return
    if not game.can_found():
        _fail("M1: a primeira capital não pode ser fundada")
        return
    game.found_city()
    if game.city_count() != 1:
        _fail("M1: cidade não foi fundada")
        return
    game.queue_warrior()
    for i in range(7):
        game.end_turn()
    if game.turns != 8 or game.player_unit_count() < 2:
        _fail("M1: avanço de turnos ou produção de guerreiro falhou")
        return
    if game.city_count(1) < 1:
        _fail("M1: rival não fundou a capital")
        return
    print("M1_SMOKE_OK: colono, guerreiro, HUD, cidade, produção e turnos")
    quit(0)
