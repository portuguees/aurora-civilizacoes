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
const CombatFX = preload("res://scripts/combat_fx.gd")
const ConstructionVisuals = preload("res://scripts/construction_visuals.gd")
const TechnologyRules = preload("res://scripts/technology_rules.gd")
const CivicRules = preload("res://scripts/civic_rules.gd")
const DiplomacyRules = preload("res://scripts/diplomacy_rules.gd")
const VictoryRules = preload("res://scripts/victory_rules.gd")
const PolicyRules = preload("res://scripts/policy_rules.gd")
const WonderRules = preload("res://scripts/wonder_rules.gd")
const WonderVisuals = preload("res://scripts/wonder_visuals.gd")
const RivalAIRules = preload("res://scripts/rival_ai_rules.gd")

const PLAYER: int = 0
const RIVAL: int = 1
const SAVE_PATH: String = "user://aurora_campanha.json"

var world: Variant
var turns: int = 1
var units: Array[Dictionary] = []
var cities: Array[Dictionary] = []
var districts: Array[Dictionary] = []
var wonders: Array[Dictionary] = []
var active_policy: String = ""
var placing_district: String = ""
var treasury: int = 90
var accumulated_science: int = 0
var researched: Array[String] = []
var current_technology: String = ""
var research_progress: Dictionary = {}
var accumulated_culture: int = 0
var civics_completed: Array[String] = []
var current_civic: String = ""
var civic_progress: Dictionary = {}
var government: String = "chiefdom"
var diplomacy: Dictionary = {}
var rival_founded: bool = false
var game_over: bool = false
var victory_type: String = ""
var victory_turn: int = 0
var rival_goal: String = "Explorar"
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
var _combat_marks: Array[Dictionary] = []
var _combat_visuals: Node3D


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
    _combat_visuals = Node3D.new()
    _combat_visuals.name = "CombateVisual"
    add_child(_combat_visuals)
    world.map_ready.connect(_new_session)
    world.hex_selected.connect(_on_hex_selected)


func _new_session() -> void:
    units.clear()
    _combat_marks.clear()
    cities.clear()
    districts.clear()
    wonders.clear()
    active_policy = ""
    explored.clear()
    visible_hexes.clear()
    placing_district = ""
    last_event = "Nova expedição: escolhe onde fundar a capital."
    treasury = 90
    accumulated_science = 0
    researched.clear()
    research_progress.clear()
    current_technology = ""
    accumulated_culture = 0
    civics_completed.clear()
    civic_progress.clear()
    current_civic = ""
    government = "chiefdom"
    diplomacy = DiplomacyRules.initial_state()
    rival_founded = false
    game_over = false
    victory_type = ""
    victory_turn = 0
    rival_goal = "Explorar"
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
        "target_enemy": -1,
        "charges": 2 if kind == "builder" else 0,
        "experience": 0
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
    if game_over:
        return false
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
    var yields: Dictionary = CityRules.evaluate(city, world.tiles, cities, districts)
    if int(city["owner"]) == PLAYER:
        if researched.has("agriculture"):
            yields["food"] = int(yields["food"]) + 1
            yields["food_surplus"] = int(yields["food_surplus"]) + 1
        if researched.has("mining"):
            yields["production"] = int(yields["production"]) + 2
        if researched.has("writing"):
            yields["science"] = int(yields["science"]) + 2
        if researched.has("commerce"):
            yields["gold"] = int(yields["gold"]) + 3
        if researched.has("engineering"):
            yields["production"] = int(yields["production"]) + 2
    yields["culture"] = 1 + int(city["population"])
    if int(city["owner"]) == PLAYER:
        CivicRules.apply_yields(yields, civics_completed, government)
        PolicyRules.apply(yields, active_policy)
    for wonder in wonders:
        if int(wonder["city_id"]) == int(city["id"]):
            WonderRules.bonus(wonder, yields)
    return yields


func choose_policy(key: String) -> bool:
    if game_over or not PolicyRules.unlocked(key, civics_completed):
        return false
    active_policy = key
    last_event = "Política ativa: %s." % (
        str(PolicyRules.POLICIES[key]["name"]) if key != "" else "Nenhuma"
    )
    state_changed.emit()
    return true


