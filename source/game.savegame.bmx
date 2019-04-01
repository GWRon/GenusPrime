Type TGameState
	Field _gameSummary:TData = Null
	Field _Game:TGame = Null
	Field _Space:TSpace = Null
	Field _Hud:THud = Null
	Field _EventManagerEvents:TList = Null

'	Field _GameRules:TGamerules = Null
'	Field _GameConfig:TGameConfig = Null
'	Field _PlayerColorList:TList
	Const MODE_LOAD:Int = 0
	Const MODE_SAVE:Int = 1


	Method Initialize:Int()
		TLogger.Log("TGameState.Initialize()", "Reinitialize all game objects", LOG_DEBUG)

'		GameConfig.Initialize()

		'reset player colors
'		TPlayerColor.Initialize()
		'initialize times before other things, as they might rely
		'on that time (eg. TBuildingIntervalTimer) and they would else
		'init with wrong times
'		GetWorldTime().Initialize()

'		GetGame().Initialize()

		'reset all achievements
'		GetAchievementCollection().Reset()
	End Method


	Method RestoreGameData:Int()
'		_Assign(_PlayerColorList, TPlayerColor.List, "PlayerColorList", MODE_LOAD)
'		_Assign(_WorldTime, TWorldTime._instance, "WorldTime", MODE_LOAD)
'		_Assign(_GameRules, GameRules, "GameRules", MODE_LOAD)
'		_Assign(_GameConfig, GameConfig, "GameConfig", MODE_LOAD)
		_Assign(_Game, game, "Game", MODE_LOAD)
		_Assign(_Space, space, "Space", MODE_LOAD)
		_Assign(_Hud, hud, "Hud", MODE_LOAD)
		_Assign(_EventManagerEvents, EventManager._events, "Events", MODE_LOAD)
	End Method


	Method BackupGameData:Int()
		'start with the most basic data, so we avoid that these basic
		'objects get serialized in the depths of more complex objects
		'instead of getting an "reference" there.


'		_Assign(GameRules, _GameRules, "GameRules", MODE_SAVE)
'		_Assign(GameConfig, _GameConfig, "GameConfig", MODE_SAVE)
'		_Assign(TWorldTime._instance, _WorldTime, "WorldTime", MODE_SAVE)

'		_Assign(TPlayerColor.List, _PlayerColorList, "PlayerColorList", MODE_SAVE)
'		_Assign(TPlayerCollection._instance, _PlayerCollection, "PlayerCollection", MODE_SAVE)

		_Assign(game, _Game, "Game", MODE_SAVE)
		_Assign(space, _Space, "Space", MODE_SAVE)
		_Assign(hud, _Hud, "Hud", MODE_SAVE)

		_Assign(EventManager._events, _EventManagerEvents, "Events", MODE_SAVE)
	End Method


	Method _Assign(objSource:Object Var, objTarget:Object Var, name:String="DATA", mode:Int=0)
		If objSource
			objTarget = objSource
			If mode = MODE_LOAD
				TLogger.Log("TGameState.RestoreGameData()", "Restore object "+name, LOG_DEBUG)
			Else
				TLogger.Log("TGameState.BackupGameData()", "Backup object "+name, LOG_DEBUG)
			EndIf
		Else
			TLogger.Log("TGameState", "object "+name+" was NULL - ignored", LOG_DEBUG)
		EndIf
	End Method
End Type



