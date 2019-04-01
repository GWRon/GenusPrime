SuperStrict
Import "Dig/base.gfx.sprite.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "game.gamecolors.bmx"
Import Brl.Map

'register this loader
new TRegistryGameSpriteLoader.Init()



'===== PACK IMPLEMENTATION =====
Type TGameSpritePack extends TSpritePack
	Field baseImage1:TImage
	Field baseImage2:TImage

	Method Init:TGameSpritePack(image:TImage, name:string)
		local palettedImage:TImage
		CreatePalettedImage(image, palettedImage)

		Super.Init(palettedImage, name)

		CreatePalettedImageVariants(palettedImage, baseImage1, baseImage2)
		return self
	End Method


	Method GetImage:TImage()
		if not GameColorCollection.alternatePalettes then return image
		'only one color defined
		if not baseImage1 or not baseImage2 then return image

		if GameColorCollection.evenFrame
			return baseImage1
		else
			return baseImage2
		endif
	End Method
End Type


'no difference for now
Type TGameSprite extends TSprite
End Type


'helper
'creates a image only using colors of the palette
Function CreatePalettedImage:int(sourceImage:TImage, targetImage:Timage var)
	if not targetImage then targetImage = CreateImage(sourceImage.width, sourceImage.height, 1, DYNAMICIMAGE)
	local sourcePix:TPixmap = LockImage(sourceImage)
	local targetPix:TPixmap = LockImage(targetImage)

	For local x:int = 0 until sourcePix.width
		For local y:int = 0 until sourcePix.height
			local sourceColor:TColor = new TColor.FromInt( sourcePix.ReadPixel(x,y) )
			if sourceColor.a = 0
				targetPix.WritePixel(x,y, sourceColor.ToInt() )
			else
				local similarColor:TGameColor = GameColorCollection.FindSimilar(sourceColor)
				targetPix.WritePixel(x,y, similarColor.GetEffectiveColor().ToInt() )
			endif
		Next
	Next
End Function


'helper
'creates two images which "drawn alternated" show the original color
Function CreatePalettedImageVariants:int(sourceImage:TImage, targetImage1:Timage var, targetImage2:TImage var)
	if not targetImage1 then targetImage1 = CreateImage(sourceImage.width, sourceImage.height, 1, DYNAMICIMAGE)
	if not targetImage2 then targetImage2 = CreateImage(sourceImage.width, sourceImage.height, 1, DYNAMICIMAGE)

	local sourcePix:TPixmap = LockImage(sourceImage)
	local targetPix1:TPixmap = LockImage(targetImage1)
	local targetPix2:TPixmap = LockImage(targetImage2)
	local imagesDiffer:int = False

	'clear targets: needed as all get overwritten?
	'targetPix1.ClearPixels(0)
	'targetPix2.ClearPixels(0)

	local colorsUsed:TIntMap = new TIntMap

	For local x:int = 0 until sourcePix.width
		For local y:int = 0 until sourcePix.height
			local sourceColor:TColor = new TColor.FromInt( sourcePix.ReadPixel(x,y) )
			if sourceColor.a = 0
				targetPix1.WritePixel(x,y, sourceColor.ToInt() )
				targetPix2.WritePixel(x,y, sourceColor.ToInt() )
			else
				local similarColor:TGameColor = GameColorCollection.FindSimilar(sourceColor)
				colorsUsed.Insert(similarColor.GetEffectiveColor().ToInt(), similarColor)
				'print sourceColor.ToRGBString(",") +"  ->  " + similarColor.GetBaseColor(1).ToRGBString(",") + " / " + similarColor.GetBaseColor(2).ToRGBString(",")
				'if x mod 5 = 0 then print similarColor.ToRGBString(",")
				targetPix1.WritePixel(x,y, similarColor.GetBaseColor(1).ToInt() )
				'if similarColor.GetBaseColor(1).ToInt() <> similarColor.GetBaseColor(2).ToInt()
					targetPix2.WritePixel(x,y, similarColor.GetBaseColor(2).ToInt() )
				'endif
			endif
		Next
	Next
