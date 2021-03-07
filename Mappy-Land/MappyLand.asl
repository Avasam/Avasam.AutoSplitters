state("fceux", "2.2.3")	{
	// base address = 0x3B1388

	byte stage : 0x3B1388, 0x60A;
	byte world : 0x3B1388, 0x56;
	byte playing: 0x3B1388, 0x15;
	// 0557, 056B and 057F are always sync and seems to be the bytes for the currently playing music
	byte music : 0x3B1388, 0x56B;
	byte celebration_scene: 0x3B1388, 0x062A;
}

state("nestopia") {
	// base address = 0x1b2bcc, 0, 8, 0xc, 0xc, +0x68;

	byte stage : "nestopia.exe", 0x1b2bcc, 0, 8, 0xc, 0xc, 0x60A;
	byte world : "nestopia.exe", 0x1b2bcc, 0, 8, 0xc, 0xc, 0x56;
	byte playing: "nestopia.exe", 0x1b2bcc, 0, 8, 0xc, 0xc, 0x15;
	// 0557, 056B and 057F are always sync and seems to be the bytes for the currently playing music
	byte music : "nestopia.exe", 0x1b2bcc, 0, 8, 0xc, 0xc, 0x56B;
	byte celebration_scene: "nestopia.exe", 0x1b2bcc, 0, 8, 0xc, 0xc, 0x062A;
}

state("mesen") {
	// base address = 0x4311838, 0x118, 0xB8, 0x90, 0x1D8, 0x08,
	 
	byte stage : "MesenCore.dll", 0x4311838, 0x118, 0xB8, 0x90, 0x1D8, 0x08, 0x60A;
	byte world : "MesenCore.dll", 0x4311838, 0x118, 0xB8, 0x90, 0x1D8, 0x08, 0x56;
	byte playing: "MesenCore.dll", 0x4311838, 0x118, 0xB8, 0x90, 0x1D8, 0x08, 0x15;
	// 0557, 056B and 057F are always sync and seems to be the bytes for the currently playing music
	byte music : "MesenCore.dll", 0x4311838, 0x118, 0xB8, 0x90, 0x1D8, 0x08, 0x56B;
	byte celebration_scene: "MesenCore.dll", 0x4311838, 0x118, 0xB8, 0x90, 0x1D8, 0x08, 0x062A;
}


startup {
	settings.Add("SplitOnStageEnd", false, "Split on stage end instead of start (experimental)");
	settings.SetToolTip("SplitOnStageEnd", "Split when Mappy reaches the end of the stage instead of when the next stage starts. This is still experimental and may not always work.");
}

split {
	/*
	celebration_scene:
		148: Game Over
		149: Playing & 1-8 Bonus screen success
		150: 2-8, 3-8 & 4-8 bonus screen Success
		151: (Quickly goes through 150) Bonus screen failure
		152: Bonus Screen Failure (persistant)

	music:
		2: Speed up
		3: Playing
		4: Playing in bonus screen
		5: Death & 4-8 Bonus screen success
		6: Level beaten
	*/

	// Split on stage ending and end split
	if (settings["SplitOnStageEnd"] || (current.world == 3 && current.stage == 7)) {
		// X-8 Splits
		if (current.stage == 7) {
		// 1-8: 149 & 5
		
			return((current.celebration_scene == 150 || current.celebration_scene == 149)
			 && ((current.music == 5 || current.music == 6) && old.music == 4));
		}
		// Every other level
		else {
			return(current.music > old.music && current.music == 6);
		}
	// Split on stage starting except end split	
	} else {
		return(current.stage != old.stage);
	}
}

start {
	return(old.playing == 255 && current.playing == 0
		&& current.world == 0 && current.stage == 0
		&& current.music != 0);
}

reset {
	return(old.playing == 255 && current.playing == 0
		&& current.world == 0 && current.stage == 0);
}
