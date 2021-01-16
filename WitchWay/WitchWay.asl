state("WitchWay") {
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
	settings.Add("hasWand", true, "Wand obtained");

	settings.Add("Artefacts", true);
	settings.Add("hasSkull", true, "Skull obtained", "Artefacts");
	settings.Add("hasWateringCan", true, "Watering Can obtained", "Artefacts");
	settings.Add("hasBook", true, "Book obtained", "Artefacts");

	settings.Add("Keys", true);
	settings.Add("hasRedKey", true, "Red Key obtained", "Keys");
	settings.Add("hasGreen", true, "Green Key obtained", "Keys");
	settings.Add("hasBlueKey", true, "Blue Key obtained", "Keys");

	// settings.Add("Doors", false);
	// settings.Add("oKeyDoor_REDDOOR_Locked", true, "Red Door Unlocked", "Doors");
	// settings.Add("oKeyDoor_GREENDOOR_Locked", true, "Green Door Unlocked", "Doors");
	// settings.Add("oKeyDoor_BLUEDOOR_Locked", true, "Blue Door Unlocked", "Doors");

	settings.Add("Bucket", true);
	// 0-1 are always unlocked. 5-9 are never unlocked. Level 5 is also exit.
	settings.Add("bucketUnlocked", true, "Bucket Unlocked", "Bucket");
	// settings.Add("bucketStopUnlocked_2", true, "Floor -2 3/4 Unlocked", "Bucket");
	// settings.Add("bucketStopUnlocked_3", true, "Floor -2 Unlocked", "Bucket");
	// settings.Add("bucketStopUnlocked_4", true, "Floor -1 Unlocked", "Bucket");
	settings.Add("bucketExitWell", true, "Exit the well", "Bucket");

	settings.Add("bunnyCount", true, "Bunny caught");
	settings.Add("secretCount", false, "Eye opened");
}

update {
	if (old.bucketCurrentStop != current.bucketCurrentStop) print("bucketCurrentStop: " + current.bucketCurrentStop.ToString());
	if (old.bucketNextStop != current.bucketNextStop) print("bucketNextStop: " + current.bucketNextStop.ToString());
	// if (old.oKeyDoor_REDDOOR_Locked != current.oKeyDoor_REDDOOR_Locked) print("oKeyDoor_REDDOOR_Locked: " + current.oKeyDoor_REDDOOR_Locked.ToString());
	// if (old.oKeyDoor_GREENDOOR_Locked != current.oKeyDoor_GREENDOOR_Locked) print("oKeyDoor_GREENDOOR_Locked: " + current.oKeyDoor_GREENDOOR_Locked.ToString());
	// if (old.oKeyDoor_BLUEDOOR_Locked != current.oKeyDoor_BLUEDOOR_Locked) print("oKeyDoor_BLUEDOOR_Locked: " + current.oKeyDoor_BLUEDOOR_Locked.ToString());
}

split { // Splits upon returning true if reset isn't explicitly returning true
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
	// Pointer to the bucket is loss, but the player was going from floor 4 to 5
	if (settings["bucketExitWell"] &&
		old.bucketNextStop == 5 && current.bucketNextStop == 0 &&
		old.bucketCurrentStop == 4 && current.bucketCurrentStop == 0) return true;

	if (settings["bunnyCount"] && old.bunnyCount < current.bunnyCount) return true;
	if (settings["secretCount"] && old.secretCount < current.secretCount) return true;
}
