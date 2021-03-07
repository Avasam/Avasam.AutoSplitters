state("WitchWay") {
	// Note: Because the game is actually ran from a different temporary executable,
	// we have to use MemoryWatchers or LiveSplit will get confused when player closes and reopens the game.
	// Thanks FromDarkHell for the tip.
}

startup { // When the script loads
	print("============================= SCRIPT STARTUP =============================");
	// At 60 FPS, it takes 51 frames between "Select" being visibly pressed on screen and when the autosplitter starts.
	// Which is also the first frame of complete darkness.
	// The Select button being pressed is consistent with GamePad input viewer and 4 frames before the sound starts.
	settings.Add("reminder", false, "Reminder: Start the timer at 0.85 ! (This option does nothing)");
	settings.Add("isInTransition", false, "Room transition");
	settings.Add("hasWand", true, "Wand obtained");

	settings.Add("Bucket", true);
	// 0-1 are always unlocked. 6-9 are never unlocked. 5 exit and unlocked with 4.
	settings.Add("bucketUnlocked", true, "Floor -3 unlocked", "Bucket");
	settings.Add("bucketStopUnlocked_2", true, "Floor -2¾ unlocked", "Bucket");
	settings.Add("bucketStopUnlocked_3", true, "Floor -2 unlocked", "Bucket");
	settings.Add("bucketStopUnlocked_4", true, "Floor -1 unlocked", "Bucket");
	settings.Add("bucketExitWell", true, "Exit the well");

	settings.Add("Artefacts", true);
	settings.Add("hasSkull", true, "Skull obtained", "Artefacts");
	settings.Add("hasWateringCan", true, "Watering Can obtained", "Artefacts");
	settings.Add("hasBook", true, "Book obtained", "Artefacts");

	settings.Add("Keys", true);
	settings.Add("hasRedKey", true, "Red Key obtained", "Keys");
	settings.Add("hasGreen", true, "Green Key obtained", "Keys");
	settings.Add("hasBlueKey", true, "Blue Key obtained", "Keys");

	// settings.Add("Doors", false);
	// settings.Add("oKeyDoor_REDDOOR_Locked", true, "Red Door unlocked", "Doors");
	// settings.Add("oKeyDoor_GREENDOOR_Locked", true, "Green Door unlocked", "Doors");
	// settings.Add("oKeyDoor_BLUEDOOR_Locked", true, "Blue Door unlocked", "Doors");

	settings.Add("bunnyCount", true, "Bunny caught");
	settings.Add("secretCount", false, "Eye opened");

	vars.bucketStopUnlocked_2 = false;
	vars.bucketStopUnlocked_3 = false;
	vars.bucketStopUnlocked_4 = false;
	// A generic Stopwatch to wait a certain amount of time in some circumstances.
	vars.stopWatch = new Stopwatch();
	vars.timerModel = new TimerModel{CurrentState = timer};
	
	vars.OnStart = (System.EventHandler)((s, e) => {
		// Cleanup
		vars.stopWatch.Reset();
	});
	timer.OnStart += vars.OnStart;
}

