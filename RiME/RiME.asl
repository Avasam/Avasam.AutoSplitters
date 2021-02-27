// Thanks Ero for the help and parsing teh save file.
state("RiME") {
	// Some camera related stuff, maybe?
	byte cameraState: "RiME.exe", 0x02E33FC0, 0x10, 0xC8, 0x70, 0x70, 0x60, 0x7C;
	// This global counter refreshes with in-gameframerate. Speed of 1 unit per second.
	// Stops refreshing while pauses menu is open. (will catch up to it's true value immediatly after)
	// double globalCounter: "RiME.exe", 0x2E3B470;
	// savePointsAmount represents the amount of CompletedSavePoints that are currently in data.sav.
	int savePointsAmount: "RiME.exe", 0x2E485C8, 0x60, 0x1A0, 0x70;
	// secretsAmount represents the amount of SecretIDs that are currently in data.sav.
	// int secretsAmountPtr: "RiME.exe", 0x2E4B240, 0x120, 0x198;
	int secretsAmount: "RiME.exe", 0x2E4B240, 0x120, 0x198, 0x38;
}

startup { // When the script loads
	print("============================= SCRIPT STARTUP =============================");
	vars.readyToStart = false;
	vars.old = new ExpandoObject();
	vars.current = new ExpandoObject();
	// To ensure that no duplicate splits can occur, we add completed things to a HashSet, whose
	// contained items we compare against.
	vars.completedSplits = new HashSet<string>();
	// A generic System.Diagnostics.Stopwatch to wait a certain amount of time in some circumstances.
	vars.stopWatch = new Stopwatch();

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
		new[]		{ "Denial", "ChimneyZ01_P", "Labirynth Exit" },
		new[]		{ "Denial", "Z00_01_P", "Chapter Complete" },
		new[]	{ "Chapters:", "Anger" },
		new[]		{ "Denial", "Z02_P", "Memory Complete" },
		new[]		{ "Anger", "BalconyPreTL", "Balcony" },
		new[]		{ "Anger", "Shelters", "Fall Down" },
		new[]		{ "Anger", "SheltersDoor", "First Windmill Open" },
		new[]		{ "Anger", "FirstStormCompleted", "First Windmill Storm" },
		new[]		{ "Anger", "ShoreFirstTime", "First Shore" },
		new[]		{ "Anger", "KeyClimbTempleCollected", "Sound Temple's Key" },
		new[]		{ "Anger", "KeySoundTempleCollected", "Climb Temple's Key" },
		new[]		{ "Anger", "SeaWindmillOpened", "Sea Windmill Open" },
		new[]		{ "Anger", "SeaWindmillWaterUp", "Sea Windmill Water Raised" },
		new[]		{ "Anger", "SeaWindmillStorm", "Sea Windmill Storm" },
		new[]		{ "Anger", "SeaWindmillShoreReached", "Sea Windmill Shore" },
		new[]		{ "Anger", "BoatWindmillGraveyard", "Boat Windmill Graveyard" },
		new[]		{ "Anger", "SheltersDestroyed", "Shelters Destroyed" },
		new[]		{ "Anger", "BoatWindmillOpened", "Boat Windmill Entrance" },
		new[]		{ "Anger", "BoatWindmillStorm", "Boat Windmill Storm" },
		new[]		{ "Anger", "CliffsAreaReached", "Cliffs" },
		new[]		{ "Anger", "PreFinalTimelapse", "Escape Predator" },
		new[]		{ "Anger", "Z00_02_P", "Chapter Complete" },
		new[]	{ "Chapters:", "Bargaining" },
		new[]		{ "Anger", "Z03_P", "Memory Complete" },
		new[]		{ "Bargaining", "KingsHall", "King's Hall" },
		new[]		{ "Bargaining", "SinkHolePuzzle", "Sinkhole" },
		new[]		{ "Bargaining", "MainPuzzleFirstTime", "Chimney First Time" },
		new[]		{ "Bargaining", "SentinelDead", "Sentinel Dead" },
		new[]		{ "Bargaining", "ShadesBridge", "Shades Bridge" },
		new[]		{ "Bargaining", "ScrewDriverAlone", "Screw Driver Alone" },
		new[]		{ "Bargaining", "QueensHallCompleted", "Queen's Hall Complete" },
		new[]		{ "Bargaining", "SentinelHead", "Sentinel Head" },
		new[]		{ "Bargaining", "SentinelRevived", "Sentinel Revived" },
		new[]		{ "Bargaining", "ScrewDriverSentinel", "Screw Driver Sentinel" },
		new[]		{ "Bargaining", "SentinelBridgeUp", "Sentinel Bridge Up" },
		new[]		{ "Bargaining", "SentinelBridgeDown", "Sentinel Bridge Down", "false" },
		new[]		{ "Bargaining", "SentinelShadesBridge", "Sentinel Shades Bridge" },
		new[]		{ "Bargaining", "CementeryPre", "Cemetery Open" },
		new[]		{ "Bargaining", "CementeryCompleted", "Cemetery Complete" },
		new[]		{ "Bargaining", "ChimneyZ03_P", "Chimney Post Cemetery" },
		new[]		{ "Bargaining", "Z00_03_P", "Chapter Complete" },
		new[]	{ "Chapters:", "Depression" },
		new[]		{ "Bargaining", "Z04_P", "Memory Complete" },
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
		new[]		{ "Depression", "Z00_04_P", "Chapter Complete" },
		new[]	{ "Chapters:", "OrichalcumHouse", "Acceptance : Orichalcum House" },

		new[]	{ "Extras:", "Outfits" },
		new[]		{ "Outfits", "SC_CLOTHES_SEA", "Sea Outfit" },
		new[]		{ "Outfits", "SC_CLOTHES_KING", "King Outfit" },
		new[]		{ "Outfits", "SC_CLOTHES_PREDATOR", "Predator Outfit" },
		new[]		{ "Outfits", "SC_CLOTHES_SENTINEL", "Sentinel Outfit" },
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
	};

	// We loop over our settings array and add settings accordingly.
	foreach (var setting in settingsArray)
		settings.Add(
			setting[1],
			setting.ElementAtOrDefault(3) != "false",
			setting.ElementAtOrDefault(2) ?? setting[1],
			setting[0]);
	for (int i = 0; i < 18; ++i) {
		var j = i < 14 ? i : i + 2;
		var s1 = (j / 4 + 1).ToString();
		var s2 = (j % 4 + 1).ToString();
		settings.Add("SC_MOSAIC_" + s1 + "0" + s2, true, "Emblem " + s1 + ":" + s2, "Emblems");
	}
	for (int i = 0; i < 6; ++i) {
		var s = (i+1).ToString();
		settings.Add("SC_LULLABY_0" + s, true, "Lullaby " + s, "Lullabies");
	}
	for (int i = 0; i < 6; ++i) {
		var s = (i+1).ToString();
		settings.Add("SC_KEYHOLE_0" + s, true, "Keyhole " + s, "Keyholes");
	}
	for (int i = 0; i < 6; ++i) {
		var s = (i+1).ToString();
		settings.Add("SC_WHITESHADE_0" + s, true, "White Shade " + s, "White Shades");
	}
	#endregion

	#region File Watcher
	var lastWriteTime = DateTime.Now.Ticks;
	System.IO.FileSystemEventHandler OnGameSave = (s, e) => {
		print("Write to data.sav detected!");
		// Ignore duplicated events (within a second of each-other)
		var newUpdateTime = DateTime.Now.Ticks;
		if (newUpdateTime - lastWriteTime > 10000000) {
			lastWriteTime = newUpdateTime;
			// Update our tracked variables for the next split() loop
			vars.updateVariables();
		}
	};

	// Create a new FileSystemWatcher and set its properties.
	vars.fileWatcher = new FileSystemWatcher();
	
	// Watch for changes in FileSize.
	vars.fileWatcher.NotifyFilter = NotifyFilters.Size;

	// Only watch the save file.
	vars.fileWatcher.Path = Environment.GetEnvironmentVariable("LOCALAPPDATA") + @"\SirenGame\Saved\SaveGames";
	vars.fileWatcher.Filter = "data.sav";

	// Add event handlers.
	vars.fileWatcher.Changed += OnGameSave;

	// Stop watching when timer isn't running
	vars.OnReset = (LiveSplit.Model.Input.EventHandlerT<TimerPhase>)((s, e) =>
		vars.fileWatcher.EnableRaisingEvents = false);
	timer.OnReset += vars.OnReset;
	#endregion

	// Since it's not always safe to assume a user's script goes through the start{} block, we must
	// use a System.EventHandler and subscribe it to timer.OnStart. This covers manual starting.
	vars.OnStart = (System.EventHandler)((s, e) => {
		// Start watching when the timer starts
		vars.updateVariables();
		vars.fileWatcher.EnableRaisingEvents = true;
		// Cleanup
		vars.justSaved = false;
		vars.completedSplits.Clear();
		vars.stopWatch.Reset();
	});
	timer.OnStart += vars.OnStart;
}

