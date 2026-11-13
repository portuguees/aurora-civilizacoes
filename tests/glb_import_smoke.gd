extends SceneTree
## Contrato de GLB original com rig articulado e dois clips. Sem dependência da cena do jogo.


func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    push_error("M4 GLB: " + message)
    quit(1)


func _run() -> void:
    var models: Array[String] = [
        "res://assets/models/warrior_animated.glb",
        "res://assets/models/settler_animated.glb"
    ]
    for path in models:
        var asset: Resource = load(path)
        if asset == null or not asset is PackedScene:
            _fail("Falhou importação glTF/GLB: " + path)
            return
        var scene: Node = (asset as PackedScene).instantiate()
        root.add_child(scene)
        var players: Array[Node] = scene.find_children("*", "AnimationPlayer", true, false)
        var armature: Node = scene.find_child("Armature", true, false)
        var left_arm: Node = scene.find_child("Arm_L", true, false)
        var meshes: Array[Node] = scene.find_children("*", "MeshInstance3D", true, false)
        if meshes.is_empty():
            _fail("Ficheiro importado sem modelo 3D: " + path)
            return
        if armature == null or left_arm == null:
            _fail("Ficheiro importado sem articulações Armature/Arm_L: " + path)
            return
        if players.is_empty():
            _fail("Ficheiro importado sem AnimationPlayer: " + path)
            return
        var anims: PackedStringArray = (players[0] as AnimationPlayer).get_animation_list()
        if anims.size() < 2:
            _fail("Faltam as duas animações Walk / Idle: " + path + " -> " + str(anims))
            return
        print("M4_GLB_MODEL_OK: ", path, " | meshes=", meshes.size(), " armature=", armature.name, " animacoes=", anims)
        root.remove_child(scene)
        scene.queue_free()
    print("M4_DEBUG: GLB isolados aprovados. A carregar World.tscn...")
    var world_scene: PackedScene = load("res://scenes/World.tscn")
    if world_scene == null:
        _fail("O mapa não carregou com os GLB")
        return
    print("M4_DEBUG: World.tscn carregada; a instanciar...")
    var world: Node = world_scene.instantiate()
    print("M4_DEBUG: cena instanciada; a adicionar à árvore...")
    root.add_child(world)
    print("M4_DEBUG: mundo adicionado")
    print("M4_DEBUG: aguardando próximo frame")
    await process_frame
    print("M4_DEBUG: frame recebido")
    var game: Node = world.get_node_or_null("Game")
    if game == null:
        _fail("O núcleo da partida não iniciou")
        return
    print("M4_DEBUG: núcleo carregado, unidades=", game.unit_count())
    var warrior: Node = game.get_node_or_null("ModelosDeJogo/Unidade_2_warrior")
    var settler: Node = game.get_node_or_null("ModelosDeJogo/Unidade_1_settler")
    if warrior == null or settler == null:
        _fail("Os modelos das unidades desapareceram do turno inicial")
        return
    if not warrior.has_method("get_imported_animator_count") or int(warrior.call("get_imported_animator_count")) != 4:
        _fail("A formação guerreira não tem quatro animadores GLB: preparados=" + str(warrior.call("get_imported_animator_count")) + " em arvore=" + str(warrior.find_children("*", "AnimationPlayer", true, false).size()) + " soldados=" + str(warrior.get_children().size()))
        return
    if not settler.has_method("get_imported_animator_count") or int(settler.call("get_imported_animator_count")) != 2:
        _fail("O colono não tem dois personagens GLB animados")
        return
    warrior.call("begin_march")
    var players: Array[Node] = warrior.find_children("*", "AnimationPlayer", true, false)
    for node in players:
        var player: AnimationPlayer = node as AnimationPlayer
        if not str(player.current_animation).ends_with("Walk"):
            _fail("O comando de movimento não ativou o clip Walk")
            return
    warrior.call("end_march")
    for node in players:
        var player: AnimationPlayer = node as AnimationPlayer
        if not str(player.current_animation).ends_with("Idle"):
            _fail("O fim de movimento não reativou o clip Idle")
            return
    print("M4_GLB_INTEGRACAO_OK: quatro guerreiros, dois colonos e transições Walk/Idle")
    print("M4_GLB_OK: modelos GLB, articulações e clips de animação importados no Godot")
    quit(0)
