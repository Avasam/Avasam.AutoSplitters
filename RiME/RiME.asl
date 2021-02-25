// Thanks Ero for the help and findin load-related values.
state("RiME") {
	// Some camera related stuff, maybe?
	byte cameraState: "RiME.exe", 0x02E33FC0, 0x10, 0xC8, 0x70, 0x70, 0x60, 0x7C;
	// int loadState: "RiME.exe", 0x02E11608, 0xF8, 0xA0, 0x160, 0xB8, 0xE28;
	// This global counter refreshes with in-gameframerate. Speed of 1 unit per second.
	// Stops refreshing while pauses menu is open. (will catch up to it's true value immediatly after)
	double globalCounter: "RiME.exe", 0x2E3B470;
	int state : "RiME.exe", 0x2E105C0, 0x10, 0x0, 0x30, 0xA0, 0x70, 0xC;
}

startup { // When the script loads
	print("============================= SCRIPT STARTUP =============================");
	settings.Add("skipSplitInMenu", false, "Prevent splits while the pause menu is open");
	settings.SetToolTip("skipSplitInMenu", "This will prevent \"Reload Last Checkpoint\" splits. Including those from pausing immediately after grabbing a collectible.");
	settings.Add("debugSounds", false, "Play debug sounds");

	vars.readyToStart = false;
	vars.isLoading = false;
	vars.lastGlobalCounterRefresh = DateTime.Now.Ticks;
	vars.justSaved = false;
	var lastWriteTime = DateTime.Now.Ticks;

	System.IO.FileSystemEventHandler OnGameSave = (s, e) => {
		print("Write to data.sav detected!");
		// Ignore event within 3s of each other
		var newUpdateTime = DateTime.Now.Ticks;
		if (newUpdateTime - lastWriteTime > 30000000) {
			lastWriteTime = newUpdateTime;
			// Helps prevent duplicate events
			vars.fileWatcher.EnableRaisingEvents = false;

			// Allow splitting in the next split() loop
			vars.justSaved = true;
		}
	};

	// Create a new FileSystemWatcher and set its properties.
	vars.fileWatcher = new FileSystemWatcher();
	
	// Watch for changes in LastWrite.
	vars.fileWatcher.NotifyFilter = NotifyFilters.LastWrite;

	// Only watch the save file.
	vars.fileWatcher.Path = Environment.ExpandEnvironmentVariables(@"%LOCALAPPDATA%\SirenGame\Saved\SaveGames");
	vars.fileWatcher.Filter = "data.sav";

	// Add event handlers.
	vars.fileWatcher.Changed += OnGameSave;

	// Stop watching when timer isn't running
	vars.OnReset = (LiveSplit.Model.Input.EventHandlerT<TimerPhase>)((s, e) =>
		vars.fileWatcher.EnableRaisingEvents = false);
	timer.OnReset += vars.OnReset;

	// Start watching when the timer starts
	vars.OnStart = (System.EventHandler)((s, e) => {
		vars.fileWatcher.EnableRaisingEvents = true;
		vars.justSaved = false;
	});
	timer.OnStart += vars.OnStart;

	// Ensures splitting still works if refreshing this script with an active timer.
	if (timer.CurrentPhase == TimerPhase.Running) vars.OnStart(null, null);
	const string BASE_LOCATION = "https://raw.githubusercontent.com/Avasam/Avasam.AutoSplitters/main/RiME/RiME.asl/";
	// vars.loadStartPlayer = new System.Media.SoundPlayer();
	// vars.loadStartPlayer.SoundLocation = BASE_LOCATION + "LoadStart.wav";
	vars.splitPlayer = new System.Media.SoundPlayer();
	vars.splitPlayer.SoundLocation = BASE_LOCATION + "Split.wav";
	vars.timeStartPlayer = new System.Media.SoundPlayer();
	vars.timeStartPlayer.SoundLocation = BASE_LOCATION + "TimeStart.wav";
}

shutdown { // When the script unloads
	timer.OnReset -= vars.OnReset;
	timer.OnStart -= vars.OnStart;
	vars.fileWatcher.Dispose();
}

update {
	if (settings["skipSplitInMenu"]) {
		const double LEEWAY = 10000000; // 1FPS
		var newUpdateTime = DateTime.Now.Ticks;
		if (old.globalCounter < current.globalCounter) {
			if (newUpdateTime - vars.lastGlobalCounterRefresh > LEEWAY) print("Menu closed");
			vars.lastGlobalCounterRefresh = newUpdateTime;
		}
	}

	if (old.cameraState != current.cameraState) print("Camera state: " + current.cameraState.ToString());
	// if (old.loadState != current.loadState) print("Load state: " + current.loadState.ToString());
}

start {
	if (old.cameraState == 2 && current.cameraState == 1) vars.readyToStart = true;
	if (old.cameraState == 1 && current.cameraState == 0 && vars.readyToStart) {
		if (settings["debugSounds"]) vars.timeStartPlayer.Play();
		return !(vars.readyToStart = false);
	}
}

// isLoading {
// 	if (old.loadState == 2 && current.loadState == 1) {
// 		if (settings["debugSounds"]) vars.loadStartPlayer.Play();
// 		vars.isLoading = true;
// 	}
// 	if (old.cameraState != 0 && current.cameraState == 0 && vars.isLoading && current.loadState != 1) {
// 		if (settings["debugSounds"]) vars.timeStartPlayer.Play();
// 		vars.isLoading = false;
// 	}
// 	return vars.isLoading;
// }

split { // Splits upon returning true if reset isn't explicitly returning true
	if (!vars.justSaved) return;
	vars.fileWatcher.EnableRaisingEvents = true;
	vars.justSaved = false;

	const double LEEWAY = 10000000; // 1FPS
	if (settings["skipSplitInMenu"]) {
		print("Last Global Counter Refresh: " +
			((DateTime.Now.Ticks - vars.lastGlobalCounterRefresh) / LEEWAY).ToString() + "s");
	}
	
	// If the global counter stops counting for a second
	// This means a split can still happen 1s immediatly after openning the menu
	if (settings["skipSplitInMenu"] && DateTime.Now.Ticks - vars.lastGlobalCounterRefresh > LEEWAY) {
		print("Skipped split due to open menu");
	} else {
		print("Splitting");
		if (settings["debugSounds"]) vars.splitPlayer.Play();
		return true;
	}
}

isLoading {
	return false;
	return current.state == 2;
}
