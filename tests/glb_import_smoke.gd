extends SceneTree
## Contrato dos modelos GLB originais importados. Sem dependência da cena do jogo.


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
        var skeletons: Array[Node] = scene.find_children("*", "Skeleton3D", true, false)
        var meshes: Array[Node] = scene.find_children("*", "MeshInstance3D", true, false)
        if meshes.is_empty():
            _fail("Ficheiro importado sem modelo 3D: " + path)
            return
        if skeletons.is_empty():
            _fail("Ficheiro importado sem Skeleton3D: " + path)
            return
        if players.is_empty():
            _fail("Ficheiro importado sem AnimationPlayer: " + path)
            return
        var anims: PackedStringArray = (players[0] as AnimationPlayer).get_animation_list()
        if anims.size() < 2:
            _fail("Faltam as duas animações Walk / Idle: " + path + " -> " + str(anims))
            return
        print("M4_GLB_MODEL_OK: ", path, " | meshes=", meshes.size(), " bones=", (skeletons[0] as Skeleton3D).get_bone_count(), " animacoes=", anims)
        root.remove_child(scene)
        scene.queue_free()
    print("M4_GLB_OK: modelos GLB, esqueletos e clips de animação importados no Godot")
    quit(0)
