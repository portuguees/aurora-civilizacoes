extends Node3D
## M1: núcleo pequeno, independente do gerador visual e da HUD.
## Todos os modelos iniciais são construídos em 3D. Não depende de texturas externas.

signal state_changed

const CityRules = preload("res://scripts/city_rules.gd")
const DistrictRules = preload("res://scripts/district_rules.gd")
const DistrictVisuals = preload("res://scripts/district_visuals.gd")

const PLAYER: int = 0
const RIVAL: int = 1
const SAVE_PATH: String = "user://aurora_campanha.json"

var world: Variant
var turns: int = 1
var units: Array[Dictionary] = []
var cities: Array[Dictionary] = []
var districts: Array[Dictionary] = []
var placing_district: String = ""
var treasury: int = 90
var accumulated_science: int = 0
var active_unit_id: int = -1
var selected_city_id: int = -1
var _id_counter: int = 1
var _models: Node3D


func _ready() -> void:
    world = get_parent()
    _models = Node3D.new()
    _models.name = "ModelosDeJogo"
    add_child(_models)
    world.map_ready.connect(_new_session)
    world.hex_selected.connect(_on_hex_selected)


func _new_session() -> void:
    units.clear()
    cities.clear()
    districts.clear()
    placing_district = ""
    treasury = 90
    accumulated_science = 0
    turns = 1
    _id_counter = 1
    selected_city_id = -1
    var origin: Vector2i = _pick_start(Vector2i(15, 12), Vector2i(-1, -1))
    var enemy: Vector2i = _pick_start(Vector2i(27, 17), origin)
    _spawn_unit(PLAYER, "settler", origin)
    var guard: Vector2i = _free_neighbor(origin)
    _spawn_unit(PLAYER, "warrior", guard)
    _spawn_unit(RIVAL, "settler", enemy)
    active_unit_id = int(units[0]["id"])
    world.rig.center_on(world.tiles[origin]["position"])
    _draw_models()
    state_changed.emit()


func _pick_start(goal: Vector2i, avoid: Vector2i) -> Vector2i:
    var best: float = INF
    var answer: Vector2i = goal
    for cell in world.tiles:
        var data: Dictionary = world.tiles[cell]
        if bool(data["water"]) or str(data["biome"]) == "mountain":
            continue
        var dist: float = (Vector2(cell) - Vector2(goal)).length_squared()
        if avoid.x >= 0 and _hex_distance(cell, avoid) < 10:
            dist += 1000.0
        if dist < best:
            best = dist
            answer = cell
    return answer


func _free_neighbor(cell: Vector2i) -> Vector2i:
    for candidate in _neighbors(cell):
        if world.tiles.has(candidate) and not bool(world.tiles[candidate]["water"]):
            return candidate
    return cell


func _neighbors(cell: Vector2i) -> Array[Vector2i]:
    var odd: bool = (cell.y % 2) == 1
    var delta: Array[Vector2i] = [
        Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)
    ]
    if odd:
        delta.append(Vector2i(1, -1))
        delta.append(Vector2i(1, 1))
    else:
        delta.append(Vector2i(-1, -1))
        delta.append(Vector2i(-1, 1))
    var result: Array[Vector2i] = []
    for offset in delta:
        result.append(cell + offset)
    return result


func _hex_distance(a: Vector2i, b: Vector2i) -> int:
    var ax: int = a.x - (a.y - (a.y & 1)) / 2
    var bx: int = b.x - (b.y - (b.y & 1)) / 2
    var dq: int = ax - bx
    var dr: int = a.y - b.y
    return int((absi(dq) + absi(dr) + absi(dq + dr)) / 2)


func _spawn_unit(owner: int, kind: String, cell: Vector2i) -> void:
    units.append({
        "id": _id_counter,
        "owner": owner,
        "kind": kind,
        "coords": cell,
        "moved": false,
        "health": 100
    })
    _id_counter += 1


func player_unit_count() -> int:
    var result: int = 0
    for unit in units:
        if int(unit["owner"]) == PLAYER:
            result += 1
    return result


