extends RefCounted
## M15: duas maravilhas originais, únicas a nível mundial, construídas pelas cidades.

const ORDER: Array[String] = ["sky_observatory", "royal_gardens"]
const WONDERS: Dictionary = {
    "sky_observatory": {
        "name": "Observatório Celeste", "cost": 62,
        "technology": "writing", "description": "+5 ciência e +1 cultura na cidade"
    },
    "royal_gardens": {
        "name": "Jardins Reais", "cost": 54,
        "technology": "agriculture", "description": "+3 alimento e +2 cultura na cidade"
    }
}


static func can_build(kind: String, researched: Array[String], completed: Array[Dictionary]) -> bool:
    if not WONDERS.has(kind) or not researched.has(str(WONDERS[kind]["technology"])):
        return false
    for wonder in completed:
        if str(wonder["kind"]) == kind:
            return false
    return true


static func bonus(wonder: Dictionary, yields: Dictionary) -> void:
    match str(wonder["kind"]):
        "sky_observatory":
            yields["science"] = int(yields["science"]) + 5
            yields["culture"] = int(yields["culture"]) + 1
        "royal_gardens":
            yields["food"] = int(yields["food"]) + 3
            yields["food_surplus"] = int(yields["food_surplus"]) + 3
            yields["culture"] = int(yields["culture"]) + 2
