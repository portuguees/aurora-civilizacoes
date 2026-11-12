extends RefCounted
## Pequenos modelos 3D originais para identificar distritos no zoom estratégico.
## Todos os modelos usam StandardMaterial3D no renderizador Compatibility.


static func make(kind: String) -> Node3D:
    var root: Node3D = Node3D.new()
    var stone: Color = Color("#e3d6b9")
    var roof: Color = Color("#507c9b")
    _cylinder(root, Vector3(0.0, 0.12, 0.0), 0.85, 0.18, Color("#c4ad88"))
    match kind:
        "campus":
            roof = Color("#528bb0")
            _box(root, Vector3(-0.31, 0.57, 0.0), Vector3(0.52, 0.86, 0.50), stone)
            _box(root, Vector3(0.31, 0.57, 0.0), Vector3(0.52, 0.86, 0.50), stone)
            _box(root, Vector3(0.0, 1.06, 0.0), Vector3(1.20, 0.18, 0.73), roof)
            _box(root, Vector3(0.0, 1.26, 0.0), Vector3(0.28, 0.22, 0.25), roof)
        "market":
            roof = Color("#c8824d")
            for x in [-0.45, 0.0, 0.45]:
                _box(root, Vector3(x, 0.37, 0.0), Vector3(0.31, 0.40, 0.66), Color("#ceb391"))
                _box(root, Vector3(x, 0.64, 0.0), Vector3(0.41, 0.16, 0.79), roof)
        "industrial":
            roof = Color("#916b57")
            _box(root, Vector3(0.0, 0.54, 0.0), Vector3(1.12, 0.62, 0.65), stone)
            _box(root, Vector3(0.0, 0.95, 0.0), Vector3(1.22, 0.16, 0.81), roof)
            _cylinder(root, Vector3(0.35, 1.40, 0.04), 0.18, 1.10, Color("#997a67"))
        "barracks":
            roof = Color("#a96556")
            _box(root, Vector3(0.0, 0.43, 0.0), Vector3(0.85, 0.52, 0.70), stone)
            _box(root, Vector3(0.0, 0.76, 0.0), Vector3(0.94, 0.15, 0.78), roof)
            for x in [-0.61, 0.61]:
                for z in [-0.47, 0.47]:
                    _cylinder(root, Vector3(x, 0.50, z), 0.16, 0.86, Color("#c0b19a"))
        "harbor":
            roof = Color("#c79c61")
            _box(root, Vector3(0.0, 0.27, 0.0), Vector3(1.35, 0.20, 0.84), Color("#745b44"))
            for x in [-0.40, 0.40]:
                _box(root, Vector3(x, 0.48, 0.0), Vector3(0.13, 0.32, 0.82), roof)
            _box(root, Vector3(0.0, 0.75, 0.0), Vector3(0.76, 0.13, 0.61), Color("#66849a"))
        "farm":
            for z in [-0.48, -0.24, 0.0, 0.24, 0.48]:
                _box(root, Vector3(0.0, 0.23, z), Vector3(1.40, 0.13, 0.14), Color("#8dba5a"))
            _box(root, Vector3(-0.44, 0.42, -0.30), Vector3(0.25, 0.38, 0.31), Color("#d9c59c"))
        "mine":
            for x in [-0.43, 0.0, 0.43]:
                _cylinder(root, Vector3(x, 0.41, 0.0), 0.29, 0.55, Color("#7c8584"))
            _box(root, Vector3(0.0, 0.72, 0.42), Vector3(0.98, 0.15, 0.16), Color("#9c7955"))

    return root


static func _mat(tint: Color) -> StandardMaterial3D:
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = 0.94
    return material


static func _box(parent: Node3D, center: Vector3, size: Vector3, tint: Color) -> void:
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = size
    var item: MeshInstance3D = MeshInstance3D.new()
    item.mesh = mesh
    item.position = center
    item.material_override = _mat(tint)
    parent.add_child(item)


static func _cylinder(parent: Node3D, center: Vector3, radius: float, height: float, tint: Color) -> void:
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 8
    var item: MeshInstance3D = MeshInstance3D.new()
    item.mesh = mesh
    item.position = center
    item.material_override = _mat(tint)
    parent.add_child(item)
