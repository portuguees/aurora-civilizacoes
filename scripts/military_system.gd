extends RefCounted
## Simulação militar M3. Sem dependência da HUD e sem aleatoriedade oculta.
## O núcleo chama estas rotinas para executar ordens de jogadores e rivais.

const Navigation = preload("res://scripts/hex_navigation.gd")


static func unit_on(game: Node, cell: Vector2i) -> Dictionary:
    for unit in game.units:
        if unit["coords"] == cell:
            return unit
    return {}


static func issue_order(game: Node, target: Vector2i) -> bool:
    var active: Dictionary = game.get_active()
    if active.is_empty() or int(active["owner"]) != game.PLAYER or not game.world.tiles.has(target):
        return false
    if int(active.get("move_points", 0)) <= 0:
        game.last_event = "Sem pontos de movimento. Termina o turno para continuar."
        return false
    var opponent: Dictionary = unit_on(game, target)
    if not opponent.is_empty():
        if int(opponent["owner"]) == game.PLAYER:
            game.last_event = "Hexágono ocupado por outra unidade tua."
            return false
        if str(active["kind"]) != "warrior":
            game.last_event = "O colono não pode atacar; protege-o com guerreiros."
            return false
        if Navigation.distance(active["coords"], target) == 1:
            return attack(game, active, opponent)
        var approach_path: Array[Vector2i] = Navigation.approach(
            game.world.tiles, game.units, active["coords"], target, int(active["id"])
        )
        if approach_path.is_empty():
            game.last_event = "O alvo está inacessível."
            return false
        active["route"] = approach_path
        active["target_enemy"] = int(opponent["id"])
    else:
        var new_route: Array[Vector2i] = Navigation.path(
            game.world.tiles, game.units, active["coords"], target, int(active["id"])
        )
        if new_route.is_empty():
            game.last_event = "Sem caminho para o destino indicado."
            return false
        active["route"] = new_route
        active["target_enemy"] = -1
    game.last_event = "Ordem de movimento definida."
    advance(game, active)
    return true


static func advance(game: Node, unit: Dictionary) -> void:
    var route: Array = unit.get("route", [])
    var remaining: int = int(unit.get("move_points", 0))
    var traveled: int = 0
    while not route.is_empty():
        var next_cell: Vector2i = route[0]
        if not game.world.tiles.has(next_cell):
            route.clear()
            break
        var cost: int = Navigation.movement_cost(game.world.tiles[next_cell])
        if cost < 0:
            route.clear()
            break
        if remaining < cost:
            break
        if not unit_on(game, next_cell).is_empty():
            route.clear()
            break
        unit["coords"] = next_cell
        remaining -= cost
        route.remove_at(0)
        traveled += 1
    unit["route"] = route
    unit["move_points"] = remaining
    unit["moved"] = remaining == 0
    if traveled > 0:
        game.last_event = "%d hexágono(s) percorrido(s); %d movimentos restantes." % [traveled, remaining]
    var target_id: int = int(unit.get("target_enemy", -1))
    if route.is_empty() and target_id >= 0 and remaining > 0:
        var rival: Dictionary = {}
        for candidate in game.units:
            if int(candidate["id"]) == target_id and int(candidate["owner"]) != int(unit["owner"]):
                rival = candidate
                break
        unit["target_enemy"] = -1
        if not rival.is_empty() and Navigation.distance(unit["coords"], rival["coords"]) == 1:
            attack(game, unit, rival)


static func attack(game: Node, attacker: Dictionary, defender: Dictionary) -> bool:
    if str(attacker.get("kind", "")) != "warrior":
        return false
    if int(attacker["owner"]) == int(defender["owner"]) or int(attacker.get("move_points", 0)) < 1:
        return false
    if Navigation.distance(attacker["coords"], defender["coords"]) != 1:
        return false
    var terrain: String = str(game.world.tiles[defender["coords"]]["biome"])
    var defensive_bonus: int = 7 if terrain in ["hills", "forest"] else 0
    var strength: int = 38 if str(defender["kind"]) == "settler" else 32
    var damage: int = maxi(12, strength - defensive_bonus)
    defender["health"] = int(defender["health"]) - damage
    game.call("record_combat", int(attacker["id"]), defender["coords"], damage, int(defender["health"]) <= 0)
    attacker["move_points"] = 0
    attacker["moved"] = true
    attacker["route"] = []
    attacker["target_enemy"] = -1
    if int(defender["health"]) <= 0:
        var enemy_position: Vector2i = defender["coords"]
        game.units.erase(defender)
        var occupied_by_city: bool = false
        for city in game.cities:
            if city["coords"] == enemy_position:
                occupied_by_city = true
                break
        if not occupied_by_city:
            attacker["coords"] = enemy_position
        game.last_event = "Vitória no combate! O adversário foi derrotado."
        return true
    var counterdamage: int = 14 if str(defender["kind"]) == "warrior" else 0
    if counterdamage > 0:
        attacker["health"] = int(attacker["health"]) - counterdamage
    if int(attacker["health"]) <= 0:
        game.units.erase(attacker)
        if game.active_unit_id == int(attacker["id"]):
            game.active_unit_id = -1
    game.last_event = "Combate: %d dano causado, %d recebido." % [damage, counterdamage]
    return true


static func begin_new_turn(game: Node) -> void:
    for unit in game.units:
        unit["moved"] = false
        unit["move_points"] = Navigation.movement_capacity(str(unit["kind"]))
    for unit in game.units.duplicate():
        if int(unit["owner"]) == game.PLAYER and not unit.get("route", []).is_empty():
            advance(game, unit)


static func rival_turn(game: Node) -> void:
    var capital: Dictionary = {}
    for city in game.cities:
        if int(city["owner"]) == game.RIVAL:
            capital = city
            break
    if capital.is_empty():
        return
    var warriors: int = 0
    for unit in game.units:
        if int(unit["owner"]) == game.RIVAL and str(unit["kind"]) == "warrior":
            warriors += 1
    if game.turns >= 5 and game.turns % 5 == 0 and warriors < 3:
        for cell in Navigation.neighbors(capital["coords"]):
            if game.world.tiles.has(cell) and Navigation.movement_cost(game.world.tiles[cell]) > 0:
                if unit_on(game, cell).is_empty():
                    game._spawn_unit(game.RIVAL, "warrior", cell)
                    break

    for unit in game.units.duplicate():
        if not game.units.has(unit) or int(unit["owner"]) != game.RIVAL or str(unit["kind"]) != "warrior":
            continue
        var fought: bool = false
        for player in game.units.duplicate():
            if int(player["owner"]) == game.PLAYER and Navigation.distance(unit["coords"], player["coords"]) == 1:
                fought = attack(game, unit, player)
                break
        if fought or not game.units.has(unit):
            continue
        var candidates: Array[Vector2i] = []
        for cell in Navigation.neighbors(unit["coords"]):
            if not game.world.tiles.has(cell) or Navigation.movement_cost(game.world.tiles[cell]) < 0:
                continue
            if Navigation.distance(cell, capital["coords"]) > 3 or not unit_on(game, cell).is_empty():
                continue
            candidates.append(cell)
        if candidates.is_empty():
            continue
        var choice: Vector2i = candidates[(game.turns + int(unit["id"])) % candidates.size()]
        var movement_cost: int = Navigation.movement_cost(game.world.tiles[choice])
        if int(unit["move_points"]) >= movement_cost:
            unit["coords"] = choice
            unit["move_points"] = int(unit["move_points"]) - movement_cost
            unit["moved"] = true