init { // When the game is found
	print("============================= INITIALISATION =============================");
	#region Global Variables
	// All these are System.Dynamic.ExpandoObjects that are initialized with the ability to compare old. and current.,
	// allowing a check for changes in it.
	vars.current.level = "";
	vars.current.savePoint = "";
	vars.current.secret = "";
	#endregion

	#region Helper Functions
	// This function is used to update our variables obtained fomr the save file.
	// level will be set to the current level, savePoint and secret to the most recently unlocked item.
	vars.updateVariables = (Action) (() => {
		try {
			// Just a simple StringBuilder to give us some information.
			StringBuilder sBuilder = new StringBuilder();
			sBuilder.AppendLine("Updating variables");

			// Since our data.sav file is generated by UE4 in binary, we can't read it as plain text.
			// Here, we get the path to the file, declare a regular expression to filter in necessary
			// characters, and replace all other clumps of gibberish with spaces.
			// This gives us a nice and clean string of all strings in plain text.
			// Then we split the plain text into separate elements of a listto a list.
			// This list will only consist of the finalized strings without any spaces.
			string filePath = Environment.GetEnvironmentVariable("LOCALAPPDATA") + @"\SirenGame\Saved\SaveGames\data.sav";
			var regex = new System.Text.RegularExpressions.Regex(@"[^a-zA-Z\d-_]+");
			List<string> fileList;
			while (true) {
				try
				{
					Thread.Sleep(16);
					using (var fileStream = File.Open(filePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
					using (var textReader = new StreamReader(fileStream)) {
						fileList = regex.Replace(textReader.ReadToEnd(), " ").Trim().Split(' ').ToList();
						break;
					} 
				} catch (IOException exception) {
					print("Exception while trying to read the save file. Trying again in 16ms:\n" + exception.ToString());
				}
			}

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

			// This is the function used to split. It is given the old and current versions of
			// level, savePoint, or secret and executes split logic accordingly.
			Func<string, string, bool> splitFunc = (oldString, currString) => {
				if (oldString == currString) return false;
				sBuilder.AppendLine("Value changed: '" + oldString + "' ==> '" + currString + "'");
				// We have to check if the new item hasn't already been split on, using our HashSet.
				// If it hasn't, add it to the HashSet and check if the setting for it is turned on.
				// oldString empty means the value just got initialized.
				// currString None is simply unused for splitting purposes.
				if (oldString == "" || currString == "None" || vars.completedSplits.Contains(currString)) return false;
				vars.completedSplits.Add(currString);
				return settings[currString];
			};

			#region Actual Updating
			// Here, we update the variables fond in the save file.

			vars.old.level = vars.current.level;
			vars.current.level = fileList
				.Skip(startIndex("PersistentLevelName", "NameProperty"))
				.Take(1)
				.First();

			var spList = fileList
				.Skip(startIndex("CompletedSavePoints", "NameProperty"))
				.Take((int)current.savePointsAmount);
			vars.old.savePoint = vars.current.savePoint;
			vars.current.savePoint = spList.LastOrDefault() ?? "None";
			// Workaround for Denial and Bargaining both having a "Chimney" SavePoint
			if (vars.current.savePoint == "Chimney") vars.current.savePoint += vars.current.level;

			var scList = fileList
				.Skip(startIndex("SirenSecretUnlockSaveData", "StrProperty"))
				.Where((x, i) => i % 8 == 0)
				.Take((int)current.secretsAmount);
			vars.old.secret = vars.current.secret;
			vars.current.secret = scList.LastOrDefault() ?? "None";

			// Call our splitFunc to check if any of them return true.
			if (
				splitFunc(vars.old.savePoint, vars.current.savePoint) ||
				splitFunc(vars.old.secret, vars.current.secret) ||
				splitFunc(vars.old.level, vars.current.level)
			) {
				sBuilder.AppendLine("Splitting");
				new TimerModel{CurrentState = timer}.Split();
			}

			#endregion

			#region Debug Printing
			/*
			sBuilder.AppendLine("SavePointsList:");
			foreach (string s in spList) sBuilder.AppendLine(s);
			sBuilder.AppendLine("\nSecretsList:\n");
			foreach (string s in scList) sBuilder.AppendLine(s);
			*/
			sBuilder.AppendLine("Current Level: " + vars.current.level);
			sBuilder.AppendLine("Current SavePoint: (" + current.savePointsAmount + ") " + vars.current.savePoint);
			sBuilder.AppendLine("Current Secret: (" + current.secretsAmount + ") " + vars.current.secret);
			
			if (sBuilder.Length > 0) print(sBuilder.ToString());
			#endregion
		} catch (Exception exception) {
			print(exception.ToString());
		}
	});
	#endregion

	// Ensures splitting still works if refreshing this script with an active timer.
	if (timer.CurrentPhase == TimerPhase.Running) vars.OnStart(null, null);
}

shutdown { // When the script unloads
	timer.OnReset -= vars.OnReset;
	timer.OnStart -= vars.OnStart;
	vars.fileWatcher.Dispose();
}

start {
	if (old.cameraState != current.cameraState) print("Camera state: " + current.cameraState.ToString());

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
