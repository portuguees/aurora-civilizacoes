extends Node3D
## M0: terreno 3D original de hexágonos. Nenhuma dependência de assets binários.
## Este script não contém simulação; M1 introduzirá entidades e turnos em módulos separados.

signal map_ready
signal hex_selected(cell: Vector2i)

const WIDTH: int = 32
const HEIGHT: int = 24
const RADIUS: float = 1.35
const SEA_LEVEL: float = 0.08

@onready var terrain: Node3D = $Terrain
@onready var rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var environment_node: WorldEnvironment = $WorldEnvironment
@onready var hud: CanvasLayer = $HUD

var seed_value: int = 481022
var tiles: Dictionary = {}
var selected: Vector2i = Vector2i(-1, -1)
var _map_ready: bool = false
var _selection_mesh: MeshInstance3D


func _ready() -> void:
    _configure_environment()
    regenerate(seed_value)


func regenerate(new_seed: int) -> void:
    seed_value = new_seed
    _map_ready = false
    for child in terrain.get_children():
        child.queue_free()
    tiles.clear()
    selected = Vector2i(-1, -1)
    _build_terrain()
    _build_selection()
    _map_ready = true
    rig.set_limits(float(WIDTH) * 2.5, float(HEIGHT) * 2.0)
    if hud.has_method("refresh_map"):
        hud.refresh_map(tiles, WIDTH, HEIGHT)
    map_ready.emit()


func is_map_ready() -> bool:
    return _map_ready


func land_count() -> int:
    var count: int = 0
    for cell in tiles:
        if not bool(tiles[cell]["water"]):
            count += 1
    return count


func _hex_center(cell: Vector2i) -> Vector3:
    var x: float = sqrt(3.0) * RADIUS * (float(cell.x) + 0.5 * float(cell.y % 2))
    var z: float = 1.5 * RADIUS * float(cell.y)
    x -= sqrt(3.0) * RADIUS * float(WIDTH) * 0.5
    z -= 1.5 * RADIUS * float(HEIGHT - 1) * 0.5
    return Vector3(x, 0.0, z)


