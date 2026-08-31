# Project Directives: slowlife-simulator

## Role & Delegation Rules
- **Your Role:** PR Gatekeeper and Quality Assurer (Claude Sonnet).
- **Sub-Agent Delegation:** Use `opencode run --agent musespark "<TASK_PROMPT>"` to offload heavy coding or asset generation.

## PR Gatekeeper Verification Workflow
1. When MuseSpark creates a PR, inspect diffs using `gh pr diff <PR_NUMBER>`.
2. Verify Godot 4 GDScript standards, SignalBus decoupling, and zero-combat vision adherence.
3. Run headless verification: `godot --headless --path . --script res://tests/run_tests.gd`
4. If checks pass, execute:
   `gh pr merge <PR_NUMBER> --repo GRITui/slowlife-simulator --squash --delete-branch`
5. Update task status in `backlog.json` to `"completed"` and close the GitHub Issue.
