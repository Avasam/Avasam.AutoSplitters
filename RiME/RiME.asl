// Thanks Ero for the help and parsing the save file.
state("RiME") {
	// 0: Main Menu,	1: Standing,			3: Falling,				4: Swimming,
	// 6: Step Up,		262: Block Grab,	1030: Ledge Grab,	1286: Vine Climb,
	// 1542: Sundial Grab, Unreliable during loads
	// short playerState: "RiME.exe", 0x2E49BE0, 0x100, 0x48, 0x190;

	// This global counter refreshes with in-gameframerate. Speed of 1 unit per second.
	// Stops refreshing while pauses menu is open. (will catch up to it's true value immediatly after)
	// double globalCounter: "RiME.exe", 0x2E3B470;

	// savePointsAmount represents the amount of CompletedSavePoints that are currently in data.sav.
	byte savePointsAmount: "RiME.exe", 0x2E485C8, 0x60, 0x1A0, 0x70;
	
	// secretsAmount represents the amount of SecretIDs that are currently in data.sav.
	// int secretsAmountPtr: "RiME.exe", 0x2E4B240, 0x120, 0x198;
	// byte secretsAmount: "RiME.exe", 0x2E4B240, 0x120, 0x198, 0x38;

	int posPtr: "RiME.exe", 0x02E34450, 0x30, 0x3A0;
	float posX: "RiME.exe", 0x02E34450, 0x30, 0x3A0, 0x1DB8;
	float posY: "RiME.exe", 0x02E34450, 0x30, 0x3A0, 0x1DBC;
	float posZ: "RiME.exe", 0x02E34450, 0x30, 0x3A0, 0x1DC0;
}