rem
	local c:int = 0
	for local v:object = EachIn colorsUsed.values()
		local col:TGameColor = TGameColor(v)
		if col
			if col.baseColor2
				print "color #"+RSet((c+1),3).Replace(" ","0")+":  " + col.GetEffectiveColor().ToString()+"  ("+col.baseColor1.ToString() + " + " + col.baseColor2.ToString()+")"
			else
				print "color #"+RSet((c+1),3).Replace(" ","0")+":  " + col.GetEffectiveColor().ToString()
			endif
		endif
		c :+ 1
	next
	print c
endrem
	return True

End Function




'===== LOADER IMPLEMENTATION =====
'loader caring about "<gamespritepack>"-types
Type TRegistryGameSpriteLoader extends TRegistrySpriteLoader
	Method Init:Int()
		name = "Sprite"
		'we also load each image as sprite
		'resourceNames = "gamesprite|gamespritepack"
		resourceNames = "gamespritepack"
		if not registered then Register()
	End Method


	'creates - modifies default resource
	Method CreateDefaultResource:Int()
		if _createdDefaults then return FALSE

		local img:TImage = TImage(GetRegistry().GetDefault("image"))
		if not img then return FALSE

		local gameSprite:TGameSprite = new TGameSprite
		gameSprite.InitFromImage(img, "defaultgamesprite")
		'try to find a nine patch pattern
		gameSprite.EnableNinePatch()

		GetRegistry().SetDefault("gamesprite", gameSprite)
		GetRegistry().SetDefault("gamespritepack", gameSprite.parent)

		_createdDefaults = TRUE
	End Method


	Method LoadFromConfig:object(data:TData, resourceName:string)
		resourceName = resourceName.ToLower()

		'if resourceName = "gamesprite" then return LoadSpriteFromConfig(data)

		if resourceName = "gamespritepack" then return LoadSpritePackFromConfig(data)
	End Method


rem
	Method LoadSpriteFromConfig:TGameSprite(data:TData)
		local gamesSprite:TGameSprite = new TGameSprite.InitFromConfig(data)
		if not gamesSprite
			TLogger.Log("TRegistryGameSpriteLoader.LoadSpriteFromConfig()", "File ~q"+data.GetString("url")+"~q could not be loaded as gamesprite.", LOG_ERROR)
			return Null
		endif

		'add to registry
		GetRegistry().Set(GetNameFromConfig(data), gamesSprite)

		'load potential new sprites from scripts
		LoadScriptResults(data, gamesSprite)

		'indicate that the loading was successful
		return gamesSprite
	End Method
endrem


	Method LoadSpritePackFromConfig:TGameSpritePack(data:TData)
		local url:string = data.GetString("url")
		if url = ""
			TLogger.Log("TRegistryGameSpriteLoader.LoadSpritePackFromConfig()", "Url is missing.", LOG_ERROR)
			return Null
		endif

		'Print "LoadSpritePackResource: "+data.GetString("name") + " ["+url+"]"
		Local img:TImage = LoadImage(url, data.GetInt("flags", 0))
		'just return - so requests to the sprite should be using the
		'registries "default sprite" (if registry is used)
		if not img
			TLogger.Log("TRegistryGameSpriteLoader.LoadSpritePackFromConfig()", "File ~q"+url+"~q is missing or corrupt.", LOG_ERROR)
			return Null
		endif

		Local spritePack:TGameSpritePack = new TGameSpritePack.Init(img, data.GetString("name"))
		'add spritepack to asset
		GetRegistry().Set(spritePack.name, spritePack)

		'add children
		local childrenData:TData[] = TData[](data.Get("childrenData"))

		For local childData:TData = eachin childrenData
			'add spritepack as parent
			childData.Add("parent", spritePack)

			Local sprite:TGameSprite = new TGameSprite
			sprite.InitFromConfig(childData)

			GetRegistry().Set(childData.GetString("name"), sprite)
		Next

		'load potential new sprites from scripts
		LoadScriptResults(data, spritePack)

		'indicate that the loading was successful
		return spritePack
	End Method
End Type


'===== CONVENIENCE REGISTRY ACCESSORS =====
Function GetGameSpritePackFromRegistry:TGameSpritePack(name:string, defaultNameOrSpritePack:object = Null)
	Return TGameSpritePack( GetRegistry().Get(name, defaultNameOrSpritePack, "gamespritepack") )
End Function


Function GetGameSpriteFromRegistry:TSprite(name:string, defaultNameOrSprite:object = Null)
	Return TGameSprite( GetRegistry().Get(name, defaultNameOrSprite, "gamesprite") )
End Function