func queue_wonder(kind: String) -> bool:
    if game_over or not WonderRules.can_build(kind, researched, wonders):
        return false
    for city in cities:
        if str(city.get("project", "")) == kind:
            return false
    var city: Dictionary = get_selected_city()
    if city.is_empty() or int(city["owner"]) != PLAYER or str(city.get("project", "")) != "":
        return false
    city["project"] = kind
    city["site"] = Vector2i(-1, -1)
    city["progress"] = 0
    last_event = "Maravilha iniciada: %s." % str(WonderRules.WONDERS[kind]["name"])
    state_changed.emit()
    return true


func choose_civic(key: String) -> bool:
    if game_over or not CivicRules.can_start(key, civics_completed):
        return false
    current_civic = key
    last_event = "Novo princípio cívico: %s." % CivicRules.title(key)
    state_changed.emit()
    return true


func _add_culture(amount: int) -> void:
    if current_civic == "" or not CivicRules.CIVICS.has(current_civic):
        return
    var key: String = current_civic
    civic_progress[key] = int(civic_progress.get(key, 0)) + amount
    if int(civic_progress[key]) >= CivicRules.cost(key):
        civics_completed.append(key)
        current_civic = ""
        last_event = "Princípio cívico concluído: %s." % CivicRules.title(key)


func civic_status() -> Dictionary:
    return {
        "name": CivicRules.title(current_civic),
        "cost": CivicRules.cost(current_civic),
        "progress": int(civic_progress.get(current_civic, 0)),
        "completed": civics_completed.size(),
        "culture": accumulated_culture,
        "government": str(CivicRules.GOVERNMENTS[government]["name"])
    }


func choose_government(key: String) -> bool:
    if game_over or not CivicRules.government_unlocked(key, civics_completed):
        return false
    government = key
    last_event = "Novo governo: %s." % str(CivicRules.GOVERNMENTS[key]["name"])
    state_changed.emit()
    return true


func has_contact() -> bool:
    return DiplomacyRules.contact(self)


func is_at_peace() -> bool:
    return DiplomacyRules.is_at_peace(diplomacy)


func can_gift() -> bool:
    return DiplomacyRules.can_gift(self)


func can_peace() -> bool:
    return DiplomacyRules.can_peace(self)


func can_trade() -> bool:
    return DiplomacyRules.can_trade(self)


func send_gift() -> bool:
    var accepted: bool = DiplomacyRules.gift(self)
    if accepted:
        state_changed.emit()
    return accepted


func negotiate_peace() -> bool:
    var accepted: bool = DiplomacyRules.peace(self)
    if accepted:
        state_changed.emit()
    return accepted


func start_trade() -> bool:
    var accepted: bool = DiplomacyRules.trade(self)
    if accepted:
        state_changed.emit()
    return accepted


func declare_war() -> bool:
    var accepted: bool = DiplomacyRules.declare_war(self)
    if accepted:
        state_changed.emit()
    return accepted


func note_hostility(attacker_owner: int, defender_owner: int) -> void:
    DiplomacyRules.hostility(self, attacker_owner, defender_owner)


func victory_details() -> Dictionary:
    return VictoryRules.describe(self)


func can_capture_rival() -> bool:
    return VictoryRules.can_capture(self)


func capture_rival_capital() -> bool:
    if not can_capture_rival():
        return false
    for city in cities:
        if int(city["owner"]) != RIVAL:
            continue
        var captured_id: int = int(city["id"])
        city["owner"] = PLAYER
        city["name"] = "Valdoria Conquistada"
        city["project"] = ""
        city["progress"] = 0
        city["site"] = Vector2i(-1, -1)
        for district in districts:
            if int(district["city_id"]) == captured_id:
                district["owner"] = PLAYER
        selected_city_id = captured_id
        last_event = "Valdoria conquistada! A campanha militar foi concluída."
        _evaluate_victory()
        _draw_models()
        state_changed.emit()
        return true
    return false


func _evaluate_victory() -> void:
    var winner: String = VictoryRules.check(self)
    if winner == "":
        return
    victory_type = winner
    victory_turn = turns
    game_over = true
    last_event = "%s no turno %d!" % [str(VictoryRules.TITLES[winner]), turns]


