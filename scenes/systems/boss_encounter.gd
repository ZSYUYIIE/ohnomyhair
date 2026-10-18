extends Node2D
## The finale reuses showers, a dryer and vent robots without blocking the floor.
## All clocks belong to the room, so restart/pause/inactive-room behavior is inherited.
const SUPPLY_LIMIT := 4
const SUPPLY_COOLDOWN := 16.0
var boss: BarberBot
var backup: WaveArena
var showers: Array[ShowerHead] = []
var dryer: HairDryer
var tonics: Array[GrowthTonic] = []
var supplies_spawned := 0
var _grace := 0.0
var _refill := 12.0
var _supply_wait := 8.0
var _phase_reward := false
var _last_robots := 0
var _scrapped := 0
var _stopped := false
var _water_running := false

func _ready() -> void:
	boss = get_parent().get_node("BarberBot")
	backup = get_parent().get_node("Backup")
	boss.phase_changed.connect(_phase_changed)
	boss.defeated.connect(_stop)
	for x in [288.0, 864.0]:
		var shower := ShowerHead.new()
		shower.position = Vector2(x, 64)
		shower.size = Vector2(64, 544)
		shower.off_time = 4.0
		shower.on_time = 2.0
		shower.warn_time = 0.8
		shower.phase = 0.0 if showers.is_empty() else 3.0
		shower.active = false
		add_child(shower)
		showers.append(shower)
	dryer = HairDryer.new()
	dryer.position = Vector2(592, 464)
	dryer.size = Vector2(64, 144)
	add_child(dryer)

func _phase_changed(number: int) -> void:
	if _stopped: return
	_grace = 1.8
	_refill = 12.0 if number == 2 else 9.0
	_phase_reward = true
	backup.start_next()
	var hint := get_parent().get_node("Hint7") as Label
	hint.text = "Showers soak hair. Dry off in the central warm air.\nWhip or dash the roaming backup." if number == 2 else "More backup, faster showers. Keep moving.\nGreen tonics restore one heart."
	if number == 3:
		for i in showers.size():
			showers[i].off_time = 3.0
			showers[i].phase = 0.0 if i == 0 else 2.5

func _physics_process(delta: float) -> void:
	if _stopped: return
	if not is_instance_valid(boss) or boss.hp <= 0:
		_stop()
		return
	_grace = maxf(0, _grace - delta)
	_supply_wait = maxf(0, _supply_wait - delta)
	var resting := boss.state in [BarberBot.State.DAZED, BarberBot.State.HURT, BarberBot.State.DEAD]
	var water_on := boss.phase() >= 2 and _grace <= 0 and not resting
	if water_on != _water_running:
		_water_running = water_on
		for shower in showers:
			shower.active = water_on
			shower._t = 0
	var count := backup.robots_left()
	_scrapped += maxi(0, _last_robots - count)
	_last_robots = count
	if boss.phase() >= 2 and not resting and _grace <= 0:
		_refill -= delta
		if _refill <= 0:
			var minimum := 2 if boss.phase() == 2 else 3
			if count < minimum: backup.reinforce()
			_refill = 12.0 if boss.phase() == 2 else 9.0
	_try_supply()

func _try_supply() -> void:
	tonics = tonics.filter(func(t): return is_instance_valid(t))
	if _stopped or supplies_spawned >= SUPPLY_LIMIT or _supply_wait > 0 or not tonics.is_empty(): return
	var wounded := false
	var critical := false
	for player: Player in get_tree().get_nodes_in_group("players"):
		if not player.alive: continue
		wounded = wounded or player.hp < player.max_hp
		critical = critical or player.hp <= 1
	if not wounded or not (_phase_reward or _scrapped >= 3 or critical): return
	var tonic := GrowthTonic.new()
	var x := 624.0
	if absf(boss.position.x - x) < 120:
		x = 432.0 if boss.position.x > x else 816.0
	tonic.position = Vector2(x, 580)
	add_child(tonic)
	tonics.append(tonic)
	supplies_spawned += 1
	_supply_wait = SUPPLY_COOLDOWN
	_phase_reward = false
	_scrapped = 0
	Sound.play("tonic", 0.0)

func _stop() -> void:
	if _stopped: return
	_stopped = true
	for shower in showers:
		shower.active = false
		shower.queue_redraw()
	backup.scrap_all()
	get_parent().get_node("Hint7").hide()
	for projectile in get_tree().get_nodes_in_group("scissors"):
		if projectile.get_parent() == get_parent(): projectile.queue_free()
