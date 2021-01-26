state("WitchWay") {
	double isInGame: 0x16B8B00;
	double didIntro: 0x16BE820, 0x34, 0x10, 0x154, 0x0;
	double isInTransition: 0x16BE820, 0x34, 0x10, 0xC4, 0x0;

	double hasWand: 0x16BE820, 0x34, 0x10, 0xE8, 0x0;

	double hasSkull: 0x16BE820, 0x34, 0x10, 0x118, 0x0;
	double hasWateringCan: 0x16BE820, 0x34, 0x10, 0x130, 0x0;
	double hasBook: 0x16BE820, 0x34, 0x10, 0x124, 0x0;

	double hasRedKey: 0x16BE820, 0x34, 0x10, 0xF4, 0x0;
	double hasGreen: 0x16BE820, 0x34, 0x10, 0x10C, 0x0;
	double hasBlueKey: 0x16BE820, 0x34, 0x10, 0x100, 0x0;

	// double oKeyDoor_REDDOOR_Locked: 0x1692124, 0x68, 0xC, 0x34, 0x10, 0xE8, 0x0;
	// // double oKeyDoor_GREENDOOR_Animation: 0x16B87F0;
	// double oKeyDoor_GREENDOOR_Locked: 0x1692124, 0x218, 0xC, 0x34, 0x10, 0xE8, 0x0;
	// // double oKeyDoor_BLUEDOOR_Locked: 0x1692124, 0x68, 0xC, 0x14C, 0x34, 0x10, 0xE8, 0x0;
	// double oKeyDoor_BLUEDOOR_Locked: 0x1692124, 0xC8, 0xC, 0x34, 0x10, 0xE8, 0x0;

	// Known issue: when the wand orb hits a wall/floor/ceiling. These two pointers becomes wrong for a second.
	double bucketCurrentStop: 0x16E079C, 0x0, 0x14C, 0x34, 0x10, 0x424, 0x0;
	double bucketNextStop: 0x16E079C, 0x0, 0x14C, 0x34, 0x10, 0x388, 0x0;

	double bunnyCount: 0x16BE820, 0x34, 0x10, 0x13C, 0x0;
	double secretCount: 0x16BE820, 0x34, 0x10, 0x148, 0x0;
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
}

/* Main methods */
update { // Returning false blocks everything but split
	var debugString = "";
	if (old.didIntro != current.didIntro) debugString += "didIntro: " + current.didIntro.ToString() + Environment.NewLine;
	if (old.isInGame != current.isInGame) debugString += "isInGame: " + current.isInGame.ToString() + Environment.NewLine;
	if (old.bucketCurrentStop != current.bucketCurrentStop) debugString += "bucketCurrentStop: " + current.bucketCurrentStop.ToString() + Environment.NewLine;
	if (old.bucketNextStop != current.bucketNextStop) debugString += "bucketNextStop: " + current.bucketNextStop.ToString() + Environment.NewLine;
	// if (old.oKeyDoor_REDDOOR_Locked != current.oKeyDoor_REDDOOR_Locked) debugString += "oKeyDoor_REDDOOR_Locked: " + current.oKeyDoor_REDDOOR_Locked.ToString() + Environment.NewLine;
	// if (old.oKeyDoor_GREENDOOR_Locked != current.oKeyDoor_GREENDOOR_Locked) debugString += "oKeyDoor_GREENDOOR_Locked: " + current.oKeyDoor_GREENDOOR_Locked.ToString() + Environment.NewLine;
	// if (old.oKeyDoor_BLUEDOOR_Locked != current.oKeyDoor_BLUEDOOR_Locked) debugString += "oKeyDoor_BLUEDOOR_Locked: " + current.oKeyDoor_BLUEDOOR_Locked.ToString() + Environment.NewLine;
	if (debugString != "") print(debugString);
}

/* Only runs when the timer is stopped */
start { // Starts the timer upon returning true
	return current.didIntro == 0 && current.isInGame > 0;
}

/* Only runs when the timer is running */
reset { // Resets the timer upon returning true
	return old.didIntro == 1 && current.didIntro == 0;
}

split { // Splits upon returning true if reset isn't explicitly returning true
	if (settings["isInTransition"] && old.isInTransition == 0 && current.isInTransition == 1) return true;
	if (settings["hasWand"] && old.hasWand == 0 && current.hasWand == 1) return true;

	if (settings["hasSkull"] && old.hasSkull == 0 && current.hasSkull == 1) return true;
	if (settings["hasWateringCan"] && old.hasWateringCan == 0 && current.hasWateringCan == 1) return true;
	if (settings["hasBook"] && old.hasBook == 0 && current.hasBook == 1) return true;

	if (settings["hasRedKey"] && old.hasRedKey == 0 && current.hasRedKey == 1) return true;
	if (settings["hasGreen"] && old.hasGreen == 0 && current.hasGreen == 1) return true;
	if (settings["hasBlueKey"] && old.hasBlueKey == 0 && current.hasBlueKey == 1) return true;

	// if (settings["oKeyDoor_REDDOOR_Locked"] && old.oKeyDoor_REDDOOR_Locked == 1 && current.oKeyDoor_REDDOOR_Locked == 0) return true;
	// if (settings["oKeyDoor_GREENDOOR_Locked"] && old.oKeyDoor_GREENDOOR_Locked == 1 && current.oKeyDoor_GREENDOOR_Locked == 0) return true;
	// if (settings["oKeyDoor_BLUEDOOR_Locked"] && old.oKeyDoor_BLUEDOOR_Locked == 1 && current.oKeyDoor_BLUEDOOR_Locked == 0) return true;

	// Additionnal checks as the pointerpath for the bucket can sometimes point elsewhere
	if (settings["bucketUnlocked"] &&
		old.bucketNextStop == 10 && current.bucketNextStop == 0 &&
		old.bucketCurrentStop == 10 && current.bucketCurrentStop == 10) return true;
	// When First calling the bucket to a certain floor
	// To floor -2¾ (#2) from above (#3 or #4)
	if (settings["bucketStopUnlocked_2"] && !vars.bucketStopUnlocked_2 &&
		old.bucketNextStop >= 3 && current.bucketNextStop == 2 &&
		old.bucketCurrentStop >= 3 && current.bucketCurrentStop >= 3) return vars.bucketStopUnlocked_2 = true;
	// To floor -2 (#3) from -3 (#1)
	if (settings["bucketStopUnlocked_3"] && !vars.bucketStopUnlocked_3 &&
		old.bucketNextStop == 1 && current.bucketNextStop == 3 &&
		old.bucketCurrentStop == 1 && current.bucketCurrentStop == 1) return vars.bucketStopUnlocked_3 = true;
	// To floor -1 (#4) from -2 (#3)
	if (settings["bucketStopUnlocked_4"] && !vars.bucketStopUnlocked_4 &&
		old.bucketNextStop == 3 && current.bucketNextStop == 4 &&
		old.bucketCurrentStop == 3 && current.bucketCurrentStop == 3) return vars.bucketStopUnlocked_4 = true;
	// Pointer to the bucket is loss, but the player was going from floor -1 (#4) to outside (#5)
	if (settings["bucketExitWell"] &&
		old.bucketNextStop == 5 && current.bucketNextStop == 0 &&
		old.bucketCurrentStop == 4 && current.bucketCurrentStop == 0) return true;

	if (settings["bunnyCount"] && old.bunnyCount < current.bunnyCount) return true;
	if (settings["secretCount"] && old.secretCount < current.secretCount) return true;
}
