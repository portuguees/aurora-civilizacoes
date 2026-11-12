extends SceneTree
## Teste executado por: godot --headless --path . --script res://tests/smoke.gd

func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    var scene: PackedScene = load("res://scenes/World.tscn")
    if scene == null:
        push_error("M0: cena World.tscn não carregou")
        quit(1)
        return
    var world: Node = scene.instantiate()
    root.add_child(world)
    await process_frame
    if not world.has_method("is_map_ready") or not world.is_map_ready():
        push_error("M0: geração do mapa não terminou")
        quit(1)
        return
    if world.tiles.size() != 32 * 24:
        push_error("M0: número de hexágonos incorreto: " + str(world.tiles.size()))
        quit(1)
        return
    if world.land_count() < 25:
        push_error("M0: mapa quase sem terra")
        quit(1)
        return
    var cam: Camera3D = world.get_node_or_null("CameraRig/Camera3D")
    if cam == null or not cam.current:
        push_error("M0: câmara estratégica não está ativa")
        quit(1)
        return
    var hud: Node = world.get_node_or_null("HUD/HUD_Root")
    if hud == null:
        push_error("M0: HUD não foi criada")
        quit(1)
        return
    if world.get_node_or_null("Terrain/Terras") == null:
        push_error("M0: não existe mesh do terreno")
        quit(1)
        return
    if world.get_node_or_null("Terrain/Florestas") == null:
        push_error("M0: não existe vegetação")
        quit(1)
        return
    print("M0_SMOKE_OK: 768 hexágonos, ", world.land_count(), " em terra; câmara, HUD e mesh presentes")
    quit(0)
