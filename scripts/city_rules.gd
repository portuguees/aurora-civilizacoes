extends RefCounted
const ResourceRules = preload("res://scripts/resource_rules.gd")
## Regras de rendimento por parcela. Não depende de nós nem da interface.
## Uma parcela só pode ser trabalhada por uma cidade, e o número de
## parcelas trabalhadas depende da população.

const WORK_RADIUS: int = 2


static func hex_distance(a: Vector2i, b: Vector2i) -> int:
    var aq: int = a.x - ((a.y - (a.y & 1)) >> 1)
    var bq: int = b.x - ((b.y - (b.y & 1)) >> 1)
    var dq: int = aq - bq
    var dr: int = a.y - b.y
    return (absi(dq) + absi(dr) + absi(dq + dr)) >> 1


static func tile_yields(tile: Dictionary) -> Dictionary:
    var result: Dictionary = {"food": 0, "production": 0}
    match str(tile.get("biome", "")):
        "grassland":
            result = {"food": 2, "production": 1}
        "plains":
            result = {"food": 2, "production": 1}
        "forest":
            result = {"food": 1, "production": 2}
        "hills":
            result = {"food": 0, "production": 3}
        "water":
            result = {"food": 1, "production": 0}
        _:
            result = {"food": 0, "production": 0}
    var bonus: Dictionary = ResourceRules.bonus(str(tile.get("resource", "")))
    result["food"] = int(result["food"]) + int(bonus["food"])
    result["production"] = int(result["production"]) + int(bonus["production"])
    return result


static func growth_cost(population: int) -> int:
    return 10 + population * 7


static func evaluate(city: Dictionary, tiles: Dictionary, cities: Array[Dictionary], districts: Array[Dictionary]) -> Dictionary:
    var center: Vector2i = city["coords"]
    var population: int = maxi(1, int(city.get("population", 1)))
    var focus: String = str(city.get("focus", "balanced"))
    var candidates: Array[Dictionary] = []
    var placed: Dictionary = {}
    var food: int = 2  # centro urbano
    var production: int = 1
    var science: int = 1
    var gold: int = 1
    var housing: int = 4

    for district in districts:
        if int(district.get("city_id", -1)) != int(city["id"]):
            continue
        var cell: Vector2i = district["coords"]
        var kind: String = str(district["kind"])
        placed[cell] = kind
        match kind:
            "campus":
                science += 3
                for neighbor in tiles:
                    if str(tiles[neighbor]["biome"]) == "mountain" and hex_distance(neighbor, cell) == 1:
                        science += 1
            "market":
                gold += 4
            "industrial":
                production += 3
                for neighbor in tiles:
                    if str(tiles[neighbor]["biome"]) == "hills" and hex_distance(neighbor, cell) == 1:
                        production += 1
            "barracks":
                production += 1
            "harbor":
                gold += 3
                food += 1
                housing += 1

    for cell in tiles:
        if cell == center or hex_distance(cell, center) > WORK_RADIUS:
            continue
        var reserved: bool = false
        for other in cities:
            if int(other["id"]) == int(city["id"]):
                continue
            if cell == other["coords"]:
                reserved = true
                break
            var other_distance: int = hex_distance(cell, other["coords"])
            if other_distance < hex_distance(cell, center):
                reserved = true
                break
        if reserved:
            continue
        var tile: Dictionary = tiles[cell]
        if str(tile["biome"]) == "mountain":
            continue
        var site_kind: String = str(placed.get(cell, ""))
        if site_kind in ["campus", "market", "industrial", "barracks", "harbor"]:
            continue
        var y: Dictionary = tile_yields(tile)
        if site_kind == "farm":
            y["food"] = int(y["food"]) + 2
        elif site_kind == "mine":
            y["production"] = int(y["production"]) + 2
        var score: float = 0.0
        match focus:
            "food":
                score = float(y["food"]) * 4.0 + float(y["production"])
            "production":
                score = float(y["production"]) * 4.0 + float(y["food"])
            _:
                score = float(y["food"]) * 2.2 + float(y["production"]) * 1.8
        score += float(WORK_RADIUS - hex_distance(cell, center)) * 0.02
        candidates.append({"coords": cell, "food": int(y["food"]), "production": int(y["production"]), "score": score})

    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return float(a["score"]) > float(b["score"])
    )
    var worked: Array[Vector2i] = []
    for i in range(mini(population, candidates.size())):
        var entry: Dictionary = candidates[i]
        worked.append(entry["coords"])
        food += int(entry["food"])
        production += int(entry["production"])

    return {
        "food": food, "food_surplus": food - population * 2,
        "production": production, "science": science, "gold": gold,
        "housing": housing, "worked": worked
    }
