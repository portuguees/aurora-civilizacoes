extends RefCounted
## Detalhes arquitetónicos da capital: praça, torre do relógio, pórticos e tochas.
## Estas peças são 3D nativas do Godot; não utilizam arte de terceiros.


static func decorate(root: Node3D, city: Dictionary) -> void:
    var architecture: Node3D = Node3D.new()
    architecture.name = "Arquitetura"
    root.add_child(architecture)
    var owner: int = int(city.get("owner", 0))
    var population: int = maxi(1, int(city.get("population", 1)))
    var accent: Color = Color("#348cb1") if owner == 0 else Color("#ba7449")
    var roof: Color = Color("#406b8b") if owner == 0 else Color("#92503d")
    var plaster: Color = Color("#e2cda5")
    var limestone: Color = Color("#b5aa95")

    # Praças pavimentadas com um pequeno pórtico e degraus visíveis.
    for i in range(7):
        var angle: float = TAU * float(i) / 7.0
        var x: float = cos(angle) * 0.80
        var z: float = sin(angle) * 0.80
        _box(architecture, Vector3(x, 0.22, z), Vector3(0.35, 0.08, 0.30), limestone)
    for i in range(3):
        _box(architecture, Vector3(0.0, 0.12 + float(i) * 0.04, 0.84 + float(i) * 0.18),
            Vector3(0.67 - float(i) * 0.10, 0.08, 0.19), limestone)

    # Fachadas em pedra, janela de rosácea e corredor sob a torre.
    for side in [-1.0, 1.0]:
        _box(architecture, Vector3(0.40 * side, 0.50, 0.39), Vector3(0.16, 0.78, 0.10), limestone)
        _box(architecture, Vector3(0.29 * side, 0.87, 0.40), Vector3(0.17, 0.18, 0.08), accent)
        _box(architecture, Vector3(0.49 * side, 0.96, -0.01), Vector3(0.12, 0.21, 0.25), plaster)
    _box(architecture, Vector3(0.0, 1.11, 0.42), Vector3(0.53, 0.16, 0.12), limestone)
    _box(architecture, Vector3(0.0, 1.29, 0.33), Vector3(0.29, 0.19, 0.07), accent)

    # Torre de menagem em três níveis e cúpula facetada.
    _cylinder(architecture, Vector3(0.0, 1.65, -0.12), 0.20, 0.68, plaster, 8)
    _cylinder(architecture, Vector3(0.0, 2.04, -0.12), 0.27, 0.13, limestone, 8)
    _cone(architecture, Vector3(0.0, 2.30, -0.12), 0.29, 0.43, roof, 8)
    _cone(architecture, Vector3(0.0, 2.61, -0.12), 0.10, 0.22, Color("#e3c36e"), 8)

    # Colunas e capitéis numa entrada lateral.
    for x in [-0.27, 0.27]:
        _cylinder(architecture, Vector3(x, 0.39, -0.77), 0.083, 0.42, limestone, 7)
        _box(architecture, Vector3(x, 0.67, -0.77), Vector3(0.20, 0.12, 0.20), plaster)
    _box(architecture, Vector3(0.0, 0.76, -0.77), Vector3(0.74, 0.15, 0.20), accent)

    # Tochas com material emissivo discreto e sem luzes adicionais.
    for x in [-0.40, 0.40]:
        _cylinder(architecture, Vector3(x, 0.50, 0.66), 0.045, 0.37, Color("#6c5340"), 7)
        _glow(architecture, Vector3(x, 0.78, 0.66))

    if population >= 2:
        # Duas torres anexas e bandeirolas assinalam o progresso urbano.
        for side in [-1.0, 1.0]:
            _cylinder(architecture, Vector3(side * 0.68, 0.85, -0.50), 0.19, 0.72, plaster, 8)
            _cone(architecture, Vector3(side * 0.68, 1.31, -0.50), 0.29, 0.36, roof, 8)
            _box(architecture, Vector3(side * 0.68, 1.48, -0.50), Vector3(0.12, 0.16, 0.10), accent)

    if population >= 3:
        for corner in [-1.0, 1.0]:
            _cylinder(architecture, Vector3(corner * 1.1, 0.92, corner * 0.02), 0.12, 0.22, plaster, 6)


static func _material(tint: Color, glowing: bool = false) -> StandardMaterial3D:
    var mat: StandardMaterial3D = StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.roughness = 0.88
    if glowing:
        mat.emission_enabled = true
        mat.emission = tint
        mat.emission_energy_multiplier = 1.25
    return mat


static func _glow(root: Node3D, pos: Vector3) -> void:
    var light: SphereMesh = SphereMesh.new()
    light.radius = 0.075
    light.height = 0.15
    light.radial_segments = 8
    light.rings = 5
    var item: MeshInstance3D = MeshInstance3D.new()
    item.mesh = light
    item.position = pos
    item.material_override = _material(Color("#ffcb72"), true)
    root.add_child(item)


static func _box(parent: Node3D, pos: Vector3, size: Vector3, tint: Color) -> void:
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = size
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