func _rival_planning() -> void:
    if not rival_founded or city_count(RIVAL) == 0 or game_over:
        return
    for city in cities:
        if int(city["owner"]) != RIVAL or str(city.get("project", "")) != "":
            continue
        var plan: Dictionary = RivalAIRules.choose(self, city)
        var kind: String = str(plan.get("kind", ""))
        rival_goal = str(plan.get("goal", "Defender o território"))
        if kind == "":
            continue
        if not DistrictRules.COSTS.has(kind):
            continue
        city["project"] = kind
        city["site"] = plan.get("site", Vector2i(-1, -1))
        city["progress"] = 0


func available_technologies() -> Array[String]:
    return TechnologyRules.available(researched)


func choose_technology(key: String) -> bool:
    if game_over or not TechnologyRules.can_start(key, researched):
        return false
    current_technology = key
    last_event = "Investigação selecionada: %s." % TechnologyRules.title(key)
    state_changed.emit()
    return true


func technology_attack_bonus(owner: int) -> int:
    var bonus: int = 8 if owner == PLAYER and researched.has("metallurgy") else 0
    if owner == PLAYER:
        bonus += PolicyRules.attack_bonus(active_policy)
    return bonus


func research_status() -> Dictionary:
    return {
        "name": TechnologyRules.title(current_technology),
        "cost": TechnologyRules.cost(current_technology),
        "progress": int(research_progress.get(current_technology, 0)),
        "completed": researched.size()
    }


func _add_research(science_income: int) -> void:
    if current_technology == "" or not TechnologyRules.TECHS.has(current_technology):
        return
    var key: String = current_technology
    research_progress[key] = int(research_progress.get(key, 0)) + science_income
    if int(research_progress[key]) >= TechnologyRules.cost(key):
        researched.append(key)
        current_technology = ""
        last_event = "Tecnologia concluída: %s! Efeitos aplicados ao império." % TechnologyRules.title(key)



func queue_warrior() -> void:
    queue_unit("warrior")


func queue_unit(kind: String) -> bool:
    if game_over or kind not in ["warrior", "builder", "archer"]:
        return false
    if kind == "archer" and not researched.has("metallurgy"):
        last_event = "Arqueiros requerem Metalurgia."
        state_changed.emit()
        return false
    var city: Dictionary = get_selected_city()
    if city.is_empty():
        for candidate in cities:
            if int(candidate["owner"]) == PLAYER:
                city = candidate
                break
    if city.is_empty() or str(city.get("project", "")) != "":
        return false
    city["project"] = kind
    city["site"] = Vector2i(-1, -1)
    city["progress"] = 0
    selected_city_id = int(city["id"])
    last_event = "Produção de %s iniciada." % str(DistrictRules.LABELS[kind])
    state_changed.emit()
    return true


func builder_can_improve(kind: String) -> bool:
    if game_over or kind not in ["farm", "mine"]:
        return false
    var builder: Dictionary = get_active()
    if builder.is_empty() or str(builder["kind"]) != "builder" or int(builder["owner"]) != PLAYER:
        return false
    if int(builder.get("charges", 0)) <= 0 or int(builder.get("move_points", 0)) <= 0:
        return false
    var site: Vector2i = builder["coords"]
    for city in cities:
        if int(city["owner"]) == PLAYER and DistrictRules.can_place(kind, site, city, world.tiles, cities, districts):
            return true
    return false


func builder_improve(kind: String) -> bool:
    if not builder_can_improve(kind):
        return false
    var builder: Dictionary = get_active()
    for city in cities:
        if int(city["owner"]) != PLAYER or not DistrictRules.can_place(kind, builder["coords"], city, world.tiles, cities, districts):
            continue
        districts.append({
            "id": _id_counter, "owner": PLAYER,
            "city_id": int(city["id"]), "kind": kind, "coords": builder["coords"]
        })
        _id_counter += 1
        builder["charges"] = int(builder["charges"]) - 1
        builder["move_points"] = 0
        builder["route"] = []
        if int(builder["charges"]) <= 0:
            units.erase(builder)
            active_unit_id = -1
        last_event = "Construtor concluiu %s. Cargas restantes: %d." % [
            str(DistrictRules.LABELS[kind]), maxi(0, int(builder["charges"]))
        ]
        _draw_models()
        state_changed.emit()
        return true
    return false