Type TSaveGame Extends TGameState
	'store the time gone since when the app started - timers rely on this
	'and without, times will differ after "loading" (so elevator stops
	'closing doors etc.)
	'this allows to have "realtime" (independend from "logic updates")
	'effects - for visual effects (fading), sound ...
	Field _Time_timeGone:Long = 0
	Field _Entity_globalWorldSpeedFactor:Float =  0
	Field _Entity_globalWorldSpeedFactorMod:Float =  0
	Field _CurrentScreenName:string
	Field _CurrentGameSpeed:int
	Field _GameTimeSpeedFactor:Float
	Field _GameTimePaused:int
	Field _GameTimeGameMillisecs:Long

	Const SAVEGAME_VERSION:string = "12"
	Const MIN_SAVEGAME_VERSION:string = "11"

	'override to do nothing
	Method Initialize:Int()
		'
	End Method


	'override to add time adjustment
	Method RestoreGameData:Int()
		'restore basics _before_ normal data restoration
		'eg. entities might get recreated, so we need to make sure
		'that the "lastID" is restored before

		'restore "time gone since start"
		Time.SetTimeGone(_Time_timeGone)
		'set event manager to the ticks of that time
		EventManager._ticks = _Time_timeGone

		'restore entity speed
		TEntity.globalWorldSpeedFactor = _Entity_globalWorldSpeedFactor
		TEntity.globalWorldSpeedFactorMod = _Entity_globalWorldSpeedFactorMod

		'restore game data
		Super.RestoreGameData()
	End Method


	'override to add time storage
	Method BackupGameData:Int()

		'save a short summary of the game at the begin of the file
		_gameSummary = new TData
		_gameSummary.Add("game_version", VersionString)
		_gameSummary.Add("game_builddate", VersionDate)
		_gameSummary.AddNumber("game_timeGone", GameTime.GetTimeGone())
		_gameSummary.Add("player_name", game.GetPlayer().name)
		_gameSummary.Add("map_galaxy_name", game.galaxyName)
		_gameSummary.Add("map_name", game.mapName)
		_gameSummary.Add("campaign_name", game.campaignName)
		_gameSummary.AddNumber("map_type", game.gameType)
		_gameSummary.Add("savegame_time", Time.GetSystemTime("%Y/%m/%d %H:%M:%S"))
		_gameSummary.Add("savegame_version", SAVEGAME_VERSION)
		'store last ID of all entities, to avoid duplicates
		'store them in game summary to be able to reset before "restore"
		'takes place
		'- game 1 run till ID 1000 and is saved then
		'- whole game is restarted then, ID is again 0
		'- load in game 1 (having game objects with ID 1 - 1000)
		'- new entities would again get ID 1 - 1000
		'  -> duplicates
		_gameSummary.AddNumber("entitybase_lastID", TEntityBase.lastID)
'		_gameSummary.AddNumber("gameobject_lastID", TGameObject.LastID)

		Super.BackupGameData()

		'store "time gone since start"
		_Time_timeGone = Time.GetTimeGone()
		'store entity speed
		_Entity_globalWorldSpeedFactor = TEntity.globalWorldSpeedFactor
		_Entity_globalWorldSpeedFactorMod = TEntity.globalWorldSpeedFactorMod

		'name of the current screen (or base screen)
		_CurrentScreenName = GetScreenManager().GetCurrent().name
		_GameTimeSpeedFactor = GameTime.speedFactor
		_GameTimePaused = GameTime.paused
		_GameTimeGameMillisecs = GameTime.GameMillisecs
	End Method


	'override to output differing log texts
	Method _Assign(objSource:Object Var, objTarget:Object Var, name:String="DATA", mode:Int=0)
		If objSource
			objTarget = objSource

			'uncommented log and update message as the real work is
			'done in the serialization and not in variable=otherVariable
			'assignments
			If mode = MODE_LOAD
				'TLogger.Log("TSaveGame.RestoreGameData()", "Loaded object "+name, LOG_DEBUG | LOG_SAVELOAD)
				'UpdateMessage(True, "Loading: " + name)
			Else
				'TLogger.Log("TSaveGame.BackupGameData()", "Saved object "+name, LOG_DEBUG | LOG_SAVELOAD)
				'UpdateMessage(False, "Saving: " + name)
			EndIf
		Else
			TLogger.Log("TSaveGame", "object "+name+" was NULL - ignored", LOG_DEBUG | LOG_SAVELOAD)
		EndIf
	End Method


	Method CheckGameData:Int()
		'check if all data is available
		Return True
	End Method


	Function GetGameSummary:TData(fileURI:string)
		local stream:TStream = ReadStream(fileURI)
		if not stream
			print "file not found: "+fileURI
			return null
		endif


		local lines:string[]
		local line:string = ""
		local lineNum:int = 0
		local validSavegame:int = False
		While not EOF(stream)
			line = stream.ReadLine()

			'scan bmo version to avoid faulty deserialization
			if line.Find("<bmo ver=~q") >= 0
				local bmoVersion:int = int(line[10 .. line.Find("~q>")])
				if bmoVersion <= 7
					return null
				endif
			endif

			if line.Find("name=~q_Game~q type=~qTGame~q>") > 0
				exit
			endif

			'should not be needed - or might fail if we once have a bigger amount stored
			'in gamesummary then expected
			if lineNum > 1500 then exit

			lines :+ [line]
			lineNum :+ 1
			if lineNum = 4 and line.Find("name=~q___gameSummary~q type=~qTData~q>") > 0
				validSavegame = True
			endif
			if lineNum = 4 and line.Find("name=~q_gameSummary~q type=~qTData~q>") > 0
				validSavegame = True
			endif
		Wend
		CloseStream(stream)
		if not validSavegame
			print "unknown savegamefile"
			return null
		endif

		'remove line 3 and 4
		lines[2] = ""
		lines[3] = ""
		'remove last line / let the bmo-file end there
		lines[lines.length-1] = "</bmo>"

		local content:string = "~n".Join(lines)


		'local p:TPersist = new TPersist
		Local p:TPersist = New TXMLPersistenceBuilder.Build()
		local res:TData = TData(p.DeserializeObject(content))
		if not res then res = new TData
		res.Add("fileURI", fileURI)
		res.Add("fileName", GetSavegameName(fileURI) )
		res.AddNumber("fileTime", FileTime(fileURI))
		p.Free()

		return res
	End Function


	global _nilNode:TNode = new TNode._parent
	Function RepairData()
	End Function


	Function CleanUpData()
	End Function


	Function Load:TSaveGame(saveName:String="savegame.xml")
		'=== CHECK SAVEGAME ===
		If filetype(saveName) <> 1
			TLogger.Log("Savegame.Load()", "Savegame file ~q"+saveName+"~q is missing.", LOG_SAVELOAD | LOG_ERROR)
			return null
		EndIf

		TPersist.maxDepth = 4096*4
		Local persist:TPersist = New TXMLPersistenceBuilder.Build()
		'Local persist:TPersist = New TPersist