startup { // When the script loads
	print("============================= SCRIPT STARTUP =============================");
	refreshRate = 30;
	vars.startDelay = -1;
	vars.old = new ExpandoObject();
	vars.current = new ExpandoObject();
	vars.timerModel = new TimerModel{CurrentState = timer};
	var EPSILON = 3.62f; // Cannot be >= 16f or Anger&Depression's Y will collide
	// To ensure that no duplicate splits can occur, we add completed things to a HashSet, whose
	// contained items we compare against.
	vars.completedSplits = new HashSet<string>();
	// A generic Stopwatch to wait a certain amount of time in some circumstances.
	vars.stopWatch = new Stopwatch();

	// A table to help us know if a load is from a spiral load screen or not
	var loadCoordinates = new [,] {
		{24396.16f,	37171.03f,	39344.44f},	// Denial
		{24275f,		36419.21f,	41604.5f},	// Anger
		{34582.34f,	10853.8f,		6103.52f},	// Bargaining
		{24275f,		36403.21f,	41604.5f},	// Depression

		{-14176.52f,-23212.73f,	29892.23f},	// Acceptance

		{-9633.225,	60839.68,		8091.374},	// Main Menu
		{-447.0481,	5114.565,		3.583954},	// Denial Memory
		{-10.39591,	3723.797,		-741.4804},	// Anger Memory
		{-84958.43,	135707,			83393.52},	// Bargaining Memory
		{7373.604,	-7613.734,	10345.52},	// Depression Memory
	};

	Func<float, float, float, int, int> getLoadCoordsLevel = (x, y, z, count) => {
		var result = Enumerable
			.Range(0, count)
			.Select(row =>
				new {
					index = row,
					x = loadCoordinates[row,0],
					y = loadCoordinates[row,1],
					z = loadCoordinates[row,2],
			})
			.FirstOrDefault(c =>
				Math.Abs(c.x - x) <= EPSILON &&
				Math.Abs(c.y - y) <= EPSILON &&
				Math.Abs(c.z - z) <= EPSILON 
			);
		return result == null ? -1 : (int) result.index;
	};

	vars.isSpiralLoad = (Func<float, float, float, bool>)((x, y, z) =>
		getLoadCoordsLevel(x, y, z, 4) > -1);

	vars.getStageLoad = (Func<float, float, float, int>)((x, y, z) =>
		getLoadCoordsLevel(x, y, z, 5));

	vars.isMemoryLoad = (Func<float, float, float, bool>)((x, y, z) =>
		Enumerable
			.Range(4, 6)
			.Select(row =>
				new {
					x = loadCoordinates[row,0],
					y = loadCoordinates[row,1],
					z = loadCoordinates[row,2],
			})
			.Any(c =>
				Math.Abs(c.x - x) <= EPSILON &&
				Math.Abs(c.y - y) <= EPSILON &&
				Math.Abs(c.z - z) <= EPSILON 
			)
	);

	#region Building Settings
	settings.Add("startDelay", true, "Delay start timer to first input (don't use this with Start Timer offset)");

	// The two outermost parents for our settings.
	settings.Add("Stages:");
	settings.Add("Extras:");

	// A nested object array to make settings creation a little bit cleaner.
	// The array is sorted in the order (parent, id, description, on/of default).
	var settingsArray = new string[][] {
		new[]	{ "Stages:", "Denial" },
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
		new[]		{ "Denial", "TimelapseCompleted", "Sundial", "false" },
		new[]		{ "Denial", "KingsHallEntrance", "Kings Hall Entrance"},
		new[]		{ "Denial", "InnerRing", "Inner Ring Entrance" },
		new[]		{ "Denial", "Labirynth", "Labirynth Entrance" },
		new[]		{ "Denial", "ChimneyZ01_P", "Labirynth Exit" },
		new[]		{ "Denial", "Z00_01_P", "Stage Complete" },
		new[]	{ "Stages:", "Anger" },
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
		new[]		{ "Anger", "Z00_02_P", "Stage Complete" },
		new[]	{ "Stages:", "Bargaining" },
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
		new[]		{ "Bargaining", "Z00_03_P", "Stage Complete" },
		new[]	{ "Stages:", "Depression" },
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
		new[]		{ "Depression", "Z00_04_P", "Stage Complete" },
		new[]	{ "Stages:", "OrichalcumHouse", "Acceptance : Orichalcum House" },

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
		var s1 = (j / 4 + 1);
		var s2 = (j % 4 + 1);
		settings.Add("SC_MOSAIC_" + s1 + "0" + s2, true, "Emblem " + s1 + ":" + s2, "Emblems");
	}
	for (int i = 0; i < 6; ++i) {
		var s = (i+1);
		// Lullabies 1 and 2 are inverted
		if (s == 1) s = 2;
		else if (s == 2) s = 1;
		settings.Add("SC_LULLABY_0" + s, true, "Lullaby " + s, "Lullabies");
	}
	for (int i = 0; i < 8; ++i) {
		var s = (i+1);
		settings.Add("SC_KEYHOLE_0" + s, true, "Keyhole " + s, "Keyholes");
	}
	for (int i = 0; i < 4; ++i) {
		var s = (i+1);
		settings.Add("SC_WHITESHADE_0" + s, true, "White Shade " + s, "White Shades");
	}
	#endregion

	#region File Watcher
	var lastWriteTime = DateTime.Now.Ticks;
	System.IO.FileSystemEventHandler OnGameSave = (s, e) => {
		print("Write to data.sav detected!");
		// Ignore duplicated events (within a second of each-other)
		var newUpdateTime = DateTime.Now.Ticks;
		if (newUpdateTime - lastWriteTime > 20000000) {
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
	#endregion

	// Since it's not always safe to assume a user's script goes through the start{} & reset{} blocks,
	// we must use an EventHandler and subscribe it to timer events. This covers manual starting/resetting.
	vars.OnStart = (EventHandler)((s, e) => {
		// Start listening to file events when the timer starts
		vars.updateVariables();
		vars.fileWatcher.EnableRaisingEvents = true;
		// Cleanup
		vars.justSaved = false;
		vars.startDelay = -1;
		vars.completedSplits.Clear();
		vars.stopWatch.Reset();
	});
	timer.OnStart += vars.OnStart;

	vars.OnReset = (LiveSplit.Model.Input.EventHandlerT<TimerPhase>)((s, e) => {
		vars.isLoading = false;
		vars.startDelay = -1;
		vars.stopWatch.Reset();
		// Stop watching when timer isn't running
		vars.fileWatcher.EnableRaisingEvents = false;
	});
	timer.OnReset += vars.OnReset;
}

init { // When the game is found
	print("============================= INITIALISATION =============================");
	#region Global Variables
	// All these are System.Dynamic.ExpandoObjects that are initialized with the ability to compare old. and current.,
	// allowing a check for changes in it.
	vars.current.level = "";
	vars.current.savePoint = "";
	vars.current.secret = "";

	vars.isLoading = false;
	var savePointsRegex = new System.Text.RegularExpressions.Regex("(?s)CompletedSavePoints\0.\0\0\0ArrayProperty\0..\0\0\0\0\0\0.\0\0\0NameProperty\0\0.");
	var secretsRegex = new System.Text.RegularExpressions.Regex("(?s)SecretUnlockData\0.\0\0\0ArrayProperty\0..\0\0\0\0\0\0.\0\0\0StructProperty\0\0.");
	#endregion

	#region Helper Functions
	// This function is used to update our variables obtained fomr the save file.
	// level will be set to the current level, savePoint and secret to the most recently unlocked item.
	vars.updateVariables = (Action) (() => {
		try {
			// Just a simple StringBuilder to give us some information.
			var sBuilder = new StringBuilder();
			sBuilder.AppendLine("Updating variables");

			// Since our data.sav file is generated by UE4 in binary, we can't read it as plain text.
			// Here, we get the path to the file, declare a regular expression to filter in necessary
			// characters, and replace all other clumps of gibberish with spaces.
			// This gives us a nice and clean string of all strings in plain text.
			// Then we split the plain text into separate elements of a listto a list.
			// This list will only consist of the finalized strings without any spaces.
			string filePath = Environment.GetEnvironmentVariable("LOCALAPPDATA") + @"\SirenGame\Saved\SaveGames\data.sav";

			string fileContent;
			while (true) {
				try
				{
					Thread.Sleep(16);
					using (var fileStream = File.Open(filePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
					using (var textReader = new StreamReader(fileStream)) {
						fileContent = textReader.ReadToEnd();
						break;
					} 
				} catch (IOException exception) {
					print("Exception while trying to read the save file. Trying again in 16ms:\n" + exception);
				}
			}

			Func<System.Text.RegularExpressions.Regex, int> findAmmount = (pattern) => {
				var match = pattern
					.Matches(fileContent)
					.Cast<System.Text.RegularExpressions.Match>()
					.Select(m => m.Value)
					.FirstOrDefault() ?? "";
				return (int) new UTF8Encoding().GetBytes(match).LastOrDefault();
			};

			var savePointsAmount = findAmmount(savePointsRegex);
			var secretsAmount = findAmmount(secretsRegex);

			var fileList = new System.Text.RegularExpressions
				.Regex(@"[^a-zA-Z\d-_]+")
				.Replace(fileContent, " ")
				.Trim()
				.Split(' ')
				.ToList();

			// This function is used to return the index of the first item of the thing we desire.
			// Using LINQ, we check the index of our parent structure, followed by the first instance
			// of the property of its items after said parent. Adding 1 to this index returns our
			// first item's index.
			Func<string, string, int> startIndex = (parent, property) => {
				var parentIndex = fileList.IndexOf(parent);
				return parentIndex > -1
					? fileList
						.Select((s, i) => new { String = s, Index = i })
						.Where(x => x.Index > parentIndex && x.String.Contains(property))
						.Select(x => x.Index)
						.First() + 1
					: -1;
			};

			// This is the function used to split. It is given the old and current versions of
			// level, savePoint, or secret and executes split logic accordingly.
			Func<string, string, bool> splitFunc = (oldString, currString) => {
				if (oldString == currString) return false;
				sBuilder.AppendLine("Value changed: '" + oldString + "' ==> '" + currString + "'");
				
				// oldString empty means the value just got initialized.
				// currString None and Z01_P are simply unused for splitting purposes.
				if (oldString == "" || currString == "None" || currString == "Z01_P" ||
				// We have to check if the new item hasn't already been split on, using our HashSet.
					vars.completedSplits.Contains(currString)
				) return false;
				// If it hasn't, add it to the HashSet and check if the setting for it is turned on.
				vars.completedSplits.Add(currString);
				return settings[currString];
			};

			#region Actual Updating
			// Here, we update the variables fond in the save file.

			var levelStartIndex = startIndex("PersistentLevelName", "NameProperty");
			vars.old.level = vars.current.level;
			vars.current.level = levelStartIndex > -1
				? fileList
					.Skip(levelStartIndex)
					.Take(1)
					.First()
				: "None";

			var spList = fileList
				.Skip(startIndex("CompletedSavePoints", "NameProperty"))
				.Take(savePointsAmount);
			vars.old.savePoint = vars.current.savePoint;
			vars.current.savePoint = spList.LastOrDefault() ?? "None";
			// Workaround for Denial and Bargaining both having a "Chimney" SavePoint
			if (vars.current.savePoint == "Chimney") vars.current.savePoint += vars.current.level;

			var scList = fileList
				.Skip(startIndex("SirenSecretUnlockSaveData", "StrProperty"))
				.Where((x, i) => i % 8 == 0)
				.Take(secretsAmount);
			vars.old.secret = vars.current.secret;
			vars.current.secret = scList.LastOrDefault() ?? "None";

			// Call our splitFunc to check if any of them return true.
			if (settings.SplitEnabled &&
				(TimeStamp.Now - vars.timerModel.CurrentState.StartTime).Ticks > 20000000 &&
				(splitFunc(vars.old.level, vars.current.level) ||
				splitFunc(vars.old.savePoint, vars.current.savePoint) ||
				splitFunc(vars.old.secret, vars.current.secret))
			) {
				sBuilder.AppendLine("Splitting");
				vars.timerModel.Split();
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
			sBuilder.AppendLine("Current SavePoint: (" + savePointsAmount + ") " + vars.current.savePoint);
			sBuilder.AppendLine("Current Secret: (" + secretsAmount + ") " + vars.current.secret);

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

// Main methods

// Only runs when the timer is stopped
start { // Starts the timer upon returning true
	var acceptanceStartDelay = 20933; // 1256 frames

	// Note: Acceptace starts at 1 savePoint, all others at 0
	if (current.savePointsAmount > 1 ||
		(current.savePointsAmount != 0 && vars.startDelay != acceptanceStartDelay) ||
		old.posPtr == 0 ||
		current.posPtr == 0) return false;
	var sBuilder = new StringBuilder();
	if (Math.Abs(old.posX - current.posX) >= 1) sBuilder.AppendLine("posX  : " + current.posX + " (from " + old.posX + ")");
	if (Math.Abs(old.posY - current.posY) >= 1) sBuilder.AppendLine("posY  : " + current.posY + " (from " + old.posY + ")");
	if (Math.Abs(old.posZ - current.posZ) >= 1) sBuilder.AppendLine("posZ  : " + current.posZ + " (from " + old.posZ + ")");

	// NOTE: If we had access to the current level from the memory watch,
	// we could do this much more concisely.

	var posChanged = Math.Abs(old.posX - current.posX) >= 1 &&
		Math.Abs(old.posY - current.posY) >= 1 &&
		Math.Abs(old.posZ - current.posZ) >= 1;

	// Step #1 Prepare the delay to use
	if (vars.startDelay < 0 &&
		current.posX != 0 &&
		current.posY != 0 &&
		current.posZ != 0 &&
		posChanged
	) {
		vars.stopWatch.Reset();
		int enteredLevel = vars.getStageLoad(current.posX, current.posY, current.posZ);
		sBuilder.AppendLine("Entered Level: " + enteredLevel);
		
		// These values were all tested at 60FPS
		if (!settings["startDelay"]) {
			vars.startDelay = 0;
		} else switch (enteredLevel) {
			case 0: // Denial
				vars.startDelay = 19550; // 1173 frames
				break;
			case 1: // Anger
				vars.startDelay = 24366; // 1462 frames
				break;
			case 2: // Bargaining
				vars.startDelay = 23900; // 1434 frames
				break;
			case 3: // Depression
				vars.startDelay = 54266; // 3256 frames
				break;
			case 4: // Acceptance
				vars.startDelay = acceptanceStartDelay;
				break;
		}
	}

	// Step #2 Start stopwatch.
	// On spiral this will run next time the position changes.
	// On Acceptance this will run immediatly after step #1
	if (vars.startDelay >= 0 &&
		!vars.stopWatch.IsRunning &&
		posChanged &&
		((old.posX != 0 && old.posY != 0 && old.posZ != 0) ||
		!vars.isSpiralLoad(current.posX, current.posY, current.posZ))
	) {
		vars.stopWatch.Start();
		sBuilder.AppendLine("Stopwatch started. startDelay: " + vars.startDelay);
	}

	if (sBuilder.Length > 0) print(sBuilder.ToString());

	// Step #3 Start LiveSplit
	if (vars.stopWatch.IsRunning && vars.startDelay >= 0 && vars.stopWatch.ElapsedMilliseconds >= vars.startDelay) {
		print("Automatic start.\nstartDelay: " + vars.startDelay + "\nElapsedMilliseconds: " + vars.stopWatch.ElapsedMilliseconds);
		return true;
	};
}

split {
	return false;
}

isLoading {
	if (old.posPtr != current.posPtr) print("posPtr: 0x" + current.posPtr.ToString("X").PadLeft(8, '0'));

	// Lost pointer means loading started
	if (current.posPtr == 0) vars.isLoading = true;

	if (vars.isLoading && old.posPtr != 0 && current.posPtr != 0) {
		var sBuilder = new StringBuilder();

		if (Math.Abs(old.posX - current.posX) >= 1) sBuilder.AppendLine("posX  : " + current.posX + " (from " + old.posX + ")");
		if (Math.Abs(old.posY - current.posY) >= 1) sBuilder.AppendLine("posY  : " + current.posY + " (from " + old.posY + ")");
		if (Math.Abs(old.posZ - current.posZ) >= 1) sBuilder.AppendLine("posZ  : " + current.posZ + " (from " + old.posZ + ")");

		// Check position changed. Must be from a non-0 value to another non-0 value on spiral loads
		if ((old.posX != 0 && old.posY != 0 && old.posZ != 0) ||
				!vars.isSpiralLoad(current.posX, current.posY, current.posZ)
		) {
			// All three values must change at the same time.
			// But it can rarely happen that all three oscillate at the start of a load.
			if (Math.Abs(old.posX - current.posX) >= 1 &&
				Math.Abs(old.posY - current.posY) >= 1 &&
				Math.Abs(old.posZ - current.posZ) >= 1
			) vars.isLoading = false;
		}

		// Stop loading as soon as a coordinate changes from non-zero for Memory loads
		else if (vars.isMemoryLoad(current.posX, current.posY, current.posZ)) {
			vars.isLoading = false;
		}

		if (sBuilder.Length > 0) print(sBuilder.ToString());
	}

	return vars.isLoading;
}
