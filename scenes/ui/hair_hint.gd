class_name HairHint
extends Label
## A room hint written per haircut, not per player slot, so it stays true after the
## chair swap, a styling chair or Tony's restyle. Tokens in `template`:
##   {tt} {pomp} {afro} {long}             -> "P1" / "P2" (the haircut's name if nobody wears it)
##   {tt.skill} {tt.attack} ... (any key)  -> that player's key: G / F for P1, K / L for P2
## e.g. "{tt}: jump, then HOLD {tt.skill} to glide".

const KEYS := {"tt": Player.Hair.TWIN_TAILS, "pomp": Player.Hair.POMPADOUR}

@export_multiline var template := ""

var _wait := 0.0


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = 0.2
	var worn := {}
	for p: Player in get_tree().get_nodes_in_group("players"):
		worn[p.hair] = p.player_id
	var resolved := resolve(template, worn)
	if resolved != text:
		text = resolved


## `worn`: hair -> player_id (1 or 2).
static func resolve(template_text: String, worn: Dictionary) -> String:
	var out := template_text
	for key in KEYS:
		var hair: int = KEYS[key]
		var id: int = worn.get(hair, 0)
		out = out.replace("{%s.skill}" % key, "G" if id == 1 else "K" if id == 2 else "skill")
		out = out.replace("{%s.attack}" % key, "F" if id == 1 else "L" if id == 2 else "attack")
		out = out.replace("{%s}" % key, "P%d" % id if id > 0 else Player.HAIR_INFO[hair].name)
	return out
