# RiME-AutoSplitter

LiveSplit AutoSplitter for RiME on PC  

## Limitations

- The AutoSplitter works by watching for changes to the save file. If you make a mistake that causes the game to save an additionnal time (like reloading checkpoint), you'll have to manually undo split.
- You will still have to start and stop the timer yourself.

## Recommended splits

[Tech](https://www.speedrun.com/user/Tech) created a split template with short, generic names. The number of splits is what's important, you can rename the splits and the category to your liking.

### Any%

See the RiME Resources page on SRC: https://www.speedrun.com/rime/resources

### Any% (without Tilt Clip)

Using the Any% template, replace `-Tilt Clip 1` by `-Underwater cave`. Also replace the following section:

```txt
-Tilt Clip 2
-Reload
```

by something like this

```txt
-Garden
-Tree
-Sentinel Head
-Escort 1 (light)
-Escort 2 (elevator)
-Elevator
-Escort 3 (garden)
-Escort 4 (shades)
```

### No Major Skips and 100%

No template yet, but the autosplitter should also work. If you make your own splits, please share!
