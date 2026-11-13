extends RefCounted
## M14: uma carta política ativa por império. Bónus verificáveis, sem empilhamento.

const ORDER: Array[String] = ["agrarian", "administration", "militia"]
const POLICIES: Dictionary = {
    "agrarian": {"name": "Colheitas", "requires": "oral_tradition", "description": "+1 alimento por cidade"},
    "administration": {"name": "Administração", "requires": "common_law", "description": "+2 ouro por cidade"},
    "militia": {"name": "Milícia", "requires": "artisan_guilds", "description": "+5 dano nos ataques"}
}


static func unlocked(key: String, civics: Array[String]) -> bool:
    if key == "":
        return true
    return POLICIES.has(key) and civics.has(str(POLICIES[key]["requires"]))


static func apply(yields: Dictionary, selected: String) -> void:
    match selected:
        "agrarian":
            yields["food"] = int(yields["food"]) + 1
            yields["food_surplus"] = int(yields["food_surplus"]) + 1
        "administration":
            yields["gold"] = int(yields["gold"]) + 2


static func attack_bonus(selected: String) -> int:
    return 5 if selected == "militia" else 0
