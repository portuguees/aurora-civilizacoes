extends RefCounted
## M7: primeira árvore de investigação de Aurora, com efeitos concretos.
## Tecnologia desbloqueada modifica rendimentos ou força militar.

const ORDER: Array[String] = [
    "agriculture", "mining", "writing", "metallurgy", "commerce", "engineering"
]

const TECHS: Dictionary = {
    "agriculture": {
        "name": "Agricultura", "cost": 12,
        "requires": [],
        "description": "+1 alimento em todas as cidades"
    },
    "mining": {
        "name": "Mineração", "cost": 14,
        "requires": [],
        "description": "+2 produção em todas as cidades"
    },
    "writing": {
        "name": "Escrita", "cost": 24,
        "requires": ["agriculture"],
        "description": "+2 ciência em todas as cidades"
    },
    "metallurgy": {
        "name": "Metalurgia", "cost": 29,
        "requires": ["mining"],
        "description": "+8 força nos ataques dos teus guerreiros"
    },
    "commerce": {
        "name": "Comércio", "cost": 31,
        "requires": ["writing"],
        "description": "+3 ouro em todas as cidades"
    },
    "engineering": {
        "name": "Engenharia", "cost": 48,
        "requires": ["mining", "writing"],
        "description": "+2 produção em todas as cidades"
    }
}


static func can_start(key: String, finished: Array[String]) -> bool:
    if not TECHS.has(key) or finished.has(key):
        return false
    for required in TECHS[key]["requires"]:
        if not finished.has(str(required)):
            return false
    return true


static func available(finished: Array[String]) -> Array[String]:
    var result: Array[String] = []
    for key in ORDER:
        if can_start(key, finished):
            result.append(key)
    return result


static func cost(key: String) -> int:
    if not TECHS.has(key):
        return 0
    return int(TECHS[key]["cost"])


static func title(key: String) -> String:
    if not TECHS.has(key):
        return "Sem pesquisa"
    return str(TECHS[key]["name"])
