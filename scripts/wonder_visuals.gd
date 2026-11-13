extends RefCounted
## M15: monumentos 3D originais construídos no mesmo hexágono urbano.

static func make(kind: String) -> Node3D:
    var root: Node3D = Node3D.new()
    root.name = "Maravilha"
    var tint: Color = Color("#bcd8dc") if kind == "sky_observatory" else Color("#e8ca96")
    _box(root, Vector3(0.0, 0.25, 0.0), Vector3(1.0, 0.25, 0.95), Color("#8d8069"))
    if kind == "sky_observatory":
        _cylinder(root, Vector3(0, 0.76, 0), 0.29, 0.91, tint, 10)
        var dome: SphereMesh = SphereMesh.new()
        dome.radius = 0.42
        dome.height = 0.53
        dome.radial_segments = 10
        dome.rings = 6
        var cap: MeshInstance3D = MeshInstance3D.new()
        cap.name = "CupulaEstelar"
        cap.mesh = dome
        cap.position.y = 1.41
        cap.material_override = _mat(Color("#6ca5c3"))
        root.add_child(cap)
        for x in [-0.44, 0.44]:
            _cylinder(root, Vector3(x, 0.55, 0.0), 0.055, 0.55, Color("#e6d7b4"), 6)
    else:
        for x in [-0.32, 0.32]:
            for z in [-0.33, 0.33]:
                _cylinder(root, Vector3(x, 0.71, z), 0.075, 0.83, tint, 8)
                var hedge: SphereMesh = SphereMesh.new()
                hedge.radius = 0.22
                hedge.height = 0.29
                hedge.radial_segments = 7
                var leaf: MeshInstance3D = MeshInstance3D.new()
                leaf.mesh = hedge
                leaf.position = Vector3(x, 1.29, z)
                leaf.material_override = _mat(Color("#4d9c6c"))
                root.add_child(leaf)
        _box(root, Vector3(0, 1.20, 0), Vector3(0.84, 0.14, 0.84), Color("#d5ba8e"))
    var nameplate: Label3D = Label3D.new()
    nameplate.name = "NomeMaravilha"
    nameplate.text = "OBSERVATÓRIO" if kind == "sky_observatory" else "JARDINS REAIS"
    nameplate.position.y = 2.05
    nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    nameplate.font_size = 31
    nameplate.pixel_size = 0.004
    nameplate.outline_size = 9
    nameplate.modulate = Color("#f7e4b7")
    root.add_child(nameplate)
    return root


static func _mat(color: Color) -> StandardMaterial3D:
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.88
    return material


static func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = size
    var model: MeshInstance3D = MeshInstance3D.new()
    model.mesh = mesh
    model.position = pos
    model.material_override = _mat(color)
    parent.add_child(model)


static func _cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, sides: int) -> void:
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = sides
    var model: MeshInstance3D = MeshInstance3D.new()
    model.mesh = mesh
    model.position = pos
    model.material_override = _mat(color)
    parent.add_child(model)
