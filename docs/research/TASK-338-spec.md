# TASK-338 — Grow the named NPC roster: Nok

Sprint 2 of the "broaden to compete with HM:BtN" plan (2026-09-02).

## Scope note

Recounted the actual named-NPC roster before scoping this (corrects
the verdict's earlier rough "~9" estimate) — it's currently 12: Elder,
Child, Handler, Headman, Vet, Monk, Trader, Niran, Fah, Ploy, NongTon,
Somchai. Still well short of HM:BtN's ~20-30, but the gap is smaller
than first estimated. This task adds exactly ONE new villager (not
1-2) to keep the diff small and reviewable.

While scoping this, found and separately fixed (commit `d876154`, not
part of this task) a real visual bug: `VillagerNPC.gd`'s idle-texture
fallback had no case for headman/vet despite both having dedicated
portrait assets — both silently rendered as Elder. Fixed already;
mentioned here so the pattern below (an explicit per-instance
`idle_texture`, not relying on the fallback switch) is understood as
the now-preferred way to add a new villager's portrait, rather than
extending that match statement further.

## Character

**Nok** — a semi-retired veteran farmer, warm and instructive,
mentoring tone. Contrasts Niran's competitive rivalry with cooperative,
patient wisdom (the "helpful old-timer neighbor" archetype this
town currently lacks).

## Verified facts (do not re-derive, use directly)

- Elder/Child/Handler are NOT separate `.tscn` files — they are 3
  instances of the SAME shared `res://scenes/entities/VillagerNPC.tscn`
  scene, declared directly in `scenes/core/Main.tscn` with per-instance
  property overrides. Exact pattern (copy this shape for Nok):
  ```
  [node name="ElderNPC" parent="." instance=ExtResource("8_villager")]
  position = Vector2(360, 336)
  npc_id = "elder"
  display_name = "Elder"
  ```
  `ExtResource("8_villager")` is declared once near the top of
  `Main.tscn` as `res://scenes/entities/VillagerNPC.tscn` — reuse that
  same ext_resource id, don't add a new one.
- Set `idle_texture` explicitly on Nok's instance block (a 4th line:
  `idle_texture = ExtResource("<new_id>_nok")`, with a matching
  `[ext_resource type="Texture2D" path="res://assets/characters/nok_idle_01.png" id="<new_id>_nok"]`
  line added near the other ext_resource declarations) — this bypasses
  `VillagerNPC.gd`'s npc_id-keyed fallback switch entirely, which is
  the simpler and now-preferred path (see scope note above). The
  portrait asset `assets/characters/nok_idle_01.png` already exists
  (created this task, hue-shifted placeholder from
  `npc_handler_idle_01.png` — same documented-placeholder approach used
  for Ploy in TASK-335, flagged for the open Art Pass item).
- No new `.tscn` file needed. No new `Main.gd` function needed — Nok is
  a static `Main.tscn` child exactly like Elder/Child/Handler, not a
  dynamically-`_ensure_*`'d node like the peer-NPC (Niran/Fah/Ploy)
  pattern.

## What to build

### 1. `scenes/core/Main.tscn`

Add the ext_resource line for `nok_idle_01.png` and a new
`[node name="NokNPC" parent="." instance=ExtResource("8_villager")]`
block (position/npc_id="nok"/display_name="Nok"/idle_texture as
described above), placed near Elder/Child/Handler's declarations for
readability. Position: `Vector2(216, 360)` — tile (4,7), verified via
a headless `ground_at()` probe to be `plantable_soil` (walkable) and
clear of every other node's position; re-verify against the current
occupied-position list if you change it (grep `position = Vector2` in
`Main.tscn` plus `pos.*Vector2` in `Main.gd` for the current list).

### 2. `scripts/narrative/DialogueDB.gd`

Add a `"nok"` entry to `DIALOGUE` (season-keyed, matching elder/child/
handler's shape — NOT the affinity-tiered shape used by niran/fah/ploy,
Nok is a regular villager, not a romance candidate): `cool`, `hot`,
`monsoon`, `rain` (2 lines each, matching the weather-branch pattern
from TASK-329 — read the `"elder"`/`"handler"` entries for exact tone
reference), `binthabat_done`, `binthabat_hint` (2 lines each).

Add `"nok": {"loved": [...], "liked": [...]}` to `GIFT_PREFERENCES`.
Suggested: loved `["sticky_rice", "ginger"]`, liked
`["rice_grain", "banana"]` — verified obtainable: `sticky_rice`/
`rice_grain` are jasmine_rice/sticky_rice crop yields, `ginger` and
`banana` are both real crops (`data/crops/ginger.tres`,
`data/crops/banana.tres`).

### 3. `scripts/narrative/ScheduleDB.gd`

Add a `"nok"` schedule (3 hour-windows): `{"from": 6, "to": 12, "pos": Vector2(4, 7)}`
(paddy check, morning), `{"from": 12, "to": 24, "pos": Vector2(4, 8)}`
(home porch — one window covering midday+evening is fine, doesn't need
to be split in two like elder/child's 3-window shape). Label the home
slot `# home` in a comment, matching elder/child's convention. Verified
via the same `ground_at()` probe: `Vector2i(4, 8)` is `plantable_soil`.

Add `"nok": Vector2(4, 8)` to the existing `RAIN_HOME` dict (from
TASK-328) — extends weather-reactive scheduling from 2 NPCs (elder,
child) to 3, for free, since the mechanism already exists.

## Tests

Extend `tests/test_schedules.gd` with a rain-home check for Nok
(mirror the existing elder/child checks) and `tests/test_gift_prefs.gd`
with a gift-flow check for Nok via `VillagerNPC.talk()` (mirror the
existing elder check). Also add `NokNPC` + its portrait to
`tests/test_villager_portraits.gd`'s `expectations` dict (that test was
written specifically to catch exactly this kind of "renders as Elder
by accident" bug — Nok should be in it).

## Constraints

- Exactly one new NPC — do not add a second.
- Do not modify Niran/Fah/Ploy, or any romance-candidate content.
- Do not touch `QuestLog.gd` — no quest tied to Nok in this task.
- Do not modify `VillagerNPC.gd`'s idle-texture fallback switch — Nok
  uses the explicit `idle_texture` override path instead (see above).
- Run `bash scripts/ci/run_gate.sh all` before considering this done —
  check the Y-sort perf budget specifically (Nok has a real sprite,
  same as every other villager — the 49→50 bump from TASK-335 may need
  to become 50→51; verify by running the gate, don't assume either way).
- No git/gh actions — stop after code + tests are written and the gate
  is green. Do not commit, push, open a PR, or merge.
