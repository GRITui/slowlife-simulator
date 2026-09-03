extends Node

# SignalBus — Decoupled event bus for slowlife-simulator
# Autoload singleton. All UI, time, and game state communication flows here.
# Spec: res://scripts/autoload/SignalBus.gd

signal minute_ticked(day: int, hour: int, minute: int)
signal season_changed(new_season: String)
signal weather_changed(new_weather: String)
signal stamina_changed(current_stamina: float, max_stamina: float)
signal binthabat_offered(item_id: String, harmony_yield: int)
signal infrastructure_repaired(structure_id: String)
signal show_dialogue(speaker_name: String, text: String)
signal barter_completed(have_id: String, want_id: String)
# TASK-352: every scene transition (doors now; save/load, debug teleport,
# festival cutscenes later) goes through SceneLoader via this one signal.
signal scene_transition_requested(target_scene_path: String, target_warp_id: String)

# Reference registry (ENGINE-006) — set once by the owning system on _ready(),
# read directly instead of hard node paths / scene-tree walks. Not a signal
# because a fire-once "ready" signal races with the reader's own _ready()
# order; a plain field survives late readers.
var grid_manager: Node = null
var time_manager: Node = null
var market_shop: Node = null # TASK-327: MarketShop UI panel registry slot.
var rival_clock: Node = null # TASK-347: RivalClock registry slot (festival tie-in reads this).
var world_render: Node = null # TASK-352: per-area render registry (was get_parent().get_node("WorldRender")).
var pending_warp_id: String = "" # TASK-352: set by SceneLoader before change_scene_to_file(); consumed by the target area on _ready().
# TASK-357: set by SaveManager.load_game() before it fires a scene
# transition to the saved scene, so the destination places the player at
# the EXACT saved position instead of resolving pending_warp_id against a
# door (a save can be made anywhere, not just standing at a door). Takes
# precedence over pending_warp_id when both would otherwise apply — an
# area's spawn resolution should check has_pending_load_position first.
var has_pending_load_position: bool = false
var pending_load_position: Vector2 = Vector2.ZERO
# TASK-357: set by the outgoing EdgeTransition (just before it emits
# scene_transition_requested) to the player's current position on the
# transition's carry_axis; read by the incoming scene's matching edge via
# InteriorBase._spawn_player so the player lands at the parallel
# coordinate across the swap (a Door warp would snap to a fixed point,
# which is wrong for walk-through area edges). A door transition leaves
# this at its default 0.0 — InteriorBase only reads it when the
# resolved pending_warp_id matches an EdgeTransition, not a Door.
var edge_carry_value: float = 0.0

# --- Extended signals (backward-compat with existing codebase) ---
signal village_harmony_changed(new_harmony: int)
signal village_goodwill_changed(new_goodwill: int)
signal crop_harvested(crop_id: int)
signal crop_growth_progress(crop_id: int, progress: int, max_stage: int)
# TASK-034: reintroduced WITH a live consumer (DayNightTintDriver grade
# shader). TASK-033's removal note applies only while no listener exists.
signal day_night_cycle_changed(time_fraction: float)
signal festival_triggered(festival_name: String)

# TASK-027 accessibility — emitted by Settings UI, consumed by HUD + SaveManager.
signal settings_changed(font_scale: float, high_contrast: bool)
# TASK-042: emitted whenever SceneTree.paused flips (pause menu / resume).
signal game_paused_changed(paused: bool)
# TASK-029: emitted by CookingStation after a recipe craft (item_id, qty).
signal craft_completed(item_id: String, qty: int)
# ISSUE-135: emitted whenever the silver wallet changes.
signal silver_changed(silver: int)
# TASK-311: emitted on buffalo interact (affinity, hearts) — HUD hearts UI.
signal buffalo_affinity_changed(affinity: int, hearts: int)
# TASK-323: emitted on chicken collect_egg (affinity, hearts) — HUD hearts UI.
signal chicken_affinity_changed(affinity: int, hearts: int)
# Phase 3 audit (2026-09-02): emitted on companion bond grant (bond, tier) —
# mirrors buffalo/chicken so HUD has a reactive hook (previously HUD had no
# way to learn about companion_bond changes at all).
signal companion_bond_changed(bond: int, tier: int)
# TASK-317: emitted on tool upgrade (tool_id, new_tier) — HUD tier display.
signal tool_upgraded(tool_id: String, new_tier: int)
