extends RefCounted
## M8 — Instituições e princípios cívicos originais do Aurora.
## Regras independentes da interface e dos objetos 3D.

const ORDER: Array[String] = [
    "oral_tradition", "common_law", "artisan_guilds", "heritage", "representation"
]

const CIVICS: Dictionary = {
    "oral_tradition": {
        "name": "Tradição Oral", "cost": 11, "requires": [],
        "effect": "+1 cultura por cidade"
    },
    "common_law": {
        "name": "Leis Comuns", "cost": 18, "requires": ["oral_tradition"],
        "effect": "Desbloqueia Conselho"
    },
    "artisan_guilds": {
        "name": "Guildas", "cost": 27, "requires": ["oral_tradition"],
        "effect": "+2 produção por cidade"
    },
    "heritage": {
        "name": "Património", "cost": 36, "requires": ["common_law"],
        "effect": "+2 cultura por cidade"
    },
    "representation": {
        "name": "Representação", "cost": 46,
        "requires": ["artisan_guilds", "common_law"],
        "effect": "Desbloqueia República"
    }
}

const GOVERNMENTS: Dictionary = {
    "chiefdom": {"name": "Clãs", "requires": "", "description": "Governo inicial"},
    "council": {"name": "Conselho", "requires": "common_law", "description": "+1 ouro e +1 cultura por cidade"},
    "republic": {"name": "República", "requires": "representation", "description": "+2 ouro, +1 ciência e +1 cultura por cidade"}
}

const GOVERNMENT_ORDER: Array[String] = ["chiefdom", "council", "republic"]


static func can_start(key: String, completed: Array[String]) -> bool:
    if not CIVICS.has(key) or completed.has(key):
        return false
    for required in CIVICS[key]["requires"]:
        if not completed.has(str(required)):
            return false
    return true


static func available(completed: Array[String]) -> Array[String]:
    var result: Array[String] = []
    for key in ORDER:
        if can_start(key, completed):
            result.append(key)
    return result


static func government_unlocked(key: String, completed: Array[String]) -> bool:
    if not GOVERNMENTS.has(key):
        return false
    var required: String = str(GOVERNMENTS[key]["requires"])
    return required == "" or completed.has(required)


static func title(key: String) -> String:
    if not CIVICS.has(key):
        return "Nenhum princípio"
    return str(CIVICS[key]["name"])


static func cost(key: String) -> int:
    return int(CIVICS[key]["cost"]) if CIVICS.has(key) else 0


static func apply_yields(yields: Dictionary, completed: Array[String], government: String) -> void:
    if completed.has("oral_tradition"):
        yields["culture"] = int(yields["culture"]) + 1
    if completed.has("artisan_guilds"):
        yields["production"] = int(yields["production"]) + 2
    if completed.has("heritage"):
        yields["culture"] = int(yields["culture"]) + 2
    if government == "council":
        yields["gold"] = int(yields["gold"]) + 1
        yields["culture"] = int(yields["culture"]) + 1
    elif government == "republic":
        yields["gold"] = int(yields["gold"]) + 2
        yields["science"] = int(yields["science"]) + 1
        yields["culture"] = int(yields["culture"]) + 1
