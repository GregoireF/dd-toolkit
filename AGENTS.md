# AGENTS.md

Instructions for any AI coding agent (Claude Code, Copilot, Cursor, Codex,
Gemini CLI, Devin, etc.) working in this repo. Humans: see
[README.md](README.md) and [CONTRIBUTING.md](CONTRIBUTING.md) instead —
this file is optimized for an agent's context window, not for reading
prose.

## What this is

AutoHotkey v2 macros for Dungeon Defenders Redux (a Windows game), plus a
PowerShell build/test/release pipeline and Node-based commit tooling. Two
runtimes matter: **AutoHotkey v2** (the actual macros) and **PowerShell**
(everything that builds/tests/releases them). Node is dev-only tooling for
commit messages — never required to run or ship the macros themselves.

## Commands (copy-pasteable, all from repo root)

```powershell
# One-time per clone
.\scripts\Install-Hooks.ps1          # core.hooksPath -> .githooks
npm install                          # only needed to use `npm run commit` / commitlint locally

# Everyday
.\tests\Test-Syntax.ps1              # syntax/load smoke test for src/*.ahk
.\tests\Run-UnitTests.ps1            # real assertions on every module's logic, Send/PixelSearch/etc. shimmed
.\build\Build-All.ps1                # compiles src/*.ahk -> dist/*.exe (gitignored)
npm run commit                       # interactive Conventional Commit + gitmoji prompt (cz-git)

# Release (on main, after Build/Test pass)
.\scripts\Bump-Version.ps1 -Version X.Y.Z   # VERSION + Ahk2Exe directives + CHANGELOG.md
git tag vX.Y.Z && git push --tags           # triggers .github/workflows/release.yml
```

`tests/Test-Syntax.ps1`, `tests/Run-UnitTests.ps1`, and `build/Build-All.ps1`
all take an `-AhkExe` / `-Ahk2Exe`/`-Base` override if AutoHotkey v2 isn't
at the default `C:\Program Files\AutoHotkey\v2\...` path.

## Code style — non-negotiable, not a style preference

- **No hardcoded key/interval/process-name values.** They belong in
  `config/settings.ini`. Read strings with `DD.Read(section, key,
  default)`, integers with `DD.ReadInt(...)`, booleans with
  `DD.ReadBool(...)` (all in `src/Lib/Common.ahk`) — never bare
  `Integer(DD.Read(...))` or a raw `= "true"` string compare. `ReadInt`/
  `ReadBool` catch a malformed value and fall back to `default` with a
  `DD.Notify`, so a typo in the ini degrades gracefully instead of
  crashing the script's auto-execute section outright. Always provide a
  sane default so the script works before anyone touches the ini.
- **`DD.ConfigPath` resolves same-folder-first** (see
  `DD.ResolveConfigPath()`), falling back to the repo's `src/`↔`config/`
  sibling layout. This is what lets a standalone `.exe` from a GitHub
  Release find `settings.ini` sitting next to it (which
  `build/Build-All.ps1` copies into `dist/` for exactly this reason) —
  don't reintroduce a hardcoded `..\config\settings.ini`-only path.
- **Every macro that sends keystrokes must scope to the game window**:
  `#HotIf WinActive(DD.GameCriterion())` for static hotkeys, or
  `HotIfWinActive(DD.GameCriterion())` / `Hotkey(...)` / `HotIfWinActive()`
  (reset) for hotkeys registered dynamically at runtime. Note this is
  `HotIfWinActive()`, not the generic `HotIf()` — `HotIf()` takes a
  boolean-returning *callback function*, not a WinTitle string; passing
  `DD.GameCriterion()` (a string) to `HotIf()` directly is a real bug that
  slipped into this codebase once already. An unscoped `Send` is a bug
  unless the script is deliberately system-wide (document why inline if
  so).
