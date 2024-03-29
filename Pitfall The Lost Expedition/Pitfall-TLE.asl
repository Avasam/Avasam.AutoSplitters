state("PITFALL The Lost Expedition") {
	// 0x5170CC follows the current zone, but not always exactly at the same time. 0 on first Jaguar. Might be related to save.
	uint zone: 0x517088;
	bool isLoading: 0x523735;

	// Items
	bool hasSling: 0x4EEBA4;
	bool hasTorch: 0x4EEBC0;
	bool hasPickaxes: 0x4EEBDC;
	bool hasTNT: 0x4EEBF8;
	bool hasShield: 0x4EEC14;
	bool hasRaft: 0x4EEC30;
	bool hasGasMask: 0x4EEC4C;
	bool hasCanteen: 0x4EEC68;

	// This seems to be related to the "forced to walk" state that happens before and after loading zones
	// bool isForcedWalk: 0x517084;

	// Current idols. Has some issues:
	// - The number vary wildly during the plane cinematic and when spit out of a hole/croc
	// - Gets zero'd and added back upon load
	// - Buying a Shaman item and dying adds back the idol count (expected behaviour, but still an issue for us)
	// There is a value in memory that doesn't have the first two issues, however, it will change place in memory upon death.
	// For that reason, I haven't been able to produce a pointermap for it yet.
	// However, watching for address changes works great.
	byte idolsCount: 0x5170A0, 0x5C, 0x0, 0x18, 0x39C;
	uint idolsCountPtr: 0x5170A0, 0x5C, 0x0, 0x18;
	// Current health. Has some quirks:
	// - Gets zero'd and added back upon load and when going back to menu
	byte harryHealth: 0x5170A0, 0x638;
	// Alternative: byte puscaHealth: 0x51A940, 0x0, 0x2A0, 0x30, 0x63C;
	byte puscaHealth: 0x51A940, 0x0, 0x3D4, 0x38, 0x63C;
}

