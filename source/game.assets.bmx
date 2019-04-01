SuperStrict
Import "Dig/base.framework.entity.spriteentity.bmx"
Import "Dig/base.util.registry.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "Dig/base.util.registry.imageloader.bmx"
Import "game.gamesprite.bmx"
Import "Dig/base.util.registry.bitmapfontloader.bmx"
'Import "Dig/base.util.registry.soundloader.bmx"


Type TAssets
	Field brick:TSprite
	Field bg:TSprite
	Field bgStartScreen:TSprite
	Field logo:TSprite
	Field gameOver:TSprite
	Field mouseCursor:TSprite
	Field initialized:int = False

	global _instance:TAssets


	Function GetInstance:TAssets()
		if not _instance then _instance = new TAssets.Initialize()
		return _instance
	End Function


	Method Initialize:TAssets()
		If initialized and bg then return self

		'=== LOAD XML CONFIGURED RESOURCES ===
		Local registryLoader:TRegistryLoader = New TRegistryLoader
		'"TRUE" indicates that the content has to get loaded immediately
'		registryLoader.LoadFromXML("config/gui.xml", True)
		registryLoader.LoadFromXML("config/assets.xml", True)

rem
		'=== LOAD INDIVIDUAL CONFIGURED RESOURCES ===
		logo = New TSprite.InitFromImage(LoadImage("assets/gfx/logo.png"), "logo")
		gameOver = New TSprite.InitFromImage(LoadImage("assets/gfx/gameover.png"), "gameOver")
		mouseCursor = New TSprite.InitFromImage(LoadAnimImage("assets/gfx/mousecursor.png", 32, 32, 0, 3), "mouseCursor")
		bg = New TSprite.InitFromImage(LoadImage("assets/gfx/bg.png"), "bg")
		'make bg available via registry
		GetRegistry().Set(bg.name, bg)
		'and just fetch that again (this is a sample usage ...)
		bgStartScreen = GetSpriteFromRegistry("bg")
endrem

		'a bitmap font
		'GetBitmapFontManager().Add("default", "path/to/font.ttf", 8)

		'music
		'Local stream:TDigAudioStreamOgg = new TDigAudioStreamOgg.CreateWithFile("path/to/sound.ogg", true)
		'GetSoundManager().AddSound("musicXYZ", stream, "default")
		'sfx
		'GetSoundManager().AddSound("boom", LoadSound("path/to/boom.ogg", SOUND_HARDWARE), "boomSounds")

		'sample when assigning registry entries (eg. GUI sprites loaded by XML)
		'mySprite = GetSpriteFromRegistry("hud_top_right")

		initialized = true
		TLogger.Log("TAssets.Initialize", "Loaded assets", LOG_LOADING)

		return self
	End Method
End Type

Function GetAssets:TAssets()
	return TAssets.GetInstance()
End Function