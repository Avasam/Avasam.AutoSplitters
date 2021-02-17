// Big thanks to DevilSquirrel for helping me understand how some of this works
state("PonyIsland") { }

startup { // When the script loads
	print("============================= SCRIPT STARTUP =============================");
	settings.Add("ActGrouping", true, "Split at the start of Acts");
	settings.Add("SplitOnAct1", true, "Act 1 /!\\ Leave OFF when running IL of Act 1. ON when running IL of Intro", "ActGrouping");
	settings.Add("SplitOnAct1Boss", true, "Act 1 Boss (Azazel)", "ActGrouping");
	settings.Add("SplitOnAct2", true, "Act 2", "ActGrouping");
	settings.Add("SplitOnAct2WorldMap", true, "Act 2 World Map (Pony Adventure)", "ActGrouping");
	settings.Add("SplitOnAct2Boss", true, "Act 2 Boss (Beelzebub)", "ActGrouping");
	settings.Add("SplitOnAct3", true, "Act 3 (Louey)", "ActGrouping");
	settings.Add("SplitOnAct3Desktop", true, "Act 3 Desktop (Minigames)", "ActGrouping");
	settings.Add("SplitOnAct3Boss", true, "Act 3 Boss (Asmodeus)", "ActGrouping");
	settings.Add("SplitOnFinale", true, "Finale (System Dump)", "ActGrouping");
	
	settings.Add("SplitOnAutoscroller", false, "Split at the start of the autoscroller escape sequence");
	settings.Add("SplitOnFadeOut", false, "Split when the game ends");
	
	vars.levelScanTarget = new SigScanTarget(0,
		"0? 00 00 00", // LevelId
		"6C 65 76 65 6C", // 'level' in ASCII
		"31 00", // LevelId - 1 in ASCII
		new String('?', 245*2), // Junk
		"6A 6F 79 73 74 69 63 6B 20 37" // 'joystick 7' in ASCII
		// The rest are strings for the Input Manager, it'd be overkill to look for more.
    );

	vars.finaleScanTarget = new SigScanTarget(0,
		"?? ?? ?? ?? 00 00 00 00", // FinaleScreen
		new String('?', 92*2), // Bunch of pointers we don't care about
		"00 00 00 00", // Progress flags
		"66 66 9E 41", // progressBarMaxLength (19.8f)
		new String('0', 16*2), // More progress flags
		"33 73 A7 43", // TRACK_LENGTH_SECONDS (334.9f)
		"FF FF FF FF", // soulsLost counter
		"00 00 00 00", // normalizedProgress
		new String('0', 16*2), // I have no idea
		"?? ?? ?? ?? 00 00 00 00", // Still no idea
		"BA 12" // No really, I have no idea, but this becomes 00 00 when the game the ends
    );

	Func<int, bool> checkForSplitFunc = (int levelId) =>
		// Only split when changing act
		vars.LevelId.Old != vars.LevelId.Current &&
		// Is the current Act the one we want?
		vars.LevelId.Current == levelId &&
		// Don't split when pressing Continue
		vars.LevelId.Old != 2 &&
		// Don't split when choosing an Act
		(vars.LevelId.Old != 3 || levelId == 4);
	vars.checkForSplit = checkForSplitFunc;
}

init { // When the game is found
	print("============================= INITIALISATION =============================");
	vars.soulsLost = null;
	vars.done = null;

	var ptr = IntPtr.Zero;
	foreach (var page in game.MemoryPages(true)) {
		var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
		ptr = scanner.Scan(vars.levelScanTarget);
		
		if (ptr != IntPtr.Zero) break;
	}
	// Waiting for the game to have booted up.
	if (ptr == IntPtr.Zero) {
		Thread.Sleep(1000); // Wait 1s between rechecking for the proper game
    throw new Exception("Waiting for the game to finish booting up. Trying again in 1 second."); // This escapes the `init` block, making it retry
	};
	
	vars.LevelId = new MemoryWatcher<int>(ptr);
}

// Main methods
update { // Returning false blocks everything but split
	vars.LevelId.Update(game);

	if (vars.LevelId.Current == 13 &&
		(settings["SplitOnAutoscroller"] || settings["SplitOnFadeOut"])) {
		if (vars.done == null || vars.soulsLost == null) {
			var ptr = IntPtr.Zero;
			foreach (var page in game.MemoryPages(true)) {
				var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
				ptr = scanner.Scan(vars.finaleScanTarget);
				
				if (ptr != IntPtr.Zero) break;
			}
			
			vars.soulsLost = new MemoryWatcher<int>(ptr+0x80);
			vars.done = new MemoryWatcher<ushort>(ptr+0xA0);
		}
		else {
			vars.soulsLost.Update(game);
		}
	}
	
	if (vars.done != null) {
		vars.done.Update(game);
	}
}

// Only runs when the timer is stopped
start { // Starts the timer upon returning true
	return vars.LevelId.Old == 2 && vars.LevelId.Current == 3;
}

// Only runs when the timer is running
reset { // Resets the timer upon returning true
	// Reset when selecting an act or New Game
	return vars.LevelId.Old == 2 && vars.LevelId.Current == 3;
}

split { // Splits upon returning true if reset isn't explicitly returning true
	if (vars.checkForSplit(4)  && settings["SplitOnAct1"]) return true;
	if (vars.checkForSplit(5)  && settings["SplitOnAct1Boss"]) return true;
	if (vars.checkForSplit(6)  && settings["SplitOnAct2"]) return true;
	if (vars.checkForSplit(7)  && settings["SplitOnAct2WorldMap"]) return true;
	if (vars.checkForSplit(8)  && settings["SplitOnAct2Boss"]) return true;
	if (vars.checkForSplit(9)  && settings["SplitOnAct3"]) return true;
	if (vars.checkForSplit(11) && settings["SplitOnAct3Desktop"]) return true;
	if (vars.checkForSplit(12) && settings["SplitOnAct3Boss"]) return true;
	if (vars.checkForSplit(13) && settings["SplitOnFinale"]) return true;
	if (vars.soulsLost != null && vars.soulsLost.Old == -1 &&
		vars.soulsLost.Current == 0 && settings["SplitOnAutoscroller"]) return true;
	if (vars.done != null && vars.done.Current == 0 && settings["SplitOnFadeOut"]) return true;
}

isLoading {
	
}