func _build_terrain() -> void:
    var noise: FastNoiseLite = FastNoiseLite.new()
    noise.seed = seed_value
    noise.frequency = 0.10
    var climate: FastNoiseLite = FastNoiseLite.new()
    climate.seed = seed_value + 203
    climate.frequency = 0.16
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = seed_value

    var land_tool: SurfaceTool = SurfaceTool.new()
    var water_tool: SurfaceTool = SurfaceTool.new()
    land_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    water_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

    var trees: Array[Transform3D] = []
    var rocks: Array[Transform3D] = []

    for y in range(HEIGHT):
        for x in range(WIDTH):
            var cell: Vector2i = Vector2i(x, y)
            var dx: float = (float(x) - float(WIDTH - 1) * 0.5) / float(WIDTH) * 2.0
            var dy: float = (float(y) - float(HEIGHT - 1) * 0.5) / float(HEIGHT) * 2.0
            var rim: float = pow(dx * dx + dy * dy, 0.70)
            var elevation: float = noise.get_noise_2d(float(x), float(y)) * 0.65 + 0.41 - rim * 0.52
            var water: bool = elevation < 0.06
            var height: float = SEA_LEVEL if water else 0.23 + maxf(0.0, elevation) * 1.05
            var climate_value: float = climate.get_noise_2d(float(x), float(y))
            var biome: String = "water"
            var tile_color: Color = Color("#328a98")

            if not water:
                if elevation > 0.53:
                    biome = "mountain"
                    tile_color = Color("#8f9587")
                elif elevation > 0.33:
                    biome = "hills"
                    tile_color = Color("#888d73")
                elif climate_value < -0.23:
                    biome = "plains"
                    tile_color = Color("#b7ad78")
                elif climate_value > 0.12:
                    biome = "forest"
                    tile_color = Color("#537a58")
                else:
                    biome = "grassland"
                    tile_color = Color("#82a66e")

            var center: Vector3 = _hex_center(cell)
            center.y = height
            tiles[cell] = {
                "position": center,
                "water": water,
                "biome": biome,
                "color": tile_color
            }

            var tool: SurfaceTool = water_tool if water else land_tool
            for side in range(6):
                var a: Vector3 = _corner(center, side)
                var b: Vector3 = _corner(center, side + 1)
                _triangle(tool, center, a, b, tile_color)
                if not water:
                    var down_a: Vector3 = Vector3(a.x, SEA_LEVEL - 0.04, a.z)
                    var down_b: Vector3 = Vector3(b.x, SEA_LEVEL - 0.04, b.z)
                    var edge_color: Color = tile_color.darkened(0.19)
                    _triangle(tool, a, down_a, b, edge_color)
                    _triangle(tool, b, down_a, down_b, edge_color)

            if water:
                continue
            if biome == "forest" or biome == "grassland" or biome == "plains":
                var amount: int = 4 if biome == "forest" else (2 if biome == "grassland" else 1)
                for k in range(amount):
                    var scatter: Vector2 = Vector2(rng.randf_range(-0.69, 0.69), rng.randf_range(-0.69, 0.69))
                    var place: Vector3 = center + Vector3(scatter.x, 0.38, scatter.y)
                    var scale_value: float = rng.randf_range(0.68, 1.45)
                    trees.append(Transform3D(Basis().scaled(Vector3(scale_value, scale_value, scale_value)), place))
            elif biome == "hills" or biome == "mountain":
                for k in range(2):
                    var place: Vector3 = center + Vector3(rng.randf_range(-0.44, 0.44), 0.20, rng.randf_range(-0.44, 0.44))
                    var scale_value: float = rng.randf_range(0.48, 1.22)
                    rocks.append(Transform3D(Basis().scaled(Vector3(scale_value, scale_value, scale_value)), place))

    _add_surface("Terras", land_tool, _material(Color.WHITE, true))
    _add_surface("Agua", water_tool, _material(Color("#3e91a1"), true))
    _build_instances("Florestas", _tree_mesh(), trees, Color("#355f48"))
    _build_instances("Rochas", _rock_mesh(), rocks, Color("#666e6a"))
    _build_sea_backdrop()


func _corner(center: Vector3, side: int) -> Vector3:
    var theta: float = PI / 180.0 * (60.0 * float(side) - 30.0)
    return Vector3(center.x + RADIUS * cos(theta), center.y, center.z + RADIUS * sin(theta))


func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, tint: Color) -> void:
    tool.set_color(tint)
    tool.add_vertex(a)
    tool.set_color(tint)
    tool.add_vertex(b)
    tool.set_color(tint)
    tool.add_vertex(c)


func _add_surface(label: String, tool: SurfaceTool, material: Material) -> void:
    tool.generate_normals()
    var node: MeshInstance3D = MeshInstance3D.new()
    node.name = label
    node.mesh = tool.commit()
    node.material_override = material
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    terrain.add_child(node)


func _material(tint: Color, vertex_colors: bool = false) -> StandardMaterial3D:
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = tint
    material.vertex_color_use_as_albedo = vertex_colors
    material.roughness = 0.94
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    return material


func _tree_mesh() -> Mesh:
    var tree: CylinderMesh = CylinderMesh.new()
    tree.top_radius = 0.05
    tree.bottom_radius = 0.38
    tree.height = 1.0
    tree.radial_segments = 5
    tree.rings = 1
    return tree


func _rock_mesh() -> Mesh:
    var rock: SphereMesh = SphereMesh.new()
    rock.radius = 0.43
    rock.height = 0.58
    rock.radial_segments = 6
    rock.rings = 3
    return rock


