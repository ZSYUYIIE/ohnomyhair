class_name Layers
extends RefCounted
## Physics layer bits. Must match [layer_names] in project.godot (PLAN.md 2.3).

const WORLD := 1
const PLAYERS := 1 << 1
const ENEMIES := 1 << 2
const PLAYER_ATTACK := 1 << 3
const ENEMY_ATTACK := 1 << 4
const INTERACTABLES := 1 << 5
const HEAD_PADS := 1 << 6
## One-way platforms (players can drop through by turning this layer off briefly).
const PLATFORMS := 1 << 7
