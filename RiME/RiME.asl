state("RiME") {
	// savePointsAmount represents the amount of CompletedSavePoints that are currently in data.sav.
	int savePointsAmount	: "RiME.exe", 0x2E485C8, 0x60, 0x1A0, 0x70;
	// secretsAmount represents the amount of SecretIDs that are currently in data.sav.
	int secretsAmountPtr	: "RiME.exe", 0x2E4B240, 0x120, 0x198;
	int secretsAmount			: "RiME.exe", 0x2E4B240, 0x120, 0x198, 0x38;

	// Some camera related stuff, maybe?
	byte cameraState			: "RiME.exe", 0x2E33FC0, 0x10, 0xC8, 0x70, 0x70, 0x60, 0x7C;
	// This global counter refreshes with in-gameframerate. Speed of 1 unit per second.
	// Stops refreshing while pauses menu is open. (will catch up to it's true value immediatly after)
	// double globalCounter: "RiME.exe", 0x2E3B470;
}

startup {
	// To ensure that no duplicate splits can occur, we add completed things to a HashSet, whose
	// contained items we compare against.
	vars.completedSplits = new HashSet<string>();

	// A generic System.Diagnostics.Stopwatch to wait a certain amount of time in some circumstances.
	vars.stopWatch = new Stopwatch();

	vars.readyToStart = false;

	#region Building Settings
	settings.Add("startDelay", true, "Delay start timer by 6.1s (don't use this with Start Timer offset)");
	// The two outermost parents for our settings.
	settings.Add("Chapters:");
	settings.Add("Extras:");

	// A nested object array to make settings creation a little bit cleaner.
	// The array is sorted in the order (parent, id, description, on/of default).
	var settingsArray = new string[][] {
		new[]	{ "Chapters:", "Denial" },
		new[]		{ "Denial", "TowerCutscene", "Tower Cutscene" },
		new[]		{ "Denial", "Fox4Found", "Fox Statue 4 (Plateau)" },
		new[]		{ "Denial", "Fox3Found", "Fox Statue 3 (Tower)" },
		new[]		{ "Denial", "Fox2Found", "Fox Statue 2 (Boar)" },
		new[]		{ "Denial", "Fox1Found", "Fox Statue 1 (Sea)" },
		new[]		{ "Denial", "FoxCinematic", "Fox Cinematic" },
		new[]		{ "Denial", "PerspectiveTutorial", "Perspective Tutorial" },
		new[]		{ "Denial", "TowerCPushpull", "Perspective Door 3" },
		new[]		{ "Denial", "KeyTutorial", "Key Tutorial" },
		new[]		{ "Denial", "KeyTowerB", "Tower B's Key" },
		new[]		{ "Denial", "TowerBCompletedAmph", "Tower B Complete", "false" },
		new[]		{ "Denial", "TowerACompleted", "Revive Tree" },
		new[]		{ "Denial", "TowerACompletedAmph", "Tower A Complete", "false" },
		new[]		{ "Denial", "KeyTowerA", "Tree's Key" },
		new[]		{ "Denial", "AmphitheaterMain", "Amphitheater Staircase", "false" },
		new[]		{ "Denial", "TimelapsePre", "Small Bridge" },
		new[]		{ "Denial", "TimelapseCompleted", "Sundial" },
		new[]		{ "Denial", "KingsHallEntrance", "Kings Hall Entrance", "false" },
		new[]		{ "Denial", "InnerRing", "Inner Ring Entrance" },
		new[]		{ "Denial", "Labirynth", "Labirynth Entrance" },
		new[]		{ "Denial", "Chimney", "Labirynth Exit" },
		new[]		{ "Denial", "Z01_P", "Chapter Finish" },
		new[]	{ "Chapters:", "Anger" },
		new[]		{ "Anger", "BalconyPreTL", "Balcony" },
		new[]		{ "Anger", "ShoreFirstTime", "First Shore" },
		new[]		{ "Anger", "KeyClimbTempleCollected", "Sound Temple's Key" },
		new[]		{ "Anger", "KeySoundTempleCollected", "Climb Temple's Key" },
		new[]		{ "Anger", "SeaWindmillOpened", "Sea Windmill Open" },
		new[]		{ "Anger", "SeaWindmillStorm", "Sea Windmill Storm" },
		new[]		{ "Anger", "SeaWindmillShoreReached", "Sea Windmill Shore" },
		new[]		{ "Anger", "BoatWindmillGraveyard", "Boat Windmill Graveyard" },
		new[]		{ "Anger", "SheltersDestroyed", "Shelters Destroyed" },
		new[]		{ "Anger", "BoatWindmillOpened", "Boat Windmill Entrance" },
		new[]		{ "Anger", "BoatWindmillStorm", "Boat Windmill Storm" },
		new[]		{ "Anger", "CliffsAreaReached", "Cliffs" },
		new[]		{ "Anger", "PreFinalTimelapse", "Escape Predator" },
		new[]		{ "Anger", "Z02_P", "Chapter Finish" },
		new[]	{ "Chapters:", "Bargaining" },
		new[]		{ "Bargaining", "KingsHall", "King's Hall" },
		new[]		{ "Bargaining", "SinkHolePuzzle", "Sinkhole" },
		new[]		{ "Bargaining", "MainPuzzleFirstTime", "Chimney First Time" },
		new[]		{ "Bargaining", "SentinelDead", "Sentinel Dead" },
		new[]		{ "Bargaining", "ShadesBridge", "Shades Bridge" },
		new[]		{ "Bargaining", "ScrewDriverAlone", "Screw Driver Alone" },
		new[]		{ "Bargaining", "QueensHallCOmpleted", "Queen's Hall Complete" },
		new[]		{ "Bargaining", "SentinelHead", "Sentinel Head" },
		new[]		{ "Bargaining", "SentinelRevived", "Sentinel Revived" },
		new[]		{ "Bargaining", "ScrewDriverSentinel", "Screw Driver Sentinel" },
		new[]		{ "Bargaining", "SentinelBridgeUp", "Sentinel Bridge Up" },
		new[]		{ "Bargaining", "SentinelBridgeDown", "Sentinel Bridge Down", "false" },
		new[]		{ "Bargaining", "SentinelShadesBridge", "Sentinel Shades Bridge" },
		new[]		{ "Bargaining", "CementeryPre", "Cemetery Open" },
		new[]		{ "Bargaining", "CementeryCompleted", "Cemetery Complete" },
		//new[]		{ "Bargaining", "Chimney", "Chimney Post Cemetery" },
		new[]		{ "Bargaining", "Z03_P", "Chapter Finish" },
		new[]	{ "Chapters:", "Depression" },
		new[]		{ "Depression", "FirstWayCompleted", "Landing" },
		new[]		{ "Depression", "SecondWayCompleted", "Fox Wall Break" },
		new[]		{ "Depression", "ThirdWayCompleted", "Last Sentinel Sacrifice" },
		new[]		{ "Depression", "NecropolisReached", "Necropolis Reached" },
		new[]		{ "Depression", "Kid4Found", "Kid Statue 4" },
		new[]		{ "Depression", "Kid3Found", "Kid Statue 3" },
		new[]		{ "Depression", "Kid2Found", "Kid Statue 2" },
		new[]		{ "Depression", "Kid1Found", "Kid Statue 1" },
		new[]		{ "Depression", "MainStatueCompleted", "Main Statue Complete", "false" },
		new[]		{ "Depression", "MainPuzzleCompleted", "Chains Puzzle Complete" },
		new[]		{ "Depression", "Z00_04_P", "Chapter Finish" },
		new[]	{ "Chapters:", "OricalcumHouse", "Acceptance : Oricalcum House", "false" },

		new[]	{ "Extras:", "Outfits" },
		new[]		{ "Outfits", "SC_CLOTHES_SEA", "Sea Outfit" },
		new[]		{ "Outfits", "SC_CLOTHES_KING", "King Outfit" },
		new[]		{ "Outfits", "SC_CLOTHES_PREDATOR", "Predator Outfit" },
		new[]		{ "Outfits", "SC_CLOTHES_SHADES", "Shades Outfit" },
		new[]	{ "Extras:", "Toys" },
		new[]		{ "Toys", "SC_TOY_FOX", "Fox Toy" },
		new[]		{ "Toys", "SC_TOY_SEAGULL", "Seagull Toy" },
		new[]		{ "Toys", "SC_TOY_BOAR", "Boar Toy" },
		new[]		{ "Toys", "SC_TOY_WINDMILL", "Windmill Toy" },
		new[]		{ "Toys", "SC_TOY_PREDATOR", "Predator Toy" },
		new[]		{ "Toys", "SC_TOY_SENTINEL", "Sentinel Toy" },
		new[]		{ "Toys", "SC_TOY_BOAT", "Boat Toy" },
		new[]	{ "Extras:", "Emblems" },
		new[]	{ "Extras:", "Lullabies" },
		new[]	{ "Extras:", "Keyholes" },
		new[]	{ "Extras:", "White Shades" },
	}.Concat(new string[18][].Select((_, i) => {
		var j = i < 14 ? i : i + 2;
		var s1 = (j / 4 + 1).ToString();
		var s2 = (j % 4 + 1).ToString();
		return new[] { "Emblems", "SC_MOSAIC_" + s1 + "0" + s2, "Emblem " + s1 + ":" + s2 };
	})).Concat(new string[6][].Select((_, i) => {
		var s = (i+1).ToString();
		return new[] { "Lullabies", "SC_LULLABY_0" + s, "Lullaby " + s };
	})).Concat(new string[8][].Select((_, i) => {
		var s = (i+1).ToString();
		return new[] { "Keyholes", "SC_KEYHOLE_0" + s, "Keyhole " + s };
	})).Concat(new string[4][].Select((_, i) => {
		var s = (i+1).ToString();
		return new[] { "White Shades", "SC_WHITESHADE_0" + s, "White Shade " + s };
	}));

	// We loop over our settings array and add settings accordingly.
	foreach (var setting in settingsArray)
		settings.Add(
			setting[1],
			setting.ElementAtOrDefault(3) != "false",
			setting.ElementAtOrDefault(2) ?? setting[1],
			setting[0]);
	#endregion

	// Since it's not always safe to assume a user's script goes through the start{} block, we must
	// use a System.EventHandler and subscribe it to timer.OnStart. This covers manual starting.
	vars.timerStart = (EventHandler) ((s, e) => {
		vars.completedSplits.Clear();
		vars.stopWatch.Reset();
	});
	timer.OnStart += vars.timerStart;
}

