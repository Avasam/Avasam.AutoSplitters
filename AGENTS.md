# AGENTS.md

LiveSplit auto splitters and load removers written in the Auto Splitting Language (ASL). Each game folder has one `.asl` script and a `README.md`, some also ship splits templates (`.lss`).

Scripts target the original LiveSplit only, the one ASL runs on. It is a Windows application (it can also run through Wine). LiveSplit One and other timers do not run ASL.

## ASL reference

Before reading or changing any `.asl` file, load the `asl` skill ([.claude/skills/asl/SKILL.md](.claude/skills/asl/SKILL.md)). Agents without skill support should read that file directly. It summarizes the language and links the official docs and LiveSplit sources.

## Conventions

- Follow [.editorconfig](.editorconfig) (CRLF line endings, tabs).
- Action bodies are C# 5 (see the `asl` skill for why).
- Action blocks keep a trailing comment saying when they run, for example `startup { // When the script loads`. When a block is chosen over a more obvious one, the comment also says why, for example `onStart { // When the timer starts, unlike start{} also on manual starts`.
- When pointers are unstable or the process name is ambiguous, scripts build `MemoryWatcher`s in `init` and update them in `update` instead of using the `state` block. Signature scanning is used when there is no stable pointer.
- Clear per run state (for example "already split on X") in `onStart`, otherwise it leaks into the next run.
- A game's `README.md` documents start offsets, known issues and future improvements. Update it when behaviour visible to runners changes.
- New games get an entry in the root [README.md](README.md): "Officials" if registered in LiveSplit's [auto splitters XML](https://github.com/LiveSplit/LiveSplit.AutoSplitters/blob/master/LiveSplit.AutoSplitters.xml), otherwise "Unofficials".

## Verifying changes

No build, linter or tests. Scripts only run inside LiveSplit on Windows (or Wine) with the game attached, which agents usually cannot do. Review the change against the execution order and variable availability in the `asl` skill, then tell the user it is untested and what to watch for when loading it in a Scriptable Auto Splitter component.