func unit_count() -> int:
    return units.size()


func city_count(owner: int = PLAYER) -> int:
    var result: int = 0
    for city in cities:
        if int(city["owner"]) == owner:
            result += 1
    return result


func get_active() -> Dictionary:
    for unit in units:
        if int(unit["id"]) == active_unit_id:
            return unit
    return {}


func has_starting_units() -> bool:
    var settler: bool = false
    var warrior: bool = false
    for unit in units:
        if int(unit["owner"]) != PLAYER:
            continue
        if str(unit["kind"]) == "settler":
            settler = true
        elif str(unit["kind"]) == "warrior":
            warrior = true
    return settler and warrior


func can_found() -> bool:
    var unit: Dictionary = get_active()
    if unit.is_empty() or str(unit["kind"]) != "settler" or int(unit["owner"]) != PLAYER:
        return false
    if city_count(PLAYER) >= 6:
        return false
    var cell: Vector2i = unit["coords"]
    if bool(world.tiles[cell]["water"]):
        return false
    for city in cities:
        if _hex_distance(cell, city["coords"]) < 4:
            return false
    return true


func found_city() -> void:
    if not can_found():
        return
    var unit: Dictionary = get_active()
    var cell: Vector2i = unit["coords"]
    cities.append({
        "id": _id_counter, "owner": PLAYER,
        "name": "Aurora" if city_count(PLAYER) == 0 else "Nova Aurora",
        "coords": cell, "population": 1, "food": 0,
        "production": 3, "project": "", "progress": 0,
        "site": Vector2i(-1, -1), "focus": "balanced"
    })
    selected_city_id = _id_counter
    _id_counter += 1
    units.erase(unit)
    active_unit_id = -1
    _draw_models()
    state_changed.emit()


func next_player_unit() -> void:
    var ids: Array[int] = []
    for unit in units:
        if int(unit["owner"]) == PLAYER:
            ids.append(int(unit["id"]))
    if ids.is_empty():
        return
    var idx: int = ids.find(active_unit_id)
    active_unit_id = ids[(idx + 1) % ids.size()]
    var target: Dictionary = get_active()
    world.rig.center_on(world.tiles[target["coords"]]["position"])
    _draw_models()
    state_changed.emit()


func get_selected_city() -> Dictionary:
    for city in cities:
        if int(city["id"]) == selected_city_id and int(city["owner"]) == PLAYER:
            return city
    return {}


func get_city_yields(city: Dictionary) -> Dictionary:
    return CityRules.evaluate(city, world.tiles, cities, districts)


func queue_warrior() -> void:
    var city: Dictionary = get_selected_city()
    if city.is_empty():
        for candidate in cities:
            if int(candidate["owner"]) == PLAYER:
                city = candidate
                break
    if city.is_empty() or str(city.get("project", "")) != "":
        return
    city["project"] = "warrior"
    city["site"] = Vector2i(-1, -1)
    city["progress"] = 0
    selected_city_id = int(city["id"])
    state_changed.emit()


func choose_district(kind: String) -> bool:
    var city: Dictionary = get_selected_city()
    if city.is_empty() or str(city.get("project", "")) != "" or not DistrictRules.COSTS.has(kind) or kind == "warrior":
        return false
    for built in districts:
        if int(built["city_id"]) == int(city["id"]) and str(built["kind"]) == kind:
            if kind not in ["farm", "mine"]:
                return false
    placing_district = kind
    active_unit_id = -1
    state_changed.emit()
    return true


func cancel_placement() -> void:
    placing_district = ""
    state_changed.emit()


func confirm_district(cell: Vector2i) -> bool:
    var city: Dictionary = get_selected_city()
    if city.is_empty() or placing_district == "" or str(city.get("project", "")) != "":
        return false
    if not DistrictRules.can_place(placing_district, cell, city, world.tiles, cities, districts):
        return false
    city["project"] = placing_district
    city["site"] = cell
    city["progress"] = 0
    placing_district = ""
    state_changed.emit()
    return true


