extends RefCounted
const CityRules = preload("res://scripts/city_rules.gd")
## Configuração centralizada dos distritos e projetos do M2.
## Não depende de cenas para permitir testes determinísticos.

const COSTS: Dictionary = {
    "warrior": 12,
    "campus": 24,
    "market": 22,
    "industrial": 27,
    "barracks": 21,
    "harbor": 25,
    "farm": 10,
    "mine": 12
}

const LABELS: Dictionary = {
    "warrior": "Guerreiro",
    "campus": "Academia",
    "market": "Mercado",
    "industrial": "Oficinas",
    "barracks": "Quartel",
    "harbor": "Porto",
    "farm": "Quinta",
    "mine": "Mina"
}

const CITY_DISTRICTS: Array[String] = ["campus", "market", "industrial", "barracks", "harbor"]
const IMPROVEMENTS: Array[String] = ["farm", "mine"]


static func can_place(
    kind: String, cell: Vector2i, city: Dictionary,
    tiles: Dictionary, cities: Array[Dictionary], districts: Array[Dictionary]
) -> bool:
    if not COSTS.has(kind) or kind == "warrior" or not tiles.has(cell):
        return false
    var distance: int = CityRules.hex_distance(cell, city["coords"])
    if distance < 1 or distance > 2:
        return false
    for other in cities:
        if cell == other["coords"]:
            return false
        if int(other["id"]) != int(city["id"]) and CityRules.hex_distance(cell, other["coords"]) < distance:
            return false
    for district in districts:
        if cell == district["coords"]:
            return false
    var biome: String = str(tiles[cell]["biome"])
    if kind == "harbor":
        return biome == "water" and _has_land_neighbor(cell, tiles)
    if biome == "water" or biome == "mountain":
        return false
    if kind == "farm":
        return biome == "grassland" or biome == "plains"
    if kind == "mine":
        return biome == "hills"
    return true


static func _has_land_neighbor(cell: Vector2i, tiles: Dictionary) -> bool:
    for other in tiles:
        if CityRules.hex_distance(other, cell) == 1 and not bool(tiles[other]["water"]):
            return true
    return false
