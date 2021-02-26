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
}
