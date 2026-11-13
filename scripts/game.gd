extends Node3D
## M1: núcleo pequeno, independente do gerador visual e da HUD.
## Todos os modelos iniciais são construídos em 3D. Não depende de texturas externas.

signal state_changed

const CityRules = preload("res://scripts/city_rules.gd")
const DistrictRules = preload("res://scripts/district_rules.gd")
const DistrictVisuals = preload("res://scripts/district_visuals.gd")
const CityVisuals = preload("res://scripts/city_visuals.gd")
const UnitVisuals = preload("res://scripts/unit_visuals.gd")
const TerritoryVisuals = preload("res://scripts/territory_visuals.gd")
const HexNavigation = preload("res://scripts/hex_navigation.gd")
const MilitarySystem = preload("res://scripts/military_system.gd")
const ExplorationVisuals = preload("res://scripts/exploration_visuals.gd")

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
var last_event: String = "Explora o mundo e funda a capital."
var explored: Dictionary = {}
var visible_hexes: Dictionary = {}
var active_unit_id: int = -1
var selected_city_id: int = -1
var _id_counter: int = 1
var _models: Node3D
var _overlays: Node3D
var _infrastructure: Node3D
var _fog: Node3D
var _old_unit_positions: Dictionary = {}


func _ready() -> void:
    world = get_parent()
    _models = Node3D.new()
    _models.name = "ModelosDeJogo"
    add_child(_models)
    _overlays = Node3D.new()
    _overlays.name = "MarcadoresDeTerreno"
    add_child(_overlays)
    _infrastructure = Node3D.new()
    _infrastructure.name = "EstradasEFronteiras"
    add_child(_infrastructure)
    _fog = Node3D.new()
    _fog.name = "NevoeiroDaExploracao"
    add_child(_fog)
    world.map_ready.connect(_new_session)
    world.hex_selected.connect(_on_hex_selected)


func _new_session() -> void:
    units.clear()
    cities.clear()
    districts.clear()
    explored.clear()
    visible_hexes.clear()
    placing_district = ""
    last_event = "Nova expedição: escolhe onde fundar a capital."
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
        "health": 100,
        "move_points": HexNavigation.movement_capacity(kind),
        "route": [],
        "target_enemy": -1
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
    last_event = "Capital fundada. Agora podes produzir e explorar."
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
    last_event = "Produção de guerreiros iniciada."
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
    _refresh_overlays()
    state_changed.emit()
    return true


func cancel_placement() -> void:
    placing_district = ""
    _refresh_overlays()
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
    _refresh_overlays()
    state_changed.emit()
    return true


func set_city_focus(mode: String) -> void:
    var city: Dictionary = get_selected_city()
    if city.is_empty() or mode not in ["balanced", "food", "production"]:
        return
    city["focus"] = mode
    _refresh_overlays()
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
    MilitarySystem.begin_new_turn(self)
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
    MilitarySystem.rival_turn(self)
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
    issue_order(target)


func issue_order(target: Vector2i) -> bool:
    var accepted: bool = MilitarySystem.issue_order(self, target)
    _draw_models()
    state_changed.emit()
    return accepted


func unit_at(cell: Vector2i) -> Dictionary:
    return MilitarySystem.unit_on(self, cell)


func _draw_models() -> void:
    _calculate_visibility()
    _old_unit_positions.clear()
    for child in _models.get_children():
        if str(child.name).begins_with("Unidade_"):
            var parts: PackedStringArray = str(child.name).split("_")
            if parts.size() >= 2:
                _old_unit_positions[int(parts[1])] = child.position
        _models.remove_child(child)
        child.queue_free()
    for city in cities:
        if int(city["owner"]) == PLAYER or visible_hexes.has(city["coords"]):
            _make_city_model(city)
    for district in districts:
        if int(district["owner"]) != PLAYER and not visible_hexes.has(district["coords"]):
            continue
        var built_model: Node3D = DistrictVisuals.make(str(district["kind"]))
        built_model.name = "Distrito_%d_%s" % [int(district["id"]), str(district["kind"])]
        built_model.position = world.tiles[district["coords"]]["position"]
        _models.add_child(built_model)
    for unit in units:
        if int(unit["owner"]) == PLAYER or visible_hexes.has(unit["coords"]):
            _make_unit_model(unit)
    _refresh_infrastructure()
    _refresh_overlays()
    _refresh_exploration()


