// Thanks Ero for the help and parsing teh save file.
state("RiME") {
	// Some camera related stuff, maybe?
	byte cameraState: "RiME.exe", 0x02E33FC0, 0x10, 0xC8, 0x70, 0x70, 0x60, 0x7C;
	// This global counter refreshes with in-gameframerate. Speed of 1 unit per second.
	// Stops refreshing while pauses menu is open. (will catch up to it's true value immediatly after)
	// double globalCounter: "RiME.exe", 0x2E3B470;
}

startup { // When the script loads
	print("============================= SCRIPT STARTUP =============================");
	vars.readyToStart = false;
	vars.justSaved = false;
	var lastWriteTime = DateTime.Now.Ticks;

	#region Building Settings
	settings.Add("startDelay", "Delay start timer by 6.1s (don't use this with Start Timer offset)");
	#endregion

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
}

shutdown { // When the script unloads
	timer.OnReset -= vars.OnReset;
	timer.OnStart -= vars.OnStart;
	vars.fileWatcher.Dispose();
}

/*
update {
	if (old.cameraState != current.cameraState) print("Camera state: " + current.cameraState.ToString());
}
*/

start {
	// Start now or in 6.1s depending on user settings
	if (current.cameraState == 0 && vars.readyToStart && vars.stopWatch.ElapsedMilliseconds >= 6100) {
		vars.stopWatch.Reset();
		vars.readyToStart = false;
		return true;
	}
	if (old.cameraState == 1 && current.cameraState == 0 && vars.readyToStart) {
		if (!settings["startDelay"]) {
			vars.readyToStart = false;
			return true;
		} else {
			vars.stopWatch.Start();
			return false;
		}
	}
	// The value should go 2 -> 1 -> 0. We need to make sure it followed the proper sequence.
	if (old.cameraState == 2 && current.cameraState == 1) vars.readyToStart = true;
}

split { // Splits upon returning true if reset isn't explicitly returning true
	if (!vars.justSaved) return;
	vars.fileWatcher.EnableRaisingEvents = true;
	vars.justSaved = false;

	if (false) // Some split condition
		print("Splitting");
		return true;
	}
}
