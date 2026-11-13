extends RefCounted
## Caminhos hexagonais odd-r, custos de terreno e colisão com unidades.
## A* determinístico sobre o mapa pequeno (32 × 24) para ordens de longa distância.

static func neighbors(cell: Vector2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    var offsets: Array[Vector2i] = [
        Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)
    ]
    if (cell.y & 1) == 1:
        offsets.append(Vector2i(1, -1))
        offsets.append(Vector2i(1, 1))
    else:
        offsets.append(Vector2i(-1, -1))
        offsets.append(Vector2i(-1, 1))
    for offset in offsets:
        result.append(cell + offset)
    return result


static func distance(a: Vector2i, b: Vector2i) -> int:
    var aq: int = a.x - ((a.y - (a.y & 1)) >> 1)
    var bq: int = b.x - ((b.y - (b.y & 1)) >> 1)
    var dq: int = aq - bq
    var dr: int = a.y - b.y
    return (absi(dq) + absi(dr) + absi(dq + dr)) >> 1


static func movement_cost(tile: Dictionary) -> int:
    if bool(tile.get("water", false)):
        return -1
    match str(tile.get("biome", "")):
        "mountain":
            return -1
        "hills", "forest":
            return 2
        _:
            return 1


static func movement_capacity(kind: String) -> int:
    if kind in ["settler", "builder", "archer"]:
        return 2
    return 3


static func path(
    tiles: Dictionary, units: Array[Dictionary],
    origin: Vector2i, goal: Vector2i, moving_id: int
) -> Array[Vector2i]:
    var empty: Array[Vector2i] = []
    if not tiles.has(origin) or not tiles.has(goal) or movement_cost(tiles[goal]) < 0:
        return empty
    if origin == goal:
        return empty
    var occupied: Dictionary = {}
    for unit in units:
        if int(unit.get("id", -1)) != moving_id:
            occupied[unit["coords"]] = true
    if occupied.has(goal):
        return empty

    var frontier: Array[Vector2i] = [origin]
    var frontier_g: Dictionary = {origin: 0}
    var came_from: Dictionary = {}
    var closed: Dictionary = {}
    var visited: int = 0
    while not frontier.is_empty() and visited < 2048:
        visited += 1
        var best_index: int = 0
        var best_f: int = 9999999
        for i in range(frontier.size()):
            var cell: Vector2i = frontier[i]
            var estimate: int = int(frontier_g[cell]) + distance(cell, goal)
            if estimate < best_f:
                best_f = estimate
                best_index = i
        var current: Vector2i = frontier.pop_at(best_index)
        if current == goal:
            var reversed_path: Array[Vector2i] = []
            while current != origin:
                reversed_path.append(current)
                current = came_from[current]
            reversed_path.reverse()
            return reversed_path
        if closed.has(current):
            continue
        closed[current] = true
        for next_cell in neighbors(current):
            if not tiles.has(next_cell) or occupied.has(next_cell) or closed.has(next_cell):
                continue
            var terrain_cost: int = movement_cost(tiles[next_cell])
            if terrain_cost < 0:
                continue
            var tentative: int = int(frontier_g[current]) + terrain_cost
            if tentative < int(frontier_g.get(next_cell, 9999999)):
                frontier_g[next_cell] = tentative
                came_from[next_cell] = current
                if not frontier.has(next_cell):
                    frontier.append(next_cell)
    return empty


static func approach(
    tiles: Dictionary, units: Array[Dictionary],
    origin: Vector2i, occupied_target: Vector2i, moving_id: int
) -> Array[Vector2i]:
    var best_path: Array[Vector2i] = []
    var best_cost: int = 9999999
    for cell in neighbors(occupied_target):
        var candidate: Array[Vector2i] = path(tiles, units, origin, cell, moving_id)
        if cell == origin:
            return candidate
        if candidate.is_empty():
            continue
        var cost: int = 0
        for step in candidate:
            cost += movement_cost(tiles[step])
        if cost < best_cost:
            best_cost = cost
            best_path = candidate
    return best_path