init {
	#region Global Variables
	// All 6 of these are System.Dynamic.ExpandoObjects. The difference here is that
	// level, savePoint, and secret are initialized with the ability to compare old. and current.,
	// allowing a check for changes in it.
	current.level = "";
	current.savePoint = "";
	current.secret = "";
	vars.spAmtReset = false;
	vars.spAmtChanged = false;
	vars.scAmtChanged = false;
	#endregion

	#region Helper Functions
	// This function is used to update our 3 important variables level, savePoint, and secret.
	// level will be set to the current level, savePoint and secret to the most recently unlocked item.
	vars.updateVariables = (Action<bool, bool, bool>) ((spReset, spChanged, scChanged) => {
		// Since our data.sav file is generated by UE4 in binary, we can't read it as plain text.
		// Here, we get the path to the file, declare a regular expression to filter out necessary
		// characters, and replace all other gibberish with spaces.
		// This gives us a nice and clean string (albeit littered with spaces) of all strings in plain text.
		string filePath = Environment.GetEnvironmentVariable("AppData") + @"\..\Local\SirenGame\Saved\SaveGames\data.sav";
		var regex = new System.Text.RegularExpressions.Regex(@"[^a-zA-Z\d-_]+");
		var fileList = regex.Replace(File.ReadAllText(filePath), " ").Trim().Split(' ').ToList();
		print(string.Join(",", fileList));
		print(fileList.Last());

		// Declaration of some temporary lists.
		var spList  = Enumerable.Empty<string>().ToList();
		var scList = Enumerable.Empty<string>().ToList();
		// Here, we split the plain text into separate elements on every string, ignore empty strings,
		// and add all remaining strings to a list. This list will only consist of the finalized
		// strings without any spaces.

		// This function is used to return the index of the first item of the thing we desire.
		// Using LINQ, we check the index of our parent structure, followed by the first instance
		// of the property of its items after said parent. Adding 1 to this index returns our
		// first item's index.
		Func<string, string, int> startIndex = (parent, property) => {
			return fileList
				.Select((s, i) => new { String = s, Index = i })
				.Where(x => x.Index > fileList.IndexOf(parent) && x.String.Contains(property))
				.Select(x => x.Index)
				.First() + 1;
		};

		#region Actual Updating
		// Here, we check which of the variables we need to update and execute logic accordingly.

		if (spReset) {
			current.level = fileList
				.Skip(startIndex("PersistentLevelName", "NameProperty"))
				.Take(1)
				.First();
			print("spReset: " + current.level);
		}

		if (spChanged) {
			int spAmt = current.savePointsAmount;
			spList = fileList
				.Skip(startIndex("CompletedSavePoints", "NameProperty"))
				.Take(spAmt)
				.ToList();

			current.savePoint = spList[spList.Count - 1];
			print("spChanged: (" + current.savePointsAmount + ") " + current.savePoint);
			print("spChanged (level):" + current.level);
		}

		if (scChanged) {
			int scAmt = current.secretsAmount;
			scList = fileList
				.Skip(startIndex("SirenSecretUnlockSaveData", "StrProperty"))
				.Where((x, i) => i % 8 == 0)
				.Take(scAmt)
				.ToList();

			current.secret = scList[scList.Count - 1];
			print("scChanged: (" + current.secretsAmount + ") " + current.secret);
		}
		#endregion

		#region Debug Printing
		/*
		// Just a simple StringBuilder to give us some information.
		StringBuilder sBuilder = new StringBuilder();

		sBuilder.Append("\nCurrent Level:\n");
		sBuilder.Append(current.level + "\n");

		sBuilder.Append("\nSavePointsList:\n");
		foreach (string s in spList) sBuilder.Append(s + "\n");

		sBuilder.Append("\nSecretsList:\n");
		foreach (string s in scList) sBuilder.Append(s + "\n");

		print(sBuilder.ToString());
		*/
		#endregion
	});

	// This is the function used to split. It is given the old. and current. versions of
	// level, savePoint, or secret and executes split logic accordingly.
	vars.splitFunc = (Func<string, string, bool>) ((oldString, currString) => {
		bool split = false;
		// We have to check if the new item hasn't already been split on, using our HashSet.
		// If it hasn't, add it to the HashSet and check if the setting for it is turned on.
		if (oldString != currString && !vars.completedSplits.Contains(currString)) {
			vars.completedSplits.Add(currString);
			print("Current level in split func:" + current.level);
			split = settings[currString];
		}

		return split;
	});
	#endregion
}