func _build_instances(label: String, geometry: Mesh, placements: Array[Transform3D], tint: Color) -> void:
    if placements.is_empty():
        return
    var batch: MultiMesh = MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.mesh = geometry
    batch.instance_count = placements.size()
    for idx in range(placements.size()):
        batch.set_instance_transform(idx, placements[idx])
    var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
    node.name = label
    node.multimesh = batch
    node.material_override = _material(tint)
    terrain.add_child(node)


func _build_sea_backdrop() -> void:
    var sea: MeshInstance3D = MeshInstance3D.new()
    sea.name = "Oceano_Exterior"
    var plane: PlaneMesh = PlaneMesh.new()
    plane.size = Vector2(245.0, 245.0)
    sea.mesh = plane
    sea.position.y = SEA_LEVEL - 0.15
    sea.material_override = _material(Color("#28697b"))
    sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    terrain.add_child(sea)


func _configure_environment() -> void:
    var environment: Environment = Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#86aeb5")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#c8d6ce")
    environment.ambient_light_energy = 0.72
    environment_node.environment = environment


func _build_selection() -> void:
    var line_material: StandardMaterial3D = StandardMaterial3D.new()
    line_material.albedo_color = Color("#ffe0a0")
    line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    var immediate: ImmediateMesh = ImmediateMesh.new()
    immediate.surface_begin(Mesh.PRIMITIVE_LINES, line_material)
    for side in range(6):
        var a: Vector3 = _corner(Vector3.ZERO, side)
        var b: Vector3 = _corner(Vector3.ZERO, side + 1)
        immediate.surface_add_vertex(a * 1.015)
        immediate.surface_add_vertex(b * 1.015)
    immediate.surface_end()
    _selection_mesh = MeshInstance3D.new()
    _selection_mesh.name = "Selecao"
    _selection_mesh.mesh = immediate
    _selection_mesh.visible = false
    terrain.add_child(_selection_mesh)


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var click: InputEventMouseButton = event
        if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
            _select_under_mouse(click.position)


func _select_under_mouse(mouse_pos: Vector2) -> void:
    var origin: Vector3 = camera.project_ray_origin(mouse_pos)
    var direction: Vector3 = camera.project_ray_normal(mouse_pos)
    if absf(direction.y) < 0.001:
        return
    var t: float = (SEA_LEVEL - origin.y) / direction.y
    if t <= 0.0:
        return
    var impact: Vector3 = origin + direction * t
    var nearest: Vector2i = Vector2i(-1, -1)
    var best: float = RADIUS * RADIUS * 2.4
    for cell in tiles:
        var tile_pos: Vector3 = tiles[cell]["position"]
        var dist: float = Vector2(impact.x - tile_pos.x, impact.z - tile_pos.z).length_squared()
        if dist < best:
            best = dist
            nearest = cell
    if nearest.x < 0:
        return
    selected = nearest
    _selection_mesh.visible = true
    _selection_mesh.position = tiles[nearest]["position"] + Vector3(0.0, 0.11, 0.0)
    if hud.has_method("set_selection"):
        hud.set_selection(nearest, str(tiles[nearest]["biome"]))
    hex_selected.emit(nearest)


func focus_center() -> void:
    rig.center_on(Vector3.ZERO)


func new_map() -> void:
    regenerate(randi_range(100000, 900000))


func cell_at_screen(mouse_pos: Vector2) -> Vector2i:
    var origin: Vector3 = camera.project_ray_origin(mouse_pos)
    var direction: Vector3 = camera.project_ray_normal(mouse_pos)
    if absf(direction.y) < 0.001:
        return Vector2i(-1, -1)
    var t: float = (SEA_LEVEL - origin.y) / direction.y
    if t <= 0.0:
        return Vector2i(-1, -1)
    var hit: Vector3 = origin + direction * t
    var result: Vector2i = Vector2i(-1, -1)
    var best: float = RADIUS * RADIUS * 2.5
    for cell in tiles:
        var center: Vector3 = tiles[cell]["position"]
        var d: float = Vector2(hit.x - center.x, hit.z - center.z).length_squared()
        if d < best:
            best = d
            result = cell
    return result
