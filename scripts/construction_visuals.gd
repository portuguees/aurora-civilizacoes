extends RefCounted
## M6 — um estaleiro 3D cresce com o progresso real da produção da cidade.

static func make(kind: String, progress: int, total: int) -> Node3D:
    var root: Node3D = Node3D.new()
    root.name = "Estaleiro"
    var fraction: float = clampf(float(progress) / float(maxi(1, total)), 0.0, 1.0)
    _block(root, Vector3(0, 0.09, 0), Vector3(1.35, 0.16, 1.15), Color("#c1a47a"))
    # Pilares, travessas e andaimes: nenhuma peça é importada de outro jogo.
    for x in [-0.51, 0.51]:
        for z in [-0.43, 0.43]:
            _block(root, Vector3(x, 0.49, z), Vector3(0.080, 0.78, 0.08), Color("#7e5e41"))
    _block(root, Vector3(0.0, 0.83, -0.43), Vector3(1.10, 0.085, 0.08), Color("#a77b51"))
    _block(root, Vector3(0.0, 0.83, 0.43), Vector3(1.10, 0.085, 0.08), Color("#a77b51"))
    for x in [-0.51, 0.51]:
        _block(root, Vector3(x, 0.83, 0.0), Vector3(0.08, 0.08, 0.92), Color("#a77b51"))
    # A alvenaria avança visualmente de acordo com os turnos de produção.
    if fraction > 0.0:
        var built_height: float = maxf(0.12, fraction * 0.93)
        _block(root, Vector3(0.0, 0.18 + built_height * 0.5, 0.0),
            Vector3(0.82, built_height, 0.66), Color("#cfc5a9"))
    if fraction >= 0.55:
        _block(root, Vector3(0.0, 0.80 + fraction * 0.22, 0.0),
            Vector3(0.96, 0.10, 0.79), Color("#658c9f"))
    var sign: Label3D = Label3D.new()
    sign.name = "ProgressoObra"
    sign.text = "%s %d%%" % [kind.to_upper(), roundi(fraction * 100.0)]
    sign.font_size = 32
    sign.pixel_size = 0.004
    sign.outline_size = 8
    sign.modulate = Color("#f5d79b")
    sign.position.y = 1.53
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    root.add_child(sign)
    root.set_meta("progress_fraction", fraction)
    return root


static func _block(root: Node3D, p: Vector3, dimensions: Vector3, tint: Color) -> void:
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = dimensions
    var node: MeshInstance3D = MeshInstance3D.new()
    node.mesh = mesh
    node.position = p
    var mat: StandardMaterial3D = StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.roughness = 0.93
    node.material_override = mat
    root.add_child(node)