/*
update {
	if (old.cameraState != current.cameraState)
		print("Camera state: " + current.cameraState);
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

split {
	#region Temporary Variables
	// For readability.
	bool spAmtReset = old.savePointsAmount > 0 && current.savePointsAmount == 0;
	bool spAmtChanged = old.savePointsAmount < current.savePointsAmount;
	// Ensure the amount didn't change because the pointer got reset.
	bool scAmtChanged = old.secretsAmountPtr != 0 && current.secretsAmountPtr != 0 &&
		old.secretsAmount < current.secretsAmount;
	bool checkFile = vars.stopWatch.ElapsedMilliseconds >= 50;
	#endregion

	// If any of our item amounts changed, set their global equivalents to represent if they did.
	// Our Stopwatch starts here to let data.sav update in time.
	// This is necessary to check them back after the Stopwatch's time has exceeded 50 milliseconds.
	if (spAmtChanged || scAmtChanged || spAmtReset) {
		vars.spAmtReset = spAmtReset;
		vars.spAmtChanged = spAmtChanged;
		vars.scAmtChanged = scAmtChanged;
		vars.stopWatch.Start();
	}

	// Once the 50 milliseconds are up, reset the Stopwatch and update the necessary variables.
	if (checkFile) {
		vars.stopWatch.Reset();
		vars.updateVariables(vars.spAmtReset, vars.spAmtChanged, vars.scAmtChanged);
	}

	// Call our splitFunc to check if any of them return true.
	return
		vars.splitFunc(old.savePoint, current.savePoint) ||
		vars.splitFunc(old.secret, current.secret) ||
		vars.splitFunc(old.level, current.level);
}

shutdown {
	// Unsubscribe the manual start code from timer.OnStart.
	// This is necessary to not execute the code when the script is unloaded.
	timer.OnStart -= vars.timerStart;
}