- **`ObjBindMethod(this, "X")` returns a brand-new object every call —
  `SetTimer` identifies "which timer" solely by that object's identity,
  not by target+method-name equivalence.** Arming with
  `SetTimer(ObjBindMethod(this,"X"), period)` in one method and later
  "disarming" with `SetTimer(ObjBindMethod(this,"X"), 0)` in a *different*
  method call creates two distinct callbacks as far as `SetTimer` is
  concerned — the disarm call silently does nothing to the timer that's
  actually running. Verified empirically (a real 20ms timer kept firing
  for hundreds of ms after being "disarmed" this way) after it shipped in
  `AutoAbilityModule.Toggle()`/`Panic()` from v0.1.0 — the panic hotkey
  updated the status text and played the stop-beep while the real
  keypress timer kept running. Fix: bind once, store the result in a
  static property (`BoundPressAbility`), and reuse that same reference
  for every arm/disarm call. Any future module that arms a repeating
  `SetTimer` with a bindable callback needs this pattern from the start,
  not just AutoAbilityModule.
- **`SetTimer(callback, period)` with a positive `period` never fires on
  its own the instant it's armed** — the first execution only happens
  after a full `period` has elapsed (confirmed in AutoHotkey's own docs).
  A macro that arms on a long interval and expects to "do something
  right away" needs an explicit immediate call in addition to arming the
  timer (see `AutoAbilityModule.Toggle()`) — otherwise arming reads as
  "did nothing" for however long the interval is, which is exactly what
  shipped from v0.1.0 with the 47s default.
- **`SetKeyDelay()` only affects *keyboard* keys sent by `Send`/
  `SendEvent` — it has no effect on mouse buttons** (`LButton`,
  `RButton`, etc.), which are governed by `SetMouseDelay()` instead
  (confirmed in AutoHotkey's own docs). A module that only ever sends
  mouse buttons and calls `SetKeyDelay` is calling a no-op — this shipped
  in `AutoClickerModule` from v0.1.0, silently making its `IntervalMs`
  setting have zero effect on the actual click rate.
- **Shared code lives in `src/Lib/`**, included explicitly
  (`#Include Lib\Common.ahk`) — this repo does not rely on AutoHotkey's
  auto-lib-by-function-name lookup.
- **Every macro's logic is a class in `src/Lib/Modules/*.ahk`** (e.g.
  `AutoAbilityModule`), not bare top-level globals/hotkeys — this is what
  lets `src/DDToolkit.ahk` `#Include` every module into one process
  without them clobbering each other's identically-named state (they'd
  all have a plain global called `intervalMs` otherwise). Each module
  exposes `Init()` (reads config, registers hotkeys — no-ops if
  `Enabled=false`) and `StatusText()` (one-line summary for the tray
  tooltip). The standalone `src/<Name>.ahk` scripts are thin wrappers:
  `#Include` the module, call `.Init()`, done.
- **`GameTweaksModule` is a different risk category from every other
  module**: it edits a file that belongs to the *game's own install*
  (`UDKEngine.ini`), not just synthetic input to a running process — the
  change outlives closing the script, unlike everything else here. Any
  code that writes to a file outside this repo/its own settings.ini must:
  back up first, never guess/create a section or structure it hasn't
  confirmed exists in the target file (search-and-replace existing lines
  instead of blind `IniWrite` to a guessed `[Section]`), and abort with a
  clear message — no silent no-op — if it finds nothing to change. See
  `GameTweaksModule.ApplyTextureFix()` and `docs/CORRECTIFS-JEU.md`.
- **Static class properties must be declared** (`static Foo := ""` in the
  class body) **before being assigned from inside a method.** Assigning
  to an undeclared name via `this.Foo := value` inside a static method
  isn't guaranteed to create a real static property in v2 — only an
  explicit `static` declaration is. Every `GuiControl` reference in
  `DDToolkit.ahk`'s `SettingsWindow` class is pre-declared for exactly
  this reason.
- **AutoHotkey v2 syntax only.** Never write v1 (`Send, x`, `WinGetPos, X,
  Y,...` command-style). Functions inside a script that read/write a
  variable assigned at top-level scope need an explicit `global` inside
  the function — v2 does not fall back to globals implicitly.
