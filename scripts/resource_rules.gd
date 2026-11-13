extends RefCounted
## M11: distribuição determinística de recursos por semente, sem loot aleatório.
## Metais, grão, cavalos, madeira e peixe modificam produção alimentar/industrial.

const NAMES: Dictionary = {
    "wheat": "Trigo", "iron": "Ferro", "horses": "Cavalos",
    "timber": "Madeira", "fish": "Peixe"
}
const BONUSES: Dictionary = {
    "wheat": {"food": 2, "production": 0},
    "iron": {"food": 0, "production": 2},
    "horses": {"food": 1, "production": 1},
    "timber": {"food": 0, "production": 1},
    "fish": {"food": 2, "production": 0}
}


static func kind_for(cell: Vector2i, biome: String, seed_value: int) -> String:
    var hash_value: int = absi(
        (cell.x * 73856093) ^ (cell.y * 19349663) ^ (seed_value * 83492791)
    )
    if hash_value % 100 >= 23:
        return ""
    match biome:
        "plains": return "wheat"
        "hills": return "iron"
        "grassland": return "horses"
        "forest": return "timber"
        "water": return "fish"
    return ""


static func bonus(kind: String) -> Dictionary:
    return BONUSES.get(kind, {"food": 0, "production": 0})


static func count(tiles: Dictionary) -> Dictionary:
    var totals: Dictionary = {}
    for key in NAMES:
        totals[key] = 0
    for tile in tiles.values():
        var key: String = str(tile.get("resource", ""))
        if totals.has(key):
            totals[key] = int(totals[key]) + 1
    return totals