init { // When the game is found
	print("============================= INITIALISATION =============================");
	// The game module itself
	vars.game = Process.GetProcessesByName("WitchWay").FirstOrDefault(process =>
		process.MainModule.FileName.Contains(System.IO.Path.GetTempPath())); 

	var g = "WitchWay.exe";
	if (vars.game == null) {
		Thread.Sleep(1000); // Wait 1s between rechecking for the proper game
		throw new Exception(g + " process from temporary folder not found. Trying again in 1 second."); // This escapes the `init` block, making it retry
	}

	vars.watchers = new ExpandoObject();
	vars.watchers.isInGame = new MemoryWatcher<double>(new DeepPointer(g, 0x16B8B00));
	vars.watchers.didIntro = new MemoryWatcher<double>(new DeepPointer(g, 0x16BE820, 0x34, 0x10, 0x154, 0x0));
	vars.watchers.isInTransition = new MemoryWatcher<double>(new DeepPointer(g, 0x16BE820, 0x34, 0x10, 0xC4, 0x0));

	vars.watchers.hasWand = new MemoryWatcher<double>(new DeepPointer(g, 0x16BE820, 0x34, 0x10, 0xE8, 0x0));

	vars.watchers.hasSkull = new MemoryWatcher<double>(new DeepPointer(g, 0x16BE820, 0x34, 0x10, 0x118, 0x0));
	vars.watchers.hasWateringCan = new MemoryWatcher<double>(new DeepPointer(g, 0x16BE820, 0x34, 0x10, 0x130, 0x0));
	vars.watchers.hasBook = new MemoryWatcher<double>(new DeepPointer(g, 0x16BE820, 0x34, 0x10, 0x124, 0x0));

	vars.watchers.hasRedKey = new MemoryWatcher<double>(new DeepPointer(g, 0x16BE820, 0x34, 0x10, 0xF4, 0x0));
	vars.watchers.hasGreen = new MemoryWatcher<double>(new DeepPointer(g, 0x16BE820, 0x34, 0x10, 0x10C, 0x0));
	vars.watchers.hasBlueKey = new MemoryWatcher<double>(new DeepPointer(g, 0x16BE820, 0x34, 0x10, 0x100, 0x0));

	// vars.watchers.oKeyDoor_REDDOOR_Locked = new MemoryWatcher<double>(new DeepPointer(g, 0x1692124, 0x68, 0xC, 0x34, 0x10, 0xE8, 0x0));
	// // vars.watchers.oKeyDoor_GREENDOOR_Animation = new MemoryWatcher<double>(new DeepPointer(g, 0x16B87F0));
	// vars.watchers.oKeyDoor_GREENDOOR_Locked = new MemoryWatcher<double>(new DeepPointer(g, 0x1692124, 0x218, 0xC, 0x34, 0x10, 0xE8, 0x0));
	// // vars.watchers.oKeyDoor_BLUEDOOR_Locked = new MemoryWatcher<double>(new DeepPointer(g, 0x1692124, 0x68, 0xC, 0x14C, 0x34, 0x10, 0xE8, 0x0));
	// vars.watchers.oKeyDoor_BLUEDOOR_Locked = new MemoryWatcher<double>(new DeepPointer(g, 0x1692124, 0xC8, 0xC, 0x34, 0x10, 0xE8, 0x0));

	// Known issue: when the wand orb hits a wall/floor/ceiling. These two pointers becomes wrong for a second.
	vars.watchers.bucketCurrentStop = new MemoryWatcher<double>(new DeepPointer(g, 0x16E079C, 0x0, 0x14C, 0x34, 0x10, 0x424, 0x0));
	vars.watchers.bucketNextStop = new MemoryWatcher<double>(new DeepPointer(g, 0x16E079C, 0x0, 0x14C, 0x34, 0x10, 0x388, 0x0));

	vars.watchers.bunnyCount = new MemoryWatcher<double>(new DeepPointer(g, 0x16BE820, 0x34, 0x10, 0x13C, 0x0));
	vars.watchers.secretCount = new MemoryWatcher<double>(new DeepPointer(g, 0x16BE820, 0x34, 0x10, 0x148, 0x0));

	// Allows us to delay when we start tracking for start timer
	vars.stopWatch.Restart();
}

shutdown { // When the script unloads
	timer.OnStart -= vars.OnStart;
}

/* Main methods */
update { // Returning false blocks everything but split
	var sBuilder = new StringBuilder();

	foreach (var watcher in vars.watchers) {
		watcher.Value.Update(vars.game);

		if (watcher.Value.Old != watcher.Value.Current) {
			sBuilder.AppendLine(watcher.Key + ": " + watcher.Value.Current);
		}
	}

	if (sBuilder.Length > 0) print(sBuilder.ToString());
}

/* Only runs when the timer is stopped */
start { // Starts the timer upon returning true
	// Wait for at least 309 frames since game started before starting the timer.
	// This is because the isInGame double will cycle twice between 0-1 on bootup.
	return vars.stopWatch.ElapsedMilliseconds >= 5150 &&
		vars.watchers.didIntro.Current == 0 &&
		vars.watchers.isInGame.Current > 0;
}

/* Only runs when the timer is running */
reset { // Resets the timer upon returning true
	return vars.watchers.didIntro.Old == 1 && vars.watchers.didIntro.Current == 0;
}