- **Every toggle gives audible/visible feedback**: `DD.Beep(bool)` and/or
  `DD.Notify(title, text)`. No silent state changes.
- New macro → start from
  [`templates/NewMacro.ahk.example`](templates/NewMacro.ahk.example), not
  a blank file.
- **In `.ps1` files, keep non-ASCII characters (em-dash, accents) confined
  to comments/help blocks.** One inside an actual string literal can get
  misdecoded under Windows PowerShell 5.1's BOM-less-file handling into a
  Unicode smart-quote-like byte, which the parser treats as a string
  delimiter — the script fails to parse under plain `powershell.exe` (not
  `pwsh`). Shipped in two scripts here before being caught; see
  `CLAUDE.md` for the mechanism. Plain ASCII (`-`) in string literals.

## Testing — know the boundary

`tests/Test-Syntax.ps1` is a **load smoke test**, not a functional test. It
launches each `src/*.ahk` with AutoHotkey v2 and checks it stays resident
(the four standalone scripts register hotkeys, which makes AHK persistent
automatically; `DDToolkit.ahk` calls `Persistent()` explicitly since it
could otherwise end up with zero hotkeys if every module is disabled in
settings.ini). It cannot verify that a tower actually stacks in-game. **There is no way
to automate that** — it requires a human launching Dungeon Defenders. If
you change macro logic, say explicitly that it needs manual in-game
verification; never claim a behavioral fix is confirmed working from the
smoke test or a build succeeding alone.