'		persist.serializer = new TSavegameSerializer

		local savegameSummary:TData = GetGameSummary(savename)
		'invalid savegame
		if not savegameSummary
			TLogger.Log("Savegame.Load()", "Savegame file ~q"+saveName+"~q is corrupt or too old.", LOG_SAVELOAD | LOG_ERROR)
			return null
		endif

		'reset entity ID
		'this avoids duplicate GUIDs
		TEntityBase.lastID = savegameSummary.GetInt("entitybase_lastID", 3000000)
'		TGameObject.LastID = savegameSummary.GetInt("gameobject_lastID", 3000000)
'		TLogger.Log("Savegame.Load()", "Restored TEntityBase.lastID="+TEntityBase.lastID+", TGameObject.LastID="+TGameObject.LastID+".", LOG_SAVELOAD | LOG_DEBUG)
		TLogger.Log("Savegame.Load()", "Restored TEntityBase.lastID="+TEntityBase.lastID+".", LOG_SAVELOAD | LOG_DEBUG)


		'try to repair older savegames
rem
		if savegameSummary.GetString("game_version") <> VersionString or savegameSummary.GetString("game_builddate") <> VersionDate
			TLogger.Log("Savegame.Load()", "Savegame was created with an older TVTower-build. Enabling basic compatibility mode.", LOG_SAVELOAD | LOG_DEBUG)
			persist.strictMode = False
			persist.converterTypeID = TTypeID.ForObject( new TSavegameConverter )
		endif
endrem

		local loadingStart:int = Millisecs()
		'this creates new TGameObjects - and therefore increases ID count!
?bmxng
		Local saveGame:TSaveGame  = TSaveGame(persist.DeserializeFromFile(savename))
?not bmxng
		Local saveGame:TSaveGame  = TSaveGame(persist.DeserializeFromFile(savename, XML_PARSE_HUGE))
