extends RefCounted
## M16: IA por prioridades económicas, defesa e contexto diplomático.
## Não usa dados que o jogador não possa observar de forma legítima.

const DistrictRules = preload("res://scripts/district_rules.gd")
const Navigation = preload("res://scripts/hex_navigation.gd")


static func choose(game: Node, city: Dictionary) -> Dictionary:
    var kinds: Array[String] = []
    var completed: Dictionary = {}
    for built in game.districts:
        if int(built.get("city_id", -1)) == int(city["id"]):
            completed[str(built["kind"])] = true
    var hostile: bool = not game.is_at_peace()
    var threatened: bool = false
    var rival_warriors: int = 0
    var archers: int = 0
    for unit in game.units:
        if int(unit["owner"]) == game.RIVAL:
            if str(unit["kind"]) == "warrior":
                rival_warriors += 1
            elif str(unit["kind"]) == "archer":
                archers += 1
        elif int(unit["owner"]) == game.PLAYER and Navigation.distance(unit["coords"], city["coords"]) <= 4:
            threatened = true

    # A ameaça militar altera a prioridade; em paz a IA investe em economia.
    if hostile and threatened and archers < 2:
        return {"kind": "archer", "site": Vector2i(-1, -1), "goal": "Recrutar arqueiros defensivos"}
    if hostile and threatened and rival_warriors < 2:
        return {"kind": "warrior", "site": Vector2i(-1, -1), "goal": "Treinar guerreiros"}

    if not completed.has("market"):
        kinds.append("market")
    if not completed.has("campus"):
        kinds.append("campus")
    if game.is_at_peace():
        for kind in ["farm", "industrial"]:
            if not completed.has(kind):
                kinds.append(kind)
    else:
        for kind in ["barracks", "mine"]:
            if not completed.has(kind):
                kinds.append(kind)
    for kind in kinds:
        for cell in game.world.tiles:
            if DistrictRules.can_place(kind, cell, city, game.world.tiles, game.cities, game.districts):
                return {"kind": kind, "site": cell, "goal": "Construir %s" % str(DistrictRules.LABELS[kind])}

    if hostile and archers < 2:
        return {"kind": "archer", "site": Vector2i(-1, -1), "goal": "Formar arqueiros de reserva"}
    if rival_warriors < 3:
        return {"kind": "warrior", "site": Vector2i(-1, -1), "goal": "Reforçar a guarnição"}
    return {"kind": "", "site": Vector2i(-1, -1), "goal": "Manter economia e defesa"}
