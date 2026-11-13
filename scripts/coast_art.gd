extends RefCounted
## M6 — transições costeiras 3D sem texturas externas.
## Uma malha de água rasa e uma de espuma, em vez de um nó por hexágono.

static func make(tiles: Dictionary, radius: float) -> Node3D:
    var root: Node3D = Node3D.new()
    root.name = "Costas"
    var shallow: SurfaceTool = SurfaceTool.new()
    shallow.begin(Mesh.PRIMITIVE_TRIANGLES)
    var foam: SurfaceTool = SurfaceTool.new()
    foam.begin(Mesh.PRIMITIVE_TRIANGLES)
    var coastal_tiles: int = 0
    var coastline_edges: int = 0
    for cell in tiles:
        if not bool(tiles[cell]["water"]):
            continue
        var coastal_sides: Array[int] = []
        for side in range(6):
            var neighbor: Vector2i = _neighbor(cell, side)
            if tiles.has(neighbor) and not bool(tiles[neighbor]["water"]):
                coastal_sides.append(side)
        if coastal_sides.is_empty():
            continue
        coastal_tiles += 1
        var middle: Vector3 = tiles[cell]["position"]
        middle.y += 0.055
        for side in range(6):
            var start: Vector3 = _corner(middle, radius * 0.987, side)
            var finish: Vector3 = _corner(middle, radius * 0.987, side + 1)
            _triangle(shallow, middle, start, finish, Color("#a5dbcf"))
        for side in coastal_sides:
            coastline_edges += 1
            var edge_a: Vector3 = _corner(middle + Vector3(0, 0.016, 0), radius * 1.012, side)
            var edge_b: Vector3 = _corner(middle + Vector3(0, 0.016, 0), radius * 1.012, side + 1)
            _ribbon(foam, edge_a, edge_b, 0.090, Color("#f5e6bc"))
    if coastal_tiles > 0:
        var water: MeshInstance3D = MeshInstance3D.new()
        water.name = "AguaRasa"
        water.mesh = shallow.commit()
        water.material_override = _material(Color(1, 1, 1, 0.35), true)
        water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        root.add_child(water)
    if coastline_edges > 0:
        var shoreline: MeshInstance3D = MeshInstance3D.new()
        shoreline.name = "LinhasDeCosta"
        shoreline.mesh = foam.commit()
        shoreline.material_override = _material(Color.WHITE, false)
        shoreline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        root.add_child(shoreline)
    root.set_meta("coastal_tiles", coastal_tiles)
    root.set_meta("coastline_edges", coastline_edges)
    return root


static func _neighbor(cell: Vector2i, side: int) -> Vector2i:
    if (cell.y & 1) == 1:
        var odd: Array[Vector2i] = [
            Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1),
            Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)
        ]
        return cell + odd[side]
    var even: Array[Vector2i] = [
        Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
        Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1)
    ]
    return cell + even[side]


static func _corner(center: Vector3, radius: float, index: int) -> Vector3:
    var angle: float = deg_to_rad(60.0 * float(index) - 30.0)
    return center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)


static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, tint: Color) -> void:
    for vertex in [a, b, c]:
        surface.set_color(tint)
        surface.add_vertex(vertex)


static func _ribbon(surface: SurfaceTool, a: Vector3, b: Vector3, width: float, tint: Color) -> void:
    var vector: Vector3 = (b - a).normalized()
    var side: Vector3 = Vector3(-vector.z, 0.0, vector.x) * width * 0.5
    _triangle(surface, a - side, a + side, b + side, tint)
    _triangle(surface, a - side, b + side, b - side, tint)


static func _material(tint: Color, alpha: bool) -> StandardMaterial3D:
    var mat: StandardMaterial3D = StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.vertex_color_use_as_albedo = true
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    if alpha:
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    return mat
