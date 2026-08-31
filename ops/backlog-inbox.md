# Backlog-Inbox — append-only ledger

> State-driven only. Squads pull READY_FOR_PM items; never direct PM-to-PM contact.
> Sprint 1 = "Match Draft B" (3/4 canon). Sprint 2 starts only after Sprint 1 exit sign-off.

<task_item>
  <id>TASK-005</id>
  <source>OWNER_POPUP</source>
  <status>NEEDS_OWNER_REVIEW</status>
  <priority>HIGH</priority>
  <title>Define 3/4 art rules in ART_STYLE_GUIDE (tile metrics, Y-sort, zoom 2.2 provisional)</title>
  <description>Update ART_STYLE_GUIDE.md with the 3/4 perspective canon per issue #5 REV 2. Ground stays flat 32x32; verticals get tall art; Y-sort origin at feet; zoom 2.2 provisional.</description>
  <researcher_notes>Owner: @visual-inspector. Issue #6. No deps. Refs: docs/art_direction/canon_34_draft_B.png, zoom_framing_comparison.png.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-006</id>
  <source>OWNER_POPUP</source>
  <status>READY_FOR_PM</status>
  <priority>HIGH</priority>
  <title>Generate tall art assets for 3/4 canon (16-color palette)</title>
  <description>Bamboo wall 32x48, structure wall 32x48 front + 32x16 cap, mango 32x64, banana/sluice 32x48, stove 32x40. Dock stays flat. Strict 16-color palette.</description>
  <researcher_notes>Owner: @data-pipeline. Issue #7. Depends: TASK-005 rules (metrics already fixed in issue #5 REV 2 - may start in parallel if rules draft is stable).</researcher_notes>
</task_item>

<task_item>
  <id>TASK-007</id>
  <source>OWNER_POPUP</source>
  <status>READY_FOR_PM</status>
  <priority>HIGH</priority>
  <title>World render: 20x16 tilemap matrix + Y-sort layers + bounds + edge dressing</title>
  <description>Render locked Hybrid A/B layout in Main.tscn: tilemap matrix, Y-sorted prop/character layer, bounds colliders, bamboo ring + Deep Pond backdrop.</description>
  <researcher_notes>Owner: @spatial-architect. Issue #8. Depends: TASK-006 tall art (can scaffold with flat tiles first).</researcher_notes>
</task_item>

<task_item>
  <id>TASK-008</id>
  <source>OWNER_POPUP</source>
  <status>READY_FOR_PM</status>
  <priority>HIGH</priority>
  <title>Camera center-lock in-engine + zoom tune (3/4 canon)</title>
  <description>Player.tscn Camera2D: drag margins off, smoothing off, zoom 2.2 provisional (tune with real art). NOTE: Camera2D 'current' property is gone in Godot 4.7 - use 'enabled'.</description>
  <researcher_notes>Owner: @visual-inspector. Issue #5 (REV 2). Depends: TASK-007 world render for meaningful tuning.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-009</id>
  <source>OWNER_POPUP</source>
  <status>READY_FOR_PM</status>
  <priority>MEDIUM</priority>
  <title>Player walk 8-frame / idle 4-frame animation wiring</title>
  <description>Wire AnimatedSprite2D states. Existing: idle 1 frame, walk_down/right 4 frames. Generate walk_up; left mirrors right if Pha Khao Ma reads OK mirrored.</description>
  <researcher_notes>Owner: @data-pipeline. Issue #9. No hard deps.</researcher_notes>
</task_item>

<task_item>
  <id>TASK-010</id>
  <source>OWNER_POPUP</source>
  <status>NEEDS_OWNER_REVIEW</status>
  <priority>MEDIUM</priority>
  <title>HUD QA + seasonal tint + screenshot capture hook</title>
  <description>Verify HUD anchors + tints per ART_STYLE_GUIDE; add screenshot hook (F12) saving 1600x900 PNG to user:// for director review.</description>
  <researcher_notes>Owner: @visual-inspector. Issue #10. No hard deps.</researcher_notes>
</task_item>

<!-- PO LEDGER: 2026-08-31 TASK-005 -> PR #11 merged (squash), issue #6 auto-closed. Tests 40/40 green. -->
<!-- PO LEDGER: 2026-08-31 hygiene: pruned stale task-005-art-rules ref, visual-inspector handshake synced. Owner locked: repo squad names unchanged (parallel design team), multi-sprint auto-continue after exit gates. -->
<!-- PO LEDGER: 2026-08-31 Sprint1 wave1: TASK-006 PR #14 merged (issue #7), TASK-009 PR #13 merged (issue #9, rebased to strip design team's unpushed 51cfd2b), TASK-010 PR #12 merged (issue #10, design team delivery). Merged main 40/40 green. Remaining Sprint 1: TASK-007 -> TASK-008. -->
<!-- PO NOTE: parallel design team works in /Users/grit/slowlife-game shared checkout; PO loop runs isolated worktrees under /Users/grit/slowlife-game-loop*. TASK-010 was claimed by design team (branch task-010-screenshot-hook) — respected, not duplicated. -->
<!-- SQUAD REPORT: 2026-08-31 TASK-007 spatial-architect done — WorldRender.gd zone matrix + Y-sort + bounds + bamboo ring + Deep Pond backdrop; monk to temple lane; tests 54/54 green (14 new worldrender checks); PR opened for PO gate. Note: headless screenshot hook null-texture under dummy renderer — windowed capture needed for TASK-008 visual evidence. -->
