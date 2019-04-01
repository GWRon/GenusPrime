SuperStrict
Import "Dig/base.util.data.xmlstorage.bmx"
Import "Dig/base.util.color.bmx"
Import "game.playerprofile.bmx"



Type TGameConfig
	Field settings:TData
	Field playerProfile:TPlayerProfile
	Field screenWidth:int
	Field screenHeight:int
	Field renderer:int
	Field fullscreen:int
	Field volumeSFX:int
	Field volumeMusic:int


	Method SaveToFile:TGameConfig(uri:string)
		'check directories and create them if needed
		local dirs:string[] = ExtractDir(uri.Replace("\", "/")).Split("/")
		local currDir:string
		for local dir:string = EachIn dirs
			currDir :+ dir + "/"
			'if directory does not exist, create it
			if filetype(currDir) <> 2
				TLogger.Log("TGameConfig.SaveToFile()", "config path contains missing directories. Creating ~q"+currDir[.. currDir.length-1]+"~q.", LOG_SAVELOAD)
				CreateDir(currDir)
			endif
		Next


		local xmlStorage:TDataXMLStorage = new TDataXMLStorage
		xmlStorage.Save(uri, ToData())

		return self
	End Method


	Method LoadFromFile:TGameConfig(uri:string)
		local xmlStorage:TDataXMLStorage = new TDataXMLStorage

		FromData( xmlStorage.Load(uri) )

		return self
	End Method


	Method FromData:TGameConfig(data:TData)
		if not data then data = new TData

		local profileName:string = data.GetString("currentProfile", "default")
		playerProfile = new TPlayerProfile.Initialize().LoadFromFile( TPlayerProfile.GetURI(profileName) )

		volumeSFX = data.GetInt("volume_sfx")
		volumeMusic = data.GetInt("volume_music")
		screenWidth = data.GetInt("screen_width")
		screenHeight = data.GetInt("screen_height")
		renderer = data.GetInt("renderer")

		return self
	End Method


	Method ToData:TData()
		local result:TData = New TData
		if playerProfile then result.AddString("currentProfile", playerProfile.name)

		result.AddString("volume_sfx", volumeSFX)
		result.AddString("volume_music", volumeMusic)
		result.AddString("screen_width", screenWidth)
		result.AddString("screen_height", screenHeight)
		result.AddString("fullscreen", fullscreen)
		result.AddString("renderer", renderer)

		return result
	End Method


	Method GetPlayerName:string()
		if not playerProfile then return "unknown"
		return playerProfile.name
	End Method


	Method GetPlayerProfile:TPlayerProfile()
		if not playerProfile then playerProfile = new TPlayerProfile.Initialize()
		return playerProfile
	End Method


	Method SavePlayerProfile:int()
		if playerProfile
			playerProfile.SaveToFile( TPlayerProfile.GetURI(playerProfile.name) )
			return True
		else
			TLogger.Log("TGameConfig.SavePlayerProfile()", "No player profile to save.", LOG_SAVELOAD)

			return False
		endif
	End Method

End Type

Global GameConfig:TGameConfig = new TGameConfig