func _make_unit_model(unit: Dictionary) -> void:
    var model: Node3D = UnitVisuals.make(unit, int(unit["id"]) == active_unit_id)
    model.name = "Unidade_%d_%s" % [int(unit["id"]), str(unit["kind"])]
    var destination: Vector3 = world.tiles[unit["coords"]]["position"] + Vector3(0.0, 0.30, 0.0)
    model.position = destination
    _models.add_child(model)
    if _old_unit_positions.has(int(unit["id"])):
        var old_position: Vector3 = _old_unit_positions[int(unit["id"])]
        if old_position.distance_to(destination) > 0.05 and old_position.distance_to(destination) < 14.0:
            model.position = old_position
            if model.has_method("begin_march"):
                model.call("begin_march")
            var tween: Tween = create_tween()
            tween.tween_property(model, "position", destination, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
            if model.has_method("end_march"):
                tween.tween_callback(Callable(model, "end_march"))


func _make_city_model(city: Dictionary) -> void:
    var model: Node3D = CityVisuals.make(city)
    model.name = "Cidade_%d" % int(city["id"])
    model.position = world.tiles[city["coords"]]["position"]
    _models.add_child(model)


func _refresh_infrastructure() -> void:
    if _infrastructure == null:
        return
    for child in _infrastructure.get_children():
        _infrastructure.remove_child(child)
        child.queue_free()
    var observed_cities: Array[Dictionary] = []
    var observed_districts: Array[Dictionary] = []
    for city in cities:
        if int(city["owner"]) == PLAYER or visible_hexes.has(city["coords"]):
            observed_cities.append(city)
    for district in districts:
        if int(district["owner"]) == PLAYER or visible_hexes.has(district["coords"]):
            observed_districts.append(district)
    var infrastructure: Node3D = TerritoryVisuals.build(world.tiles, observed_cities, observed_districts)
    _infrastructure.add_child(infrastructure)


func _calculate_visibility() -> void:
    visible_hexes.clear()
    for unit in units:
        if int(unit["owner"]) == PLAYER:
            _reveal_around(unit["coords"], 3)
    for city in cities:
        if int(city["owner"]) == PLAYER:
            _reveal_around(city["coords"], 4)


func _refresh_exploration() -> void:
    _calculate_visibility()
    if world.hud.has_method("refresh_exploration"):
        world.hud.refresh_exploration(explored, visible_hexes)
    if _fog == null:
        return
    for child in _fog.get_children():
        _fog.remove_child(child)
        child.queue_free()
    _fog.add_child(ExplorationVisuals.build(world.tiles, explored, visible_hexes))


func _reveal_around(origin: Vector2i, radius: int) -> void:
    for cell in world.tiles:
        if HexNavigation.distance(cell, origin) <= radius:
            visible_hexes[cell] = true
            explored[cell] = true


func discovered_count() -> int:
    return explored.size()


func visible_count() -> int:
    return visible_hexes.size()


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
        "last_event": last_event,
        "explored": _encode_explored(),
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
    explored.clear()
    for coords in data.get("explored", []):
        if coords is Array and coords.size() == 2:
            var cell: Vector2i = Vector2i(int(coords[0]), int(coords[1]))
            if world.tiles.has(cell):
                explored[cell] = true
    last_event = str(data.get("last_event", "Campanha retomada."))
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
        if item.has("route"):
            var route_encoded: Array = []
            for step in item["route"]:
                route_encoded.append([int(step.x), int(step.y)])
            item["route"] = route_encoded
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
        if item.has("route"):
            var route_decoded: Array[Vector2i] = []
            for step in item["route"]:
                if step is Array and step.size() == 2:
                    route_decoded.append(Vector2i(int(step[0]), int(step[1])))
            item["route"] = route_decoded
        else:
            item["route"] = []
        if item.has("kind"):
            item["move_points"] = int(item.get("move_points", HexNavigation.movement_capacity(str(item["kind"]))))
            item["target_enemy"] = int(item.get("target_enemy", -1))
        decoded.append(item)
    return decoded


## Visualização do território: verde = parcela trabalhada; dourado = local válido.
func _refresh_overlays() -> void:
    if _overlays == null:
        return
    for child in _overlays.get_children():
        _overlays.remove_child(child)
        child.queue_free()
    var city: Dictionary = get_selected_city()
    if city.is_empty():
        var only_unit: Dictionary = get_active()
        if not only_unit.is_empty():
            for step in only_unit.get("route", []):
                if world.tiles.has(step):
                    _overlay_hex(step, "Rota", Color(0.19, 0.85, 0.99, 0.55), 0.35)
        return
    var yields: Dictionary = get_city_yields(city)
    for cell in yields["worked"]:
        _overlay_hex(cell, "Trabalhada", Color(0.37, 0.85, 0.52, 0.48), 0.29)
    if placing_district != "":
        for cell in world.tiles:
            if DistrictRules.can_place(placing_district, cell, city, world.tiles, cities, districts):
                _overlay_hex(cell, "Disponivel", Color(1.0, 0.80, 0.31, 0.61), 0.62)
    var active: Dictionary = get_active()
    if not active.is_empty():
        for step in active.get("route", []):
            if world.tiles.has(step):
                _overlay_hex(step, "Rota", Color(0.19, 0.85, 0.99, 0.55), 0.35)


func _overlay_hex(cell: Vector2i, prefix: String, tint: Color, radius: float) -> void:
    var marker: MeshInstance3D = MeshInstance3D.new()
    marker.name = "%s_%d_%d" % [prefix, cell.x, cell.y]
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = 0.06
    mesh.radial_segments = 6
    marker.mesh = mesh
    marker.position = world.tiles[cell]["position"] + Vector3(0.0, 0.28, 0.0)
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = tint
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    marker.material_override = material
    _overlays.add_child(marker)


func _encode_explored() -> Array:
    var data: Array = []
    for cell in explored:
        data.append([cell.x, cell.y])
    return data
