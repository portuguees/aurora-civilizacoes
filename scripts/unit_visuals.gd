extends RefCounted
## Grupos de unidades geométricas 3D com silhuetas distintas.
## Um colono tem carroça e acompanhantes; um guerreiro tem formação com escudos.


static func make(unit: Dictionary, selected: bool) -> Node3D:
    var root: Node3D = Node3D.new()
    var owner: int = int(unit.get("owner", 0))
    var faction: Color = Color("#39bfe4") if owner == 0 else Color("#dc8e54")
    var kind: String = str(unit.get("kind", "warrior"))
    # Base elevada para contrastar com a vegetação no mapa.
    _cylinder(root, Vector3(0.0, 0.04, 0.0), 0.78, 0.11, Color("#243c3f"), 12)
    if kind == "settler":
        _settlers(root, faction)
    else:
        _warriors(root, faction)
    var nameplate: Label3D = Label3D.new()
    nameplate.name = "NomeUnidade"
    nameplate.text = "COLONO" if kind == "settler" else "GUERREIROS"
    nameplate.font_size = 38
    nameplate.pixel_size = 0.0047
    nameplate.outline_size = 9
    nameplate.modulate = faction
    nameplate.position.y = 1.9
    nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    root.add_child(nameplate)
    _health_bar(root, int(unit.get("health", 100)))
    if selected:
        var ring: TorusMesh = TorusMesh.new()
        ring.inner_radius = 0.83
        ring.outer_radius = 0.91
        ring.rings = 8
        ring.ring_segments = 32
        var marker: MeshInstance3D = MeshInstance3D.new()
        marker.name = "AnelSelecao"
        marker.mesh = ring
        marker.position.y = 0.11
        marker.material_override = _material(Color("#ffdc80"), true)
        root.add_child(marker)
    return root


static func _settlers(root: Node3D, faction: Color) -> void:
    # Carroça com rodas laterais e toldo: legível de longe.
    _box(root, Vector3(0.0, 0.46, 0.0), Vector3(0.94, 0.25, 0.68), Color("#916d46"))
    _box(root, Vector3(0.0, 0.83, 0.0), Vector3(0.92, 0.14, 0.75), Color("#ede1c3"))
    for x in [-0.51, 0.51]:
        for z in [-0.28, 0.28]:
            var wheel: CylinderMesh = CylinderMesh.new()
            wheel.top_radius = 0.20
            wheel.bottom_radius = 0.20
            wheel.height = 0.085
            wheel.radial_segments = 10
            var item: MeshInstance3D = MeshInstance3D.new()
            item.mesh = wheel
            item.position = Vector3(x, 0.27, z)
            item.rotation_degrees.z = 90.0
            item.material_override = _material(Color("#423729"))
            root.add_child(item)
    _person(root, Vector3(-0.23, 0.0, -0.62), faction, false)
    _person(root, Vector3(0.27, 0.0, -0.63), Color("#c2b09b"), false)
    _flag(root, Vector3(0.47, 0.0, 0.40), faction)


static func _warriors(root: Node3D, faction: Color) -> void:
    var positions: Array[Vector3] = [
        Vector3(-0.34, 0.0, -0.32), Vector3(0.34, 0.0, -0.32),
        Vector3(-0.34, 0.0, 0.32), Vector3(0.34, 0.0, 0.32)
    ]
    for point in positions:
        _person(root, point, faction, true)
    _flag(root, Vector3(0.63, 0.0, 0.0), faction)


static func _person(parent: Node3D, base: Vector3, faction: Color, armed: bool) -> void:
    var torso: CylinderMesh = CylinderMesh.new()
    torso.top_radius = 0.12
    torso.bottom_radius = 0.18
    torso.height = 0.49
    torso.radial_segments = 7
    var body: MeshInstance3D = MeshInstance3D.new()
    body.mesh = torso
    body.position = base + Vector3(0.0, 0.48, 0.0)
    body.material_override = _material(faction)
    parent.add_child(body)
    var head: SphereMesh = SphereMesh.new()
    head.radius = 0.14
    head.height = 0.28
    head.radial_segments = 10
    head.rings = 5
    var face: MeshInstance3D = MeshInstance3D.new()
    face.mesh = head
    face.position = base + Vector3(0.0, 0.88, 0.0)
    face.material_override = _material(Color("#e7c69d"))
    parent.add_child(face)
    if armed:
        _cylinder(parent, base + Vector3(0.0, 1.01, 0.0), 0.18, 0.13, Color("#647c83"), 8)
        _box(parent, base + Vector3(-0.21, 0.49, 0.13), Vector3(0.12, 0.37, 0.29), Color("#cbb489"))
        _cylinder(parent, base + Vector3(0.23, 0.81, 0.0), 0.022, 1.22, Color("#74573e"), 6)
        _cone(parent, base + Vector3(0.23, 1.47, 0.0), 0.07, 0.20, Color("#c6cfcd"), 6)


static func _flag(root: Node3D, offset: Vector3, tint: Color) -> void:
    _cylinder(root, offset + Vector3(0.0, 0.85, 0.0), 0.035, 1.65, Color("#69513b"), 6)
    _box(root, offset + Vector3(0.24, 1.43, 0.0), Vector3(0.52, 0.30, 0.06), tint)


static func _material(tint: Color, unshaded: bool = false) -> StandardMaterial3D:
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = 0.95
    if unshaded:
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return material


static func _box(parent: Node3D, pos: Vector3, dims: Vector3, tint: Color) -> void:
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = dims
    var item: MeshInstance3D = MeshInstance3D.new()
    item.mesh = mesh
    item.position = pos
    item.material_override = _material(tint)
    parent.add_child(item)


static func _cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, tint: Color, sides: int) -> void:
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = sides
    var item: MeshInstance3D = MeshInstance3D.new()
    item.mesh = mesh
    item.position = pos
    item.material_override = _material(tint)
    parent.add_child(item)


static func _cone(parent: Node3D, pos: Vector3, radius: float, height: float, tint: Color, sides: int) -> void:
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = 0.0
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = sides
    var item: MeshInstance3D = MeshInstance3D.new()
    item.mesh = mesh
    item.position = pos
    item.material_override = _material(tint)
    parent.add_child(item)


static func _health_bar(root: Node3D, value: int) -> void:
    var ratio: float = clampf(float(value) / 100.0, 0.0, 1.0)
    var tint: Color = Color("#76cc7d") if ratio > 0.65 else (Color("#edc15b") if ratio > 0.30 else Color("#e66d5f"))
    _box(root, Vector3(0.0, 1.52, 0.06), Vector3(0.84, 0.10, 0.10), Color("#21333a"))
    if ratio > 0.01:
        var width: float = 0.77 * ratio
        _box(root, Vector3(-0.385 + width * 0.5, 1.52, 0.13), Vector3(width, 0.07, 0.035), tint)
