extends RefCounted
## M10: condições verificáveis e pontuação civilizacional.
## A vitória militar exige captura; nunca é declarada só porque o rival ainda
## não fundou a capital.

const SCIENCE_MIN: int = 145
const CULTURE_MIN: int = 120
const GOLD_MIN: int = 290
const MIN_TURN: int = 9

const TITLES: Dictionary = {
    "science": "Vitória Científica",
    "culture": "Vitória Cultural",
    "economic": "Vitória Económica",
    "military": "Vitória Militar"
}


static func scores(game: Node) -> Dictionary:
    var city_count: int = game.city_count(game.PLAYER)
    var people: int = 0
    for city in game.cities:
        if int(city["owner"]) == game.PLAYER:
            people += int(city["population"])
    return {
        "science": mini(100, roundi(100.0 * float(game.researched.size()) / 6.0)),
        "culture": mini(100, roundi(100.0 * float(game.civics_completed.size()) / 5.0)),
        "economic": mini(100, roundi(100.0 * float(game.treasury) / float(GOLD_MIN))),
        "expansion": city_count,
        "population": people
    }


static func check(game: Node) -> String:
    if game.game_over or game.turns < MIN_TURN or game.city_count(game.PLAYER) < 1:
        return ""
    if game.rival_founded and game.city_count(game.RIVAL) == 0:
        return "military"
    if game.researched.size() >= 6 and game.accumulated_science >= SCIENCE_MIN:
        return "science"
    if game.civics_completed.size() >= 5 and game.accumulated_culture >= CULTURE_MIN:
        return "culture"
    if game.treasury >= GOLD_MIN and int(game.diplomacy["trade_turns"]) > 0         and int(game.diplomacy["peace_turns"]) > 0:
        return "economic"
    return ""


static func can_capture(game: Node) -> bool:
    if game.game_over or not game.rival_founded or game.city_count(game.PLAYER) < 1:
        return false
    var capital: Dictionary = {}
    for city in game.cities:
        if int(city["owner"]) == game.RIVAL:
            capital = city
            break
    if capital.is_empty():
        return false
    var player_warrior: bool = false
    for unit in game.units:
        var distance: int = game.HexNavigation.distance(unit["coords"], capital["coords"])
        if int(unit["owner"]) == game.RIVAL and distance <= 1:
            return false
        if int(unit["owner"]) == game.PLAYER and str(unit["kind"]) == "warrior" and distance == 1:
            player_warrior = true
    return player_warrior and not game.is_at_peace()


static func describe(game: Node) -> Dictionary:
    return {
        "science": "Concluir 6 tecnologias e atingir %d de ciência total" % SCIENCE_MIN,
        "culture": "Concluir 5 princípios cívicos e atingir %d de cultura total" % CULTURE_MIN,
        "economic": "Ter %d ouro, paz e uma caravana ativa" % GOLD_MIN,
        "military": "Eliminar a guarnição e capturar Valdoria com um guerreiro adjacente",
        "scores": scores(game)
    }
