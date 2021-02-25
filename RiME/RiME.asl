state("RiME") {
	int state : "RiME.exe", 0x2E105C0, 0x10, 0x0, 0x30, 0xA0, 0x70, 0xC;
}

startup { // When the script loads
	print("============================= SCRIPT STARTUP =============================");
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
}

shutdown { // When the script unloads
	timer.OnReset -= vars.OnReset;
	timer.OnStart -= vars.OnStart;
	vars.fileWatcher.Dispose();
}

split { // Splits upon returning true if reset isn't explicitly returning true
	if (vars.justSaved) {
		print("Splitting");
		vars.fileWatcher.EnableRaisingEvents = true;
		vars.justSaved = false;
		return true;
	};
}

isLoading {
	return current.state == 2;
}