func set_city_focus(mode: String) -> void:
    var city: Dictionary = get_selected_city()
    if city.is_empty() or mode not in ["balanced", "food", "production"]:
        return
    city["focus"] = mode
    state_changed.emit()


func _finish_project(city: Dictionary) -> void:
    var kind: String = str(city["project"])
    var site: Vector2i = city.get("site", Vector2i(-1, -1))
    if kind == "warrior":
        _spawn_unit(int(city["owner"]), "warrior", city["coords"])
    elif kind != "" and world.tiles.has(site):
        districts.append({
            "id": _id_counter, "owner": int(city["owner"]),
            "city_id": int(city["id"]), "kind": kind, "coords": site
        })
        _id_counter += 1
    city["project"] = ""
    city["site"] = Vector2i(-1, -1)
    city["progress"] = 0


func end_turn() -> void:
    turns += 1
    for unit in units:
        unit["moved"] = false
    for city in cities:
        var yields: Dictionary = get_city_yields(city)
        city["production"] = int(yields["production"])
        city["food"] = maxi(0, int(city["food"]) + int(yields["food_surplus"]))
        if int(city["population"]) < int(yields["housing"]) and int(city["food"]) >= CityRules.growth_cost(int(city["population"])):
            city["food"] = int(city["food"]) - CityRules.growth_cost(int(city["population"]))
            city["population"] = int(city["population"]) + 1
        if int(city["owner"]) == PLAYER:
            treasury += int(yields["gold"])
            accumulated_science += int(yields["science"])
        var project: String = str(city.get("project", ""))
        if DistrictRules.COSTS.has(project):
            city["progress"] = int(city["progress"]) + int(yields["production"])
            if int(city["progress"]) >= int(DistrictRules.COSTS[project]):
                _finish_project(city)

    if turns == 3 and city_count(RIVAL) == 0:
        for unit in units.duplicate():
            if int(unit["owner"]) == RIVAL and str(unit["kind"]) == "settler":
                var enemy_cell: Vector2i = unit["coords"]
                cities.append({
                    "id": _id_counter, "owner": RIVAL,
                    "name": "Valdoria", "coords": enemy_cell, "population": 1,
                    "food": 0, "production": 3, "project": "", "progress": 0,
                    "site": Vector2i(-1, -1), "focus": "balanced"
                })
                _id_counter += 1
                units.erase(unit)
                break
    _draw_models()
    state_changed.emit()


func _on_hex_selected(cell: Vector2i) -> void:
    if placing_district != "":
        confirm_district(cell)
        return
    for unit in units:
        if int(unit["owner"]) == PLAYER and unit["coords"] == cell:
            active_unit_id = int(unit["id"])
            _draw_models()
            state_changed.emit()
            return
    for city in cities:
        if int(city["owner"]) == PLAYER and city["coords"] == cell:
            selected_city_id = int(city["id"])
            placing_district = ""
            active_unit_id = -1
            _draw_models()
            state_changed.emit()
            return


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key: InputEventKey = event
        if not key.pressed or key.echo:
            return
        if key.keycode == KEY_F:
            found_city()
        elif key.keycode == KEY_E:
            end_turn()
        elif key.keycode == KEY_J:
            next_player_unit()
        elif key.keycode == KEY_ESCAPE:
            cancel_placement()
    elif event is InputEventMouseButton:
        var mouse: InputEventMouseButton = event
        if mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
            # Um clique direito é uma ordem; o terreno continua selecionável pelo esquerdo.
            var target: Vector2i = world.cell_at_screen(mouse.position)
            _move_selected(target)


func _move_selected(target: Vector2i) -> void:
    if not world.tiles.has(target) or bool(world.tiles[target]["water"]):
        return
    var active: Dictionary = get_active()
    if active.is_empty() or int(active["owner"]) != PLAYER or bool(active["moved"]):
        return
    if _hex_distance(active["coords"], target) != 1:
        return
    for unit in units:
        if unit["coords"] == target and int(unit["owner"]) != PLAYER:
            # Primeiro sistema de combate: ataque adjacente.
            units.erase(unit)
            break
        elif unit["coords"] == target and int(unit["owner"]) == PLAYER:
            return
    active["coords"] = target
    active["moved"] = true
    _draw_models()
    state_changed.emit()