split { // Splits upon returning true if reset isn't explicitly returning true
	if (settings["isInTransition"] && vars.watchers.isInTransition.Old == 0 && vars.watchers.isInTransition.Current == 1) return true;
	if (settings["hasWand"] && vars.watchers.hasWand.Old == 0 && vars.watchers.hasWand.Current == 1) return true;

	if (settings["hasSkull"] && vars.watchers.hasSkull.Old == 0 && vars.watchers.hasSkull.Current == 1) return true;
	if (settings["hasWateringCan"] && vars.watchers.hasWateringCan.Old == 0 && vars.watchers.hasWateringCan.Current == 1) return true;
	if (settings["hasBook"] && vars.watchers.hasBook.Old == 0 && vars.watchers.hasBook.Current == 1) return true;

	if (settings["hasRedKey"] && vars.watchers.hasRedKey.Old == 0 && vars.watchers.hasRedKey.Current == 1) return true;
	if (settings["hasGreen"] && vars.watchers.hasGreen.Old == 0 && vars.watchers.hasGreen.Current == 1) return true;
	if (settings["hasBlueKey"] && vars.watchers.hasBlueKey.Old == 0 && vars.watchers.hasBlueKey.Current == 1) return true;

	// if (settings["oKeyDoor_REDDOOR_Locked"] && vars.watchers.oKeyDoor.Old_REDDOOR_Locked == 1 && vars.watchers.oKeyDoor.Current_REDDOOR_Locked == 0) return true;
	// if (settings["oKeyDoor_GREENDOOR_Locked"] && vars.watchers.oKeyDoor.Old_GREENDOOR_Locked == 1 && vars.watchers.oKeyDoor.Current_GREENDOOR_Locked == 0) return true;
	// if (settings["oKeyDoor_BLUEDOOR_Locked"] && vars.watchers.oKeyDoor.Old_BLUEDOOR_Locked == 1 && vars.watchers.oKeyDoor.Current_BLUEDOOR_Locked == 0) return true;

	// Additionnal checks as the pointerpath for the bucket can sometimes point elsewhere
	if (settings["bucketUnlocked"] &&
		vars.watchers.bucketNextStop.Old == 10 && vars.watchers.bucketNextStop.Current == 0 &&
		vars.watchers.bucketCurrentStop.Old == 10 && vars.watchers.bucketCurrentStop.Current == 10) return true;
	// When First calling the bucket to a certain floor
	// To floor -2¾ (#2) from above (#3 or #4)
	if (settings["bucketStopUnlocked_2"] && !vars.bucketStopUnlocked_2 &&
		vars.watchers.bucketNextStop.Old >= 3 && vars.watchers.bucketNextStop.Current == 2 &&
		vars.watchers.bucketCurrentStop.Old >= 3 && vars.watchers.bucketCurrentStop.Current >= 3) return vars.bucketStopUnlocked_2 = true;
	// To floor -2 (#3) from -3 (#1)
	if (settings["bucketStopUnlocked_3"] && !vars.bucketStopUnlocked_3 &&
		vars.watchers.bucketNextStop.Old == 1 && vars.watchers.bucketNextStop.Current == 3 &&
		vars.watchers.bucketCurrentStop.Old == 1 && vars.watchers.bucketCurrentStop.Current == 1) return vars.bucketStopUnlocked_3 = true;
	// To floor -1 (#4) from -2 (#3)
	if (settings["bucketStopUnlocked_4"] && !vars.bucketStopUnlocked_4 &&
		vars.watchers.bucketNextStop.Old == 3 && vars.watchers.bucketNextStop.Current == 4 &&
		vars.watchers.bucketCurrentStop.Old == 3 && vars.watchers.bucketCurrentStop.Current == 3) return vars.bucketStopUnlocked_4 = true;
	// To exit (#) from -1 (#4)
	if (settings["bucketExitWell"]) {
		// Screen turns to full white 168 frames after sending the elevator up
		if (vars.stopWatch.ElapsedMilliseconds >= 2800) {
			vars.stopWatch.Reset();
			return true;
		} else if (
			vars.watchers.bucketNextStop.Old == 4 && vars.watchers.bucketNextStop.Current == 5 &&
			vars.watchers.bucketCurrentStop.Old == 4 && vars.watchers.bucketCurrentStop.Current == 4) {
				vars.stopWatch.Start();
				return false;
		}
	}

	if (settings["bunnyCount"] && vars.watchers.bunnyCount.Old < vars.watchers.bunnyCount.Current) return true;
	if (settings["secretCount"] && vars.watchers.secretCount.Old < vars.watchers.secretCount.Current) return true;
}
