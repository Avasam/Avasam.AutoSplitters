state("RiME") {
	// Some camera related stuff, maybe?
	byte cameraState: "RiME.exe", 0x02E33FC0, 0x10, 0xC8, 0x70, 0x70, 0x60, 0x7C;
	// This global counter refreshes with in-gameframerate. Speed of 1 unit per second.
	// Stops refreshing while pauses menu is open. (will catch up to it's true value immediatly after)
	// double globalCounter: "RiME.exe", 0x2E3B470;
}

startup { // When the script loads
	print("============================= SCRIPT STARTUP =============================");
	settings.Add("debugSounds", false, "Play debug sounds");

	vars.readyToStart = false;
	
	const string BASE_LOCATION = "https://raw.githubusercontent.com/Avasam/Avasam.AutoSplitters/main/RiME/";
	// vars.loadStartPlayer = new System.Media.SoundPlayer();
	// vars.loadStartPlayer.SoundLocation = BASE_LOCATION + "LoadStart.wav";
	vars.splitPlayer = new System.Media.SoundPlayer();
	vars.splitPlayer.SoundLocation = BASE_LOCATION + "Split.wav";
	vars.timeStartPlayer = new System.Media.SoundPlayer();
	vars.timeStartPlayer.SoundLocation = BASE_LOCATION + "TimeStart.wav";
}

shutdown { // When the script unloads
}

update {
	if (old.cameraState != current.cameraState) print("Camera state: " + current.cameraState.ToString());
}

start {
	if (old.cameraState == 2 && current.cameraState == 1) vars.readyToStart = true;
	if (old.cameraState == 1 && current.cameraState == 0 && vars.readyToStart) {
		if (settings["debugSounds"]) vars.timeStartPlayer.Play();
		return !(vars.readyToStart = false);
	}
}

split { // Splits upon returning true if reset isn't explicitly returning true
	if (false) // Some split condition
		print("Splitting");
		if (settings["debugSounds"]) vars.splitPlayer.Play();
		return true;
	}
}
