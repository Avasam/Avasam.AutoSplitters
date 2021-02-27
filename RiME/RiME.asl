state("RiME") {
	// savePointsAmount represents the amount of CompletedSavePoints that are currently in data.sav.
	int savePointsAmount  : "RiME.exe", 0x2E485C8, 0x60, 0x1A0, 0x70;
	// secretsAmount represents the amount of SecretIDs that are currently in data.sav.
	int secretsAmount     : "RiME.exe", 0x2E4B240, 0x120, 0x198, 0x38;

	// Some camera related stuff, maybe?
	byte cameraState: "RiME.exe", 0x02E33FC0, 0x10, 0xC8, 0x70, 0x70, 0x60, 0x7C;
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
	settings.Add("startDelay", "Delay start timer by 6.1s (don't use this with Start Timer offset)");
	// A nested object array to make settings creation a little bit cleaner.
	// The array is sorted in the order (parent, id, on/off, description).
	object[,] settingsArray = {
		{ "Stages:", "stageFinish", true, "Split when finishing a Level" },
		{ "Stages:", "Denial", true, "Denial" },
			{ "Denial", "TowerCutscene", true, "Tower Cutscene" },
			{ "Denial", "Fox1Found", true, "Water Fox" },
			{ "Denial", "Fox2Found", true, "Boar Fox" },
			{ "Denial", "Fox3Found", true, "Tower Fox" },
			{ "Denial", "Fox4Found", true, "Plateau Fox" },
			{ "Denial", "Z01_P", true, "Stage Finish" },
		{ "Stages:", "Anger", true, "Anger" },
			{ "Anger", "Z02_P", true, "Stage Finish" },
		{ "Stages:", "Bargaining", true, "Bargaining" },
			{ "Bargaining", "Z03_P", true, "Stage Finish" },
		{ "Stages:", "Depression", true, "Depression" },
			{ "Depression", "Z04_P", true, "Stage Finish" },
		{ "Stages:", "Acceptance", true, "Acceptance" },
			{ "Acceptance", "Z00_04_P", true, "Stage Finish" }
	};

	// The two outermost parents for our settings.
	settings.Add("Stages:");
	settings.Add("Secrets:");

	// We loop over our object array using the 0th dimension's Length and add settings accordingly.
	for (int i = 0; i < settingsArray.GetLength(0); ++i)
		settings.Add((string)settingsArray[i, 1], (bool)settingsArray[i, 2], (string)settingsArray[i, 3], (string)settingsArray[i, 0]);
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
	// stage, savePoint, and secret are initialized with the ability to compare old. and current.,
	// allowing a check for changes in it.
	current.stage = "";
	current.savePoint = "";
	current.secret = "";
	vars.spAmtReset = false;
	vars.spAmtChanged = false;
	vars.scAmtChanged = false;
	#endregion

	#region Helper Functions
	// This function is used to update our 3 important variables stage, savePoint, and secret.
	// stage will be set to the current level, savePoint and secret to the most recently unlocked item.
	vars.updateVariables = (Action<bool, bool, bool>) ((spReset, spChanged, scChanged) => {
		// Since our data.sav file is generated by UE4 in binary, we can't read it as plain text.
		// Here, we get the path to the file, declare a regular expression to filter out necessary
		// characters, and replace all other gibberish with spaces.
		// This gives us a nice and clean string (albeit littered with spaces) of all strings in plain text.
		string filePath = Environment.GetEnvironmentVariable("AppData") + @"\..\Local\SirenGame\Saved\SaveGames\data.sav";
		var regex = new System.Text.RegularExpressions.Regex("[^a-zA-Z0-9 -_]");
		string fileToPlainText = regex.Replace(File.ReadAllText(filePath), " ");

		// Declaration of some temporary lists.
		List<string> fileList, spList, scList;
		// Here, we split the plain text into separate elements on every string, ignore empty strings,
		// and add all remaining strings to a list. This list will only consist of the finalized
		// strings without any spaces.
		fileList = fileToPlainText.Split(' ').Where(x => !String.IsNullOrEmpty(x)).ToList();

		// This function is used to return the index of the first item of the thing we desire.
		// Using LINQ, we check the index of our parent structure, followed by the first instance
		// of the property of its items after said parent. Adding 1 to this index returns our
		// first item's index.
		Func<string, string, int> startIndex = (parent, propterty) => {
			return fileList
				.Select((s, i) => new { String = s, Index = i })
				.Where(x => x.Index > fileList.IndexOf(parent) && x.String.Contains(propterty))
				.Select(x => x.Index)
				.First() + 1;
		};

		#region Actual Updating
		// Here, we check which of the variables we need to update and execute logic accordingly.

		if (spReset) {
			current.stage = fileList
				.Skip(startIndex("PersistentLevelName", "NameProperty"))
				.Take(1)
				.First();
		}

		if (spChanged) {
			int spAmt = current.savePointsAmount;
			spList = fileList
				.Skip(startIndex("CompletedSavePoints", "NameProperty"))
				.Take(spAmt)
				.ToList();

			current.savePoint = spList[spList.Count - 1];
		}

		if (scChanged) {
			int scAmt = current.secretsAmount;
			scList = fileList
				.Skip(startIndex("SirenSecretUnlockSaveData", "StrProperty"))
				.Where((x, i) => i % 8 == 0)
				.Take(scAmt)
				.ToList();

			current.secret = scList[scList.Count - 1];
		}
		#endregion

		/*
		#region Debug Printing
		// Just a simple StringBuilder to give us some information.
		StringBuilder sBuilder = new StringBuilder();

		sBuilder.Append("All entries:\n");
		foreach (string s in vars.fileToList()) sBuilder.Append(s + "\n");

		sBuilder.Append("\nCurrent Stage:\n");
		sBuilder.Append(current.stage + "\n");

		sBuilder.Append("\nSavePointsList:\n");
		foreach (string s in spList) sBuilder.Append(s + "\n");

		sBuilder.Append("\nSecretsList:\n");
		foreach (string s in scList) sBuilder.Append(s + "\n");

		print(sBuilder.ToString());
		#endregion
		*/
	});

	// This is the function used to split. It is given the old. and current. versions of
	// stage, savePoint, or secret and executes split logic accordingly.
	vars.splitFunc = (Func<string, string, bool>) ((oldString, currString) => {
		bool split = false;
		// We have to check if the new item hasn't already been split on, using our HashSet.
		// If it hasn't, add it to the HashSet and check if the setting for it is turned on.
		if (oldString != currString && !vars.completedSplits.Contains(currString)) {
			vars.completedSplits.Add(currString);
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
	bool scAmtChanged = old.secretsAmount < current.secretsAmount;
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
		vars.splitFunc(old.stage, current.stage);
}

shutdown {
	// Unsubscribe the manual start code from timer.OnStart.
	// This is necessary to not execute the code when the script is unloaded.
	timer.OnStart -= vars.timerStart;
}
