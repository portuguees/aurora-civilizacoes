extends RefCounted
const CityDetails = preload("res://scripts/city_details.gd")
## Pequena cidade estilizada em 3D. Arte geométrica original, sem texturas externas.
## A população aumenta o número de casas e as muralhas surgem a partir de pop. 3.


static func make(city: Dictionary) -> Node3D:
    var root: Node3D = Node3D.new()
    var population: int = maxi(1, int(city.get("population", 1)))
    var owner: int = int(city.get("owner", 0))
    var faction: Color = Color("#3eb7d8") if owner == 0 else Color("#d68851")
    var sandstone: Color = Color("#e2d1a9")
    var stone: Color = Color("#ad9e87")
    var roof: Color = Color("#537d9b") if owner == 0 else Color("#b56d50")

    _cylinder(root, Vector3(0.0, 0.13, 0.0), 0.99, 0.24, stone, 8)
    _box(root, Vector3(0.0, 0.65, 0.0), Vector3(0.85, 0.86, 0.69), sandstone)
    _cone(root, Vector3(0.0, 1.20, 0.0), 0.68, 0.41, roof, 4)
    _box(root, Vector3(0.0, 1.44, 0.0), Vector3(0.15, 0.23, 0.15), stone)
    _cone(root, Vector3(0.0, 1.64, 0.0), 0.17, 0.21, Color("#e7c778"), 6)
    # Arcada e portal voltados para a câmara.
    _box(root, Vector3(0.0, 0.47, 0.37), Vector3(0.26, 0.43, 0.09), Color("#745c4b"))
    _box(root, Vector3(-0.27, 0.61, 0.39), Vector3(0.12, 0.23, 0.055), Color("#789fb1"))
    _box(root, Vector3(0.27, 0.61, 0.39), Vector3(0.12, 0.23, 0.055), Color("#789fb1"))

    # Casas dispostas à volta da praça, sem tapar a torre.
    var spots: Array[Vector3] = [
        Vector3(-0.83, 0, -0.35), Vector3(0.83, 0, -0.35),
        Vector3(-0.78, 0, 0.48), Vector3(0.78, 0, 0.48),
        Vector3(-0.29, 0, 0.86), Vector3(0.29, 0, 0.86),
        Vector3(-0.28, 0, -0.86), Vector3(0.28, 0, -0.86)
    ]
    var houses: int = mini(spots.size(), 2 + population * 2)
    for i in range(houses):
        var p: Vector3 = spots[i]
        var height: float = 0.35 + float(i % 3) * 0.065
        _box(root, p + Vector3(0.0, 0.28, 0.0), Vector3(0.32, height, 0.35), Color("#e4d6b9"))
        _cone(root, p + Vector3(0.0, 0.28 + height * 0.5 + 0.11, 0.0), 0.27, 0.23, roof, 4)

    # Muralhas mais altas e torres só quando o centro urbano cresce.
    if population >= 3:
        for edge in range(8):
            var angle: float = TAU * float(edge) / 8.0
            var p: Vector3 = Vector3(cos(angle) * 1.12, 0.0, sin(angle) * 1.12)
            var wall: Vector3 = Vector3(0.65, 0.38, 0.12)
            _box_rotated(root, p + Vector3(0.0, 0.27, 0.0), wall, -rad_to_deg(angle) - 90.0, Color("#b2a18a"))
        for edge in [0, 2, 4, 6]:
            var angle: float = TAU * float(edge) / 8.0
            var p: Vector3 = Vector3(cos(angle) * 1.1, 0.0, sin(angle) * 1.1)
            _cylinder(root, p + Vector3(0.0, 0.42, 0.0), 0.17, 0.72, stone, 6)
            _cone(root, p + Vector3(0.0, 0.86, 0.0), 0.24, 0.22, roof, 6)

    # Estandarte próprio.
    _cylinder(root, Vector3(0.64, 1.24, -0.16), 0.037, 1.65, Color("#65503f"), 6)
    _box(root, Vector3(0.94, 1.82, -0.16), Vector3(0.62, 0.32, 0.05), faction)

    CityDetails.decorate(root, city)

    var banner: Label3D = Label3D.new()
    banner.name = "FaixaCidade"
    banner.text = "%s  •  %d" % [str(city.get("name", "Cidade")), population]
    banner.font_size = 43
    banner.pixel_size = 0.005
    banner.outline_size = 10
    banner.modulate = faction
    banner.position.y = 3.05
    banner.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    root.add_child(banner)
    return root


static func _material(tint: Color) -> StandardMaterial3D:
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = 0.94
    return material


static func _box(parent: Node3D, position: Vector3, dimensions: Vector3, tint: Color) -> void:
    _box_rotated(parent, position, dimensions, 0.0, tint)


static func _box_rotated(parent: Node3D, position: Vector3, dimensions: Vector3, rotation_y: float, tint: Color) -> void:
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = dimensions
    var item: MeshInstance3D = MeshInstance3D.new()
    item.mesh = mesh
    item.position = position
    item.rotation_degrees.y = rotation_y
    item.material_override = _material(tint)
    parent.add_child(item)


static func _cylinder(parent: Node3D, position: Vector3, radius: float, height: float, tint: Color, sides: int) -> void:
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = sides
    var item: MeshInstance3D = MeshInstance3D.new()
    item.mesh = mesh
    item.position = position
    item.material_override = _material(tint)
    parent.add_child(item)


static func _cone(parent: Node3D, position: Vector3, radius: float, height: float, tint: Color, sides: int) -> void:
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = 0.0
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = sides
    var item: MeshInstance3D = MeshInstance3D.new()
    item.mesh = mesh
    item.position = position
    item.material_override = _material(tint)
    parent.add_child(item)
