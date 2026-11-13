extends RefCounted
## M9: relação bilateral, paz e caravana comercial entre as capitais.

const GIFT_COST: int = 25
const PEACE_COST: int = 12
const TRADE_COST: int = 12
const TRADE_GOLD_PER_TURN: int = 5
const TRADE_CULTURE_PER_TURN: int = 1


static func initial_state() -> Dictionary:
    return {
        "relations": -18,
        "peace_turns": 0,
        "trade_turns": 0,
        "trade_total": 0,
        "agreements": 0,
        "rival_posture": "Vigilância"
    }


static func contact(game: Node) -> bool:
    return game.city_count(game.PLAYER) > 0 and game.city_count(game.RIVAL) > 0


static func is_at_peace(state: Dictionary) -> bool:
    return int(state.get("peace_turns", 0)) > 0


static func can_gift(game: Node) -> bool:
    return contact(game) and game.treasury >= GIFT_COST and not game.game_over


static func can_peace(game: Node) -> bool:
    return contact(game) and game.treasury >= PEACE_COST and not game.game_over         and not is_at_peace(game.diplomacy) and int(game.diplomacy["relations"]) >= -5


static func can_trade(game: Node) -> bool:
    return contact(game) and game.treasury >= TRADE_COST and not game.game_over         and is_at_peace(game.diplomacy) and int(game.diplomacy["trade_turns"]) <= 0


static func gift(game: Node) -> bool:
    if not can_gift(game):
        return false
    game.treasury -= GIFT_COST
    game.diplomacy["relations"] = mini(100, int(game.diplomacy["relations"]) + 24)
    game.last_event = "Oferta diplomática aceite. Relação melhorou para %d." % int(game.diplomacy["relations"])
    return true


static func peace(game: Node) -> bool:
    if not can_peace(game):
        return false
    game.treasury -= PEACE_COST
    game.diplomacy["peace_turns"] = 10
    game.diplomacy["relations"] = mini(100, int(game.diplomacy["relations"]) + 8)
    game.diplomacy["agreements"] = int(game.diplomacy["agreements"]) + 1
    game.last_event = "Tratado de paz com Valdoria durante dez turnos."
    return true


static func trade(game: Node) -> bool:
    if not can_trade(game):
        return false
    game.treasury -= TRADE_COST
    game.diplomacy["trade_turns"] = mini(8, int(game.diplomacy["peace_turns"]))
    game.diplomacy["trade_total"] = int(game.diplomacy["trade_total"]) + 1
    game.last_event = "Caravana criada: +%d ouro e +%d cultura por turno enquanto durar." % [
        TRADE_GOLD_PER_TURN, TRADE_CULTURE_PER_TURN
    ]
    return true


static func declare_war(game: Node) -> bool:
    if not contact(game) or game.game_over:
        return false
    game.diplomacy["peace_turns"] = 0
    game.diplomacy["trade_turns"] = 0
    game.diplomacy["relations"] = -65
    game.last_event = "A guerra com Valdoria foi declarada. As caravanas cessaram."
    return true


static func hostility(game: Node, attacker_owner: int, defender_owner: int) -> void:
    if attacker_owner != game.PLAYER or defender_owner != game.RIVAL:
        return
    game.diplomacy["relations"] = maxi(-100, int(game.diplomacy["relations"]) - 16)
    game.diplomacy["peace_turns"] = 0
    game.diplomacy["trade_turns"] = 0


static func tick(game: Node) -> void:
    if not contact(game) or game.game_over:
        return
    if int(game.diplomacy["trade_turns"]) > 0 and is_at_peace(game.diplomacy):
        game.treasury += TRADE_GOLD_PER_TURN
        game.accumulated_culture += TRADE_CULTURE_PER_TURN
        game._add_culture(TRADE_CULTURE_PER_TURN)
        game.diplomacy["trade_turns"] = maxi(0, int(game.diplomacy["trade_turns"]) - 1)
        game.diplomacy["rival_posture"] = "Parceiro comercial"
    else:
        game.diplomacy["rival_posture"] = "Acordo de paz" if is_at_peace(game.diplomacy) else "Vigilância"
    if is_at_peace(game.diplomacy):
        game.diplomacy["relations"] = mini(100, int(game.diplomacy["relations"]) + 1)
        game.diplomacy["peace_turns"] = maxi(0, int(game.diplomacy["peace_turns"]) - 1)
        if int(game.diplomacy["peace_turns"]) == 0:
            game.diplomacy["trade_turns"] = 0
            game.diplomacy["rival_posture"] = "Trégua terminada"
    elif game.turns % 4 == 0:
        game.diplomacy["relations"] = maxi(-100, int(game.diplomacy["relations"]) - 1)