func _draw_models() -> void:
    for child in _models.get_children():
        child.queue_free()
    for city in cities:
        _make_city_model(city)
    for district in districts:
        var built_model: Node3D = DistrictVisuals.make(str(district["kind"]))
        built_model.name = "Distrito_%d_%s" % [int(district["id"]), str(district["kind"])]
        built_model.position = world.tiles[district["coords"]]["position"]
        _models.add_child(built_model)
    for unit in units:
        _make_unit_model(unit)


func _make_unit_model(unit: Dictionary) -> void:
    var model: Node3D = Node3D.new()
    model.name = "Unidade_%d_%s" % [int(unit["id"]), str(unit["kind"])]
    model.position = world.tiles[unit["coords"]]["position"] + Vector3(0, 0.30, 0)
    _models.add_child(model)
    var color: Color = Color("#4bc9f1") if int(unit["owner"]) == PLAYER else Color("#e9a16c")
    var is_settler: bool = str(unit["kind"]) == "settler"

    var body: CylinderMesh = CylinderMesh.new()
    body.top_radius = 0.20
    body.bottom_radius = 0.27
    body.height = 0.80
    body.radial_segments = 8
    var torso: MeshInstance3D = MeshInstance3D.new()
    torso.mesh = body
    torso.position.y = 0.47
    torso.material_override = _mat(color)
    model.add_child(torso)

    var head: SphereMesh = SphereMesh.new()
    head.radius = 0.21
    head.height = 0.42
    var face: MeshInstance3D = MeshInstance3D.new()
    face.mesh = head
    face.position.y = 1.10
    face.material_override = _mat(Color("#eed3a8"))
    model.add_child(face)

    var banner: BoxMesh = BoxMesh.new()
    banner.size = Vector3(0.68, 0.39, 0.055)
    var cloth: MeshInstance3D = MeshInstance3D.new()
    cloth.mesh = banner
    cloth.material_override = _mat(color)
    cloth.position = Vector3(0.35, 1.52, 0)
    model.add_child(cloth)

    var pole: CylinderMesh = CylinderMesh.new()
    pole.top_radius = 0.035
    pole.bottom_radius = 0.045
    pole.height = 1.72
    var staff: MeshInstance3D = MeshInstance3D.new()
    staff.mesh = pole
    staff.position = Vector3(0.0, 0.90, 0.0)
    staff.material_override = _mat(Color("#70583b"))
    model.add_child(staff)

    var sign: Label3D = Label3D.new()
    sign.text = "COLONO" if is_settler else "GUERREIRO"
    sign.font_size = 32
    sign.pixel_size = 0.0045
    sign.outline_size = 8
    sign.position.y = 2.11
    sign.modulate = Color("#f1f0da")
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    model.add_child(sign)

    if int(unit["id"]) == active_unit_id:
        var ring: MeshInstance3D = MeshInstance3D.new()
        var cylinder: CylinderMesh = CylinderMesh.new()
        cylinder.top_radius = 0.74
        cylinder.bottom_radius = 0.74
        cylinder.height = 0.045
        ring.mesh = cylinder
        ring.position.y = 0.06
        ring.material_override = _mat(Color("#ffda7c"))
        model.add_child(ring)