?
		persist.Free()
		If Not saveGame
			TLogger.Log("Savegame.Load()", "Savegame file ~q"+saveName+"~q is corrupt.", LOG_SAVELOAD | LOG_ERROR)
			Return null
		Else
			TLogger.Log("Savegame.Load()", "Savegame file ~q"+saveName+"~q loaded in " + (Millisecs() - loadingStart)+"ms.", LOG_SAVELOAD | LOG_DEBUG)
		EndIf

		If Not saveGame.CheckGameData()
			TLogger.Log("Savegame.Load()", "Savegame file ~q"+saveName+"~q is in bad state.", LOG_SAVELOAD | LOG_ERROR)
			Return null
		EndIf


		'=== RESET CURRENT GAME ===
		'reset game data before loading savegame data
		new TGameState.Initialize()


		'=== LOAD SAVED GAME ===
		'tell everybody we start loading (eg. for unregistering objects before)
		'payload is saveName
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnBeginLoad", New TData.addString("saveName", saveName)))
		'load savegame data into game object
		saveGame.RestoreGameData()

		GameTime.speedFactor = savegame._GameTimeSpeedFactor
		GameTime.paused = savegame._GameTimePaused
		GameTime.GameMillisecs = savegame._GameTimeGameMillisecs
		'tell everybody we finished loading (eg. for clearing GUI-lists)
		'payload is saveName and saveGame-object
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnLoad", New TData.addString("saveName", saveName).add("saveGame", saveGame)))


'		Local playerScreen:TScreen = ScreenCollection.GetScreen(saveGame._CurrentScreenName)
'		ScreenCollection._SetCurrentScreen(playerScreen)



		CleanUpData()
		RepairData()


		'call game that game continues/starts now
'		GetGame().StartLoadedSaveGame()

		Return savegame
	End Function


	Function Save:Int(saveName:String="savegame.xml")
		'check directories and create them if needed
		local dirs:string[] = ExtractDir(saveName.Replace("\", "/")).Split("/")
		local currDir:string
		for local dir:string = EachIn dirs
			currDir :+ dir + "/"
			'if directory does not exist, create it
			if filetype(currDir) <> 2
				TLogger.Log("Savegame.Save()", "Savegame path contains missing directories. Creating ~q"+currDir[.. currDir.length-1]+"~q.", LOG_SAVELOAD)
				CreateDir(currDir)
			endif
		Next
		if filetype(currDir) <> 2
			TLogger.Log("Savegame.Save()", "Failed to create directories for ~q"+saveName+"~q.", LOG_SAVELOAD)
		endif

		Local saveGame:TSaveGame = New TSaveGame
		'tell everybody we start saving
		'payload is saveName
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnBeginSave", New TData.addString("saveName", saveName)))

		'store game data in savegame
		saveGame.BackupGameData()

		'setup tpersist config
		TPersist.format=True
'during development...(also savegame.XML should be savegame.ZIP then)
'		TPersist.compressed = True

'		saveGame.UpdateMessage(False, "Saving: Serializing data to savegame file.")
		TPersist.maxDepth = 4096
		'save the savegame data as xml
		'TPersist.format=False
		Local p:TPersist = New TXMLPersistenceBuilder.Build()
		'local p:TPersist = New TPersist
'		p.serializer = new TSavegameSerializer
		if TPersist.compressed
			p.SerializeToFile(saveGame, saveName+".zip")
		else
			p.SerializeToFile(saveGame, saveName)
		endif
		p.Free()

		'tell everybody we finished saving
		'payload is saveName and saveGame-object
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnSave", New TData.addString("saveName", saveName).add("saveGame", saveGame)))

		Return True
	End Function


	Function GetSavegameName:string(fileURI:string)
		local p:string = GetSavegamePath()
		local r:string
		if p.length > 0 and fileURI.Find( p ) = 0
			r = StripExt( fileURI[ p.length .. ] )
		else
			r = StripDir(StripExt(fileURI))
		endif

		if r.length = 0 then return ""
		if chr(r[0]) = "/" or chr(r[0]) = "\"
			r = r[1 ..]
		endif

		return r
	End Function


	Function GetSavegameURI:string(fileName:string)
		if GetSavegamePath() <> "" then return GetSavegamePath() + "/" + GetSavegameName(fileName) + ".xml"
		return GetSavegameName(fileName) + ".xml"
	End Function


	Function GetSavegamePath:string()
		return "savegames"
	End Function
End Type