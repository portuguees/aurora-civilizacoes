extends RefCounted
## Biomas ilustrados em 3D, construídos com poucas MultiMesh.
## Todo o desenho é original, determinístico e sem downloads ou texturas externas.

const Navigation = preload("res://scripts/hex_navigation.gd")


static func decorate(root: Node3D, tiles: Dictionary, seed_value: int) -> void:
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = seed_value * 53 + 1961

    var trunks: Array[Transform3D] = []
    var pine_low: Array[Transform3D] = []
    var pine_high: Array[Transform3D] = []
    var leafy: Array[Transform3D] = []
    var shrubs: Array[Transform3D] = []
    var stones: Array[Transform3D] = []
    var wildflowers: Array[Transform3D] = []
    var foam: Array[Transform3D] = []

    for cell in tiles:
        var tile: Dictionary = tiles[cell]
        var place: Vector3 = tile["position"]
        var biome: String = str(tile["biome"])
        if biome == "forest" or biome == "grassland":
            var trees: int = 3 if biome == "forest" else 1
            for j in range(trees):
                var offset: Vector3 = _scatter(rng, 0.64)
                var scale: float = rng.randf_range(0.76, 1.18)
                var pos: Vector3 = place + offset
                var tree_basis: Basis = Basis().scaled(Vector3.ONE * scale)
                trunks.append(Transform3D(tree_basis, pos + Vector3(0.0, 0.42 * scale, 0.0)))
                if biome == "forest" or rng.randf() < 0.55:
                    pine_low.append(Transform3D(tree_basis, pos + Vector3(0.0, 0.80 * scale, 0.0)))
                    pine_high.append(Transform3D(tree_basis, pos + Vector3(0.0, 1.13 * scale, 0.0)))
                else:
                    leafy.append(Transform3D(tree_basis, pos + Vector3(0.0, 1.05 * scale, 0.0)))
            if biome == "grassland":
                for j in range(3):
                    var spread: Vector3 = _scatter(rng, 0.91)
                    var scale: float = rng.randf_range(0.68, 1.36)
                    shrubs.append(Transform3D(Basis().scaled(Vector3.ONE * scale), place + spread + Vector3(0.0, 0.13, 0.0)))
                if rng.randf() > 0.55:
                    for j in range(3):
                        var spread: Vector3 = _scatter(rng, 0.78)
                        wildflowers.append(Transform3D(Basis(), place + spread + Vector3(0.0, 0.16, 0.0)))
        elif biome == "plains":
            for j in range(4):
                var spread: Vector3 = _scatter(rng, 0.86)
                var scale: float = rng.randf_range(0.72, 1.12)
                shrubs.append(Transform3D(Basis().scaled(Vector3.ONE * scale), place + spread + Vector3(0.0, 0.13, 0.0)))
        elif biome == "hills" or biome == "mountain":
            var rocks: int = 2 if biome == "hills" else 4
            for j in range(rocks):
                var scale: float = rng.randf_range(0.60, 1.30) if biome == "hills" else rng.randf_range(0.82, 1.56)
                var size: Vector3 = Vector3(scale, scale * rng.randf_range(0.85, 1.35), scale)
                stones.append(Transform3D(Basis().scaled(size), place + _scatter(rng, 0.70) + Vector3(0.0, 0.23, 0.0)))
        elif biome == "water":
            var nearby_land: bool = false
            for neighbor in Navigation.neighbors(cell):
                if tiles.has(neighbor) and not bool(tiles[neighbor]["water"]):
                    nearby_land = true
                    break
            var reflections: int = 3 if nearby_land else 1
            for j in range(reflections):
                var offset: Vector3 = _scatter(rng, 0.80)
                var rot: Basis = Basis(Vector3.UP, rng.randf_range(-PI, PI))
                var scale: Vector3 = Vector3(rng.randf_range(0.50, 1.3), 1.0, 1.0)
                foam.append(Transform3D(rot.scaled(scale), place + offset + Vector3(0.0, 0.07, 0.0)))

    _batch(root, "Troncos", _cylinder(0.075, 0.10, 0.86, 7), trunks, Color("#5f4936"))
    _batch(root, "PinheirosBase", _cylinder(0.0, 0.51, 0.80, 7), pine_low, Color("#2e6a58"))
    _batch(root, "PinheirosTopo", _cylinder(0.0, 0.34, 0.68, 7), pine_high, Color("#43846a"))
    _batch(root, "ArvoresFolhosas", _sphere(0.53, 0.72, 9), leafy, Color("#588c65"))
    _batch(root, "VegetacaoRasteira", _sphere(0.22, 0.19, 6), shrubs, Color("#8fa46e"))
    _batch(root, "PedrasDeMontanha", _sphere(0.42, 0.34, 7), stones, Color("#777d76"))
    _batch(root, "FloresSilvestres", _sphere(0.075, 0.09, 6), wildflowers, Color("#dbb575"))
    _batch(root, "ReflexosNoMar", _reflection_mesh(), foam, Color("#83c9c8"), true)


static func _scatter(rng: RandomNumberGenerator, radius: float) -> Vector3:
    var angle: float = rng.randf_range(0.0, TAU)
    var size: float = sqrt(rng.randf()) * radius
    return Vector3(cos(angle) * size, 0.0, sin(angle) * size)


static func _sphere(radius: float, height: float, sections: int) -> SphereMesh:
    var m: SphereMesh = SphereMesh.new()
    m.radius = radius
    m.height = height
    m.radial_segments = sections
    m.rings = 5
    return m


static func _cylinder(top: float, bottom: float, height: float, sides: int) -> CylinderMesh:
    var m: CylinderMesh = CylinderMesh.new()
    m.top_radius = top
    m.bottom_radius = bottom
    m.height = height
    m.radial_segments = sides
    m.rings = 1
    return m


static func _reflection_mesh() -> BoxMesh:
    var m: BoxMesh = BoxMesh.new()
    m.size = Vector3(0.62, 0.014, 0.026)
    return m


static func _batch(
    root: Node3D, label: String, geometry: Mesh,
    transforms: Array[Transform3D], tint: Color, unshaded: bool = false
) -> void:
    if transforms.is_empty():
        return
    var batch: MultiMesh = MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.mesh = geometry
    batch.instance_count = transforms.size()
    for i in range(transforms.size()):
        batch.set_instance_transform(i, transforms[i])
    var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
    node.name = label
    node.multimesh = batch
    node.material_override = _material(tint, unshaded)
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(node)


static func _material(tint: Color, unshaded: bool) -> StandardMaterial3D:
    var mat: StandardMaterial3D = StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.roughness = 0.93
    if unshaded:
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return mat
