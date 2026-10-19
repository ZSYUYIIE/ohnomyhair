extends Node2D
## A marked lane, not a homing projectile. The player has time to leave it.
var boss: BarberBot
var target := Vector2.ZERO
var delay := 1.15
var elapsed := 0.0
var fired := false

func _physics_process(delta: float) -> void:
	if not is_instance_valid(boss) or boss.state in [BarberBot.State.DAZED, BarberBot.State.HURT, BarberBot.State.DEAD] or boss.hp <= 0:
		queue_free()
		return
	elapsed += delta
	if elapsed >= delay and not fired:
		fired = true
		var scissor := Scissor.new()
		scissor.restyles = true
		scissor.direction = Vector2.DOWN
		scissor.speed = 320.0
		scissor.position = Vector2(to_local(target).x, 64)
		get_parent().add_child(scissor)
	if elapsed > delay + 0.18:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var point := to_local(target)
	var ink := Color("b0306a")
	var alpha := 0.45 + 0.25 * sin(elapsed * 18)
	for i in 10:
		var y := lerpf(64, point.y + 20, i / 10.0)
		draw_line(Vector2(point.x, y), Vector2(point.x, y + 12), Color(ink, alpha), 2, true)
	draw_arc(point, 24, 0, TAU, 24, ink, 2, true)
	draw_string(UiTheme.heading_font(), point + Vector2(-28, -42), "SNIP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ink)