startup { // When the script loads
	print("============================= SCRIPT STARTUP =============================");
	settings.Add("Reminder", false, "Reminders (these options do nothing)");
	settings.Add("Reminder1", false, "Remember to set your \"Start Time at:\" to 1.35 !", "Reminder");
	settings.Add("Reminder2", false, "Automatic Reset is experimental", "Reminder");
	settings.Add("DebugLogs", false, "Print debug logs in DbgView", "Reminder");

	settings.Add("SplitOnLoad", true, "Split on Loading Screen (except the first one)");
	settings.Add("DontSplitOnCutsceneLoad", false, "Except for loads that only contains a cutscene or running forward", "SplitOnLoad");
	settings.Add("SplitOnPusca", true, "Split on Defeating Pusca");

	settings.Add("SplitOnShaman", false, "Split on buying from Shaman (except Mystery Item)");
	settings.Add("NativeGamesStart", true, "Split on starting Native Games for the first time");
	settings.Add("NativeGamesIdol", true, "Split on collecting Native Games idols");
	settings.Add("SplitOnIdol", false, "Split on Idol collection");
	settings.Add("SplitOnExplorer", true, "Only on Explorer Idols", "SplitOnIdol");
	settings.Add("UnsplitOnDeath", false, "Automatically undo Idol and Shaman split on death (experimental)");

	settings.Add("SplitOnItems", false, "Split on item collection");
	settings.Add("SplitOnCanteen", true, "Split on Canteen", "SplitOnItems");
	settings.Add("SplitOnSling", true, "Split on Sling", "SplitOnItems");
	settings.Add("SplitOnTorch", true, "Split on Torch", "SplitOnItems");
	settings.Add("SplitOnShield", true, "Split on Shield", "SplitOnItems");
	settings.Add("SplitOnGasMask", true, "Split on Gas Mask", "SplitOnItems");
	settings.Add("SplitOnRaft", true, "Split on Raft", "SplitOnItems");
	settings.Add("SplitOnPickaxes", true, "Split on Pickaxes", "SplitOnItems");
	settings.Add("SplitOnTNT", true, "Split on TNT", "SplitOnItems");
	settings.Add("IncludeStClaire", true, "Include St. Claire's Excavation Camp item collection", "SplitOnItems");

	/*
		2, 4, 8, 16, 32, // Extra Health
		1, 2, 3, 4, 5, // Canteen Max Increase
		10, // Smash Strike
		10, // Super Sling
		10, // Breakdance
		9, // Jungle Notes
		7, // Native Notes
		7, // Cavern Notes
		8, // Mountain Notes
	*/
	var shamanInventory = new [] { 1, 2, 3, 4, 5, 7, 8, 9, 10, 16, 32 };
	vars.isValidShamanPrice = (Func<int, bool>)((int idolsPaid) => {
		if (idolsPaid <= 0) return false;
		var index = Array.IndexOf(shamanInventory, idolsPaid);
		if (index == -1) return false;
		return true;
	});

	vars.isCustsceneLoad = (Func<uint, bool>)((uint zoneId) =>
		vars.custsceneLoadZoneIDs.Remove(zoneId));

	var nativeGamesZoneIDs = new uint[] {
		0xE411440A, // KaBOOM!
		0x0D72E13F, // Tuco Shoot
		0x0A1F2526, // Whack-a-Tuco
		0x9316749C, // Raft Bowling
		0x7A75D1A9, // Pickaxe Race
	};
	vars.isNativeGame = (Func<uint, bool>)((uint zoneId) =>
		Array.Exists(nativeGamesZoneIDs, zone => zone == zoneId));

	Action reset = () => {
		vars.firstLoadingSkipped = false;
		vars.nativeGamesStarted = false;
		vars.ignoreResetForCredits = false;
		vars.unsplitOnDeathCount = 0;
		vars.custsceneLoadZoneIDs = new HashSet<uint> {
			0xEE8F6900, // Plane Crash
			0xABD7CCD8, // Altar of Ages
			0x6F498BBD, // Viracocha Monoliths
			0x02C7B675, // Monkey Temple (Monkey)
			0x1F237F32, // Penguin Temple (Penguin)
			0x0305DC42, // Scorpion Temple (Scorpion)
			0x72AD42FA, // Escavation Camp Night
			0x99885996, // Ruins of El Dorado (Supai)
		};
		print("Ran Reset method");
	};
	reset();
	vars.OnReset = (LiveSplit.Model.Input.EventHandlerT<TimerPhase>)((s, e) => reset());
	timer.OnReset += vars.OnReset;
	vars.timerModel = new TimerModel{CurrentState = timer};
}

init { // When the game is found
	// print("============================= INITIALISATION =============================");
}

shutdown { // When the script unloads
	timer.OnReset -= vars.OnReset;
}

/* Main methods */
update { // Returning false blocks everything but split
	// Some debugging logs
	if (settings["DebugLogs"]) {
		var idolsGained = current.idolsCount - old.idolsCount;
		var debugString = "";
		if (current.puscaHealth != old.puscaHealth) debugString += "Pusca health: " + current.puscaHealth + Environment.NewLine;
		if (current.harryHealth != old.harryHealth) debugString += "Health: " + current.harryHealth + Environment.NewLine;
		// if (current.isForcedWalk && !old.isForcedWalk) debugString += "Forced walk start" + Environment.NewLine;
		// if (!current.isForcedWalk && old.isForcedWalk) debugString += "Forced walk stop" + Environment.NewLine;
		if (current.zone != old.zone) debugString += "Zone change: 0x" + current.zone.ToString("X").PadLeft(8, '0') + Environment.NewLine;
		if (current.isLoading && !old.isLoading) debugString += "Load start" + Environment.NewLine;
		if (!current.isLoading && old.isLoading) debugString += "Load End" + Environment.NewLine;
		if (current.idolsCountPtr != old.idolsCountPtr) {
			debugString += "Idol count Pointer: 0x" + current.idolsCountPtr.ToString("X").PadLeft(8, '0') + Environment.NewLine;
		}
		if (idolsGained != 0) debugString += "Idols gained: " + idolsGained + Environment.NewLine;
		if (debugString != "") print(debugString);
	}
}

/* Only runs when the timer is stopped */
start { // Starts the timer upon returning true
	if (current.isLoading && !old.isLoading && current.zone == 0x99885996) {
		return vars.firstLoadingSkipped = true;
	}
}

