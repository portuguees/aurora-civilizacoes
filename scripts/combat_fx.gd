extends Node3D
## M5: impacto visível sem texturas externas e sem modificar regras de combate.
## Cada efeito é temporário; não é guardado nem afeta a simulação.

var _seconds: float = 0.0
var _float_label: Label3D
var _pulse: MeshInstance3D
var _shards: Array[Node3D] = []


func setup(amount: int, defeated: bool) -> void:
    name = "ImpactoCombate"
    _pulse = MeshInstance3D.new()
    _pulse.name = "OndaImpacto"
    var ring: TorusMesh = TorusMesh.new()
    ring.inner_radius = 0.25
    ring.outer_radius = 0.33
    ring.rings = 7
    ring.ring_segments = 20
    _pulse.mesh = ring
    _pulse.material_override = _material(Color("#f8c86c") if not defeated else Color("#f68a73"))
    _pulse.position.y = 0.09
    add_child(_pulse)

    _float_label = Label3D.new()
    _float_label.name = "DanoVisivel"
    _float_label.text = "-%d" % amount
    _float_label.position = Vector3(0.0, 1.95, 0.0)
    _float_label.font_size = 65
    _float_label.pixel_size = 0.005
    _float_label.outline_size = 11
    _float_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    _float_label.modulate = Color("#ffe09a") if not defeated else Color("#ffae98")
    add_child(_float_label)
    for i in range(9):
        var piece: MeshInstance3D = MeshInstance3D.new()
        piece.name = "Faisca_%d" % i
        var mesh: BoxMesh = BoxMesh.new()
        mesh.size = Vector3(0.095, 0.15, 0.06)
        piece.mesh = mesh
        piece.material_override = _material(Color("#ffdfa3") if i % 2 == 0 else Color("#f2a66e"))
        piece.position = Vector3(0, 0.80, 0)
        add_child(piece)
        _shards.append(piece)


func _process(delta: float) -> void:
    _seconds += delta
    var phase: float = clampf(_seconds / 0.68, 0.0, 1.0)
    if _pulse != null:
        _pulse.scale = Vector3.ONE * (0.4 + phase * 2.4)
        _pulse.transparency = phase
    if _float_label != null:
        _float_label.position.y = 1.95 + phase * 1.25
        _float_label.transparency = phase
    for i in range(_shards.size()):
        var spark: Node3D = _shards[i]
        var theta: float = TAU * float(i) / float(_shards.size())
        spark.position = Vector3(
            cos(theta) * phase * 0.75,
            0.80 + phase * (0.25 + float(i % 3) * 0.26),
            sin(theta) * phase * 0.75
        )
        spark.scale = Vector3.ONE * maxf(0.01, 1.0 - phase)
    if _seconds >= 0.72:
        queue_free()


func _material(tint: Color) -> StandardMaterial3D:
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = tint
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.roughness = 0.9
    return material
