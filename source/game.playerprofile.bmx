SuperStrict
Import "Dig/base.util.data.xmlstorage.bmx"
Import "Dig/base.util.string.bmx"
Import "Dig/base.util.logger.bmx"



Type TPlayerProfile
	Field file:string
	Field name:string
	Field score:Long = 0
	Field currentLevelNumber:int = 0


	Method Initialize:TPlayerProfile()
		name = GetRandomName()
		currentLevelNumber = 0
		score = 0

		return self
	End Method


	Method GetRandomName:string()
		local names:string[] = ["Santa", "Weihnachtsmann", "Pere Noel", "Joulupukki", "Father Christmas", "Ded Moroz", "Sinterklaas"]
		return names[ rand(0, names.length-1) ]
	End Method


	Method ToData:TData()
		local result:TData = New TData
		result.AddString("name", name)

		result.AddNumber("currentLevelNumber", currentLevelNumber)
		result.AddNumber("score", score)

		return result
	End Method


	Method FromData:TPlayerProfile(data:TData)
		if not data then data = new TData

		name = data.GetString("name", GetRandomName())

		currentLevelNumber = data.GetLong("currentLevelNumber", 0)
		score = data.GetLong("score", 0)
		
		return self
	End Method
	

	Method SaveToFile:TPlayerProfile(uri:string)
		'check directories and create them if needed
		local dirs:string[] = ExtractDir(uri.Replace("\", "/")).Split("/")
		local currDir:string
		for local dir:string = EachIn dirs
			currDir :+ dir + "/"
			'if directory does not exist, create it
			if filetype(currDir) <> 2
				TLogger.Log("TPlayerProfile.SaveToFile()", "profile path contains missing directories. Creating ~q"+currDir[.. currDir.length-1]+"~q.", LOG_SAVELOAD)
				CreateDir(currDir)
			endif
		Next

		local xmlStorage:TDataXMLStorage = new TDataXMLStorage
		xmlStorage.Save(uri, ToData())

		return self
	End Method


	Method LoadFromFile:TPlayerProfile(uri:string)
		local xmlStorage:TDataXMLStorage = new TDataXMLStorage

		FromData( xmlStorage.Load(uri) )

		return self
	End Method


	Function GetURI:string(name:string)
		local cleaned:string = StringHelper.RemoveNonAlphaNum( StringHelper.RemoveUmlauts( name ) ).ToLower()
		if cleaned = "" then cleaned = "default"
		
		return "config/profiles/"+cleaned+".xml"
	End Function
	

	'=== GETTERS / SETTERS ===
	'add setXYZ and getXYZ() here
	'(especially for things like arrays which need boundary checks)
	
End Type