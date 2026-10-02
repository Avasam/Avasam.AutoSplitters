---
name: asl
description: LiveSplit Auto Splitting Language (ASL) reference. State descriptors, actions and their execution order, vars, settings, memory helpers, debugging. Use when reading, writing, reviewing or debugging any .asl file.
---

# Auto Splitting Language (ASL)

ASL scripts are LiveSplit auto splitters. A script is one or more `state` blocks followed by optional action blocks whose bodies are C#, compiled by LiveSplit at load time.

## Which LiveSplit

Only the original LiveSplit (.NET Framework, Windows only, can run through Wine) runs ASL, through its Scriptable Auto Splitter component. LiveSplit One (web and desktop) and other timers do not run ASL. They use sandboxed WebAssembly auto splitters instead, which are out of scope here.

## ASL and C#

ASL is neither a superset nor a subset of C#. It is a small outer grammar whose action bodies are C# statements.

- Outer grammar ([ASLGrammar.cs](https://raw.githubusercontent.com/LiveSplit/LiveSplit.ScriptableAutoSplit/master/src/LiveSplit.ScriptableAutoSplit/ASL/ASLGrammar.cs)): all `state` blocks first, then action blocks, plus `//` and `/* */` comments. Nothing else is allowed at top level: no `using`, `namespace`, classes, fields or methods.
- Each action body is pasted as the body of a generated method ([ASLMethod.cs](https://raw.githubusercontent.com/LiveSplit/LiveSplit.ScriptableAutoSplit/master/src/LiveSplit.ScriptableAutoSplit/ASL/ASLMethod.cs)): `dynamic Execute(LiveSplitState timer, dynamic old, dynamic current, dynamic vars, Process game, dynamic settings)`, with `var memory = game;` and `var modules = game != null ? game.ModulesWow64Safe() : null;` declared before it. `return;` is rewritten to `return null;`.
- The `using`s are fixed by that wrapper. In 1.8.37: `System`, `System.Collections.Generic`, `System.Diagnostics`, `System.Dynamic`, `System.IO`, `System.Linq`, `System.Reflection`, `System.Text`, `System.Text.Json`, `System.Text.Json.Nodes`, `System.Threading`, `System.Windows.Forms`, `LiveSplit.ComponentUtil`, `LiveSplit.Model`, `LiveSplit.Options`. Fully qualify anything else.
- Language version: released LiveSplit (1.8.37 and earlier) compiles with the .NET Framework CodeDom compiler, so **C# 5 only**. No `$"..."`, `?.`, `nameof`, `out var`, local functions, tuples or pattern matching. LiveSplit's `master` switched to Roslyn in June 2026, but write C# 5 until that ships and runners have updated.
- Shared helpers cannot be methods. Store a lambda in `vars` with an explicit delegate cast, since `vars` is `dynamic`: `vars.isLoad = (Func<float, bool>)(y => y > 0f);`

## Sources of truth

This file is a summary. When in doubt, read the official README: <https://raw.githubusercontent.com/LiveSplit/LiveSplit.AutoSplitters/master/README.md>

APIs the README mentions without documenting live in the LiveSplit source. Read it instead of guessing signatures.

- `MemoryWatcher<T>`: <https://raw.githubusercontent.com/LiveSplit/LiveSplit/master/src/LiveSplit.Core/ComponentUtil/MemoryWatcher.cs>
- `DeepPointer`: <https://raw.githubusercontent.com/LiveSplit/LiveSplit/master/src/LiveSplit.Core/ComponentUtil/DeepPointer.cs>
- `SigScanTarget`, `SignatureScanner`: <https://raw.githubusercontent.com/LiveSplit/LiveSplit/master/src/LiveSplit.Core/ComponentUtil/SignatureScanner.cs>
- `memory.ReadValue<T>`, `ReadString`, `ReadBytes`, `game.MemoryPages()`, `ModulesWow64Safe()`: <https://raw.githubusercontent.com/LiveSplit/LiveSplit/master/src/LiveSplit.Core/ComponentUtil/ProcessExtensions.cs>
- `timer` (`LiveSplitState`): <https://raw.githubusercontent.com/LiveSplit/LiveSplit/master/src/LiveSplit.Core/Model/LiveSplitState.cs>
- `TimerModel`: <https://raw.githubusercontent.com/LiveSplit/LiveSplit/master/src/LiveSplit.Core/Model/TimerModel.cs>
- Published scripts to learn from: <https://fatalis.github.io/livesplit-asl-list/>

## State descriptors

```asl
state("PROCESS_NAME", "OPTIONAL_VERSION") {
    byte levelId : "Module.dll", 0x1234, 0x10, 0x8;
    string255 name : 0xABCD, 0x20;
}
```

- Process name has no `.exe`. LiveSplit attaches to the first running process matching any `state` block.
- Each line is a pointer path. Without a module name it starts at the main module. Offsets are integer literals and may be negative.
- Types: `sbyte byte short ushort int uint long ulong float double bool`, `string<N>`, `byte<N>`.
- Values are exposed as `current.name` and `old.name` (previous tick).
- Several `state` blocks handle emulators or game versions. Setting `version` in `init` picks the matching block, and shows in the settings GUI.
- The grammar accepts zero `state` blocks, but a script needs at least one, even when all memory is read manually. Without one LiveSplit never attaches to a process, so `init`, `update` and the timer actions never run. It may be empty.

## Actions

| Action | Runs | Return value |
| - | - | - |
| `startup` | Once when the script loads | none. Only place to call `settings.Add` |
| `shutdown` | Script unloaded or reloaded | none |
| `init` | Each time a matching process is found | none. Throwing retries `init` |
| `exit` | Attached process exits | none |
| `update` | Every tick while attached, first | `false` skips `start` through `split` for that tick |
| `start` | Every tick, only when the timer is not running (not after the run ends) | `true` starts the timer |
| `isLoading` | Every tick, while running or paused | `true` pauses Game Time |
| `gameTime` | Every tick, while running or paused | `TimeSpan` to set Game Time |
| `reset` | Every tick, while running or paused | `true` resets. Explicit `true` also skips `split` |
| `split` | Every tick, while running or paused, after `reset` | `true` splits |
| `onStart`, `onSplit`, `onReset` | On the matching timer event | none |

## Pitfalls

- Ticks run about 60 times per second. `refreshRate` changes that.
- `vars` is a dynamic bag shared across actions. Initialize every member (in `startup` or `init`) before reading it.
- `current`, `old`, `game`, `modules` and `memory` need an attached process. They are unavailable in `startup` and `exit`, and may be `null` in `shutdown`, `onStart`, `onSplit` and `onReset` (the timer can be started, split or reset with the game closed). Keep code in those actions to `vars`.
- Use `modules.First()`, not `game.MainModule` or `game.Modules`.
- The Start/Split/Reset checkboxes discard the return value but the action code still runs. `settings.StartEnabled`, `settings.SplitEnabled` and `settings.ResetEnabled` expose them. Code that drives the timer itself (for example `new TimerModel { CurrentState = timer }.Reset()`) must check them.
- Prefer the `onStart`, `onSplit` and `onReset` actions for reacting to timer events. They need no cleanup. Handlers added by hand to other `timer` events must be stored in `vars` and removed in `shutdown`, or reloading the script stacks them.
- Custom settings are booleans only. A child reads `false` whenever any ancestor is unchecked. `settings["id"]` must match a `settings.Add` id.
- `isLoading` only has an effect when the layout compares against Game Time.
- `print()` output is read with DebugView on Windows. Compile and runtime errors go to the Windows Event Log under Application.
- Never invent pointer paths or offsets. They come from the user (Cheat Engine and the like) or existing code.