func choose_district(kind: String) -> bool:
    if game_over:
        return false
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
    if game_over:
        return false
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
    if game_over:
        return
    var city: Dictionary = get_selected_city()
    if city.is_empty() or mode not in ["balanced", "food", "production"]:
        return
    city["focus"] = mode
    _refresh_overlays()
    state_changed.emit()


func _finish_project(city: Dictionary) -> void:
    var kind: String = str(city["project"])
    var site: Vector2i = city.get("site", Vector2i(-1, -1))
    if kind in WonderRules.WONDERS:
        var already_exists: bool = false
        for wonder in wonders:
            if str(wonder["kind"]) == kind:
                already_exists = true
        if not already_exists:
            wonders.append({
                "id": _id_counter, "owner": int(city["owner"]),
                "city_id": int(city["id"]), "kind": kind, "coords": city["coords"]
            })
            _id_counter += 1
            last_event = "Maravilha concluída: %s!" % str(WonderRules.WONDERS[kind]["name"])
    elif kind in ["warrior", "builder", "archer"]:
        var spawn_cell: Vector2i = city["coords"]
        if not unit_at(spawn_cell).is_empty():
            for candidate in _neighbors(spawn_cell):
                if world.tiles.has(candidate) and HexNavigation.movement_cost(world.tiles[candidate]) > 0:
                    if unit_at(candidate).is_empty():
                        spawn_cell = candidate
                        break
        if unit_at(spawn_cell).is_empty():
            _spawn_unit(int(city["owner"]), kind, spawn_cell)
        else:
            city["progress"] = maxi(0, int(DistrictRules.COSTS[kind]) - 1)
            return
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
    if game_over:
        return
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
            _add_research(int(yields["science"]))
            accumulated_culture += int(yields["culture"])
            _add_culture(int(yields["culture"]))
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
                rival_founded = true
                break
    DiplomacyRules.tick(self)
    _rival_planning()
    MilitarySystem.rival_turn(self)
    _evaluate_victory()
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
    if game_over:
        return false
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
    for wonder in wonders:
        if int(wonder["owner"]) != PLAYER and not visible_hexes.has(wonder["coords"]):
            continue
        var visual: Node3D = WonderVisuals.make(str(wonder["kind"]))
        visual.name = "Maravilha_%d_%s" % [int(wonder["id"]), str(wonder["kind"])]
        visual.position = world.tiles[wonder["coords"]]["position"] + Vector3(0.92, 0.0, 0.65)
        _models.add_child(visual)
    for city in cities:
        var project: String = str(city.get("project", ""))
        var site: Vector2i = city.get("site", Vector2i(-1, -1))
        if project in ["", "warrior", "builder", "archer"] or not world.tiles.has(site):
            continue
        if int(city["owner"]) != PLAYER and not visible_hexes.has(site):
            continue
        var cost: int = int(DistrictRules.COSTS.get(project, 1))
        var site_model: Node3D = ConstructionVisuals.make(project, int(city["progress"]), cost)
        site_model.name = "Obra_%d" % int(city["id"])
        site_model.position = world.tiles[site]["position"]
        _models.add_child(site_model)
    for unit in units:
        if int(unit["owner"]) == PLAYER or visible_hexes.has(unit["coords"]):
            _make_unit_model(unit)
    _refresh_infrastructure()
    _refresh_overlays()
    _refresh_exploration()
    _show_combat_marks()


func record_combat(attacker_id: int, target: Vector2i, damage: int, defeated: bool) -> void:
    _combat_marks.append({
        "attacker": attacker_id,
        "target": target,
        "damage": damage,
        "defeated": defeated
    })


