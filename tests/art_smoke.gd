extends SceneTree
const DistrictVisuals = preload("res://scripts/district_visuals.gd")
## Smoke M3.5: os novos detalhes visuais existem como nós 3D reais.


func _initialize() -> void:
    call_deferred("_run")


func _fail(reason: String) -> void:
    push_error("M35: " + reason)
    quit(1)


func _run() -> void:
    var packed: PackedScene = load("res://scenes/World.tscn")
    if packed == null:
        _fail("A cena principal não abriu")
        return
    var world: Node3D = packed.instantiate()
    root.add_child(world)
    await process_frame
    var game: Node = world.get_node_or_null("Game")
    if game == null or world.tiles.size() != 768:
        _fail("O mapa ou a sessão de jogo não arrancou")
        return

    var art: Node = world.get_node_or_null("Terrain/Florestas")
    if art == null:
        _fail("A camada 3D de vegetação não foi criada")
        return
    for name in ["Troncos", "PinheirosBase", "PinheirosTopo", "PedrasDeMontanha", "ReflexosNoMar"]:
        var child: Node = art.get_node_or_null(name)
        if child == null or not child is MultiMeshInstance3D:
            _fail("Falta uma instância MultiMesh: " + name)
            return
        var multi: MultiMesh = (child as MultiMeshInstance3D).multimesh
        if multi == null or multi.instance_count == 0:
            _fail("A malha de " + name + " não tem geometria visível")
            return

    var settler: Node = game.get_node_or_null("ModelosDeJogo/Unidade_1_settler")
    var warrior: Node = game.get_node_or_null("ModelosDeJogo/Unidade_2_warrior")
    if settler == null or warrior == null:
        _fail("Colono ou guerreiro não estão presentes no primeiro turno")
        return
    if warrior.get_node_or_null("Soldado_0") == null or warrior.get_node_or_null("Soldado_3") == null:
        _fail("A formação do guerreiro não tem os quatro soldados")
        return
    if warrior.get_node_or_null("Estandarte") == null or settler.get_node_or_null("Estandarte") == null:
        _fail("Os estandartes 3D não foram criados")
        return
    if not warrior.has_method("begin_march") or not warrior.has_method("end_march"):
        _fail("O script de animação procedural não foi carregado")
        return
    warrior.call("begin_march")
    await process_frame
    if not bool(warrior.get("marching")):
        _fail("A marcha não começou")
        return
    var actor: Node3D = warrior.get_node("Soldado_0")
    var before_pose: float = actor.position.y
    # Simula 0,19 segundos de animação, independente da velocidade da CI.
    warrior.call("_process", 0.19)
    if absf(actor.position.y - before_pose) < 0.008:
        _fail("O soldado não alterou efetivamente a pose durante a marcha")
        return
    warrior.call("end_march")
    if bool(warrior.get("marching")):
        _fail("A marcha não terminou")
        return

    if not game.can_found():
        _fail("O colono deixou de poder fundar a capital")
        return
    game.found_city()
    var city: Dictionary = game.get_selected_city()
    var city_model: Node = game.get_node_or_null("ModelosDeJogo/Cidade_%d" % int(city["id"]))
    if city_model == null or city_model.get_node_or_null("Arquitetura") == null:
        _fail("A nova arquitetura do centro urbano não existe")
        return

    # Validar a presença do letreiro de distrito sem duplicar os testes económicos.
    var district_model: Node3D = DistrictVisuals.make("campus")
    root.add_child(district_model)
    if district_model.get_node_or_null("NomeDistrito") == null:
        _fail("Os novos letreiros 3D dos distritos estão ausentes")
        return
    district_model.queue_free()

    print("M35_SMOKE_OK: arte 3D MultiMesh, capital detalhada, formações e marcha animada")
    quit(0)
