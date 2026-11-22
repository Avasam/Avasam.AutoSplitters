state("PITFALL The Lost Expedition") {
	// Names and offsets are from DaveUltra's PC Ghidra project and PTLE_Mods SDK
	// https://github.com/DaveUltra/ptle
	// Image base is 0x400000, so module offset 0x517028 is the game's global struct at 0x917028.

	// GlobalStruct + 0x60, m_currentLevelCRC: the current level's CRC, 0 in the main menu and credits.
	// Not used: GlobalStruct + 0xA4 (0x5170CC), m_nextLevelCRC, is the level being loaded, so it
	// changes before this one. Observed 0 on the first Jaguar.
	uint zone: 0x517088;
	// Resource prefetcher thread struct (0x5236B8) + 0x7D, a bool with no name yet.
	bool isLoading: 0x523735;

	// Items: an array of 0x1C byte ItemStruct at 0x4EEB90, m_unlocked (int) at + 0x14.
	// Read as bool, which is the int's low byte: enough, since it only holds 0 or 1.
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

	// GlobalStruct + 0x78, m_harry: the EIHarry instance. Harry is recreated on death and on load,
	// so this pointer changes then. His constructor zeroes his fields, and EIHarry_LoadSavedValues
	// fills them later.
	uint harryPtr: 0x5170A0;
	// EIHarry + 0x1900, m_idolsCollected: the count that collecting adds to and buying from a
	// Shaman takes from. Buying a Shaman item and dying gives the idols back (expected
	// behaviour, but still an issue for us).
	int idolsCount: 0x5170A0, 0x1900;
	// EIPlayer + 0x638, m_healthValue. Zero'd on load and when going back to menu.
	int harryHealth: 0x5170A0, 0x638;
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

	vars.isCutsceneLoad = (Func<uint, bool>)((uint zoneId) =>
		vars.cutsceneLoadZoneIDs.Remove(zoneId));

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
		vars.cutsceneLoadZoneIDs = new HashSet<uint> {
			0xEE8F6900, // Plane Crash
			0xABD7CCD8, // Altar of Ages
			0x6F498BBD, // Viracocha Monoliths
			0x02C7B675, // Monkey Temple (Monkey)
			0x1F237F32, // Penguin Temple (Penguin)
			0x0305DC42, // Scorpion Temple (Scorpion)
			0x72AD42FA, // Excavation Camp Night
			0x99885996, // Ruins of El Dorado (Supai)
		};
		print("Ran Reset method");
	};
	reset();
	vars.reset = reset;
	vars.timerModel = new TimerModel{CurrentState = timer};
}

init { // When the game is found
	// print("============================= INITIALISATION =============================");
	var baseAddress = modules.First().BaseAddress;
	// vtable_EIPusca. Exact class match, so EIPuscaMinion is skipped.
	var puscaVtable = baseAddress + 0x493EA8;
	vars.puscaVtable = puscaVtable;
	// Same walk as PTLE_Mods' GizmodWorld::getEntitiesOfType
	vars.findPusca = (Func<IntPtr>)(() => {
		// GlobalStruct + 0x4, a level controller whose first field is the ERLevel
		var level = memory.ReadPointer(memory.ReadPointer(baseAddress + 0x51702C));
		if (level == IntPtr.Zero) return IntPtr.Zero;
		// ERLevel + 0x59C, m_entitiesByID: a HashMap, m_iterateFirst at + 0x4, m_size at + 0x10.
		// Capped in case the level is mid teardown and the size is garbage.
		var entry = memory.ReadPointer(level + 0x59C + 0x4);
		var size = Math.Min(memory.ReadValue<int>(level + 0x59C + 0x10), 0x10000);
		// HashMapEntry: m_iterateNext at + 0x0, m_ptr at + 0x10
		for (var i = 0; i < size && entry != IntPtr.Zero; i++, entry = memory.ReadPointer(entry)) {
			var entity = memory.ReadPointer(entry + 0x10);
			if (entity != IntPtr.Zero && memory.ReadPointer(entity) == puscaVtable) return entity;
		}
		return IntPtr.Zero;
	});
	vars.puscaPtr = IntPtr.Zero;
	vars.puscaScanCooldown = 0;
	// Set in update{}, seeded so old has it on the first update{}
	current.puscaHealth = -1;
}

onReset { // When the timer resets, unlike reset{} also on manual resets
	vars.reset();
}

/* Main methods */
update { // Returning false skips start, split, reset, isLoading and gameTime
	// -1 while Pusca isn't found, so losing him (death, quit) never reads as his health hitting 0
	current.puscaHealth = -1;
	if (current.zone == 0xCFD2FE10) { // Ancient El Dorado (Pusca)
		IntPtr puscaPtr = vars.puscaPtr;
		if (puscaPtr != IntPtr.Zero && memory.ReadPointer(puscaPtr) != vars.puscaVtable) puscaPtr = IntPtr.Zero;
		// Scan about once a second until found, not on every tick
		if (puscaPtr == IntPtr.Zero && !current.isLoading && --vars.puscaScanCooldown <= 0) {
			vars.puscaScanCooldown = 60;
			puscaPtr = vars.findPusca();
			if (settings["DebugLogs"] && puscaPtr != IntPtr.Zero) print("Pusca found: 0x" + puscaPtr.ToString("X8"));
		}
		vars.puscaPtr = puscaPtr;
		// EIBeast + 0x63C, m_bossHealth
		if (puscaPtr != IntPtr.Zero) current.puscaHealth = memory.ReadValue<int>(puscaPtr + 0x63C);
	} else {
		vars.puscaPtr = IntPtr.Zero;
		vars.puscaScanCooldown = 0;
	}

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
		if (current.harryPtr != old.harryPtr) {
			debugString += "Harry pointer: 0x" + current.harryPtr.ToString("X").PadLeft(8, '0') + Environment.NewLine;
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

		if (settings["DontSplitOnCutsceneLoad"] && vars.isCutsceneLoad(current.zone)) {
			return false;
		}

		return settings["SplitOnLoad"];
	};

	// Don't run anything else if Harry was just recreated or doesn't exist
	if (current.harryPtr == 0 || current.harryPtr != old.harryPtr) return;

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

	// A new Harry reads 0 idols until his saved values load. Health loads after idols,
	// so non-zero health on both ticks means both idol counts are real.
	var idolsGained = old.harryHealth != 0 && current.harryHealth != 0
		? current.idolsCount - old.idolsCount
		: 0;

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