func _show_combat_marks() -> void:
    for mark in _combat_marks:
        var cell: Vector2i = mark["target"]
        if not world.tiles.has(cell) or not visible_hexes.has(cell):
            continue
        var effect: Node3D = CombatFX.new()
        effect.setup(int(mark["damage"]), bool(mark["defeated"]))
        effect.position = world.tiles[cell]["position"] + Vector3(0.0, 0.20, 0.0)
        _combat_visuals.add_child(effect)
        var attacker_model: Node3D = null
        for child in _models.get_children():
            if str(child.name).begins_with("Unidade_%d_" % int(mark["attacker"])):
                attacker_model = child as Node3D
                break
        if attacker_model != null and attacker_model.has_method("begin_march"):
            attacker_model.call("begin_march")
            var strike: Tween = create_tween()
            strike.tween_property(attacker_model, "rotation_degrees:z", 11.0, 0.10)
            strike.tween_property(attacker_model, "rotation_degrees:z", 0.0, 0.15)
            strike.tween_callback(Callable(attacker_model, "end_march"))
    _combat_marks.clear()


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
        "researched": researched,
        "research_selected": current_technology,
        "research_progress": research_progress,
        "culture": accumulated_culture,
        "civics": civics_completed,
        "civic_selected": current_civic,
        "civic_progress": civic_progress,
        "government": government,
        "diplomacy": diplomacy,
        "rival_founded": rival_founded,
        "rival_goal": rival_goal,
        "game_over": game_over,
        "victory_type": victory_type,
        "victory_turn": victory_turn,
        "last_event": last_event,
        "explored": _encode_explored(),
        "next_id": _id_counter,
        "active_unit": active_unit_id,
        "selected_city": selected_city_id,
        "units": _encode_entries(units),
        "cities": _encode_entries(cities),
        "districts": _encode_entries(districts),
        "wonders": _encode_entries(wonders),
        "active_policy": active_policy
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
    wonders = _decode_entries(data.get("wonders", []))
    active_policy = str(data.get("active_policy", ""))
    turns = maxi(1, int(data.get("turns", 1)))
    treasury = int(data.get("treasury", 90))
    accumulated_science = int(data.get("science", 0))
    researched.clear()
    for raw_key in data.get("researched", []):
        var key: String = str(raw_key)
        if TechnologyRules.TECHS.has(key) and not researched.has(key):
            researched.append(key)
    research_progress = {}
    var loaded_progress: Variant = data.get("research_progress", {})
    if loaded_progress is Dictionary:
        for key in loaded_progress:
            if TechnologyRules.TECHS.has(str(key)):
                research_progress[str(key)] = maxi(0, int(loaded_progress[key]))
    current_technology = str(data.get("research_selected", ""))
    if not TechnologyRules.can_start(current_technology, researched):
        current_technology = ""
    accumulated_culture = maxi(0, int(data.get("culture", 0)))
    civics_completed.clear()
    for item in data.get("civics", []):
        var civic_key: String = str(item)
        if CivicRules.CIVICS.has(civic_key) and not civics_completed.has(civic_key):
            civics_completed.append(civic_key)
    civic_progress = {}
    var raw_civic_progress: Variant = data.get("civic_progress", {})
    if raw_civic_progress is Dictionary:
        for key in raw_civic_progress:
            if CivicRules.CIVICS.has(str(key)):
                civic_progress[str(key)] = maxi(0, int(raw_civic_progress[key]))
    current_civic = str(data.get("civic_selected", ""))
    if not CivicRules.can_start(current_civic, civics_completed):
        current_civic = ""
    government = str(data.get("government", "chiefdom"))
    if not CivicRules.government_unlocked(government, civics_completed):
        government = "chiefdom"
    if not PolicyRules.unlocked(active_policy, civics_completed):
        active_policy = ""
    diplomacy = DiplomacyRules.initial_state()
    var old_diplomacy: Variant = data.get("diplomacy", {})
    if old_diplomacy is Dictionary:
        for key in diplomacy.keys():
            if old_diplomacy.has(key):
                if key in ["rival_posture"]:
                    diplomacy[key] = str(old_diplomacy[key])
                else:
                    diplomacy[key] = int(old_diplomacy[key])
    rival_founded = bool(data.get("rival_founded", city_count(RIVAL) > 0))
    rival_goal = str(data.get("rival_goal", "Explorar"))
    game_over = bool(data.get("game_over", false))
    victory_type = str(data.get("victory_type", ""))
    victory_turn = maxi(0, int(data.get("victory_turn", 0)))
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
            item["charges"] = int(item.get("charges", 2 if str(item["kind"]) == "builder" else 0))
            item["experience"] = int(item.get("experience", 0))
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
