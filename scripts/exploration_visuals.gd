extends RefCounted
## Nevoeiro de guerra eficiente: duas MultiMesh, sem centenas de nós.
## Não modifica os dados do mapa nem esconde unidades por script de UI.

static func build(tiles: Dictionary, explored: Dictionary, visible: Dictionary) -> Node3D:
    var root: Node3D = Node3D.new()
    root.name = "Exploracao"
    var undiscovered: Array[Transform3D] = []
    var outside_sight: Array[Transform3D] = []
    var hex_radius: float = 1.28
    for cell in tiles:
        var origin: Vector3 = tiles[cell]["position"] + Vector3(0.0, 0.205, 0.0)
        var transform: Transform3D = Transform3D(Basis.IDENTITY, origin)
        if not explored.has(cell):
            undiscovered.append(transform)
        elif not visible.has(cell):
            outside_sight.append(transform)
    _batch(root, "NevoeiroDesconhecido", undiscovered, Color(0.055, 0.11, 0.15, 0.84), hex_radius)
    _batch(root, "NevoeiroExplorado", outside_sight, Color(0.055, 0.09, 0.12, 0.40), hex_radius)
    return root


static func _batch(root: Node3D, label: String, transforms: Array[Transform3D], tint: Color, radius: float) -> void:
    if transforms.is_empty():
        return
    var cell_mesh: CylinderMesh = CylinderMesh.new()
    cell_mesh.top_radius = radius
    cell_mesh.bottom_radius = radius
    cell_mesh.height = 0.035
    cell_mesh.radial_segments = 6
    var multi: MultiMesh = MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.mesh = cell_mesh
    multi.instance_count = transforms.size()
    for i in range(transforms.size()):
        multi.set_instance_transform(i, transforms[i])
    var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
    node.name = label
    node.multimesh = multi
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = tint
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    node.material_override = material
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(node)
