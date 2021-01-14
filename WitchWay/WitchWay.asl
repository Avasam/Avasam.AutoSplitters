state("WitchWay") {
	double hasWand: 0x16BE820, 0x34, 0x10, 0xE8, 0x0;

	double hasSkull: 0x16BE820, 0x34, 0x10, 0x118, 0x0;
	double hasWateringCan: 0x16BE820, 0x34, 0x10, 0x130, 0x0;
	double hasBook: 0x16BE820, 0x34, 0x10, 0x124, 0x0;

	double hasRedKey: 0x16BE820, 0x34, 0x10, 0xF4, 0x0;
	double hasGreen: 0x16BE820, 0x34, 0x10, 0x10C, 0x0;
	double hasBlueKey: 0x16BE820, 0x34, 0x10, 0x100, 0x0;

	// double oKeyDoor_REDDOOR_Animation: 0x0;
	double oKeyDoor_GREENDOOR_Animation: 0x16B87F0;
	// double oKeyDoor_BLUEDOOR_Animation: 0x0;

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
	// settings.Add("oKeyDoor_REDDOOR_Animation", true, "Red Door Unlocked", "Doors");
	settings.Add("oKeyDoor_GREENDOOR_Animation", true, "Green Door Unlocked"/*, "Doors"*/);
	// settings.Add("oKeyDoor_BLUEDOOR_Animation", true, "Blue Door Unlocked", "Doors");

	settings.Add("bunnyCount", true, "Bunny caught");
	settings.Add("secretCount", false, "Eye opened");
}

split { // Splits upon returning true if reset isn't explicitly returning true
	if (settings["hasWand"] && old.hasWand == 0 && current.hasWand == 1) return true;

	if (settings["hasSkull"] && old.hasSkull == 0 && current.hasSkull == 1) return true;
	if (settings["hasWateringCan"] && old.hasWateringCan == 0 && current.hasWateringCan == 1) return true;
	if (settings["hasBook"] && old.hasBook == 0 && current.hasBook == 1) return true;

	if (settings["hasRedKey"] && old.hasRedKey == 0 && current.hasRedKey == 1) return true;
	if (settings["hasGreen"] && old.hasGreen == 0 && current.hasGreen == 1) return true;
	if (settings["hasBlueKey"] && old.hasBlueKey == 0 && current.hasBlueKey == 1) return true;

	// if (settings["oKeyDoor_REDDOOR_Animation"] && old.oKeyDoor_REDDOOR_Animation < 0 && current.oKeyDoor_REDDOOR_Animation == 1) return true;
	if (settings["oKeyDoor_GREENDOOR_Animation"] && old.oKeyDoor_GREENDOOR_Animation < 1 && current.oKeyDoor_GREENDOOR_Animation == 1) return true;
	// if (settings["oKeyDoor_BLUEDOOR_Animation"] && old.oKeyDoor_BLUEDOOR_Animation < 0 && current.oKeyDoor_BLUEDOOR_Animation == 1) return true;

	if (settings["bunnyCount"] && old.bunnyCount < current.bunnyCount) return true;
	if (settings["secretCount"] && old.secretCount < current.secretCount) return true;
}
