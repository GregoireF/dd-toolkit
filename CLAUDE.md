<!--
  Read by Claude Code specifically. The full, agent-agnostic guide lives
  in AGENTS.md — this file stays thin and points there instead of
  duplicating it. (HTML comments are stripped before this file reaches
  Claude's context, so this note is free — it's for the next human
  editing this file, not for the model.)
-->

# CLAUDE.md

Read [AGENTS.md](AGENTS.md) first — commands, code style, testing
boundary, and commit/branch conventions all live there. This file only
adds what's specific to operating as Claude Code in this repo.

## Environment reality

- This repo's tooling is **PowerShell**, not POSIX shell —
  `tests/*.ps1`, `build/*.ps1`, `scripts/*.ps1` are all `.ps1`. Use the
  PowerShell tool for shell commands here, not Bash.
- Windows PowerShell 5.1's `Get-Content`/`Set-Content -Encoding utf8`
  mis-decodes this repo's accented French text when the source has no
  BOM, and adds a BOM on write where none existed before. Anything that
  reads/writes repo text files (CHANGELOG.md, `.ahk`, `.ini` — anything
  with accents) should use `[System.IO.File]::ReadAllText` /
  `WriteAllText` with an explicit `UTF8Encoding($false)`, the way
  `scripts/Bump-Version.ps1` does. Don't reintroduce the mojibake bug.
- The same BOM-less-UTF8-misread-as-cp1252 issue doesn't just corrupt text
  — it can break a `.ps1` outright. An em-dash (or any accented char)
  inside an actual string literal (not a comment) gets misdecoded into a
  byte sequence ending in a smart-quote-like character, and PowerShell's
  parser treats Unicode smart quotes as string delimiters, so the string
  terminates early and the whole script fails with "Le terminateur \" est
  manquant" — under plain `powershell.exe` (5.1), not `pwsh`. This shipped
  in `tests/Test-Syntax.ps1` and `scripts/Install-Hooks.ps1` before being
  caught — both
  `[System.Management.Automation.Language.Parser]::ParseFile()` and an
  actual `powershell -File` run surfaced it identically once tried. Keep
  non-ASCII characters in `.ps1` files confined to comments/help blocks;
  use plain ASCII (`-`, not an em-dash) in anything that's an actual
  string literal. This is **specific to `.ps1`** — AutoHotkey v2 defaults
  to reading its own scripts as UTF-8 even without a BOM, so em-dashes/
  accents in `.ahk` string literals (there are many, e.g. every
  `DD.Notify(...)` call) are fine and don't need the same treatment.
- Piping a literal string into a native process's stdin
  (`Write-Output "..." | someExe`) can also mangle the encoding here. To
  test a tool that reads text (e.g. commitlint), write a real file and
  pass its path, or call the tool's Node/API directly — don't trust a
  piped-stdin test result at face value.
- For dynamically-scoped hotkeys, it's `HotIfWinActive(DD.GameCriterion())`
  — not the generic `HotIf(callback)`, which takes a boolean-returning
  *function*, not a WinTitle string. Passing a criterion string straight
  to `HotIf()` doesn't error at load time, it just silently never matches
  — this shipped in two files before being caught. AHK v2 docs are
  frequently unreachable via WebFetch (403) from this environment; use
  WebSearch and cross-reference multiple mirrors before trusting a v2 API
  detail you're not certain of, the way this one was verified.
- Class static properties must be pre-declared (`static Foo := ""`) —
  see AGENTS.md's code style section. Treat every non-trivial v2 API
  claim as needing a search-verified source, not recall, before it goes
  in a file — this specific bug is why.
- **AutoHotkey v2 is not installed on this machine by default, but it can
  be fetched for real testing**: download the same official portable zip
  `ci.yml`/`release.yml` use (`https://api.github.com/repos/AutoHotkey/AutoHotkey/releases/latest`,
  asset matching `AutoHotkey_*.zip`) to a scratch temp folder and point
  `tests/Test-Syntax.ps1 -AhkExe <path>\AutoHotkey64.exe` at it — no
  admin rights needed. Do this rather than reasoning from static review
  alone when a change touches non-trivial AHK logic (GUI construction,
  regex-based file edits, registry reads); it has already caught real
  things static review missed.
- **This machine has no isolated test display — GUI/input testing runs on
  the user's real desktop.** A screenshot of a script's own window is
  safe (own process, own window handle). Simulating a click/keystroke is
  not: a single miscalculated coordinate landed on an unrelated window
  that happened to be open (no damage done, but it could have typed into
  the wrong app). Never simulate mouse/keyboard input against the live
  desktop without the user's explicit go-ahead for that specific action —
  a screenshot alone already answers most "does the GUI render right"
  questions.

## Before claiming something works

This project's actual behavior (does a tower really stack, does the
cooldown macro really fire) can only be verified by a human running
Dungeon Defenders. A passing `tests/Test-Syntax.ps1` or a successful
build means the script loads — nothing more. Say that explicitly; never
imply in-game verification happened when it didn't.

## Git

Don't run `git init`, `commit`, `tag`, or `push` unless the user has said
so for *this* change, in *this* conversation. Approval doesn't carry
forward to the next one.