`tests/Run-UnitTests.ps1` (via `tests/RunTests.ahk`) is one level deeper
than the smoke test: it runs real assertions, via the vendored
[AutoHotUnit](https://github.com/joshuacc/AutoHotUnit) framework
(`tests/vendor/AutoHotUnit.ahk`, MIT, single file, no other dependency),
against **every** module's logic — not just the pure pieces. `Init()`
runs for real on every module (config loading, real hotkey registration —
see the `SetTimer` note above; a registered hotkey makes AHK persistent,
and AutoHotUnitCLIReporter's own `onRunComplete()` ends the run with
`Exit(count)`, which only ends the *current thread* once persistence has
kicked in, not the process — verified empirically before `RunTests.ahk`'s
custom `CIReporter` was written to call `ExitApp()` instead, confirmed to
terminate regardless).

Methods that would otherwise send real synthetic input or query the real
OS/desktop — `PressAbility`/`Toggle`/`Panic`, `Stack`/`HandleHotkey`,
`FireChargedShot`, `FireLeft`/`FireRight`/`TurboFire`, `SpinWheel`/
`SlotMatches`, `ResolveInstallPath`/`AutoDetectInstallPath`/`Apply*Fix` —
are also fully tested, via `tests/Shims.ahk`: a same-named user-defined
function overrides a built-in for the rest of a script in AHK v2
(verified empirically), so `Send`, `SendEvent`, `GetKeyState`,
`PixelSearch`, `WinExist`, `WinGetPos`, `SetTimer`, `DirSelect`, `MsgBox`,
and `RegRead` are all replaced with deterministic, resettable recorders/
stubs for the whole test process. This means the real Send()-calling
code runs end to end in every test, but no real keystroke, click, screen
read, modal dialog, or registry query ever reaches the OS or the live
desktop — the same category of risk as simulated mouse/keyboard input
(see the GUI/input testing section above), neutralized at the source
instead of avoided by not testing the method at all. `GetKeyState(key,
"P")` deserves a callout: it's immune to synthetic `Send()`/`SendEvent()`
by AHK's own design (verified empirically), so `AutoClickerModule.
TurboFire()`'s loop is fundamentally untestable through any real input in
*any* environment — only `Shims.KeyStatePMode` can exercise it.

Because the shim override is global and total for the rest of the
process (there's no "call the real one as a fallback" once a name is
shadowed), a test that genuinely needs real OS behavior from one of
those ten functions doesn't belong in this suite — none currently do.
`Shims.Reset()` in each suite's `beforeEach()` keeps tests isolated from
each other; `GameTweaksSuite`'s `afterEach()` additionally resets
`GameTweaksModule.InstallPath` and rewrites it to `""` in the fixture
ini, since `ResolveInstallPath()`/`AutoDetectInstallPath()` persist a
found path via `DD.Write` — without that cleanup, a scratch path from one
test run would leak into `tests/settings.ini` and show up as a stray git
diff.

Neither level proves a hotkey fires correctly against a live game
window — that gap is exactly what `Test-Syntax.ps1`'s own limitation
above describes, and still requires a human in Dungeon Defenders. When
adding a new module, add its logic here — pure functions directly,
anything OS-touching via a new `Shims.ahk` entry following the existing
pattern — rather than leaving it covered only by the load smoke test.

## Security boundaries

Scripts in `src/` only call Windows `SendInput` targeted at the configured
game process (`DunDefGame.exe` by default). No network calls, no telemetry,
no file access outside `config/settings.ini`. Don't add any — if a change
would need network access or data collection, stop and ask first (see
[SECURITY.md](SECURITY.md)).

In `.github/workflows/*.yml`: never splice a `${{ }}` expression whose
value is free-form/attacker-or-user-controllable text (a `workflow_dispatch`
input, a PR title, a branch name, a commit message) directly into a `run:`
script body — that's the standard GitHub Actions script-injection vector.
Pass it through `env:` first and read it back as `$env:NAME` instead (see
`release.yml`'s `TAG_NAME`). GitHub-computed opaque values (commit SHAs
like `github.event.pull_request.head.sha`) are fine to interpolate
directly — they're not attacker-controllable text.

## Commits / branches / PRs

- Conventional Commits, optionally gitmoji-prefixed, enforced by
  `commitlint.config.js` (see [CONTRIBUTING.md](CONTRIBUTING.md#commits)).
  Valid types: `feat fix docs style refactor perf test build ci chore
  revert`. French subjects are fine — `subject-case` is intentionally
  disabled.
- Branch naming and PR flow: [BRANCHING.md](BRANCHING.md). Squash-merge
  into `main`; the squash commit message must itself pass commitlint.
- Never commit, tag, or push without the user's explicit go-ahead in the
  current conversation — this repo's history is intentionally
  hand-curated, not agent-automated.

## Directory map

```
docs/DEMARRAGE.md      Zero-prerequisite install guide (French, for non-technical end users)
docs/CORRECTIFS-JEU.md Known fixes to the game itself (not this toolkit) — sourced, backup-first
config/settings.ini    User-tunable values (keys, intervals, game process name, Enabled per module)
src/Lib/Common.ahk     Shared helpers (config read/write, window scoping, notify/beep)
src/Lib/Modules/*.ahk  One class per macro/tool — the actual logic, reused by both entry points below
src/DDToolkit.ahk      Unified entry point: tray icon + menu + tabbed GUI settings window, all modules
src/Setup.ahk          Optional installer: desktop shortcut / Windows-startup shortcut, nothing else
src/<Name>.ahk         Thin standalone wrapper around one module (AutoAbility, TowerStacking, ...)
templates/*.example    Starting point for a new macro
scripts/*.ps1          One-off maintenance (hook install, version bump)
build/Build-All.ps1    src/*.ahk -> dist/*.exe + settings.ini (dist/ is gitignored)
tests/Test-Syntax.ps1  Load smoke test (see boundary above)
tests/Run-UnitTests.ps1 Real assertions on every module's logic (see boundary above)
tests/Shims.ahk        Test doubles for OS-touching built-ins (Send, PixelSearch, RegRead, ...)
tests/vendor/          Vendored AutoHotUnit.ahk (MIT) — the test framework itself
.github/workflows/     ci.yml (smoke test+unit tests+build), release.yml (tag -> GitHub Release),
                       commitlint.yml (PR commit messages)
.githooks/             Versioned git hooks (core.hooksPath) — pre-commit, commit-msg
```
