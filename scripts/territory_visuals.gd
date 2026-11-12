extends RefCounted
## Território e estradas construídos no mapa, separados dos dados de jogo.
## Fronteiras: um contorno por hexágono que separa propriedades de civilizações.
## Caminhos: unem cada distrito ao centro da cidade que o construiu.

const TILE_RADIUS: float = 1.35


static func build(tiles: Dictionary, cities: Array[Dictionary], districts: Array[Dictionary]) -> Node3D:
    var root: Node3D = Node3D.new()
    root.name = "InfraestruturaImperial"
    if cities.is_empty():
        return root
    _add_borders(root, tiles, cities)
    _add_roads(root, tiles, cities, districts)
    return root


static func _add_borders(root: Node3D, tiles: Dictionary, cities: Array[Dictionary]) -> void:
    var tools: Array[SurfaceTool] = []
    var colors: Array[Color] = [Color("#42c7ed"), Color("#e7a06c")]
    for owner in range(2):
        var surface: SurfaceTool = SurfaceTool.new()
        surface.begin(Mesh.PRIMITIVE_TRIANGLES)
        tools.append(surface)
    var positions: Dictionary = {}
    for cell in tiles:
        var owner: int = _owner_for(cell, cities)
        if owner >= 0:
            positions[cell] = owner
    for cell in positions:
        var owner: int = positions[cell]
        var center: Vector3 = tiles[cell]["position"] + Vector3(0.0, 0.21, 0.0)
        for edge in range(6):
            var neighbor: Vector2i = _neighbor(cell, edge)
            if int(positions.get(neighbor, -1)) == owner:
                continue
            var angle0: float = deg_to_rad(60.0 * float(edge) - 30.0)
            var angle1: float = deg_to_rad(60.0 * float(edge + 1) - 30.0)
            var p0: Vector3 = center + Vector3(cos(angle0) * TILE_RADIUS * 1.015, 0.0, sin(angle0) * TILE_RADIUS * 1.015)
            var p1: Vector3 = center + Vector3(cos(angle1) * TILE_RADIUS * 1.015, 0.0, sin(angle1) * TILE_RADIUS * 1.015)
            _ribbon(tools[owner], p0, p1, 0.095, colors[owner])
    for owner in range(2):
        var mesh: ArrayMesh = tools[owner].commit()
        if mesh.get_surface_count() == 0:
            continue
        var visual: MeshInstance3D = MeshInstance3D.new()
        visual.name = "Fronteira_%d" % owner
        visual.mesh = mesh
        visual.material_override = _material(Color.WHITE, true)
        root.add_child(visual)


static func _add_roads(root: Node3D, tiles: Dictionary, cities: Array[Dictionary], districts: Array[Dictionary]) -> void:
    if districts.is_empty():
        return
    var surface: SurfaceTool = SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var count: int = 0
    for district in districts:
        if not tiles.has(district["coords"]):
            continue
        for city in cities:
            if int(city["id"]) != int(district["city_id"]) or not tiles.has(city["coords"]):
                continue
            var a: Vector3 = tiles[city["coords"]]["position"] + Vector3(0.0, 0.26, 0.0)
            var b: Vector3 = tiles[district["coords"]]["position"] + Vector3(0.0, 0.26, 0.0)
            var dist: float = a.distance_to(b)
            var sections: int = maxi(2, int(ceil(dist / 0.75)))
            for i in range(sections):
                var t0: float = float(i) / float(sections)
                var t1: float = float(i + 1) / float(sections)
                var p0: Vector3 = a.lerp(b, t0)
                var p1: Vector3 = a.lerp(b, t1)
                _ribbon(surface, p0, p1, 0.18, Color("#a18865"))
            count += 1
            break
    if count == 0:
        return
    var path: MeshInstance3D = MeshInstance3D.new()
    path.name = "Estradas"
    path.mesh = surface.commit()
    path.material_override = _material(Color.WHITE, true)
    root.add_child(path)


static func _owner_for(cell: Vector2i, cities: Array[Dictionary]) -> int:
    var min_distance: int = 999
    var owner: int = -1
    for city in cities:
        var dist: int = _distance(cell, city["coords"])
        if dist <= 2 and dist < min_distance:
            min_distance = dist
            owner = int(city["owner"])
    return owner


static func _distance(a: Vector2i, b: Vector2i) -> int:
    var aq: int = a.x - ((a.y - (a.y & 1)) >> 1)
    var bq: int = b.x - ((b.y - (b.y & 1)) >> 1)
    var dq: int = aq - bq
    var dr: int = a.y - b.y
    return (absi(dq) + absi(dr) + absi(dq + dr)) >> 1


static func _neighbor(cell: Vector2i, direction: int) -> Vector2i:
    # Ângulos da malha (cantos a -30, 30, 90, 150, 210, 270 graus).
    # A aresta 0 une cantos -30 e 30: vizinho a Este.
    var odd: bool = (cell.y & 1) == 1
    if odd:
        var offsets: Array[Vector2i] = [
            Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1),
            Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)
        ]
        return cell + offsets[direction]
    else:
        var offsets: Array[Vector2i] = [
            Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
            Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1)
        ]
        return cell + offsets[direction]


static func _ribbon(surface: SurfaceTool, p0: Vector3, p1: Vector3, width: float, color: Color) -> void:
    var axis: Vector3 = p1 - p0
    if axis.length_squared() < 0.0001:
        return
    var right: Vector3 = Vector3(-axis.z, 0.0, axis.x).normalized() * width * 0.5
    var a: Vector3 = p0 - right
    var b: Vector3 = p0 + right
    var c: Vector3 = p1 + right
    var d: Vector3 = p1 - right
    for vertex in [a, b, c, a, c, d]:
        surface.set_color(color)
        surface.add_vertex(vertex)


static func _material(color: Color, vertex_color: bool) -> StandardMaterial3D:
    var mat: StandardMaterial3D = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.vertex_color_use_as_albedo = vertex_color
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat
