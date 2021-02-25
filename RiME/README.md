# RiME AutoSplitter

LiveSplit AutoSplitter for RiME on PC  

## Limitations

- The AutoSplitter works by watching for changes to the save file. If you make a mistake that causes the game to save an additionnal time (like reloading checkpoint), you'll have to manually undo split.
- You will still have to start and stop the timer yourself.
- No Load remover.

## Recommended splits

### Any% and No Major Skips

[Tech](https://www.speedrun.com/user/Tech) created a split template with short, generic names. The number of splits is what's important, you can rename the splits and the category to your liking. See the RiME [Resources](https://www.speedrun.com/rime/resources) page on SRC.

### Any% (without Tilt Clip)

Using the Any% template, replace `-Tilt Clip 1` by `-Underwater Caves`. Also replace the following section:

```txt
-Tilt Clip 2
-Reload
```

by something like this

```txt
-Garden
-Tree
-Sentinel Head
-Sentinel Body
-Escort 1 (hub)
-Escort 2 (elevator)
-Elevator
-Escort 3 (garden)
-Escort 4 (shades)
```

### 100%

No template yet, but the autosplitter should also work. If you make your own splits, please share!

## Shared Gold Splits

These are the splits that are identical between categories, meaning that you can sync your golds in both.

### Any% <--> No Major Skips

- Hill
- ...
- Hub
- Tree
- Hub
- Key 2
- Staircase
- Bridge
- Sun Dial
- Bridge
- Throne
- Wind
- Labyrinth
- {Denial} Spiral
- Memory
- Exit Tower
- ...
- {Anger} Spiral
- Memory
- Hallway
- *Caves*\*
- *Hub*\*
- Sentinel
- Shades
- *Garden*\*
- *Tree*\*
- *Sentinel Head*\*
- *Sentinel Body*\*
- *Escort 1 (hub)*\*
- *Escort 2 (elevator)*\*
- *Elevator*\*
- *Escort 3 (garden)*\*
- *Escort 4 (shades)*\*
- *Orb*\*
- Race
- {Bargaining} Spiral
- Memory
- Ride
- Shades Skip
- Gate
- Hub
- Statue 1
- Statue 2
- Statue 3
- Statue 4
- Activate
- Reload
- Chains
- {Depression} Spiral
- Memory
- {Acceptance} Let Go

*If not doing Tilt Clip
