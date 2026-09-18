# GuitarMap project instructions

These rules extend `C:\dev\Godot\games\AGENTS.md` and do not replace its
global Godot paths, skills, MCP package, or verification requirements.

## Product constraints

- Treat `docs/DEVELOPMENT_PLAN.md` as the implementation roadmap and
  `docs/reference/guitarmap-ui-reference.png` as UX direction, not a pixel-perfect specification.
- Keep music theory, tuning, fretboard geometry, interaction, audio, and UI as
  separate modules. UI nodes must not become the source of truth for pitches.
- A fret position is identified by `string_index + fret`; its pitch is the
  selected tuning's open-string MIDI note plus the fret.
- Standard tuning is the initial preset, never a hard-coded architectural
  assumption. Preserve support for arbitrary string counts and alternate tunings.
- CAGED belongs to the first product layer alongside full-fretboard and
  position views. Do not reduce CAGED to five fixed fret ranges; model shapes
  relative to root and tuning.
- Multitouch contacts own independent note voices. Never collapse simultaneous
  touches into a single monophonic player.
- Preserve enharmonic spelling as a presentation choice; pitch identity uses
  pitch class/MIDI internally.

## UX and accessibility

- Design landscape-first for phone/tablet and keep desktop responsive.
- The fretboard remains the primary interaction surface. Maintain the reference
  hierarchy: compact selectors, view modes, clear tonic contrast, and readable
  note/degree labels.
- Do not use colour as the only distinction. Provide text/shape cues, minimum
  touch targets, scalable UI, and an accessible palette.
- Mouse input may emulate one touch, but multitouch behavior must be verified
  separately on a device or with explicit multi-contact tests.

## Models and delegation

- Follow the global default: `gpt-5.6-terra` with medium reasoning for routine
  implementation, tests, review, and bounded debugging.
- Use Luna/low only for mechanical edits. Recommend Sol/high for architecture,
  audio concurrency, difficult cross-module defects, or security-sensitive work.
- Use `gpt-5.3-codex-spark`/low (`FAST_INTERACTIVE_EXECUTOR`) only for a
  delegated short, local, well-defined coding or UI adjustment in an existing
  implementation when rapid feedback materially helps. Do not use it for
  architecture, cross-module or unclear work, risky changes, or deep reasoning.
- Use Astra/xhigh only for a difficult indivisible end-to-end problem where it
  materially reduces rework. Delegate only bounded independent workstreams;
  the primary agent owns integration and verification.

## Tools and verification

- Reuse the global `godot:godot`, `imagegen`, `generate2dsprite`,
  `generate2dmap`, and `video2dsprite` skills when relevant. Do not copy them
  into this repository.
- Reuse the workspace MCP at `C:\dev\Godot\tools\godot-mcp`; do not add another
  MCP configuration. The local `godot_ai_bridge` addon is the required project
  endpoint for live-editor/runtime tools.
- Before an MCP write, confirm that the selected project is
  `C:\dev\Godot\games\Guitar`.
- After GDScript or scene changes, run headless import/parse, targeted tests,
  and the main-scene smoke test. State clearly when visible rendering, real
  audio, multitouch, Android, or iOS device behavior has not been verified.
- Do not initialize Git unless the user explicitly requests it.
