# Environment Prop Density Guideline

For future area work (TASK-343/344, whenever they resume) and any further
decoration passes on existing areas. Written after TASK-368's light pass on
`World.tscn` — a reference for the judgment calls that pass made, not a
hard rule enforced by code.

## Density target

Roughly **1 standing prop (PROPS-style, y-sorted) per 15-20 open tiles**,
plus **1 flat-decor accent (FLAT_DECOR-style, ground-level) per 20-30 open
tiles**, counting only genuinely open/walkable ground — not water, canal,
paddy-core (the player's actual farmable plots), or tiles already occupied
by an interactable/NPC/building. This is deliberately sparse: the game's
own art direction already reads as clean and uncluttered, and the goal of
a decoration pass is to soften empty corners, not fill the map.

## Asset-reuse convention

- **Never generate new art for a decoration pass.** `assets/environment/`
  already has enough variety (bamboo thicket, banana/mango tall trees,
  clay stove) for a modest pass. Check there first, always.
- **Respect the existing `_tall` suffix convention**: textures suffixed
  `_tall` (e.g. `banana_tree_tall.png`, `mango_tree_tall.png`,
  `clay_stove_tall.png`) are this project's established *purely
  decorative* standing-prop art — even though the same crop's harvestable
  entity (`ForestTree.tscn`, etc.) may reuse the same base texture
  elsewhere, the "_tall" prop entries in `WorldRender.gd`'s `PROPS` array
  carry no interaction of their own. Reuse these confidently for decor.
- **Never decorate with an asset that implies interactivity the tile
  doesn't have.** Don't place a decorative crop-tree prop close enough to
  a real farmable/harvestable tile that a player might expect it to be
  the interactable one — keep decorative standing props in genuinely
  non-farmable ground (pasture edges, temple lane, home yard), not inside
  `paddy_core`/`paddy_south`.
- **Flat decor (`FLAT_DECOR`) never blocks a tile** — it's ground-level,
  y-sort-exempt dressing (bamboo thicket accents), safe to place more
  liberally than standing `PROPS` since it never visually competes with
  a walking character or NPC for the same tile.

## Placement checklist (what TASK-368 actually checked before placing)

1. Read `WorldRender.gd`'s own `GROUND_TILES`/zone-rect data (or the
   equivalent for a new area) — know which rects are water/canal (never
   place), plantable soil (avoid — that's the player's farmland), and
   genuinely open ground (fair game).
2. Cross-reference every existing occupied position (NPCs, interactables,
   doors, existing `PROPS`/`FLAT_DECOR` entries) before picking a new
   cell — no overlaps.
3. Keep the total addition "a handful," not a redesign. If a pass adds
   more than ~5-6 new entries to one area, it's no longer a light
   decoration pass — split it into its own scoped task instead.