func _make_city_model(city: Dictionary) -> void:
    var model: Node3D = Node3D.new()
    model.name = "Cidade_%d" % int(city["id"])
    model.position = world.tiles[city["coords"]]["position"]
    _models.add_child(model)
    var tint: Color = Color("#4bc9f1") if int(city["owner"]) == PLAYER else Color("#e9a16c")
    var foundation: CylinderMesh = CylinderMesh.new()
    foundation.top_radius = 0.80
    foundation.bottom_radius = 1.01
    foundation.height = 0.22
    var square: MeshInstance3D = MeshInstance3D.new()
    square.mesh = foundation
    square.position.y = 0.14
    square.material_override = _mat(Color("#d1b992"))
    model.add_child(square)

    for i in range(mini(4 + maxi(0, int(city["population"]) - 1), 6)):
        var building: MeshInstance3D = MeshInstance3D.new()
        var house: BoxMesh = BoxMesh.new()
        house.size = Vector3(0.38, 0.42 + 0.06 * float(i), 0.37)
        building.mesh = house
        building.position = Vector3(-0.35 + float(i % 2) * 0.70, 0.45, -0.35 + float(i / 2) * 0.70)
        building.material_override = _mat(Color("#eee3c7"))
        model.add_child(building)
    var sign: Label3D = Label3D.new()
    sign.text = "%s  •  %d" % [str(city["name"]), int(city["population"])]
    sign.font_size = 34
    sign.pixel_size = 0.005
    sign.outline_size = 7
    sign.position.y = 1.85
    sign.modulate = tint
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    model.add_child(sign)


func _mat(tint: Color) -> StandardMaterial3D:
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = 0.95
    return material


## Gravação M2: todos os estados simulados usam dados JSON simples.
## Os modelos 3D são reconstruídos ao restaurar a partida.
func save_game() -> bool:
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return false
    var data: Dictionary = {
        "format": 2,
        "seed": world.seed_value,
        "turns": turns,
        "treasury": treasury,
        "science": accumulated_science,
        "next_id": _id_counter,
        "active_unit": active_unit_id,
        "selected_city": selected_city_id,
        "units": _encode_entries(units),
        "cities": _encode_entries(cities),
        "districts": _encode_entries(districts)
    }
    file.store_string(JSON.stringify(data))
    file.close()
    return true


func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)


func load_game() -> bool:
    if not has_save():
        return false
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return false
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not parsed is Dictionary:
        return false
    var data: Dictionary = parsed
    if int(data.get("format", 0)) != 2:
        return false
    if not data.has("units") or not data.has("cities") or not data.has("districts"):
        return false
    var saved_seed: int = int(data.get("seed", world.seed_value))
    if saved_seed != int(world.seed_value):
        world.regenerate(saved_seed)
    units = _decode_entries(data["units"])
    cities = _decode_entries(data["cities"])
    districts = _decode_entries(data["districts"])
    turns = maxi(1, int(data.get("turns", 1)))
    treasury = int(data.get("treasury", 90))
    accumulated_science = int(data.get("science", 0))
    _id_counter = maxi(1, int(data.get("next_id", 1)))
    active_unit_id = int(data.get("active_unit", -1))
    selected_city_id = int(data.get("selected_city", -1))
    placing_district = ""
    _draw_models()
    var active: Dictionary = get_active()
    if not active.is_empty() and world.tiles.has(active["coords"]):
        world.rig.center_on(world.tiles[active["coords"]]["position"])
    else:
        var city: Dictionary = get_selected_city()
        if not city.is_empty() and world.tiles.has(city["coords"]):
            world.rig.center_on(world.tiles[city["coords"]]["position"])
    state_changed.emit()
    return true


func _encode_entries(entries: Array[Dictionary]) -> Array:
    var encoded: Array = []
    for entry in entries:
        var item: Dictionary = entry.duplicate(true)
        var coords: Vector2i = item.get("coords", Vector2i(-1, -1))
        item["coords"] = [coords.x, coords.y]
        if item.has("site"):
            var site: Vector2i = item["site"]
            item["site"] = [site.x, site.y]
        encoded.append(item)
    return encoded


func _decode_entries(entries: Array) -> Array[Dictionary]:
    var decoded: Array[Dictionary] = []
    for entry in entries:
        if not entry is Dictionary:
            continue
        var item: Dictionary = entry.duplicate(true)
        var xy: Array = item.get("coords", [-1, -1])
        if xy.size() != 2:
            continue
        item["coords"] = Vector2i(int(xy[0]), int(xy[1]))
        if item.has("site"):
            var site: Array = item["site"]
            if site.size() == 2:
                item["site"] = Vector2i(int(site[0]), int(site[1]))
            else:
                item["site"] = Vector2i(-1, -1)
        decoded.append(item)
    return decoded