/* Only runs when the timer is running */
reset { // Resets the timer upon returning true
	// Resets on going back to menu. Credits also sets the zone to 0
	if (current.zone == 0
		&& old.zone != 0 // Menu
		&& old.zone != 0x62548B77 // White Valley
		&& old.zone != 0x0305DC42 // Scorpion Fight
	) {
		if (vars.ignoreResetForCredits) {
			return vars.ignoreResetForCredits = false;
		}
		return true;
	}
}

split { // Splits upon returning true if reset isn't explicitly returning true
	if (current.isLoading && !old.isLoading) {
		vars.unsplitOnDeathCount = 0;
		if (!vars.firstLoadingSkipped) {
			vars.firstLoadingSkipped = true;
			return false;
		}

		if (settings["DontSplitOnCutsceneLoad"] && vars.isCustsceneLoad(current.zone)) {
			return false;
		}

		return settings["SplitOnLoad"];
	};

	// Don't run anything else if the pointer to current idol just changed or is null
	if (current.idolsCountPtr == 0 || current.idolsCountPtr != old.idolsCountPtr) return;

	if (current.harryHealth == 0 && old.harryHealth != 0) {
		for (; vars.unsplitOnDeathCount > 0; vars.unsplitOnDeathCount--)
		{
			vars.timerModel.UndoSplit();
		}
		return false;
	}

	if (settings["NativeGamesStart"] &&
		!vars.nativeGamesStarted &&
		vars.isNativeGame(current.zone)
	) {
		if (settings["DebugLogs"]) print("Native Games started");
		return vars.nativeGamesStarted = true;
	}

	if (current.puscaHealth == 0 && old.puscaHealth == 1) {
		vars.ignoreResetForCredits = true;
		if (settings["SplitOnPusca"]) return true;
	};

	var idolsGained = current.idolsCount - old.idolsCount;

	if (settings["SplitOnIdol"] && idolsGained == 5) {
		vars.unsplitOnDeathCount++;
		if (settings["DebugLogs"]) print("Split on Explorer");
		return true;
	}

	if (idolsGained == 1 &&
		(settings["SplitOnIdol"] && !settings["SplitOnExplorer"] ||
		settings["NativeGamesIdol"] && vars.isNativeGame(current.zone))
	) {
		vars.unsplitOnDeathCount++;
		if (settings["DebugLogs"]) print("Split on Idol");
		return true;
	}

	if (settings["SplitOnShaman"] && vars.isValidShamanPrice(-idolsGained)) {
		vars.unsplitOnDeathCount++;
		if (settings["DebugLogs"]) print("Split on Shaman");
		return true;
	};

	if (settings["IncludeStClaire"] ||
		// Daytime && Nighttime
		(current.zone != 0xBA9370DF && current.zone != 0x72AD42FA)
	) {
		if (settings["SplitOnCanteen"] && current.hasCanteen && !old.hasCanteen) {
			if (settings["DebugLogs"]) print("Split on Canteen");
			return true;
		}
		if (settings["SplitOnSling"] && current.hasSling && !old.hasSling) {
			if (settings["DebugLogs"]) print("Split on Sling");
			return true;
		}
		if (settings["SplitOnTorch"] && current.hasTorch && !old.hasTorch) {
			if (settings["DebugLogs"]) print("Split on Torch");
			return true;
		}
		if (settings["SplitOnShield"] && current.hasShield && !old.hasShield) {
			if (settings["DebugLogs"]) print("Split on Shield");
			return true;
		}
		if (settings["SplitOnGasMask"] && current.hasGasMask && !old.hasGasMask) {
			if (settings["DebugLogs"]) print("Split on Gas Mask");
			return true;
		}
		if (settings["SplitOnRaft"] && current.hasRaft && !old.hasRaft) {
			if (settings["DebugLogs"]) print("Split on Raft");
			return true;
		}
		if (settings["SplitOnPickaxes"] && current.hasPickaxes && !old.hasPickaxes) {
			if (settings["DebugLogs"]) print("Split on Pickaxes");
			return true;
		}
		if (settings["SplitOnTNT"] && current.hasTNT && !old.hasTNT) {
			if (settings["DebugLogs"]) print("Split on TNT");
			return true;
		}
	}
}

isLoading { // Pauses the Game Timer upon returning true
	return current.isLoading;
}
