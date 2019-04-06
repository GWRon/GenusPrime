SuperStrict
Framework Brl.StandardIO

Import "source/Dig/base.util.directorytree.bmx"
Import "source/Dig/base.gfx.gui.dropdown.bmx"
Import "source/Dig/base.gfx.gui.list.selectlist.bmx"
Import "source/Dig/base.gfx.gui.button.bmx"
Import "source/Dig/base.gfx.gui.input.bmx"
Import "source/Dig/base.gfx.gui.checkbox.bmx"
Import "source/Dig/base.gfx.gui.slider.bmx"
Import "source/Dig/base.util.registry.soundloader.bmx"
?bmxng
Import "source/Dig/external/persistence.mod/persistence_mxml.bmx"
?Not bmxng
Import "source/Dig/external/persistence.mod/persistence.bmx"
?
Import "source/game.main.bmx"
Import "source/game.gametime.bmx"
'Import "source/game.world.worldtime.bmx"
'Import "Dig/base.gfx.sprite.bmx"


Rem
	INTER SOLAR SUPPORT

	-> Timer pro Rasse bei der Support durch "Portal" kommt
	-> Portal benoetigt einen Planeten ("blauer wachsender Kreis drum herum bei Ankunft")
	-> kann  bei Missionen Zeitdruck "bis dahin geschafft" ausueben
endrem


Incbin "source/version.txt"
Global VersionDate:String = LoadText("incbin::source/version.txt").Trim()
Global VersionNumberString:String = "v1.0.2"
Global VersionString:String = VersionNumberString + " Build ~q" + VersionDate + "~q"
Global CopyrightString:String = "by Ronny Otto aka ~qDerron~q"

Global APP_NAME:String = "Genus Prime"
Global LOG_NAME:String = "log.profiler.txt"

'on a windows notebook ships flickered during movement
Global AVOID_FLICKERING:Int = False
'FLICKERN AUS?!
GameColorCollection.alternatePalettes = True

Global DEV_MODE:Int = False

Global titleScreen:TGameSpritePack = New TGameSpritePack.Init(LoadImage("assets/gfx/title_screen.png",0), "titlescreen")


'register toaster position: position, alignment, name
GetToastMessageCollection().AddNewSpawnPoint( New TRectangle.Init(2,7, 90,100), New TVec2D.Init(0,0), "TOPLEFT" )
GetToastMessageCollection().AddNewSpawnPoint( New TRectangle.Init(245,7, 90,100), New TVec2D.Init(1,0), "TOPRIGHT" )
GetToastMessageCollection().AddNewSpawnPoint( New TRectangle.Init(2,91, 90,100), New TVec2D.Init(0,1), "BOTTOMLEFT" )
GetToastMessageCollection().AddNewSpawnPoint( New TRectangle.Init(245,91, 90,100), New TVec2D.Init(1,1), "BOTTOMRIGHT" )
TToastMessage.defaultDimension.SetXY(90, 20)
TToastMessage.defaultLifeTimeBarHeight = 2
TToastMessage.defaultLifeTimeBarColor = GameColorCollection.basePalette[14]
TToastMessage.defaultLifeTimeBarBottomY = 5
TToastMessage.defaultTextOffset = New TVec2D.Init(3,3)

Global game:TGame
Global gameStats:TGameStats
Global space:TSpace
Global hud:THud
Global app:TMyApp = New TMyApp
Global MessageWindowCollection:TMessageWindowCollection = New TMessageWindowCollection
Global SimpleSoundSource:TSimpleSoundSource = New TSimpleSoundSource


Rem
local oldF:Float
local newF:Float
for local i:int = 1 to 500
'	newF = (Helper.LogisticalInfluence_Tangens(i/500.0, 0.99))
	newF = (Helper.LogisticalInfluence_Euler(i/500.0, 5))
	print Rset(i, 4)+":"+ RSet(newF,15) + "   +"+RSet(newF-oldF, 15)
	oldF = newF
next
end
endrem

'app._customUpdateFunction = UpdateGameWorld
'app._customRenderFunction = RenderGameWorld
app._customPrepareFunction = PrepareGameWorld
app.Init(30, 30, 60)

app.SetTitle("Genus Prime " + VersionString)
app.Run()



Function PrepareGameWorld:Int()
	app.autoCLS = True 'solange kein Hintergrundbild
	SetBlend(MASKBLEND) ' NO ALPHA - but allow "full transparency"!!

	For Local pixelFontName:String = EachIn ["", ".yellow", ".gray"]
		Local pixelFont:TSpritePackBitmapFont = TSpritePackBitmapFont.Create("pixelfont"+pixelFontName, "pixelfontsprite"+pixelFontName, 4, 0)
		pixelFont.lineHeightModifier = 1.4
		GetBitmapFontManager().AddFont(pixelFont)
	Next

	SetImageFont( LoadImageFont("assets/fonts/pzim3x5_fixed.ttf", 10, 0))


	Local playerCount:Int = 4
	hud = New THud
	game = New TGame


'	Print "Loading campaigns ... "
	GetCampaignCollection().LoadCampaignsInDirectory("assets/maps")



	'=== CREATE SCREENS ===
	GetScreenManager().Set(New TScreen_MainMenu.Init("mainmenu"))
	GetScreenManager().Set(New TScreen_InGame.Init("ingame"))
	GetScreenManager().Set(New TScreen_SkirmishMenu.Init("skirmishmenu"))
	GetScreenManager().Set(New TScreen_CampaignMenu.Init("campaignmenu"))
	'set the active one
	GetScreenManager().SetCurrent( GetScreenManager().Get("mainmenu") )

	GetGraphicsManager().SetVsync(True)
End Function



Type TBackgroundStarsPanel
	Field stars:TBackgroundStar[]

	Method New()
		Local gm:TGraphicsManager = GetGraphicsManager()
		stars = New TBackgroundStar[150]
		For Local i:Int = 0 Until stars.length
			stars[i] = New TBackgroundStar
			'TODO: Abstand zu anderen Planeten und Sternen!
			stars[i].position = New TVec3D.Init(RandRange(10, gm.GetWidth()-10), RandRange(10, gm.GetHeight()-10), -0.5 -0.05 * RandRange(1, 10))
		Next
	End Method


	Method Update:Int()
		For Local star:TBackgroundStar = EachIn stars
			star.Update()
		Next
	End Method


	Method Render:Int()
		For Local star:TBackgroundStar = EachIn stars
			star.Render()
		Next
	End Method
End Type




Type TGameScreen Extends TScreen
	Method Render:Int() 'override

	End Method


	Method Update:Int() 'override
'		Super.Update()

		If KeyManager.IsHit(KEY_F8)
			TGame.LoadGame("savegames/quicksave.xml")
		EndIf
		Return True
	End Method
End Type




Type TScreen_MainMenu Extends TGameScreen
	Field guiStartCampaignButton:TGameGUIButton
	Field guiStartRandomButton:TGameGUIButton
	Field guiSkirmishButton:TGameGUIButton
	Field guiLoadButton:TGameGUIButton
	Field guiSettingsButton:TGameGUIButton
	Field guiQuitButton:TGameGUIButton
	Field backgroundStarsPanel:TBackgroundStarsPanel
	Field lsScreenKey:TLowerString = New TLowerString.Create("MAINMENU")

	Field _eventListeners:TLink[]


	Method Init:TScreen_MainMenu(name:String)
		Super.Init(name)
		fadeInEffect = New TScreenFaderRectGrid
		fadeOutEffect = New TScreenFaderRectGrid

		backgroundStarsPanel = New TBackgroundStarsPanel

		Local startX:Int = 17
		Local widthX:Int = 43
		Local spacingX:Int = 49
		guiStartCampaignButton = New TGameGUIButton.Create(New TVec2D.Init(startX + 0*spacingX, 160), New TVec2D.Init(widthX, 17), "New~nCampaign", lsScreenKey.ToString())
		guiLoadButton = New TGameGUIButton.Create(New TVec2D.Init(startX + 1*spacingX, 160), New TVec2D.Init(widthX, 17), "Load~nGame", lsScreenKey.ToString())
		guiStartRandomButton = New TGameGUIButton.Create(New TVec2D.Init(startX + 2*spacingX, 160), New TVec2D.Init(widthX, 17), "Random~nGame", lsScreenKey.ToString())
		guiSkirmishButton = New TGameGUIButton.Create(New TVec2D.Init(startX + 3*spacingX, 160), New TVec2D.Init(widthX, 17), "Skirmish~nGame", lsScreenKey.ToString())
		guiSettingsButton = New TGameGUIButton.Create(New TVec2D.Init(startX + 4*spacingX, 160), New TVec2D.Init(widthX, 17), "Settings", lsScreenKey.ToString())
		guiQuitButton = New TGameGUIButton.Create(New TVec2D.Init(startX + 5*spacingX, 160), New TVec2D.Init(widthX, 17), "Quit", lsScreenKey.ToString())


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = New TLink[0]

		'=== register event listeners
		_eventListeners :+ [ EventManager.registerListenerMethod( "guiobject.onclick", Self, "onButtonClick", guiStartCampaignButton ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod( "guiobject.onclick", Self, "onButtonClick", guiSettingsButton ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod( "guiobject.onclick", Self, "onButtonClick", guiSkirmishButton ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod( "guiobject.onclick", Self, "onButtonClick", guiStartRandomButton ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod( "guiobject.onclick", Self, "onButtonClick", guiLoadButton ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod( "guiobject.onclick", Self, "onButtonClick", guiQuitButton ) ]


		Return Self
	End Method


	Method PrepareStart:Int() 'override
		Super.PrepareStart()

		If game.GetCampaignMapsWon() > 0
			guiStartCampaignButton.SetCaption("Continue~nCampaign")
		EndIf

		If Not GetSoundManager().isPlaying() Then GetSoundManager().PlayMusicPlaylist("menu")
	End Method


	'remove all messagewindows
	Method Kill:Int() 'override
		MessageWindowCollection.RemoveByScreenLimit("mainmenu")

		Return Super.Kill()
	End Method



	Method onButtonClick:Int(triggerEvent:TEventBase)
		Select triggerEvent.GetSender()
			Case guiStartRandomButton
				StartRandomGame()
			Case guiStartCampaignButton
				GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("campaignmenu"), 0.2 )
			Case guiSkirmishButton
				GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("skirmishmenu"), 0.2 )
			Case guiQuitButton
				app.exitApp = True
			Case guiSettingsButton
				MessageWindowCollection.OpenSettings( GetGraphicsManager().GetWidth()/2 )
			Case guiLoadButton
				MessageWindowCollection.OpenLoadMenu( GetGraphicsManager().GetWidth()/2 )
		End Select
	End Method


	Method StartRandomGame:Int()
		If hud
			hud.Reset()
		Else
			hud = New THud
		EndIf

		game.Reset()
		game.SetPaused(True)
		Local playerCount:Int = RandRange(2,6)
		game.InitNewRandomGame(playerCount, playerCount * RandRange(1,2) + playerCount/2, -1, -1)
		game.Start()

		GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("ingame"), 0.2 )
	End Method


	Method Render:Int() 'override
		SetColor 0,0,0
		DrawRect(0,0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
		SetColor 255,255,255

		backgroundStarsPanel.Render()

		DrawImage(titleScreen.GetImage(), 0,0)

		GetBitmapFont("pixelfont", 4).DrawBlock(VersionNumberString + " by Ronny Otto", 0, GetGraphicsManager().GetHeight() - 6, GetGraphicsManager().GetWidth()-1, 8, ALIGN_RIGHT_TOP)

		GuiManager.Draw(lsScreenKey)

		MessageWindowCollection.Render("mainmenu")
	End Method


	Method Update:Int() 'override
		backgroundStarsPanel.Update()

		MessageWindowCollection.Update("mainmenu")

		GuiManager.Update(lsScreenKey)


		If KeyManager.IsHit(KEY_F8)
			TGame.LoadGame("savegames/quicksave.xml")
		EndIf

	End Method
End Type




Type TScreen_SkirmishMenu Extends TGameScreen
	Field guiRaceSelect:TGameGUIDropDown[]
	Field guiDifficultySelect:TGameGUIDropDown[]
	Field guiStartButton:TGameGUIButton
	Field guiMapSizeXInput:TGameGUIInput
	Field guiMapSizeYInput:TGameGUIInput
	Field guiMapSizePresets:TGameGUIButton[]
	Field guiMapPlanetsInput:TGameGUIInput
	Field backgroundStarsPanel:TBackgroundStarsPanel
	Field lsScreenKey:TLowerString = New TLowerString.Create("SKIRMISHMENU")
	Field assignedRaces:Int[] = New Int[6] '0 = player
	Field assignedDifficulties:Int[] = [1,1,1,1,1]
	Field mapSizeX:Int
	Field mapSizeY:Int
	Field mapPlanets:Int = 10
	Field changedAssignedRaces:Int = False
	Field ignoreGUIRaceSelectChanges:Int = False

	Field _eventListeners:TLink[]


	Method New()
		mapSizeX = game.defaultMapSizeX
		mapSizeY = game.defaultMapSizeY
	End Method


	Method Init:TScreen_SkirmishMenu(name:String)
		Super.Init(name)
		fadeInEffect = New TScreenFaderRectGrid
		fadeOutEffect = New TScreenFaderRectGrid

		backgroundStarsPanel = New TBackgroundStarsPanel

'		assignedRaces = New Int[6]

		guiRaceSelect = New TGameGUIDropDown[6]
		guiDifficultySelect = New TGameGUIDropDown[5]
		For Local i:Int = 0 Until 6
			guiRaceSelect[i] = New TGameGUIDropDown_Race.Create(New TVec2D.Init(60, 30 + (i+1)*20 - 4),New TVec2D.Init(65, 15), "", 100, lsScreenKey.ToString())
			guiRaceSelect[i].SetListContentHeight(4 * 10)

		Next
		For Local i:Int = 0 Until 5
			guiDifficultySelect[i] = New TGameGUIDropDown.Create(New TVec2D.Init(130, 30 + (i+2)*20 - 4),New TVec2D.Init(40, 15), "", 100, lsScreenKey.ToString())
			guiDifficultySelect[i].SetListContentHeight(5 * 10)
			guiDifficultySelect[i].AddItem(New TGameGUIDropDownItem.Create(Null, Null, "NOOB").SetExtra("50"))
			guiDifficultySelect[i].AddItem(New TGameGUIDropDownItem.Create(Null, Null, "EASY").SetExtra("75"))
			guiDifficultySelect[i].AddItem(New TGameGUIDropDownItem.Create(Null, Null, "NORM").SetExtra("100"))
			guiDifficultySelect[i].AddItem(New TGameGUIDropDownItem.Create(Null, Null, "HARD").SetExtra("150"))
			guiDifficultySelect[i].AddItem(New TGameGUIDropDownItem.Create(Null, Null, "PRO").SetExtra("200"))
			guiDifficultySelect[i].SetSelectedEntryByPos( assignedDifficulties[i] )
		Next
		UpdateGUIRaceSelects()

		guiMapSizePresets = New TGameGUIButton[4]
		For Local i:Int = 0 Until guiMapSizePresets.length
			guiMapSizePresets[i] = New TGameGUIButton.Create(New TVec2D.Init(233 + i*16, 55), New TVec2D.Init(14, 15), (i+1), lsScreenKey.ToString())
		Next
		guiMapSizeXInput = New TGameGUIInput.Create(New TVec2D.Init(232, 40), New TVec2D.Init(32, 14), mapSizeX, 4, lsScreenKey.ToString())
		guiMapSizeYInput = New TGameGUIInput.Create(New TVec2D.Init(263, 40), New TVec2D.Init(32, 14), mapSizeY, 4, lsScreenKey.ToString())

		guiMapPlanetsInput = New TGameGUIInput.Create(New TVec2D.Init(263, 80), New TVec2D.Init(32, 14), mapPlanets, 2, lsScreenKey.ToString())

		guiStartButton = New TGameGUIButton.Create(New TVec2D.Init(200, 164), New TVec2D.Init(95, 17), "Start Game", lsScreenKey.ToString())


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = New TLink[0]

		'=== register event listeners
		'to react on changes in the programmeCollection (eg. custom script finished)
		For Local i:Int = 0 Until 6
			_eventListeners :+ [ EventManager.registerListenerMethod( "GUIDropDown.onSelectEntry", Self, "onRaceDropDownSelectEntry", guiRaceSelect[i] ) ]
		Next
		For Local i:Int = 0 Until 5
			_eventListeners :+ [ EventManager.registerListenerMethod( "GUIDropDown.onSelectEntry", Self, "onDifficultyDropDownSelectEntry", guiDifficultySelect[i] ) ]
		Next
		For Local i:Int = 0 Until 4
			_eventListeners :+ [ EventManager.registerListenerMethod( "guiobject.onclick", Self, "onButtonClick", guiMapSizePresets[i] ) ]
		Next

		_eventListeners :+ [ EventManager.registerListenerMethod( "guiinput.onChangeValue", Self, "onChangeInputValue", guiMapPlanetsInput ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod( "guiinput.onChangeValue", Self, "onChangeInputValue", guiMapSizeXInput ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod( "guiinput.onChangeValue", Self, "onChangeInputValue", guiMapSizeYInput ) ]

		_eventListeners :+ [ EventManager.registerListenerMethod( "guiobject.onclick", Self, "onButtonClick", guiStartButton ) ]


		Return Self
	End Method


	Method onButtonClick:Int(triggerEvent:TEventBase)
		Select triggerEvent.GetSender()
			Case guiStartButton
				StartGame()
			Case guiMapSizePresets[0]
				guiMapSizeXInput.SetValue(game.defaultMapSizeX * 1)
				guiMapSizeYInput.SetValue(game.defaultMapSizeY * 1)
			Case guiMapSizePresets[1]
				guiMapSizeXInput.SetValue(game.defaultMapSizeX * 2)
				guiMapSizeYInput.SetValue(game.defaultMapSizeY * 1)
			Case guiMapSizePresets[2]
				guiMapSizeXInput.SetValue(game.defaultMapSizeX * 2)
				guiMapSizeYInput.SetValue(game.defaultMapSizeY * 2)
			Case guiMapSizePresets[3]
				guiMapSizeXInput.SetValue(game.defaultMapSizeX * 3)
				guiMapSizeYInput.SetValue(game.defaultMapSizeY * 2)
		End Select
	End Method


	Method onChangeInputValue:Int(triggerEvent:TEventBase)
		Select triggerEvent.GetSender()
			Case guiMapPlanetsInput
				mapPlanets = Int(guiMapPlanetsInput.GetValue())
			Case guiMapSizeXInput
				mapSizeX = Int(guiMapSizeXInput.GetValue())
			Case guiMapSizeYInput
				mapSizeY = Int(guiMapSizeYInput.GetValue())
		End Select
	End Method


	Method onRaceDropDownSelectEntry:Int(triggerEvent:TEventBase)
		If ignoreGUIRaceSelectChanges Then Return True

		Local dropdown:TGUIDropDown = TGUIDropDown( triggerEvent.GetSender() )
		For Local i:Int = 0 Until 6
			If guiRaceSelect[i] = dropdown
				assignedRaces[i] = Int(String(TGUIDropDownItem(dropdown.GetSelectedEntry()).extra))
				changedAssignedRaces = True
				Return True
			EndIf
		Next
		Return False
	End Method


	Method onDifficultyDropDownSelectEntry:Int(triggerEvent:TEventBase)
'		if ignoreGUIRaceSelectChanges then return True

		Local dropdown:TGUIDropDown = TGUIDropDown( triggerEvent.GetSender() )
		For Local i:Int = 0 Until 5
			If guiDifficultySelect[i] = dropdown
				assignedDifficulties[i] = Int(String(TGUIDropDownItem(dropdown.GetSelectedEntry()).extra))
				Return True
			EndIf
		Next
		Return False
	End Method


	'remove all messagewindows
	Method Kill:Int() 'override
		MessageWindowCollection.RemoveByScreenLimit("skirmishmenu")
Rem
	We do not DESTROY, we just set the screen inactive!

		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = New TLink[0]


		For Local g:TGUIObject = EachIn guiRaceSelect
			GuiManager.Remove(g)
		Next

		For Local g:TGUIObject = EachIn guiDifficultySelect
			GuiManager.Remove(g)
		Next

		For Local g:TGUIObject = EachIn guiMapSizePresets
			GuiManager.Remove(g)
		Next

		GuiManager.Remove(guiMapSizeXInput)
		GuiManager.Remove(guiMapSizeYInput)
		GuiManager.Remove(guiPlanetsInput)
endrem

		Return Super.Kill()
	End Method


	Method StartGame:Int()
		'=== START NEW GAME ===
		If hud
			hud.Reset()
		Else
			hud = New THud
		EndIf

		game.Reset()
		game.SetPaused(True)
		game.InitNewGame(TGame.GAMETYPE_SKIRMISH, assignedRaces, [1] + assignedDifficulties, mapPlanets, mapSizeX, mapSizeY)
		game.Start()

		GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("ingame"), 0.2 )
	End Method


	Method GetAvailableRaces:Int[](addRaces:Int[])
		Local result:Int[]

		For Local i:Int = 1 To 6
			If Not MathHelper.InIntArray(i, assignedRaces) Or MathHelper.InIntArray(i, addRaces)
				result :+ [i]
			EndIf
		Next
		Return result
	End Method


	Method GetUsedRaces:Int[]()
		Local result:Int[]

		For Local i:Int = 1 To 6
			If MathHelper.InIntArray(i, assignedRaces)
				result :+ [i]
			EndIf
		Next
		Return result
	End Method


	Method UpdateGUIRaceSelects()
		ignoreGUIRaceSelectChanges = True

		Local availableRaces:Int[] = [1,2,3,4,5,6]

		'mark all currently used races
		Local usedRaces:Int[] = GetUsedRaces()


		For Local i:Int = 0 Until 6
			Local added:Int = 0
			guiRaceSelect[i].EmptyList()

			If i > 0
				guiRaceSelect[i].AddItem(New TGameGUIDropDownItem_Race.Create(Null, Null, "NONE").SetExtra("0"))
				added :+ 1
			EndIf

			'add all not yet used
			Local availableRaces:Int[] = GetAvailableRaces( [assignedRaces[i]] )
'print "  player " + (i+1)+": " + StringHelper.JoinIntarray(", ", availableRaces) +"   assigned="+assignedRaces[i]
			For Local raceNum:Int = EachIn availableRaces
				If raceNum = 0 Then Continue 'already handled NONE

				guiRaceSelect[i].AddItem(New TGameGUIDropDownItem_Race.Create(Null, Null, game.racesNames[ raceNum -1 ]).SetExtra(String(raceNum)) )
				added :+ 1
			Next
			guiRaceSelect[i].SetListContentHeight(added * 10)

			'select none if race is no longer available
			If Not MathHelper.InIntArray(assignedRaces[i], availableRaces)
				guiRaceSelect[i].SetSelectedEntryByPos( 0 )
				assignedRaces[i] = 0

				If i > 0 Then guiDifficultySelect[i-1].Hide()

			Else
				If i > 0 Then guiDifficultySelect[i-1].Show()
			EndIf


			'first player - select first race if not done yet
			If i = 0 And assignedRaces[i] = 0
				guiRaceSelect[i].SetSelectedEntryByPos( 0 )
				assignedRaces[i] = availableRaces[0]
			EndIf
		Next

		ignoreGUIRaceSelectChanges = False
	End Method


	Method Render:Int() 'override
		SetColor 0,0,0
		DrawRect(0,0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
		SetColor 255,255,255

		backgroundStarsPanel.Render()

		DrawImage(titleScreen.GetImage(), 0,0)

		Rem
		GameColorCollection.basePalette[0].SetRGB()
		GetSpriteFromRegistry("pattern.hlines1").TileDraw(0,0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
		SetColor 255,255,255
		endrem

		GameColorCollection.basePalette[0].SetRGB()
		GetSpriteFromRegistry("pattern.dots2").TileDraw(0,0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
'		GetSpriteFromRegistry("pattern.dots2").TileDraw(- (Time.GetTimeGone()/2500 mod 6),0, GetGraphicsManager().GetWidth() + 6, GetGraphicsManager().GetHeight())
'		GetSpriteFromRegistry("pattern.diagonal1").TileDraw(0,0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
		SetColor 255,255,255


		GetSpriteFromRegistry("messagewindow.big.bg").DrawArea(15, 10, 165, 180)

		GetSpriteFromRegistry("messagewindow.bg").DrawArea(190, 20, 115, 125)

		GetSpriteFromRegistry("messagewindow.bg").DrawArea(190, 155, 115, 35)

		GetBitmapFont("small",, BOLDFONT).DrawBlock("Skirmish Game", 20, 14+1, 165-2, 20, ALIGN_CENTER_TOP, GameColorCollection.basePalette[0])
		GetBitmapFont("small",, BOLDFONT).DrawBlock("Skirmish Game", 20, 14, 165-2, 20, ALIGN_CENTER_TOP, GameColorCollection.basePalette[1])

		GetBitmapFont("default").DrawBlock("Player Settings", 25, 30, 150, 20, ALIGN_LEFT_TOP, GameColorCollection.basePalette[1])

		GetBitmapFont("default").DrawBlock("Map Settings", 200, 30, 150, 20, ALIGN_LEFT_TOP, GameColorCollection.basePalette[1])

		Local f:TBitmapFont = GetBitmapFont("small")

		f.Draw("size:", 200, 44, GameColorCollection.basePalette[1])
		f.Draw("Planets:", 200, 84, GameColorCollection.basePalette[1])

		f.DrawBlock("Player", 25, 50 + 0*20, 150, 20, ALIGN_LEFT_TOP, GameColorCollection.basePalette[1])
		For Local i:Int = 1 To 5
			f.DrawBlock("CPU " + i, 25, 50 + i*20, 150, 20, ALIGN_LEFT_TOP, GameColorCollection.basePalette[1])
		Next

		GuiManager.Draw(lsScreenKey)

		MessageWindowCollection.Render("skirmishmenu")
	End Method


	Method Update:Int() 'override
		Super.Update()
		If changedAssignedRaces
			Repeat
				changedAssignedRaces = False
				UpdateGUIRaceSelects()
			Until changedAssignedRaces = False
		EndIf

		backgroundStarsPanel.Update()

		MessageWindowCollection.Update("skirmishmenu")

		GuiManager.Update(lsScreenKey)


		If guiStartButton.IsEnabled() And GetUsedRaces().length <= 1
			guiStartButton.Disable()
		ElseIf Not guiStartButton.IsEnabled() And GetUsedRaces().length > 1
			guiStartButton.Enable()
		EndIf

		If KeyManager.IsHit(KEY_ESCAPE) Or MouseManager.IsHit(2)
			GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("mainmenu"), 0.2 )
		EndIf

		Return True
	End Method
End Type




Type TScreen_CampaignMenu Extends TGameScreen
	Field backgroundStarsPanel:TBackgroundStarsPanel
	Field lsScreenKey:TLowerString = New TLowerString.Create("CAMPAIGNMENU")
	Field hoveredMapIndex:Int = -1
	Field selectedMapIndex:Int = -1
	Field selectedMapGUID:String
	Field selectedCampaignGUID:String
	Field guiStartButton:TGameGUIButton

	Field _eventListeners:TLink[]


	Method Init:TScreen_CampaignMenu(name:String)
		Super.Init(name)
		fadeInEffect = New TScreenFaderRectGrid
		fadeOutEffect = New TScreenFaderRectGrid

		backgroundStarsPanel = New TBackgroundStarsPanel

		guiStartButton = New TGameGUIButton.Create(New TVec2D.Init(200, 164), New TVec2D.Init(95, 17), "Start Game", lsScreenKey.ToString())

		Return Self
	End Method


	Method PrepareStart:Int()
		hoveredMapIndex = -1
		selectedMapIndex = -1
		selectedMapGUID = ""
		selectedCampaignGUID = ""

		Return Super.PrepareStart()
	End Method


	Method StartGame:Int()
		Local mapData:TMapData = GetCampaignCollection().GetCampaignMapByGUIDs(selectedCampaignGUID, selectedMapGUID)
		If Not mapData Then Return False

		'=== START NEW GAME ===
		If hud
			hud.Reset()
		Else
			hud = New THud
		EndIf

		game.Reset()
		game.SetPaused(True)


		game.InitNewMapGame(mapData)

		game.Start()

		GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("ingame"), 0.2 )
	End Method


	Method Update:Int()
		If KeyManager.IsHit(KEY_F8)
			TGame.LoadGame("savegames/quicksave.xml")
		EndIf

		MessageWindowCollection.Update("campaignmenu")

		Local currentRect:TRectangle = New TRectangle.Init(30, 30, 135, 7)
		Local mapIndex:Int = 0

		hoveredMapIndex = -1

		For Local campaignData:TCampaignData = EachIn GetCampaignCollection().campaigns
			currentRect.MoveXY(0, 9)

			Local lastMapWasWon:Int = True
			Local thisMapWasWon:Int = False

			For Local mapData:TMapData = EachIn campaignData.maps
				thisMapWasWon = game.IsCampaignMapWon( mapData.guid )

				If lastMapWasWon Or thisMapWasWon
					lastMapWasWon = thisMapWasWon

					If currentRect.Contains(MouseManager.currentPos)
						hoveredMapIndex = mapIndex
						If MouseManager.IsHit(1)
							selectedMapIndex = mapIndex
							selectedMapGUID = mapData.guid
							selectedCampaignGUID = campaignData.guid
						EndIf

						Exit
					EndIf
				EndIf

				mapIndex :+ 1
				currentRect.MoveXY(0, 8)
			Next
			currentRect.MoveXY(0, 6)
			If hoveredMapIndex <> -1 Then Exit
		Next

		If selectedMapIndex = -1
			If guiStartButton.IsEnabled() Then guiStartButton.Disable()
		Else
			If Not guiStartButton.IsEnabled() Then guiStartButton.Enable()
		EndIf


		guiStartButton.Update()
		If guiStartButton.IsClicked()
			guiStartButton.mouseIsClicked = Null
			StartGame()
		EndIf


		'only open escape menu if nothing else used ESC key already
		If KeyManager.IsHit(KEY_ESCAPE) Or MouseManager.IsHit(2)
			KeyManager.ResetKey(KEY_ESCAPE)
			KeyManager.BlockKey(KEY_ESCAPE, 200)

			MouseManager.ResetKey(2)
			GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("mainmenu"), 0.2)
		EndIf
	End Method


	Method Render:Int()
		SetColor 0,0,0
		DrawRect(0,0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
		SetColor 255,255,255

		backgroundStarsPanel.Render()

		DrawImage(titleScreen.GetImage(), 0,0)

		GameColorCollection.basePalette[0].SetRGB()
		GetSpriteFromRegistry("pattern.diagonal1").TileDraw(0,0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
		SetColor 255,255,255


		GetSpriteFromRegistry("messagewindow.big.bg").DrawArea(15, 10, 165, 180)

		GetSpriteFromRegistry("messagewindow.bg").DrawArea(190, 20, 115, 125)

		GetSpriteFromRegistry("messagewindow.bg").DrawArea(190, 155, 115, 35)

		GetBitmapFont("small",, BOLDFONT).DrawBlock("Campaigns", 15, 14+1, 165-2, 20, ALIGN_CENTER_TOP, GameColorCollection.basePalette[0])
		GetBitmapFont("small",, BOLDFONT).DrawBlock("Campaigns", 15, 14, 165-2, 20, ALIGN_CENTER_TOP, GameColorCollection.basePalette[1])


		Local currentY:Int = 30
		Local mapIndex:Int = 0

		Local font:TBitmapFont = GetBitmapFont("small")
		Local showMap:TMapData
		For Local campaignData:TCampaignData = EachIn GetCampaignCollection().campaigns
			GetBitmapFont("default").Draw(campaignData.title.Get(), 25, currentY, GameColorCollection.basePalette[1])
			currentY :+ 9


			Local lastMapWasWon:Int = True
			Local thisMapWasWon:Int = False

			For Local mapData:TMapData = EachIn campaignData.maps
				thisMapWasWon = game.IsCampaignMapWon( mapData.guid )
				If lastMapWasWon Or thisMapWasWon
					lastMapWasWon = thisMapWasWon
					If hoveredMapIndex = mapIndex
						showMap = mapData
						DrawRect(28, currentY, 137, 7)
						font.Draw(mapData.title.Get(), 30, currentY, GameColorCollection.basePalette[9])
					ElseIf selectedMapIndex = mapIndex
						showMap = mapData
						GameColorCollection.basePalette[7].SetRGB()
						DrawRect(28, currentY, 137, 7)
						SetColor 255,255,255
						font.Draw(mapData.title.Get(), 30, currentY, GameColorCollection.basePalette[9])
					Else
						font.Draw(mapData.title.Get(), 30, currentY, GameColorCollection.basePalette[1])
					EndIf
				Else
					font.Draw(mapData.title.Get(), 30, currentY, GameColorCollection.basePalette[15])
				EndIf

				mapIndex :+ 1
				currentY :+ 8
			Next
			currentY :+ 6
		Next

		If showMap
			Local offsetY:Int = 0
			If showMap.description And showMap.description.Get() <> ""
				offsetY :+ font.DrawBlock(showMap.description.Get(), 200, 20 +10 + offsetY, 115 -20, 125 - 20 - offsetY, ALIGN_LEFT_TOP, Null, 0, 1, 1.0, True, False, 7).y
			Else
				Local c:TCampaignData = GetCampaignCollection().GetCampaignByGUID(showMap.campaignGUID)
				If c And c.description And c.description.Get() <> ""
					offsetY :+ font.DrawBlock(c.description.Get(), 200, 20 +10 + offsetY, 115 -20, 125 - 20 - offsetY, ALIGN_LEFT_TOP, Null, 0, 1, 1.0, True, False, 7).y
				EndIf
			EndIf
			offsetY :+ 5
			font.Draw("players: " + showMap.playerConfigs.length, 200, 20 + 10 + offsetY)
			offsetY :+ 7
			font.Draw("planets: " + showMap.planetConfigs.length, 200, 20 + 10 + offsetY)
		EndIf

		guiStartButton.Draw()
	End Method

End Type



Type TScreen_InGame Extends TScreen
	Method Init:TScreen_InGame(name:String)
		Super.Init(name)
		fadeInEffect = New TScreenFaderRectGrid
		fadeOutEffect = New TScreenFaderRectGrid

		Return Self
	End Method


	Method PrepareStart:Int() 'override
		Super.PrepareStart()

		GetSoundManager().PlayMusicPlaylist("default")
	End Method


	'remove all messagewindows
	Method Kill:Int() 'override
		MessageWindowCollection.RemoveByScreenLimit("ingame")

		'play menu music
		GetSoundManager().PlayMusicPlaylist("menu")

		Return Super.Kill()
	End Method


	Method Update:Int()
		If KeyManager.IsHit(KEY_F5)
			TGame.SaveGame("savegames/quicksave.xml")
		ElseIf KeyManager.IsHit(KEY_F8)
			TGame.LoadGame("savegames/quicksave.xml")
		EndIf


If DEV_MODE
		If KeyManager.IsHit(KEY_W)
			KeyManager.ResetKey(KEY_W)
			Game.SetPlayerWon(game.GetPlayer().playerID)
		EndIf


		If KeyManager.IsHit(KEY_L)
			KeyManager.ResetKey(KEY_L)
			Game.SetPlayerLost(game.GetPlayer().playerID)
		EndIf

		If KeyManager.IsHit(KEY_S)
			KeyManager.ResetKey(KEY_S)
			game.StartSolarSupport(20, 2)
		EndIf
EndIf

Rem
		If KeyManager.IsHit(KEY_R)
			KeyManager.ResetKey(KEY_R)
			Game.StartRebels()
		EndIf


		If KeyManager.IsHit(KEY_O)
			KeyManager.ResetKey(KEY_O)
			MessageWindowCollection.OpenGameStatsWindow()
		EndIf
endrem


		GameTime.Update()

		MessageWindowCollection.Update("ingame")
		hud.Update()
		game.Update()


		'only open escape menu if nothing else used ESC key already
		If KeyManager.IsHit(KEY_ESCAPE)
			MessageWindowCollection.OpenIngameMenu()
			KeyManager.ResetKey(KEY_ESCAPE)
			KeyManager.BlockKey(KEY_ESCAPE, 200)
'			GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("mainmenu"), 0.2)
		EndIf
	End Method


	Method Render:Int()
	'	Cls

		game.Render()
		hud.Render()
		MessageWindowCollection.Render("ingame")

		If Game.IsPaused() Then DrawText("PAUSED", 5,8)
		'DrawText("Ships: " + space.GetShipCount(0), 5, 30)
	End Method


	'overwrite the function of TScreen - TGraphicalApp-Apps call this
	'automatically
	Method ExtraRender:Int() 'override
	End Method

End Type




Include "source/game.savegame.bmx"



Type TCampaignCollection
	Field campaigns:TCampaignData[]
	Global _instance:TCampaignCollection

	Function GetInstance:TCampaignCollection()
		If Not _instance Then _instance = New TCampaignCollection
		Return _instance
	End Function


	Method GetCampaignByGUID:TCampaignData(guid:String)
		If Not campaigns Or campaigns.length = 0 Then Return Null

		For Local i:Int = 0 Until campaigns.length
			If campaigns[i].guid.ToLower() = guid.ToLower() Then Return campaigns[i]
		Next
		Return Null
	End Method


	Method GetCampaignMapByGUIDs:TMapData(campaignGUID:String, mapGUID:String)
		If Not campaigns Or campaigns.length = 0 Then Return Null

		For Local i:Int = 0 Until campaigns.length
			If campaigns[i].guid.ToLower() = campaignGUID.ToLower()
				Return campaigns[i].GetMapByGUID(mapGUID)
			EndIf
		Next
		Return Null
	End Method


	Method LoadCampaignsInDirectory(dir:String)
'		campaigns = New TCampaignData[0]

		Local DT:TDirectoryTree = New TDirectoryTree.Init(dir)
		DT.relativePaths = False
		DT.AddIncludeFileEndings(["xml"])
		DT.AddIncludeFileNames(["*"])
		DT.ScanDir()

		For Local f:String = EachIn DT.GetFiles()
			LoadCampaigns(f)
		Next
	End Method


	Method LoadCampaigns(fileURI:String)
		Local xml:TXmlHelper = TXmlHelper.Create(fileURI)

'		local campaignsRoodNode:TxmlNode = xml.FindRootChild("campaigns")

		For Local campaignNode:TxmlNode = EachIn xml.GetNodeChildElements(xml.GetRootNode() )
			If campaignNode.getName() <> "campaign" Then Continue

			campaigns :+ [ LoadCampaignData(campaignNode, xml) ]
		Next
	End Method


	Method LoadCampaignData:TCampaignData(node:TxmlNode, xml:TXmlHelper)
'		Print " LoadCampaign..."

		Local c:TCampaignData = New TCampaignData
		c.guid = xml.FindValue(node, "id", "campaign")
		c.title = New TLocalizedString.Append( xml.GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
		c.description = New TLocalizedString.Append( xml.GetLocalizedStringFromNode(xml.FindElementNode(node, "description")) )

		For Local mapNode:TxmlNode = EachIn xml.GetNodeChildElements(node)
			If mapNode.getName() <> "map" Then Continue

			Local loadedMaps:Int = 0
			If c.maps Then loadedMaps = c.maps.length

			c.maps :+ [ LoadMapData(mapNode, xml, loadedMaps + 1) ]

			'assign campaign guid
			c.maps[ c.maps.length -1].campaignGUID = c.GUID
		Next

		Return c
	End Method


	Method LoadMapData:TMapData(node:TxmlNode, xml:TXmlHelper, mapNumber:Int = 1)
'		print "  LoadMap..."

		Local m:TMapData = New TMapData
		m.guid = xml.FindValue(node, "id", "map_" + (mapNumber))
		m.title = New TLocalizedString.Append( xml.GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
		m.description = New TLocalizedString.Append( xml.GetLocalizedStringFromNode(xml.FindElementNode(node, "description")) )


		'MESSAGES
		Local nodeMessages:TxmlNode = xml.FindChild(node, "messages")
		For Local child:TxmlNode = EachIn xml.GetNodeChildElements(nodeMessages)
			If child.getName() <> "message" Then Continue

			m.messageTitles :+ [New TLocalizedString.Append( xml.GetLocalizedStringFromNode(xml.FindElementNode(child, "title")) )]
			m.messageTexts :+ [New TLocalizedString.Append( xml.GetLocalizedStringFromNode(xml.FindElementNode(child, "text")) )]
			m.messageGameTime :+ [ Long(xml.FindValueInt(child, "game_time", -1)) ]
		Next
'		print "   loaded " + m.messageTitles.length +" messages."


		'EVENTS
		Local nodeEvents:TxmlNode = xml.FindChild(node, "events")
		For Local child:TxmlNode = EachIn xml.GetNodeChildElements(nodeEvents)
			If child.getName() <> "event" Then Continue
			Local ev:TMapEvent = New TMapEvent
			ev.eventType = xml.FindValue(child, "type", "")
			ev.title = New TLocalizedString.Append( xml.GetLocalizedStringFromNode(xml.FindElementNode(child, "title")) )
			ev.text = New TLocalizedString.Append( xml.GetLocalizedStringFromNode(xml.FindElementNode(child, "text")) )
			ev.notifyEnabled = xml.FindValueBool(child, "notify_enabled", False)
			ev.notifyDelay = 1000 * xml.FindValueFloat(child, "notify_delay", 0)
			ev.gameTime = 1000 * xml.FindValueFloat(child, "game_time", 0)
			ev.gameTimeFrom = 1000 * xml.FindValueFloat(child, "game_time_from", -1)
			ev.gameTimeTo = 1000 * xml.FindValueFloat(child, "game_time_to", -1)
			ev.playerID = xml.FindValueInt(child, "player", -1)
			ev.amount = xml.FindValueInt(child, "amount", -1)
			ev.amountRelative = xml.FindValueInt(child, "amount_relative", False)

			m.AddEvent(ev)
		Next

		'CONFIG
		Local nodeConfig:TxmlNode = xml.FindChild(node, "config")
		m.winCondition = xml.FindValue(nodeConfig, "win_condition", "win")
		m.time = xml.FindValueInt(nodeConfig, "time", -1)
		m.width = xml.FindValueInt(nodeConfig, "width", -1)
		m.height = xml.FindValueInt(nodeConfig, "height", -1)
		m.width_relative = xml.FindValueInt(nodeConfig, "width_relative", -1)
		m.height_relative = xml.FindValueInt(nodeConfig, "height_relative", -1)
		m.galaxyName = xml.FindValue(nodeConfig, "galaxy_name", "")
		m.randomSeed = xml.FindValueInt(nodeConfig, "random_seed", -1)

		m.rebelsTime = xml.FindValueInt(nodeConfig, "rebels_time", -1)
		m.rebelsAllowed = xml.FindValueBool(nodeConfig, "rebels_allowed", 0)
		m.rebelsUnusedPlanets = xml.FindValueInt(nodeConfig, "rebels_unused_planets", 0)



		'PLAYERS
		m.playerConfigs = New TData[0]
		Local nodePlayers:TxmlNode = xml.FindChild(node, "players")
		For Local child:TxmlNode = EachIn xml.GetNodeChildElements(nodePlayers)
			If child.getName() <> "player" Then Continue

			Local d:TData = New TData
			xml.LoadValuesToData(child, d, ["id", "race", "control", "difficulty"])
			m.playerConfigs :+ [d]
		Next
'		print "   loaded " + m.playerConfigs.length +" players."


		'PLANETS
		m.planetConfigs = New TData[0]
		Local nodePlanets:TxmlNode = xml.FindChild(node, "planets")
		For Local child:TxmlNode = EachIn xml.GetNodeChildElements(nodePlanets)
			If child.getName() <> "planet" Then Continue

			Local d:TData = New TData
			xml.LoadValuesToData(child, d, ["id", "x", "y", "x2", "y2", "owner", "population", "missiles", "missileLimit", "name"])
			m.planetConfigs :+ [d]
		Next
'		print "   loaded " + m.planetConfigs.length +" planets."

		Return m
	End Method
End Type

Function GetCampaignCollection:TCampaignCollection()
	Return TCampaignCollection.GetInstance()
End Function





Type TCampaignData
	Field guid:String = ""
	Field maps:TMapData[]
	Field title:TLocalizedString
	Field description:TLocalizedString

	Method GetMapByGUID:TMapData(guid:String)
		If Not maps Or maps.length = 0 Then Return Null

		For Local i:Int = 0 Until maps.length
			If maps[i].guid.ToLower() = guid.ToLower() Then Return maps[i]
		Next
	End Method
End Type




Type TMapData
	Field guid:String = ""
	Field campaignGUID:String
	Field title:TLocalizedString
	Field description:TLocalizedString
	Field messageTitles:TLocalizedString[]
	Field messageTexts:TLocalizedString[]
	Field messageGameTime:Long[]
	Field winCondition:String = "win"
	Field time:Int = -1
	Field width:Int = -1
	Field height:Int = -1
	Field width_relative:Int = -1
	Field height_relative:Int = -1
	Field randomSeed:Int = 0
	Field galaxyName:String
	Field playerConfigs:TData[]
	Field planetConfigs:TData[]
	Field rebelsAllowed:Int = 0
	Field rebelsUnusedPlanets:Int = 0
	Field rebelsTime:Int = 0

	Field events:TMapEvent[]


	Method AddEvent:Int(event:TMapEvent)
		events :+ [event]
		Return True
	End Method



End Type



Type TMapEvent
	Field eventType:String
	Field title:TLocalizedString
	Field text:TLocalizedString
	Field notifyEnabled:Int = False
	Field notifyDelay:Int = 0
	Field notifyDone:Int = False
	Field notifyLifetime:Float = 5.0
	'times in milliseconds!
	Field gameTime:Long = -1
	Field gameTimeFrom:Long = -1
	Field gameTimeTo:Long = -1
	Field playerID:Int = -1
	Field amount:Int = 0
	Field amountRelative:Int = False

	Field calculatedGameTime:Long


	Method Reset:Int()
		calculatedGameTime = -1
		notifyDone= False
	End Method


	Method CalculateTime:Int()
		calculatedGameTime = gameTime
		If calculatedGameTime = -1 Then calculatedGameTime = RandRange(Int(gameTimeFrom), Int(gameTimeTo)) 'DATA LOSS possible!
	End Method


	Method GetTime:Long()
		If calculatedGameTime = -1 Then CalculateTime()
		Return calculatedGameTime
	End Method


	Method GetNotifyTime:Long()
		Return GetTime() + GetNotifyDelay()
	End Method


	Method GetNotifyDelay:Int()
		Return notifyDelay
	End Method


	Method DoNotify:Int()
		If Not title And Not text Then Return False

		Local useTitle:String
		If title Then useTitle = title.Get()
		Local useText:String
		If text Then useText = text.Get()

		Local toast:TGameToastMessage = New TGameToastMessage
		toast.SetLifeTime( notifyLifetime )

		If useTitle Then toast.SetCaption(usetitle)
		toast.SetText( useText )
		toast.captionColor = GameColorCollection.basePalette[7]
		toast.captionFont = GetBitmapFont("default")
		toast.textFont = GetBitmapFont("small")
		GetToastMessageCollection().AddMessage(toast, "TOPLEFT")

		notifyDone = True
	End Method


	Method Execute:Int()
		Select eventType.ToLower()
			Case "rebellion"
				Execute_Rebellion()
			Case "message"
				Execute_Message()
			Case "support"
				Execute_Support()

			Default
				Print "unsupported event :" + eventType
		End Select
	End Method


	Method Execute_Rebellion()
		game.StartRebels()
	End Method


	Method Execute_Message()
		Local w:TMessageWindow_SimpleMessage = New TMessageWindow_SimpleMessage
		w.area = New TRectangle.Init(15,16, 259-30, 30 + 23*6)
		w.screenLimit = "ingame"
		w.caption = title.Get()
		w.text = text.Get()

		w.Open()

		MessageWindowCollection.windows :+ [w]
	End Method


	Method Execute_Support()
		If game.GetPlayer(playerID) And game.GetPlayer(playerID).IsAlive()
			game.StartSolarSupport(amount, playerID)
		EndIf
	End Method
End Type



Type TGame
	Field playerID:Int = 1
	Field players:TPlayer[]
	Field playerColors:TGameColor[]
	Field playerState:Int
	'one for every player
	Field gameStatsArchive:TGameStatsArchive[6]
	Field gameStatsArchiveTimer:Float

	Field groupSelectionArea:TRectangle

	Field racesColors:TGameColor[]
	Field racesNames:String[]
	Field gameType:Int = 1

	'contains guids of won maps
	Field campaignMapsWonCount:Int = 0
	Field campaignMapsWon:TStringMap = New TStringMap

	Field galaxyName:String
	Field mapName:String
	Field campaignName:String
	Field campaignGUID:String
	Field mapGUID:String
	Field mapTimeLimit:Int = -1
	Field mapEvents:TIntMap = New TIntMap

	Field missilesPerPlanetLimit:Int = 50
	Field state:Int = 0
	Field rebelsTime:Int = 0
	Field rebelsUnusedPlanets:Int = 0
	Field rebelsAllowed:Int = True
	Field rebelsActivated:Int = False

	Global hoverRectCol1:TGameColor = GameColorCollection.FindSimilarRGB(255,0,0)
	Global hoverRectCol2:TGameColor = GameColorCollection.FindSimilarRGB(150,0,0)
	Global selectionRectCol1:TGameColor = GameColorCollection.FindSimilarRGB(255,255,255)
	Global selectionRectCol2:TGameColor = GameColorCollection.FindSimilarRGB(150,150,150)

	Global defaultPopulationGrowthTime:Double = 1.0
	Global defaultResearchTime:Double = 1.0
	Global defaultMissileRefillTime:Double = 4.0 '2 seconds

	Global defaultMapSizeX:Int = 259
	Global defaultMapSizeY:Int = 185

	Global _eventListeners:TLink[]
	Global _initDone:Int = False

	Const GAMESTATE_INTRO:Int = 0
	Const GAMESTATE_RUNNING:Int = 1

	Const GAMETYPE_RANDOM:Int = 1
	Const GAMETYPE_SKIRMISH:Int = 2
	Const GAMETYPE_CAMPAIGN:Int = 3

	Method New()
		Reset()

		If Not _initDone
			'=== EVENTS ===
			'=== remove all registered event listeners
			EventManager.unregisterListenersByLinks(_eventListeners)
			_eventListeners = New TLink[0]

			'=== register event listeners
			'to react on changes in the programmeCollection (eg. custom script finished)
			_eventListeners :+ [ EventManager.registerListenerFunction( "Planet.SetOwner", onPlanetSetOwner ) ]

			_initDone = True
		EndIf
	End Method



	Method Reset()
		playerID = 1
		players = Null
		playerColors = Null
		groupSelectionArea = Null
		racesColors = Null
		racesNames = Null
		missilesPerPlanetLimit = 50

		rebelsActivated = False

		gameStatsArchive = New TGameStatsArchive[6]
		For Local i:Int = 0 Until gameStatsArchive.length
			gameStatsArchive[i] = New TGameStatsArchive
		Next


		'baseKeys contains indices of real C64 colors
		'nonFlickerKeys contains indices of "mixes between 2 C64 colors"
		'which do not flicker too much when alternating between them
		Local baseKeys:String = "0, 16, 31, 45, 58, 70, 81, 91, 100, 108, 115, 121, 126, 130, 133, 135"
		Local nonFlickerKeys:String = baseKeys  + "," + "18, 29, 52"' "18,29,52,59,65,78,79,80,91,97,104,105,106, 117, 118, 119, 120, 128, 131, 132, 134"
		Local parts:String[] = nonFlickerKeys.split(",")
		Local colorIndices:Int[] = New Int[parts.length]
		For Local i:Int = 0 Until parts.length
			colorIndices[i] = Int(parts[i])
		Next


		racesColors = New TGameColor[8] 'last is for rebels
		racesColors[0] = GameColorCollection.basePalette[12] 'gray
		racesColors[1] = GameColorCollection.basePalette[2] 'red-brown
		racesColors[2] = GameColorCollection.basePalette[5] 'green
		racesColors[3] = GameColorCollection.basePalette[14] 'blue
		racesColors[4] = GameColorCollection.basePalette[4] 'purple
		racesColors[5] = GameColorCollection.basePalette[7] 'yellow
		racesColors[6] = GameColorCollection.basePalette[8] 'orange
		racesColors[7] = GameColorCollection.basePalette[12] 'gray (unknown)

		racesNames = ["Credtopus", "Aquaxian", "Blyshyn", "Pinkz'ac","Yobots", "Orantex", "Unknown", "Unknown"]
	End Method


	Function LoadGame:Int(uri:String)
		Local s:TSaveGame = TSaveGame.Load(uri)

		'remove old messages
		MessageWindowCollection.Reset()

		If s And s._CurrentScreenName <> GetScreenManager().GetCurrent().name
			GetScreenManager().GetCurrent().FadeToScreen(GetScreenManager().Get(s._CurrentScreenName), 0.2)
		EndIf
	End Function


	Function SaveGame:Int(uri:String)
		TSaveGame.Save(uri)
	End Function


	Method RestartGame:Int()
		Local mapData:TMapData = GetCampaignCollection().GetCampaignMapByGUIDs(campaignGUID, mapGUID)
		If Not mapData Then Return False

		'=== RESTART GAME ===
		hud.Reset()

		Reset()
		SetPaused(True)

		InitNewMapGame(mapData)

		Start()

		GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("ingame"), 0.2 )
	End Method


	Method InitNewMapGame(mapData:TMapData)
		'set the same seed everytime so we generate planets at the same position
		'if seed is -1 then it becomes more or less "truely random"
		If mapData.randomSeed > 0
			SeedRand( mapData.randomSeed )
		Else
			SeedRand( Abs(MilliSecs()) )
		EndIf


		galaxyName = mapData.galaxyName
		If Not galaxyName Then galaxyName = GenerateGalaxyName()

		mapName = mapData.title.Get()
		campaignName = ""
		If GetCampaignCollection().GetCampaignByGUID(mapData.campaignGUID)
			campaignName = GetCampaignCollection().GetCampaignByGUID(mapData.campaignGUID).title.Get()
		EndIf

		If Not mapName Then mapName = "Mission in " + galaxyName


		mapTimeLimit = mapData.time
		mapGUID = mapData.guid
		campaignGUID = mapData.campaignGUID
		gameType = TGame.GAMETYPE_CAMPAIGN

		rebelsAllowed = mapData.rebelsAllowed
		rebelsTime = mapData.rebelsTime
		rebelsUnusedPlanets = mapData.rebelsUnusedPlanets

		'take over map events (and calculate random times if needed)
		'ATTENTION:
		'================
		'events need to take place at _DIFFERENT_ times !!!
		'================
		For Local event:TMapEvent = EachIn mapData.events
			event.CalculateTime()
			mapEvents.Insert(Int(event.GetTime()), event)
		Next

		Local playerCount:Int = mapData.playerConfigs.length

		players = New TPlayer[playerCount]
		playerColors = New TGameColor[playerCount + 1] '0 = gray
		playerColors[0] = racesColors[0]

		For Local pID:Int = 1 To playerCount
			Local raceID:Int = mapData.playerConfigs[pID-1].GetInt("race", 0)
			playerColors[pID] = racesColors[raceID] '0 = all ,so "raceID-1 +1"

			?bmxng
			players[pID-1] = New TPlayer(pID)
			?Not bmxng
			players[pID-1] = New TPlayer
			players[pID-1].playerID = pID
			?
			'assign name, racial bonus/malus ...
			players[pID-1].SetRace(raceID)

			If mapData.playerConfigs[pID-1].GetString("control").ToLower() = "human"
				playerID = pID
			EndIf

			If pID <> playerID
				players[pID-1].AI = New TAI
				players[pID-1].AI.playerID = pID
				players[pID-1].AI.RandomizeCharacter()

				players[pID-1].SetDifficulty( mapData.playerConfigs[pID-1].GetInt("difficulty", 100) )
			EndIf
		Next


		Local w:Int = mapData.width
		Local h:Int = mapData.height
		If w <= 0 Then w = Int(0.01 * mapData.width_relative * TGame.defaultMapSizeX)
		If h <= 0 Then h = Int(0.01 * mapData.height_relative * TGame.defaultMapSizeY)

		space = New TSpace
		space.Init(mapData.planetConfigs, playerCount, w, h)
		space.SetScreenArea(0,7, 259, 185)


		'add some population according to difficulty
		For Local planet:TPlanet = EachIn space.planets
			If planet.ownerID <= 0 Then Continue

			'-3 for very easy, 0 for normal
			planet.population :- Max(0, Int(6.0 * (1 - 0.01 * players[planet.ownerID-1].difficulty)))
			'+2 (up to +3) for hard, 0 for normal
			planet.population :+ Min(3, Max(0, Int(0.01 * players[planet.ownerID-1].difficulty) - 1))
		Next

		'make AI decisions from now on - more random
		SeedRand( Abs(MilliSecs()) )
	End Method


	Method InitNewRandomGame(playerCount:Int, planetCount:Int=-1, spaceWidth:Int=-1, spaceHeight:Int=-1)
		'create players
		Local randomRaceIDs:Int[] = RandRangeArray(1, 6, playerCount)
		Local difficulties:Int[] = New Int[playerCount] 'first is player -> ignored
		For Local i:Int = 0 Until playerCount
			difficulties[i] = 50 + 50 * RandRange(0,3) '50 - 200%
		Next

		If spaceWidth = -1 Then spaceWidth = MathHelper.Clamp(RandRange(TGame.defaultMapSizeX - 50, 2*TGame.defaultMapSizeX), TGame.defaultMapSizeX, 2*TGame.defaultMapSizeX )
		If spaceHeight = -1 Then spaceHeight = MathHelper.Clamp(RandRange(TGame.defaultMapSizeY - 50, 2*TGame.defaultMapSizeY), TGame.defaultMapSizeY, 2*TGame.defaultMapSizeY )
		'scale up
		If planetCount = -1 Then planetCount = Int(12 * spaceWidth/Float(TGame.defaultMapSizeX) * spaceHeight/Float(TGame.defaultMapSizeY))

		InitNewGame(TGame.GAMETYPE_RANDOM, randomRaceIDs, difficulties, planetCount, spaceWidth, spaceHeight)
	End Method


	Method InitNewGame(gameType:Int, playerRaces:Int[], playerDifficulties:Int[], planetCount:Int, spaceWidth:Int, spaceHeight:Int, galaxyName:String="", mapName:String="")
		Local validPlayerRaces:Int[]
		Local validPlayerDifficulties:Int[]
		For Local i:Int = 0 Until playerRaces.length
			If playerRaces[i] > 0
				validPlayerRaces :+ [playerRaces[i]]
				validPlayerDifficulties :+ [playerDifficulties[i]]
			EndIf
		Next

		If Not galaxyName Then galaxyName = GenerateGalaxyName()
		Self.galaxyName = galaxyName

		If Not mapName
			Select gameType
				Case TGame.GAMETYPE_CAMPAIGN
					mapName = "Mission in " + galaxyName
				Case TGame.GAMETYPE_RANDOM
					mapName = "Random game in " + galaxyName
				Case TGame.GAMETYPE_SKIRMISH
					mapName = "Skirmish game in " + galaxyName
			End Select
		EndIf
		Self.mapName = mapName

		Self.gameType = gameType

		Local playerCount:Int = validPlayerRaces.length

		players = New TPlayer[playerCount]
		playerColors = New TGameColor[playerCount + 1] '0 = gray
		playerColors[0] = racesColors[0]
		For Local pID:Int = 1 To playerCount
			Local raceID:Int = validPlayerRaces[pID-1]
			playerColors[pID] = racesColors[raceID] '0 = all ,so "raceID-1 +1"
			'print "player " + pID +"  race = " + randomRaceIDs[pID-1] +"  color = " + (raceID) +"  = " + playerColors[pID].ToString()

			?bmxng
			players[pID-1] = New TPlayer(pID)
			?Not bmxng
			players[pID-1] = New TPlayer
			players[pID-1].playerID = pID
			?
			'assign name, racial bonus/malus ...
			players[pID-1].SetRace(raceID)
			If pID <> playerID
				players[pID-1].AI = New TAI
				players[pID-1].AI.playerID = pID
				players[pID-1].AI.RandomizeCharacter()
				Select validPlayerDifficulties[pID-1]
					Case 0	players[pID-1].SetDifficulty(50)
					Case 1	players[pID-1].SetDifficulty(100)
					Case 2	players[pID-1].SetDifficulty(150)
				End Select
			EndIf
		Next


		space = New TSpace
		space.InitRandom(playerCount, planetCount, spaceWidth, spaceHeight)
		space.SetScreenArea(0,7, 259, 185)


		'add some population according to difficulty
		For Local planet:TPlanet = EachIn space.planets
			If planet.ownerID <= 0 Then Continue

			'3 for easy, 0 for normal
			planet.population :+ Max(0, (4 - players[planet.ownerID-1].difficulty))
			'-2 for hard, 0 for normal
			planet.population :- Min(3, Sqr(players[planet.ownerID-1].difficulty))
		Next

	End Method


	Method Start:Int()
		GameTime.Reset()
		state = 1


		space.ScrollToPlayerPlanet(game.playerID)

		'NEW GAME START INFO SCREENS
		MessageWindowCollection.OpenLevelStartWindow()
	End Method


	Method StartSolarSupport:Int(amount:Int, playerID:Int, planetID:Int =-1)
		If planetID = -1
			Local planets:TPlanet[] = space.GetPlanets(playerID)
			'use a random one of another player?
			If Not planets Or planets.length = 0
				planets = space.planets
			EndIf

			planetID = planets[ RandRange(0, planets.length -1) ].ID
		EndIf

		Local spawn:TVec2D = New TVec2D.Init(0,0)
		Local planet:TPlanet = space.GetPlanet(planetID)

		'find best direction
		Local toLeft:Int = planet.position.x
		Local toRight:Int = space.width - planet.position.x
		Local toTop:Int = planet.position.y
		Local toBottom:Int = space.height - planet.position.y

		If toLeft < toRight And toLeft < toTop And toLeft < toBottom
			spawn.Init(-20, planet.position.y) 'left
		ElseIf toRight < toLeft And toRight < toTop And toRight < toBottom
			spawn.Init(space.width + 20, planet.position.y) 'right
		ElseIf toTop < toLeft And toTop < toRight And toTop < toBottom
			spawn.Init(planet.position.x, - 20) 'top
		Else
			spawn.Init(planet.position.x, space.height + 20) 'bottom
		EndIf



		For Local i:Int = 0 Until amount
			Local ship:TShip = New TShip
			ship.ownerID = playerID
			ship.sourcePlanetID = -1
			ship.targetPlanetID = planetID
			ship.position = spawn.Copy()
			'randomize a bit
			ship.position.AddXY(RandRange(-10, 10), RandRange(-10, 10))

			ship.speed = planet.GetShipSpeed() * 2 'fast

			ship.sourcePosition = ship.position.Copy()
			ship.targetPosition = planet.position 'no copy so it can adjust

'support does not add
'			game.GetPlayerGameStats(planet.ownerID).shipsStarted :+ 1

			space.AddShip(ship)
		Next
	End Method


	Method StartRebels:Int()
		If rebelsActivated Then Return False

		gameStatsArchive :+[ New TGameStatsArchive ]
		space._shipsAlive :+ [0]

		Local raceID:Int = 7 'unknown
		Local pID:Int = players.length +1

		playerColors :+ [ racesColors[raceID] ]

		?bmxng
		players :+ [New TPlayer(pID)]
		?Not bmxng
		Local p:TPlayer = New TPlayer
		p.playerID = pID
		players :+ [p]
		?

		'assign name, racial bonus/malus ...
		players[pID-1].SetRace(raceID)

		players[pID-1].AI = New TAI
		players[pID-1].AI.playerID = pID
		players[pID-1].AI.RandomizeCharacter()

		players[pID-1].SetDifficulty( 100 )


		'assign planets
		For Local p:TPlanet = EachIn space.GetPlanets(0)
			If p.ownerID <> 0 Then Continue 'how can it...

			p.SetOwner(pID)
		Next

		rebelsActivated = True

		Return True
	End Method


	Method IsPaused:Int()
		Return GameTime.paused
	End Method


	Method SetPaused(paused:Int)
		GameTime.paused = paused
	End Method


	Method SetGameSpeed(speed:Int)
		GameTime.speedFactor = Float(speed)
	End Method


	Method GetCampaignMapsWon:Int()
		Return campaignMapsWonCount
	End Method


	Method IsCampaignMapWon:Int(mapGUID:String)
		Return campaignMapsWon.Contains(mapGUID)
	End Method


	Method SetCampaignMapWon:Int(mapGUID:String)
		If Not campaignMapsWon.Contains(mapGUID)
			campaignMapsWon.insert(mapGUID, Time.GetSystemTime("%Y/%m/%d %H:%M:%S"))
			campaignMapsWonCount :+ 1
		EndIf
	End Method


	Method GetPlayer:TPlayer(playerID:Int=-1)
		If playerID = -1 Then playerID = Self.playerID
		If playerID < 1 Or playerID > players.length Then Return Null
		Return players[playerID-1]
	End Method


	Method GetPlayerGameStats:TGameStats(playerID:Int)
		Return gameStatsArchive[playerID-1].GetCurrent()
	End Method

	Method GetPlayerGameStatsArchive:TGameStatsArchive(playerID:Int)
		Return gameStatsArchive[playerID-1]
	End Method


	Method BuyMissileForPlanet:Int(playerID:Int, planetID:Int)
		Local player:TPlayer = GetPlayer(playerID)
		Local planet:TPlanet = space.GetPlanet(planetID)
		If Not player Or Not planet Then Return False

		If Not planet.IsMissileMaxReached() And player.researchPoints > 0
			player.researchPoints :- 1
			planet.missilesLimit :+ 1

			GetPlayerGameStats(playerID).missilesBought :+ 1
			Return True
		EndIf
		Return False
	End Method


	Method UpdatePlayerControls()
		Local mouseOver:Int = space.screenArea.Contains(MouseManager.currentPos)

		'deselect planet with rightclick
		If MouseManager.IsHit(2) And mouseOver Then space.DeselectPlanets()

		Local localMousePos:TVec2D = space.ScreenPosToLocal(MouseManager.currentPos)
		Local groupSelectKeysDown:Int = (KeyManager.IsDown(KEY_LCONTROL) Or KeyManager.IsDown(KEY_RCONTROL))
		Local hoveredPlanet:TPlanet

		'reset states
		For Local planet:TPlanet = EachIn space.planets
			planet.SetHovered(False)
		Next

		'set new states
		For Local planet:TPlanet = EachIn space.planets
			If planet.GetArea().ContainsVec(localMousePos)
				planet.SetHovered(True)
				hoveredPlanet = planet
				Exit
			EndIf
		Next


		'handle clicks / selection / attack
		'group select
		If groupSelectionArea And Not MouseManager.IsDown(1) And mouseOver
			If Not groupSelectKeysDown Then space.DeselectPlanets()
'			if groupSelectionArea.GetW() > 2 or groupSelectionArea.GetH() > 2
				space.AddSelectedPlanets(groupSelectionArea.MakeDimensionsPositive(), playerID)
				MouseManager.ResetKey(1)
'			endif
			groupSelectionArea = Null
		ElseIf MouseManager.IsDown(1)
			If groupSelectionArea
				groupSelectionArea.SetX2( localMousePos.x )
				groupSelectionArea.SetY2( localMousePos.y )
			Else If mouseOver 'only start when within space area
				groupSelectionArea = New TRectangle.Init( localMousePos.x, localMousePos.y, 1, 1)
			EndIf
		EndIf
		'single select
		'if not groupSelectionArea and MouseManager.IsHit(1) and hoveredPlanet
		If MouseManager.IsHit(1) And hoveredPlanet And mouseOver
			If space.IsSelectedPlanet(hoveredPlanet.ID)
				'deselect
				space.DeselectPlanet(hoveredPlanet.ID)
			Else
				'can only group select if the other selected is also of player's planets
				Local onlyPlayerPlanetsSelected:Int = (space.selectedPlanets And space.selectedPlanets.length > 0 And space.selectedPlanets[0].ownerID = playerID)
				Local playerOwnedPlanet:Int = (hoveredPlanet.ownerID = playerID)

				'extend group selection
				If onlyPlayerPlanetsSelected And playerOwnedPlanet And groupSelectKeysDown
					space.AddSelectedPlanet(hoveredPlanet)
					'done in Add* already
					'hoveredPlanet.SetSelected(True)

				'send ships
				ElseIf onlyPlayerPlanetsSelected And Not IsPaused()
					If Not GetPlayer().isObserving
						GetPlayer().SpawnShipsFromPlanets(space.selectedPlanets, hoveredPlanet.ID)
						SimpleSoundSource.PlayRandomSfx("ship_start")
					EndIf

				'simple click on a planet - select it
				Else
					space.DeselectPlanets()
					space.AddSelectedPlanet(hoveredPlanet)
					'done in Add* already
					'hoveredPlanet.SetSelected(True)
				EndIf
			EndIf
			MouseManager.ResetKey(1)
		EndIf
	End Method


	Method CheckPlayerStates:Int()
		For Local pID:Int = 1 To players.length
			If Not GetPlayer(pID).state = TPlayer.PLAYERSTATE_ALIVE Then Continue

			If space.GetPlanetCount(pID) = 0
				If space.GetShipCount(pID) <= 0
					SetPlayerLost(pID)
				EndIf
			EndIf
		Next


		Local deadCount:Int = 0
		Local aliveID:Int = 0
		For Local pID:Int = 1 To players.length
			If players[pID-1].state = TPlayer.PLAYERSTATE_LOST
				deadCount :+ 1
			Else
				aliveID = pID
			EndIf
		Next
		If deadCount = players.length -1 And aliveID > 0
			SetPlayerWon(aliveID)
		EndIf

	End Method


	Method UpdateGameStats()
		For Local p:TPlayer = EachIn players
			Local gs:TGameStats = GetPlayerGameStats(p.playerID)
			gs.population = p.GetTotalPopulation()
			gs.domination = space.GetDomination(p.playerID)
			gs.planetsOwned = space.GetPlanetCount(p.playerID)
			gs.techtreeProgress = p.GetTechTree().GetTotalProgress()
		Next
	End Method


	Method SetPlayerWon:Int(playerID:Int)
		If GetPlayer(playerID).state = TPlayer.PLAYERSTATE_WON Then Return False

		GetPlayer(playerID).state = TPlayer.PLAYERSTATE_WON

		'human player?
		If playerID = game.playerID
			SetCampaignMapWon(mapGUID)
		EndIf

		'show game-won window for all (but of course other text)
		If GetPlayer().state = TPlayer.PLAYERSTATE_WON Or GetPlayer().isObserving
			MessageWindowCollection.OpenGameWonWindow()
		EndIf
	End Method


	Method SetPlayerLost:Int(playerID:Int)
		If GetPlayer(playerID).state = TPlayer.PLAYERSTATE_LOST Then Return False

		GetPlayer(playerID).state = TPlayer.PLAYERSTATE_LOST

		If Self.playerID <> playerID
			Local toast:TGameToastMessage = New TGameToastMessage
			toast.SetLifeTime( 2.5 )
			toast.SetCaption("Gone...")
			toast.SetText( GetPlayer(playerID).name + " was removed from the system.")
			toast.captionColor = GameColorCollection.basePalette[7]
			toast.captionFont = GetBitmapFont("default")
			toast.textFont = GetBitmapFont("small")
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		Else
			MessageWindowCollection.OpenGameLostWindow()
		EndIf
	End Method


	Method RenderPlayerControls()
		Local vpx:Int, vpy:Int, vpw:Int, vph:Int
		If space.screenArea
			GetGraphicsManager().GetViewport(vpx, vpy, vpw, vph)
			GetGraphicsManager().SetViewport(space.screenArea.GetIntX(), space.screenArea.GetIntY(), space.screenArea.GetIntW(), space.screenArea.GetIntH())
		EndIf


		If groupSelectionArea
			'add offset as we render to the screen, not the "space"
			Local r:TRectangle = groupSelectionArea.Copy()
			r.position = space.LocalPosToScreen(r.position)
			DrawMarkerRect(r, 1)
		EndIf


		If space.screenArea
			GetGraphicsManager().SetViewport(vpx, vpy, vpw, vph)
		EndIf
	End Method



	Method Update:Int()
		'update events
		Local toRemove:Int[]
		For Local t:TIntKey = EachIn mapEvents.Keys()
			Local ev:TMapEvent = TMapEvent(mapEvents.ValueForKey(t.value))
			If ev.notifyEnabled And Not ev.notifyDone And ev.GetNotifyTime() < GameTime.GetTimeGone()
				ev.DoNotify()
			EndIf

			If t.value <= GameTime.GetTimeGone()
				TMapEvent(mapEvents.ValueForKey(t.value)).Execute()
				toRemove :+ [t.value]
			EndIf
		Next

		For Local t:Int = EachIn toRemove
			mapEvents.Remove(t)
		Next

	'	While mapEvents._FirstNode().Key() < GameTime.GetTimeGone()
	'		TMapEvent(mapEvents._FirstNode().Value()).Execute()
	'		mapEvents.Remove( mapEvents._FirstNode().Key() )
	'	Wend


		If Not hud.HasOpenModalWindow()
			UpdatePlayerControls()
		EndIf

		For Local p:TPlayer = EachIn players
			p.Update()
		Next

		space.Update()

		gameStatsArchiveTimer :- GetGameTimeDelta()
		If gameStatsArchiveTimer <= 0
			For Local p:TPlayer = EachIn players
				If Not p.state = TPlayer.PLAYERSTATE_ALIVE Then Continue

				GetPlayerGameStatsArchive(p.playerID).ArchiveCurrent()
			Next
			gameStatsArchiveTimer = 15
		EndIf


		If rebelsAllowed And Not rebelsActivated
			'check time
			If rebelsTime > 0 And rebelsTime < GameTime.GetTimeGone()/1000
				StartRebels()
			EndIf
			'check planets
			If rebelsUnusedPlanets > 0 And rebelsUnusedPlanets <= space.GetPlanetCount(0)
				StartRebels()
			EndIf
		EndIf

		If mapTimeLimit > 0 And Long(GameTime.GetTimeGone() / 1000) > mapTimeLimit
			Game.SetPlayerLost(game.GetPlayer().playerID)
		EndIf

		CheckPlayerStates()
		UpdateGameStats()
	End Method


	Method Render:Int()
		space.Render()
		RenderPlayerControls()
	End Method




	Function onPlanetSetOwner:Int(triggerEvent:TEventBase)
		Local oldOwnerID:Int = triggerEvent.GetData().GetInt("oldOwnerID", -1)
		Local ownerID:Int = triggerEvent.GetData().GetInt("ownerID", -1)

		If oldOwnerID > 0 Then game.GetPlayerGameStats(oldOwnerID).planetsLost :+ 1
		If ownerID > 0 Then game.GetPlayerGameStats(ownerID).planetsWon :+ 1

		If oldOwnerID = game.playerID
			SimpleSoundSource.PlayRandomSfx("planet_lost")
		ElseIf ownerID = game.playerID
			SimpleSoundSource.PlayRandomSfx("planet_won")
		EndIf

	End Function
End Type




Type TGameStats
	Field population:Int
	Field domination:Float
	Field planetsOwned:Int
	Field planetsWon:Int
	Field planetsLost:Int
	Field shipsStarted:Int
	Field missilesBought:Int
	Field missilesStarted:Int
	Field planetsHit:Int
	Field shipsHit:Int
	Field techtreeProgress:Float

	Method Copy:TGameStats()
		Local c:TGameStats = New TGameStats
		c.population = population
		c.domination = domination
		c.planetsOwned = planetsOwned
		c.planetsWon = planetsWon
		c.planetsLost = planetsLost
		c.shipsStarted = shipsStarted
		c.missilesBought = missilesBought
		c.missilesStarted = missilesStarted
		c.planetsHit = planetsHit
		c.shipsHit = shipsHit
		c.techtreeProgress = techtreeProgress
		Return c
	End Method


	Method GetAtIndex:Int(index:Int)
		Select index
			Case 0	Return population
			Case 1	Return Int(100*domination)
			Case 2	Return planetsOwned
			Case 3	Return planetsWon
			Case 4	Return planetsLost
			Case 5	Return shipsStarted
			Case 6	Return missilesBought
			Case 7	Return missilesStarted
			Case 8	Return planetsHit
			Case 9	Return shipsHit
			Case 10	Return Int(100*techtreeProgress)
		End Select
		Return 0
	End Method
End Type




Type TGameStatsArchive
	Field currentStats:TGameStats
	Field stats:TGameStats[]
	Field statsTime:Long[]

	Method New()
		currentStats = New TGameStats
	End Method


	Method GetCurrent:TGameStats()
		Return currentStats
	End Method


	Method ArchiveCurrent()
		AddStats( currentStats.copy() )
	End Method


	Method AddStats(g:TGameStats)
		stats :+ [g]
		statsTime :+ [GameTime.GetTimeGone()]
	End Method
End Type




Type TSpace
	'defines area occupied on screen - to know scroll requirements
	Field screenArea:TRectangle
	Field viewOffset:TVec2D = New TVec2D
	Field width:Int = 400
	Field height:Int = 300
	Field minOffsetX:Int = 0
	Field maxOffsetX:Int = 400 - 320
	Field minOffsetY:Int = 0
	Field maxOffsetY:Int = 300 - 200

	Field selectedPlanets:TPlanet[]

	Field _shipsAlive:Int[] = New Int[0] '0 = all, 1 = of player 1 ...

	Field deadShips:int[] = new Int[0]
	Field deadMissiles:int[] = new Int[0]

	Field planets:TPlanet[]
	Field missiles:TIntMap = New TIntMap
	Field ships:TIntMap = New TIntMap
	Field backgroundStars:TBackgroundStar[]
	Global _eventListeners:TLink[]
	Global _initDone:Int = False
	Global _instance:TSpace


	Function GetInstance:TSpace()
		If Not _instance Then _instance = New TSpace
		Return _instance
	End Function


	Method New()
		If Not _initDone
			'=== EVENTS ===
			'=== remove all registered event listeners
			EventManager.unregisterListenersByLinks(_eventListeners)
			_eventListeners = New TLink[0]

			'=== register event listeners
			'to react on changes in the programmeCollection (eg. custom script finished)
			_eventListeners :+ [ EventManager.registerListenerFunction( "Planet.SpawnShip", onPlanetSpawnsShip ) ]
			_eventListeners :+ [ EventManager.registerListenerFunction( "Planet.SpawnMissile", onPlanetSpawnsMissile ) ]
			_eventListeners :+ [ EventManager.registerListenerFunction( "Ship.ArriveTarget", onShipArrivesTarget ) ]
			_eventListeners :+ [ EventManager.registerListenerFunction( "Missile.ArriveTarget", onMissileArrivesTarget ) ]

			_initDone = True
		EndIf
	End Method


	Method SetScreenArea(x:Int, y:Int, w:Int, h:Int)
		screenArea = New TRectangle.Init(x,y,w,h)

		UpdateScrollLimits()
	End Method


	Method UpdateScrollLimits()
		If screenArea
			minOffsetX = 0
			maxOffsetX = width - screenArea.GetIntW()
			minOffsetY = 0
			maxOffsetY = height - screenArea.GetIntH()
		Else
			minOffsetX = 0
			maxOffsetX = width
			minOffsetY = 0
			maxOffsetY = height
		EndIf
		'clamp to new rules
		ScrollView(0, 0)
	End Method


	Method InitBackgroundStars:Int()
		backgroundStars = New TBackgroundStar[100]
		For Local i:Int = 0 Until backgroundStars.length
			backgroundStars[i] = New TBackgroundStar
			'TODO: Abstand zu anderen Planeten und Sternen!
			backgroundStars[i].position = New TVec3D.Init(RandRange(10, width-10), RandRange(10, height-10), -0.5 -0.05 * RandRange(1, 10))
		Next
	End Method


	Method Init(planetConfigs:TData[], playerCount:Int, width:Int, height:Int)
		Self.width = width
		Self.height = height
		Self._shipsAlive = New Int[playerCount + 1] '0 = all

		InitBackgroundStars()

		UpdateScrollLimits()



		planets = New TPlanet[ planetConfigs.length ]
		For Local i:Int = 0 Until planets.length
			If Not planetConfigs[i] Then planetConfigs[i] = New TData

			planets[i] = New TPlanet
			planets[i].ID = i+1 'start with 1
			planets[i].size = 11 'RandRange(9, 11)

			planets[i].name = planetConfigs[i].GetString("name")
			If Not planets[i].name Then planets[i].name = GeneratePlanetName()

			Local pX:Int = planetConfigs[i].GetInt("x", -1)
			Local pY:Int = planetConfigs[i].GetInt("y", -1)

			If pX = -1 And planetConfigs[i].GetInt("x2", -1) > 0 Then pX = width - planetConfigs[i].GetInt("x2")
			If pY = -1 And planetConfigs[i].GetInt("y2", -1) > 0 Then pY = height - planetConfigs[i].GetInt("x2")

			If pX <> -1 And pY <> -1
				pX = MathHelper.Clamp(pX, 15, width - 15)
				pY = MathHelper.Clamp(pY, 15, height - 15)
				planets[i].SetPosition(pX, pY )
			Else

				'position planet
				'and check distance to previous planets
				Local positionOK:Int = True
				Local minimumDistance:Int = 50
				Repeat
					positionOK = True
					Local tries:Int = 0
					Repeat
						positionOK = True

						planets[i].SetPosition(RandRange(15, width-15), RandRange(15, height-15))
						For Local j:Int = 0 Until i
							If planets[i].position.DistanceTo(planets[j].position) < minimumDistance
								positionOK = False
								Exit
							EndIf
						Next
						tries :+ 1
					Until positionOK Or tries > 20
					minimumDistance :- 2
					If minimumDistance <= 0 Then Throw "no place to position planet #"+i
				Until positionOK
			EndIf

			planets[i].population = planetConfigs[i].GetInt("population", -1)
			If planets[i].population = -1 Then planets[i].population = RandRange(5, 10)

			planets[i].ownerID = planetConfigs[i].GetInt("owner", 0) 'default to unowned

			planets[i].missiles = planetConfigs[i].GetInt("missiles", 0)
			planets[i].missilesLimit = planetConfigs[i].GetInt("missilesLimit", 0)
			planets[i].researchPoints = planetConfigs[i].GetFloat("researchPoints", 0)
		Next
	End Method


	Method InitRandom(playerCount:Int, planetCount:Int, width:Int, height:Int)
		Self.width = width
		Self.height = height
		Self._shipsAlive = New Int[playerCount + 1] '0 = all

		InitBackgroundStars()

		UpdateScrollLimits()

		planets = New TPlanet[planetCount]
		For Local i:Int = 0 Until planets.length
			planets[i] = New TPlanet
			planets[i].ID = i+1 'start with 1
			planets[i].size = 11 'RandRange(9, 11)
			planets[i].name = GeneratePlanetName()

			'position planet
			'and check distance to previous planets
			Local positionOK:Int = True
			Local minimumDistance:Int = 50
			Repeat
				positionOK = True
				Local tries:Int = 0
				Repeat
					positionOK = True

					planets[i].SetPosition(RandRange(15, width-15), RandRange(15, height-15))
					For Local j:Int = 0 Until i
						If planets[i].position.DistanceTo(planets[j].position) < minimumDistance
							positionOK = False
							Exit
						EndIf
					Next
					tries :+ 1
				Until positionOK Or tries > 20
				minimumDistance :- 2
				If minimumDistance <= 0 Then Throw "no place to position planet #"+i
			Until positionOK
		Next


		RandomizePlanetPopulation()
		RandomizePlanetAssignments(playerCount, 1)
	End Method


	Method ScrollView:Int(dx:Int, dy:Int)
		ScrollViewTo(Int(viewOffset.x + dx), Int(viewOffset.y + dy))
	End Method


	Method ScrollToPlayerPlanet(playerID:Int, planetID:Int=-1, selectPlanet:Int = True)
		'(try to) center to players planet
		For Local p:TPlanet = EachIn planets
			If p.ownerID = playerID
				ScrollViewTo(p.position.GetIntX() - Int(0.5 * screenArea.GetIntW()), p.position.GetIntY() - Int(0.5 * screenArea.GetIntH()))
				If selectPlanet Then AddSelectedPlanetByID(p.ID)
				Exit
			EndIf
		Next
	End Method


	'x and y are LOCAL not SCREEN
	Method ScrollViewTo:Int(x:Int, y:Int)
		viewOffset.x = MathHelper.Clamp(x, minOffsetX, maxOffsetX)
		viewOffset.y = MathHelper.Clamp(y, minOffsetY, maxOffsetY)
	End Method


	Method ScreenXToLocal:Int(screenX:Int)
		Return screenX + viewOffset.x - screenArea.GetIntX()
	End Method

	Method ScreenYToLocal:Int(screenY:Int)
		Return screenY + viewOffset.y - screenArea.GetIntY()
	End Method

	Method ScreenPosToLocal:TVec2D(screenPos:TVec2D)
		Return screenPos.Copy().AddXY(viewOffset.x - screenArea.GetIntX(), viewOffset.y - screenArea.GetIntY())
	End Method

	Method LocalPosToScreen:TVec2D(localPos:TVec2D)
		Return localPos.Copy().AddXY(- viewOffset.x + screenArea.GetIntX(), - viewOffset.y + screenArea.GetIntY())
	End Method


	Method RandomizePlanetPopulation:Int(minPop:Int=5, maxPop:Int=10)
		For Local planet:TPlanet = EachIn planets
			planet.population = RandRange(minPop, maxPop)
		Next
	End Method


	'Assign planets to players
	Method RandomizePlanetAssignments(playerCount:Int, planetsPerPlayer:Int = 1, startPopulation:Int = 8)
		For Local playerID:Int = 1 To playerCount 'start with 1!
			Local assignedPlanets:Int = 0
			For Local planet:TPlanet = EachIn planets
				If planet.ownerID <> 0 Then Continue

				planet.SetOwner(playerID)
				planet.population = startPopulation

				assignedPlanets :+ 1
				If assignedPlanets >= planetsPerPlayer Then Exit
			Next
		Next
	End Method


	Method GetShipCount:Int(playerID:Int = 0)
		If playerID < 0 Or playerID >= _shipsAlive.length Then playerID = 0
		Return _shipsAlive[playerID]
	End Method


	Method GetAveragePlanetPopulation:Int(onlyOwned:Int = False)
		Local sum:Int
		Local count:Int
		For Local i:Int = 0 Until planets.length
			If onlyOwned And planets[i].ownerID <= 0 Then Continue

			sum :+ planets[i].GetPopulation()
			count :+ 1
		Next
		If count > 0 Then Return sum/count
		Return 0
	End Method


	Method GetPlanets:TPlanet[](ownerID:Int)
		Local result:TPlanet[] = New TPlanet[10]
		Local found:Int = 0

		For Local i:Int = 0 Until planets.length
			If planets[i].ownerID <> ownerID Then Continue

			If result.length <= found Then result = result[.. result.length + 5]
			result[found] = planets[i]
			found :+ 1
		Next
		If result.length <> found Then result = result[.. found]

		Return result
	End Method


	Method GetPlanet:TPlanet(planetID:Int)
		If planetID <= 0 Or planetID > planets.length Then Return Null
		Return planets[planetID-1]
	End Method


	Method GetPlanetCount:Int(playerID:Int = -1)
		If playerID = -1 Or playerID >= _shipsAlive.length Then Return planets.length

		Local result:Int
		For Local p:TPlanet = EachIn planets
			If p.ownerID = playerID Then result :+ 1
		Next

		Return result
	End Method


	Method GetSelectedPlanetIndex:Int(planetID:Int)
		If Not selectedPlanets Then Return -1

		For Local i:Int = 0 Until selectedPlanets.length
			If selectedPlanets[i].ID = planetID Then Return i
		Next
		Return -1
	End Method


	Method IsSelectedPlanet:Int(planetID:Int)
		Return GetSelectedPlanetIndex(planetID) >= 0
	End Method


	Method AddSelectedPlanetByID:Int(planetID:Int)
		Return AddSelectedPlanet( GetPlanet(planetID) )
	End Method


	Method AddSelectedPlanet:Int(planet:TPlanet)
		If Not planet Then Return False
		If Not IsSelectedPlanet(planet.ID)
			selectedPlanets :+ [planet]
			planet.SetSelected(True)
		EndIf

		hud.OpenSlider(False)
	End Method


	Method AddSelectedPlanets:Int(rect:TRectangle, ownerID:Int = -1)
		For Local p:TPlanet = EachIn planets
			If ownerID >= 0 And p.ownerID <> ownerID Then Continue

			If rect.ContainsVec(p.position) And Not IsSelectedPlanet(p.ID)
				AddSelectedPlanetByID(p.ID)
			EndIf
		Next
		Return True
	End Method


	Method DeselectPlanet:Int(planetID:Int)
		Local i:Int = GetSelectedPlanetIndex(planetID)
		If i < 0 Then Return False

		selectedPlanets[i].SetSelected(False)

		selectedPlanets = selectedPlanets[.. i] + selectedPlanets[i+1 ..]

		If selectedPlanets.length = 0
			hud.CloseSlider(False)
		EndIf

		Return True
	End Method


	Method DeselectPlanets:Int()
		If Not selectedPlanets Then Return True

		For Local p:TPlanet = EachIn selectedPlanets
			p.SetSelected(False)
		Next
		selectedPlanets = New TPlanet[0]

		hud.CloseSlider(False)

		Return True
	End Method


	Method AddShip:Int(ship:TShip)
		_shipsAlive[ship.ownerID] :+ 1
		_shipsAlive[0] :+ 1

		Return ships.Insert(ship.ID, ship)
	End Method


	Method RemoveShip:Int(shipID:Int)
		Local ship:TShip = GetShip(shipID)
		if ship and ship.alive
			_shipsAlive[ship.ownerID] :- 1
			_shipsAlive[0] :- 1
			ship.alive = False
		endif
		
		deadShips :+ [shipID]

		'Return ships.Remove(shipID)
		Return True
	End Method


	Method GetShip:TShip(shipID:Int)
		Return TShip(ships.ValueForKey(shipID))
	End Method


	Method AddMissile:Int(missile:TMissile)
		Return missiles.Insert(missile.ID, missile)
	End Method


	Method RemoveMissile:Int(missileID:Int)
		local missile:TMissile = GetMissile(missileID)

		deadMissiles :+ [missileID]
		if missile then missile.alive = False

		'Return missiles.Remove(missileID)
		Return True
	End Method


	Method GetMissile:TMissile(missileID:Int)
		Return TMissile(missiles.ValueForKey(missileID))
	End Method



	Method GetDomination:Float(playerID:Int)
		Local ownedPlanets:Int = 0
		For Local p:TPlanet = EachIn planets
			If p.ownerID = playerID Then ownedPlanets :+ 1
		Next

		Return ownedPlanets/Float(planets.length)
	End Method



	Method Update:Int()
		For Local star:TBackgroundStar = EachIn backgroundStars
			star.Update()
		Next


		For Local missile:TMissile = EachIn missiles.Values()
			missile.Update()
		Next


		For Local ship:TShip = EachIn ships.Values()
			ship.Update()
		Next
		

		For local id:int = EachIn deadShips
			ships.Remove(id)
		Next
		For local id:int = EachIn deadMissiles
			missiles.Remove(id)
		Next
		deadShips = new Int[0]
		deadMissiles = new Int[0]
		

		'ACHTUNG: eventuell Updates "randomisieren", damit jeder Planet
		'         mal zuerst dran kommt (angegriffen wird, produziert,...)
		For Local planet:TPlanet = EachIn planets
			planet.Update()
		Next
	End Method


	Method Render:Int()
		Local vpx:Int, vpy:Int, vpw:Int, vph:Int
		If screenArea
			GetGraphicsManager().GetViewport(vpx, vpy, vpw, vph)
			GetGraphicsManager().SetViewport(screenArea.GetIntX(), screenArea.GetIntY(), screenArea.GetIntW(), screenArea.GetIntH())
		EndIf

		Local mapOffsetX:Int = -viewOffset.GetIntX() + screenArea.GetIntX()
		Local mapOffsetY:Int = -viewOffset.GetIntY() + screenArea.GetIntY()

		For Local star:TBackgroundStar = EachIn backgroundStars
			star.Render(mapOffsetX, mapOffsetY)
		Next

		For Local planet:TPlanet = EachIn planets
			planet.Render(mapOffsetX, mapOffsetY)
			planet.RenderOverlays(mapOffsetX, mapOffsetY)
		Next

		For Local missile:TMissile = EachIn missiles.Values()
			missile.Render(mapOffsetX, mapOffsetY)
		Next

		For Local ship:TShip = EachIn ships.Values()
			ship.Render(mapOffsetX, mapOffsetY)
		Next


		If screenArea
			GetGraphicsManager().SetViewport(vpx, vpy, vpw, vph)
		EndIf

		Local localMousePos:TVec2D = ScreenPosToLocal(MouseManager.currentPos)
		'DrawText(localMousePos.GetIntX(), 4,8)
		'DrawText(localMousePos.GetIntY(), 4,16)
	End Method


	Function onShipArrivesTarget:Int(triggerEvent:TEventBase)
		Local ship:TShip = TShip(triggerEvent.GetSender())
		Local targetPlanet:TPlanet = space.GetPlanet(triggerEvent.GetData().GetInt("targetPlanetID",-1))
		If Not ship Or Not targetPlanet Then Return False

		targetPlanet.OnShipArrives(ship.ownerID)

		space.RemoveShip(ship.ID)
	End Function


	Function onMissileArrivesTarget:Int(triggerEvent:TEventBase)
		Local missile:TMissile = TMissile(triggerEvent.GetSender())
		If Not missile Then Return False

		Local targetPlanet:TPlanet
		Local targetShip:TShip

		If triggerEvent.GetData().GetInt("targetPlanetID", -1) > 0
			targetPlanet = space.GetPlanet( triggerEvent.GetData().GetInt("targetPlanetID", -1) )
		ElseIf triggerEvent.GetData().GetInt("targetShipID", -1) > 0
			targetShip = space.GetShip( triggerEvent.GetData().GetInt("targetShipID", -1) )
		EndIf
		'do not return - remove missile even if target ship does no longer exist
		'If Not targetPlanet and not targetShip Then Return False

		If targetPlanet
			targetPlanet.OnMissileArrives(missile.ID, missile.ownerID, missile)

			game.GetPlayerGameStats(missile.ownerID).planetsHit :+ 1
		EndIf
		If targetShip
			targetShip.OnMissileArrives(missile.ID, missile.ownerID, missile)
			space.RemoveShip(targetShip.ID)

			game.GetPlayerGameStats(missile.ownerID).shipsHit :+ 1
		EndIf

		space.RemoveMissile(missile.ID)
	End Function


	Function onPlanetSpawnsShip:Int(triggerEvent:TEventBase)
		Local planet:TPlanet = TPlanet(triggerEvent.GetSender())
		If Not planet Then Return False

		Local targetPlanet:TPlanet = space.GetPlanet( triggerEvent.GetData().GetInt("targetPlanetID", -1) )
		If Not targetPlanet Then Return False

		Local ship:TShip = New TShip
		ship.ownerID = planet.ownerID
		ship.sourcePlanetID = planet.ID
		ship.targetPlanetID = targetPlanet.ID
		ship.position = planet.position.Copy()

		ship.speed = planet.GetShipSpeed()
		'randomize start on planet a bit
		ship.position.AddXY(RandRange(-planet.size/2, planet.size/2), RandRange(-planet.size/2, planet.size/2))

		ship.sourcePosition = ship.position.Copy()
		ship.targetPosition = targetPlanet.position 'no copy so it can adjust

		game.GetPlayerGameStats(planet.ownerID).shipsStarted :+ 1

		space.AddShip(ship)

'		Print "planet "+ planet.ID+" spawns ship to planet " + targetPlanet.ID
	End Function


	Function onPlanetSpawnsMissile:Int(triggerEvent:TEventBase)
		Local planet:TPlanet = TPlanet(triggerEvent.GetSender())
		If Not planet Then Return False


		Local targetPlanet:TPlanet
		Local targetShip:TShip

		If triggerEvent.GetData().GetInt("targetPlanetID", -1) > -1
			targetPlanet = space.GetPlanet( triggerEvent.GetData().GetInt("targetPlanetID", -1) )
		ElseIf triggerEvent.GetData().GetInt("targetShipID", -1) > -1
			targetShip = space.GetShip( triggerEvent.GetData().GetInt("targetShipID", -1) )
		EndIf
		If Not targetPlanet And Not targetShip Then Return False

		Local missile:TMissile = New TMissile
		missile.ownerID = planet.ownerID
		missile.position = planet.position.Copy()

		missile.speed = 20 ' planet.GetShipSpeed()
		'randomize start on planet a bit
		missile.position.AddXY(RandRange(-planet.size/2, planet.size/2), RandRange(-planet.size/2, planet.size/2))

		missile.sourcePosition = missile.position.Copy()
		missile.sourcePlanetID = planet.ID

		If targetPlanet
			missile.targetPlanetID = targetPlanet.ID
			missile.targetPosition = targetPlanet.position 'no copy so it can follow a moving target
		ElseIf targetShip
			missile.targetShipID = targetShip.ID
			missile.targetPosition = targetShip.position 'no copy so it can follow a moving target
		EndIf
		game.GetPlayerGameStats(missile.ownerID).missilesStarted :+ 1

		space.AddMissile(missile)
	End Function
End Type



Type TMessageWindowCollection
	Field windows:TMessageWindow[]

	Method Reset:Int()
		For Local w:TMessageWindow = EachIn windows
			w.Destroy()
		Next
		windows = New TMessageWindow[0]
	End Method


	Method RemoveByScreenLimit:Int(screenLimit:String)
		Local toRemove:TMessageWindow[] = New TMessageWindow[0]

		For Local w:TMessageWindow = EachIn windows
			If w.screenLimit = screenLimit Then toRemove :+ [w]
		Next

		For Local w:TMessageWindow = EachIn toRemove
			RemoveMessageWindow(w)
		Next
		Return toRemove.length
	End Method


	Method HasOpenModalWindow:Int()
		Return windows.length > 0
	End Method


	Method IsActiveWindow:Int(w:TMessageWindow)
		If windows And windows.length > 0 And windows[ windows.length -1 ] = w Then Return True
		Return False
	End Method


	Method Update:Int(screenLimit:String)
		Local destroyedWindows:Int = 0
		'update from "down to top"
		For Local i:Int = 0 Until windows.length
			If Not windows Then Exit 'eg a savegame load
			Local w:TMessageWindow = windows[windows.length-1 - i]

			'skip others
			If screenLimit And w.screenLimit And w.screenLimit <> screenLimit Then Continue
			w.Update()
			If w._destroyed Then destroyedWindows :+ 1
		Next
		If destroyedWindows
			Local newWindows:TMessageWindow[] = New TMessageWindow[ windows.length - destroyedWindows ]
			Local addedWindows:Int = 0
			For Local w:TMessageWindow = EachIn windows
				If Not w._destroyed
					newWindows[addedWindows] = w
					addedWindows :+ 1
				EndIf
			Next
			windows = newWindows
		EndIf
	End Method


	Method Render:Int(screenLimit:String)
		For Local w:TMessageWindow = EachIn windows
			'skip others
			If screenLimit And w.screenLimit And w.screenLimit <> screenLimit Then Continue
			w.Render(0, 0)
		Next
	End Method


	Method MoveMessageWindowInStack:Int(w:TMessageWindow)
		If RemoveMessageWindow(w)
			Return AddMessageWindow(w)
		EndIf
		Return False
	End Method


	Method RemoveMessageWindow:Int(w:TMessageWindow)
		w.Destroy()
		Local index:Int
		For Local i:Int = 0 Until windows.length
			If w = windows[i]
				index = i
				Exit
			EndIf
		Next

		'nothing to do
		If windows.length = 1
			windows = New TMessageWindow[0]
		Else
			windows = windows[.. index] + windows[index+1 ..]
		EndIf
		Return True
	End Method


	Method AddMessageWindow:Int(w:TMessageWindow)
		windows :+ [w]
		Return True
	End Method


	Method OpenIngameMenu:Int()
		'is there already one?
		For Local w:TMessageWindow = EachIn windows
			If TMessageWindow_InGameMenu(w)
				'put at bottom of stack
				Return MoveMessageWindowInStack(w)
			EndIf
		Next

		Local width:Int = 33 + 3*23 +2
		Local xCenter:Int = 259/2

		Local w:TMessageWindow_InGameMenu = New TMessageWindow_InGameMenu
		w.area = New TRectangle.Init(xCenter - width/2, 10, width, 30 + 24*6)
		w.screenLimit = GetScreenManager().GetCurrent().name
		w.Open()

		windows :+ [w]
	End Method


	Method OpenGameStatsWindow:Int(exitOnClose:Int = False)
		'is there already one?
		For Local w:TMessageWindow = EachIn windows
			If TMessageWindow_GameStats(w) Then Return False
		Next

		Local width:Int = 33 + 8*23
		Local xCenter:Int = 259/2

		Local w:TMessageWindow_GameStats = New TMessageWindow_GameStats
		w.area = New TRectangle.Init(xCenter - width/2, 20, width, 30 + 21*6)
		w.screenLimit = "ingame"
		w.exitOnClose = exitOnClose
		w.Open()

		windows :+ [w]
	End Method


	Method OpenUpgradeWindow:Int()
		'is there already one?
		For Local w:TMessageWindow = EachIn windows
			If TMessagewindow_Upgrade(w) Then Return False
		Next

		Local w:TMessagewindow_Upgrade = New TMessagewindow_Upgrade
		w.area = New TRectangle.Init(18,20, 33 + 8*23, 30 + 21*6)
		w.screenLimit = "ingame"
		If space.selectedPlanets.length = 1
			w.planetID = space.selectedPlanets[0].ID
		EndIf
		w.Open()

		windows :+ [w]
	End Method


	Method OpenLevelStartWindow:Int()
		'is there already one?
		For Local w:TMessageWindow = EachIn windows
			If TMessageWindow_LevelStart(w) Then Return False
		Next

		Local w:TMessagewindow_LevelStart = New TMessagewindow_LevelStart
		w.area = New TRectangle.Init(18,16, 33 + 8*23, 30 + 23*6)
		w.screenLimit = "ingame"
		w.Open()

		windows :+ [w]
	End Method


	Method OpenGameWonWindow:Int(xCenter:Int = -1)
		'is there already one?
		For Local w:TMessageWindow = EachIn windows
			If TMessagewindow_GameWon(w)
				'put at bottom of stack
				Return MoveMessageWindowInStack(w)
			EndIf
		Next

		Local width:Int = 33 + 6*23
		If xCenter = - 1 Then xCenter = 259/2
		Local w:TMessageWindow_GameWon = New TMessageWindow_GameWon
		w.area = New TRectangle.Init(xCenter - width/2, 20, width, 30 + 20*6)
		w.screenLimit = GetScreenManager().GetCurrent().name
		w.Open()

		windows :+ [w]

	End Method


	Method OpenGameLostWindow:Int(xCenter:Int = -1)
		'is there already one?
		For Local w:TMessageWindow = EachIn windows
			If TMessagewindow_GameLost(w)
				'put at bottom of stack
				Return MoveMessageWindowInStack(w)
			EndIf
		Next

		Local width:Int = 33 + 6*23
		If xCenter = - 1 Then xCenter = 259/2
		Local w:TMessageWindow_GameLost = New TMessageWindow_GameLost
		w.area = New TRectangle.Init(xCenter - width/2, 20, width, 30 + 20*6)
		w.screenLimit = GetScreenManager().GetCurrent().name
		w.Open()

		windows :+ [w]

	End Method


	Method OpenSettings:Int(xCenter:Int = -1)
		'is there already one?
		For Local w:TMessageWindow = EachIn windows
			If TMessageWindow_Settings(w)
				'put at bottom of stack
				Return MoveMessageWindowInStack(w)
			EndIf
		Next

		Local width:Int = 33 + 6*23
		If xCenter = - 1 Then xCenter = 259/2
		Local w:TMessageWindow_Settings = New TMessageWindow_Settings
		w.area = New TRectangle.Init(xCenter - width/2, 20, width, 30 + 20*6)
		w.screenLimit = GetScreenManager().GetCurrent().name
		w.Open()

		windows :+ [w]
	End Method


	Method OpenLoadMenu:Int(xCenter:Int = -1)
		'is there already one?
		For Local w:TMessageWindow = EachIn windows
			If TMessageWindow_LoadOrSaveGameMenu(w)
				'make sure we are saving now (might be an old saving-menu)
				TMessageWindow_LoadOrSaveGameMenu(w).SetLoadMode(True)

				'put at bottom of stack
				Return MoveMessageWindowInStack(w)
			EndIf
		Next

		Local width:Int = 33 + 6*23
		If xCenter = - 1 Then xCenter = 259/2
		Local w:TMessageWindow_LoadOrSaveGameMenu = New TMessageWindow_LoadOrSaveGameMenu
		w.SetLoadMode(True)
		w.area = New TRectangle.Init(xCenter - width/2, 20, width, 30 + 19*6)
		w.screenLimit = GetScreenManager().GetCurrent().name
		w.Open()

		windows :+ [w]
	End Method


	Method OpenSaveMenu:Int(xCenter:Int = -1)
		'is there already one?
		For Local w:TMessageWindow = EachIn windows
			If TMessageWindow_LoadOrSaveGameMenu(w)
				'make sure we are saving now (might be an old loading-menu)
				TMessageWindow_LoadOrSaveGameMenu(w).SetLoadMode(False)

				'put at bottom of stack
				Return MoveMessageWindowInStack(w)
			EndIf
		Next

		Local width:Int = 33 + 6*23
		If xCenter = - 1 Then xCenter = 259/2
		Local w:TMessageWindow_LoadOrSaveGameMenu = New TMessageWindow_LoadOrSaveGameMenu
		w.SetLoadMode(False)
		w.area = New TRectangle.Init(xCenter - width/2, 20, width, 30 + 21*6)
		w.screenLimit = GetScreenManager().GetCurrent().name
		w.Open()

		windows :+ [w]
	End Method
End Type




Type THud
	Field minimap:TMinimap = New TMinimap
	Field sliderOpenPercentage:Float
	Field sliderDirection:Int = 0
	Field popCount:Int
	Field rpCount:Float
	Field missileCount:Int
	Field missileLimit:Int
	Field selectionTitle:String
	Field font:TBitmapFont {nosave}


	Method Reset:Int()
		minimap = New TMinimap
		sliderOpenPercentage = 0.0
		sliderDirection = 0

		MessageWindowCollection.Reset()

		popCount = 0.0
		rpCount = 0.0
		missileCount = 0
		missileLimit = 0
		selectionTitle = ""
		Return True
	End Method


	Method HasOpenModalWindow:Int()
		Return MessageWindowCollection.HasOpenModalWindow()
	End Method


	Method Update:Int()
		minimap.Update()

		If Not HasOpenModalWindow()
			If space.screenArea And space.screenArea.Contains(MouseManager.currentPos)
				If MouseManager.x <= space.screenArea.GetX() + 10 Then space.ScrollView(-2, 0)
				If MouseManager.x >= space.screenArea.GetX2() - 10 Then space.ScrollView(+2, 0)
				If MouseManager.y <= space.screenArea.GetY() + 10 Then space.ScrollView(0, -2)
				If MouseManager.y >= space.screenArea.GetY2() - 10 And MouseManager.y <= space.screenArea.GetY2() Then space.ScrollView(0, +2)
			EndIf

			If KeyManager.IsHit(KEY_SPACE)
				Game.SetPaused( Not game.IsPaused() )
			EndIf


			If MouseManager.IsHit(1)
				If space.selectedPlanets And space.selectedPlanets.length = 1 And space.selectedPlanets[0].ownerID = game.playerID
					If missileLimit = game.missilesPerPlanetLimit
						'
					ElseIf game.GetPlayer().GetResearchPoints() < 1
						'
					ElseIf space.selectedPlanets[0].ownerID = game.playerID
						If New TRectangle.Init(301, 126, 15, 12).Contains(MouseManager.currentPos)
							game.BuyMissileForPlanet(game.playerID, space.selectedPlanets[0].ID)
							MouseManager.ResetKey(1)
						EndIf
					EndIf
				EndIf
			EndIf


'			If space.selectedPlanets and space.selectedPlanets.length = 1 and space.selectedPlanets[0].ownerID = game.playerID
				If MouseManager.IsHit(1) And New TRectangle.Init(271, 141, 40, 17).Contains(MouseManager.currentPos)
					MessageWindowCollection.OpenUpgradeWindow()
					MouseManager.ResetKey(1)
				EndIf
'			endif

			Local menuX:Int = 263
			Local menuRect:TRectangle = New TRectangle.Init(menuX, 181, 0,0)
			Local menuButtons:String[] = ["menu.pause", "menu.speed1", "menu.speed2", "menu.speed3", "menu.esc"]
			For Local name:String = EachIn menuButtons
				Local s:TSprite = GetSpriteFromRegistry(name+".normal")
				menuRect.dimension.SetXY(s.GetWidth(), s.GetHeight())

				If MouseManager.IsHit(1) And menuRect.Contains(MouseManager.currentPos)
					If name = "menu.pause" Then Game.SetPaused(True)
					If name = "menu.speed1" Then Game.SetPaused(False); Game.SetGameSpeed(1)
					If name = "menu.speed2" Then Game.SetPaused(False); Game.SetGameSpeed(2)
					If name = "menu.speed3" Then Game.SetPaused(False); Game.SetGameSpeed(3)
					If name = "menu.esc" Then MessageWindowCollection.OpenIngameMenu()
					MouseManager.ResetKey(1)
				EndIf
				menuRect.MoveXY(s.GetWidth()+2, 0)
			Next
		EndIf
	End Method


	Method OpenSlider:Int(restart:Int = False)
		If restart Then sliderOpenPercentage = 0
		sliderDirection = 1
	End Method

	Method CloseSlider:Int(restart:Int = False)
		If restart Then sliderOpenPercentage = 1.0
		sliderDirection = -1
	End Method


	Method Render:Int()
		If Not font Then font = GetBitmapFont("small")

		If sliderDirection = 1
			sliderOpenPercentage :+ 0.02
		ElseIf sliderDirection = -1
			sliderOpenPercentage :- 0.02
		EndIf
		If sliderOpenPercentage > 1.0 Then sliderOpenPercentage = 1.0; sliderDirection = 0
		If sliderOpenPercentage < 0.0 Then sliderOpenPercentage = 0; sliderDirection = 0

		'slot backgrounds
		GameColorCollection.basePalette[11].SetRGB()
		DrawRect(260,89,35,60)

		SetColor 255,255,255


		If sliderOpenPercentage > 0.0
			If space.selectedPlanets.length > 0
				popCount = 0
				rpCount = 0
				missileCount = 0
				missileLimit = 0
				For Local p:TPlanet = EachIn space.selectedPlanets
					popCount :+ p.GetPopulation()
					rpCount :+ p.GetResearchPoints()
					missileCount :+ p.GetMissileCount()
					missileLimit :+ p.GetMissileLimit()
				Next
			EndIf
			font.DrawBlock(popCount, 269, 90-1 +1, 20, 10, ALIGN_RIGHT_CENTER, GameColorCollection.basePalette[0])
			font.DrawBlock(popCount, 269, 90-1, 20, 10, ALIGN_RIGHT_CENTER, GameColorCollection.basePalette[15])

			font.DrawBlock(MathHelper.NumberToString(rpCount, 2), 269, 105-1 +1, 20, 10, ALIGN_RIGHT_CENTER, GameColorCollection.basePalette[0])
			font.DrawBlock(MathHelper.NumberToString(rpCount, 2), 269, 105-1, 20, 10, ALIGN_RIGHT_CENTER, GameColorCollection.basePalette[15])

			font.DrawBlock(missileCount, 269, 120-1 +1, 20, 10, ALIGN_RIGHT_CENTER, GameColorCollection.basePalette[0])
			font.DrawBlock(missileCount, 269, 120-1, 20, 10, ALIGN_RIGHT_CENTER, GameColorCollection.basePalette[15])
		EndIf


		GetSpriteFromRegistry("slot.slider").DrawInArea(266 + Int(-22*MathHelper.Clamp(sliderOpenPercentage, 0, 1.0)), 89, New TRectangle.Init(264, 89, 27, 11) )
		GetSpriteFromRegistry("slot.slider").DrawInArea(266 + Int(-26*MathHelper.Clamp(sliderOpenPercentage * 1.05, 0, 1.0)), 104, New TRectangle.Init(264, 104, 27, 11) )
		GetSpriteFromRegistry("slot.slider").DrawInArea(266 + Int(-30*MathHelper.Clamp(sliderOpenPercentage * 1.1, 0, 1.0)),119, New TRectangle.Init(264,119, 27, 11) )




		GetSpriteFromRegistry("hud.top").Draw(0,0)
		GetSpriteFromRegistry("hud.bottom").Draw(0,0)
		GetSpriteFromRegistry("hud.right").Draw(0,0)
		minimap.Render()




'		If space.selectedPlanets and space.selectedPlanets.length = 1 and space.selectedPlanets[0].ownerID = game.playerID
			If New TRectangle.Init(270, 141, 40, 17).Contains(MouseManager.currentPos)
				GetSpriteFromRegistry("button.upgrade.hover").Draw(270, 141)
			Else
				GetSpriteFromRegistry("button.upgrade.normal").Draw(270, 141)
			EndIf
'		EndIf


		Local menuX:Int = 262
		Local menuRect:TRectangle = New TRectangle.Init(menuX, 181, 0,0)
		Local menuButtons:String[] = ["menu.pause", "menu.speed1", "menu.speed2", "menu.speed3", "menu.esc"]
		For Local name:String = EachIn menuButtons
			Local s:TSprite = GetSpriteFromRegistry(name+".normal")
			menuRect.dimension.SetXY(s.GetWidth(), s.GetHeight())

			If menuRect.Contains(MouseManager.currentPos)
				GetSpriteFromRegistry(name+".hover").Draw(menuRect.GetIntX(), menuRect.GetIntY())
			Else
				Local state:String = ".normal"
				If name="menu.pause" And Game.IsPaused() Then state = ".active"
				If name="menu.esc"  Then state = ".active"
				If Not Game.IsPaused() And name="menu.speed1" And GameTime.speedFactor = 1.0 Then state = ".active"
				If Not Game.IsPaused() And name="menu.speed2" And GameTime.speedFactor = 2.0 Then state = ".active"
				If Not Game.IsPaused() And name="menu.speed3" And GameTime.speedFactor = 3.0 Then state = ".active"
				GetSpriteFromRegistry(name+state).Draw(menuRect.GetIntX(), menuRect.GetIntY())
			EndIf

			menuRect.MoveXY(s.GetWidth()+2, 0)
		Next


		If space.selectedPlanets And space.selectedPlanets.length = 1 And space.selectedPlanets[0].ownerID = game.playerID
			If missileLimit = game.missilesPerPlanetLimit
				GetSpriteFromRegistry("button.missileup.max").Draw(301, 126)
			ElseIf game.GetPlayer().GetResearchPoints() < 1
				GetSpriteFromRegistry("button.missileup.disabled").Draw(301, 126)
			Else 'if missileCount < game.missilesPerPlanetLimit
				If New TRectangle.Init(301, 126, 15, 12).Contains(MouseManager.currentPos)
					GetSpriteFromRegistry("button.missileup.hover").Draw(301, 126)
				Else
					GetSpriteFromRegistry("button.missileup.normal").Draw(301, 126)
				EndIf
			EndIf
		EndIf



		SetColor 0,0,0
		DrawRect(262, 60, 55, 15)
		SetColor 255,255,255

		If space.selectedPlanets.length = 1
			Local p:TPlanet = space.selectedPlanets[0]
			selectionTitle = p.name
		ElseIf space.selectedPlanets.length > 1
			selectionTitle = "MULTIPLE"
		EndIf
		font.DrawBlock(selectionTitle, 263, 62, 52, 11, ALIGN_CENTER_CENTER, GameColorCollection.basePalette[15])

		GetSpriteFromRegistry("slider.door.left").DrawInArea(264 + Int(-19*sliderOpenPercentage),62, New TRectangle.Init(264, 62, 26, 11) )
		GetSpriteFromRegistry("slider.door.right").DrawInArea(290 + Int(+19*sliderOpenPercentage),62, New TRectangle.Init(290, 62, 26, 11) )
		GetSpriteFromRegistry("slider.top").Draw(262, 60)



		For Local i:Int = 1 To 20 * game.GetPlayer().GetResearchPointsPercentage()
			If i > 10
				GetSpriteFromRegistry("bar.researchSmall").Draw(103 + 4*(i-10-1) + (i>15)*1, 193 + 4)
				If i > 19 And (Time.GetTimeGone()/500) Mod 2 = 0
					GetSpriteFromRegistry("bar.researchWarnSmall").Draw(103 + 4*(i-10-1) + (i>15)*1, 193 + 4)
				EndIf
			Else
				GetSpriteFromRegistry("bar.researchSmall").Draw(103 + 4*(i-1) + (i>5)*1, 193)
			EndIf
		Next
Rem
		local maxRP:int = 10 * game.GetPlayer().GetResearchPointsPercentage()
		For Local i:Int = 1 To maxRP
			if i mod 2 = 0
				GetSpriteFromRegistry("bar.research2").Draw(108 + 2*(i-1), 193)
			elseif i mod 2 = 1 and i <> maxRP
				GetSpriteFromRegistry("bar.research1").Draw(108 + 2*(i-1), 193)
			endif
endrem
		For Local i:Int = 1 To 10 * game.GetPlayer().GetSpaceDominationPercentage()
			GetSpriteFromRegistry("bar.domination").Draw(199 + 4*(i-1) + (i>5)*1, 193)
		Next


		If space.selectedPlanets And space.selectedPlanets.length > 0
			font.DrawBlock(missileLimit, 269+13, 120-1 +1, 20, 10, ALIGN_RIGHT_CENTER, GameColorCollection.basePalette[0])
			font.DrawBlock(missileLimit, 269+13, 120-1, 20, 10, ALIGN_RIGHT_CENTER, GameColorCollection.basePalette[15])
		EndIf

		Local gTime:Long = Long(GameTime.GetTimeGone() / 1000)
		Local textCol:TGameColor = GameColorCollection.basePalette[1]
		If game.mapTimeLimit > 0
'print gTime +"  limit="+game.mapTimeLimit +"   timeGonE=" + GameTime.GetTimeGone()
			gTime = game.mapTimeLimit - gTime
			If gTime < 60 And Time.GetTimeGone()/500 Mod 2 = 1
				textCol = GameColorCollection.basePalette[10]
			ElseIf gTime < 120 And Time.GetTimeGone()/500 Mod 2 = 1
				textCol = GameColorCollection.basePalette[7]
			EndIf
		EndIf

		Local gameTimeStr:String = RSet((gTime/60),2).Replace(" ", "0") + ":" + RSet((gTime Mod 60),2).Replace(" ", "0")
		font.DrawBlock(gameTimeStr, 273,1, 34, 8, ALIGN_CENTER_TOP, GameColorCollection.basePalette[11])
		font.DrawBlock(gameTimeStr, 273,0, 34, 8, ALIGN_CENTER_TOP, textCol)
	End Method
End Type




Type TMinimap
	Field area:TRectangle = New TRectangle.Init(267, 16, 44, 28)
	'pixels of "minimap" per space pixel
	Field scaleX:Float
	Field scaleY:Float
	Field spaceViewportScaleX:Float
	Field spaceViewportScaleY:Float


	Method Update:Int()
		scaleX = area.GetW() / space.width 'space.screenArea.GetW()
		scaleY = area.GetH() / space.height 'space.screenArea.GetH()
		spaceViewportScaleX = space.screenArea.GetW() / space.width
		spaceViewportScaleY = space.screenArea.GetH() / space.height

		'handle clicks

		If Not hud.HasOpenModalWindow()
			If (MouseManager.IsHit(1) Or MouseManager.IsDown(1)) And area.Contains(MouseManager.currentPos)
				Local halfW:Int = Int(0.5 * area.GetIntW() * spaceViewportScaleX)
				Local halfH:Int = Int(0.5 * area.GetIntH() * spaceViewportScaleY)
				Local localX:Int = MathHelper.Clamp(MouseManager.currentPos.GetIntX() - area.GetIntX() - halfW, 0, area.GetIntW())
				Local localY:Int = MathHelper.Clamp(MouseManager.currentPos.GetIntY() - area.GetIntY() - halfH, 0, area.GetIntH())

				space.ScrollViewTo(Int(localX / scaleX), Int(localY / scaleY))
			EndIf
		EndIf
	End Method


	Method Render:Int()
		'background
		SetColor 0,0,0
		DrawRect(area.GetIntX(), area.GetIntY(), area.GetIntW(), area.GetIntH())
		SetColor 255,255,255


		'planets
		For Local p:TPlanet = EachIn space.planets
			If p.ownerID <= 0
				game.playerColors[0].SetRGB()
			Else
				game.playerColors[p.ownerID].SetRGB()
			EndIf

			DrawRect(area.GetIntX() + p.position.GetIntX() * scaleX, area.GetIntY() + p.position.GetIntY() * scaleY, 1, 1)
		Next
		SetColor 255,255,255



		'viewport / passepartout
		If spaceViewportScaleX < 1 Or spaceViewportScaleY < 1
			RenderViewportRect()
		EndIf
	End Method


	Method RenderViewportRect()
		'coverage of viewport
		Local currentX:Int = area.GetIntX() + space.viewOffset.x * scaleX
		Local currentY:Int = area.GetIntY() + space.viewOffset.y * scaleY
		Local w:Int = area.GetIntW() * spaceViewportScaleX
		Local h:Int = area.GetIntH() * spaceViewportScaleY

		GameColorCollection.basePalette[10].SetRGB()
		DrawRect(currentX, currentY, 1, h)
		DrawRect(currentX, currentY, w, 1)
		DrawRect(currentX + w - 1, currentY, 1 , h)
		DrawRect(currentX, currentY + h - 1, w, 1)

		SetColor 255,255,255
	End Method
End Type



Type TMissile Extends TSpacecraft
	Field targetShipID:Int = -1
	Field _targetCheckTurns:Int = 10
	Global lastID:Int = 0

Rem
homing missiles -> planeten abwehr / Planeten-Im-Radius-Auto-Attack
-> jeder abwehrlevel erhoeht "max missiles"
-> missiles laden aller x spielsekunden +1
-> jede missile schiesst das naechste Angriffsschiff ab
endrem

	Method New()
		lastID :+ 1
		ID = lastID
	End Method


	Method ApproachTarget:Int()
		If targetPlanetID
			Local p:TPlanet = space.GetPlanet(targetPlanetID)
			If p Then p.OnMissileApproaching(Self.ID, Self.ownerID, Self)
		ElseIf targetShipID
			Local s:TShip = space.GetShip(targetShipID)
			If s Then s.OnMissileApproaching(Self.ID, Self.ownerID, Self)
		EndIf
	End Method


	Method ArriveTarget:Int() 'override
		EventManager.triggerEvent( TEventSimple.Create( "Missile.ArriveTarget", New TData.AddNumber("sourcePlanetID", sourcePlanetID).AddNumber("targetPlanetID", targetPlanetID).AddNumber("targetShipID", targetShipID).AddNumber("ownerID", Self.ownerID), Self ) )
		Super.ArriveTarget()
	End Method


	Method Update:Int() 'override
		'here and there we need to check if our target is still valid
		'doing it only on occassion means to save some CPU

		_targetCheckTurns :- 1
		If _targetCheckTurns <= 0
			'too slow - ship already removed/arrived
			If targetShipID And Not space.GetShip(targetShipID)
				ArriveTarget()
			EndIf

			_targetCheckTurns = 10
		EndIf

		Return Super.Update()
	End Method


	Method Render:Int(offsetX:Int=0, offsetY:Int=0)
		If (Time.GetTimeGone() / 150) Mod 2 = 0
			Local ownerColor:TGameColor = game.playerColors[ownerID] 'ownerID is 1-based
			If ownerColor Then ownerColor.SetRGB()
		Else
			GameColorCollection.basePalette[15].SetRGB()
		EndIf

		DrawRect(offsetX + position.GetIntX(), offsetY + position.GetIntY(), 1, 1)

		SetColor(255,255,255)
	End Method
End Type




Type TShip Extends TSpacecraft
	Field targetedByPlanetID:Int = -1
	Field targetedByPlayerID:Int = -1
	Global lastID:Int = 0


	Method New()
		lastID :+ 1
		ID = lastID
	End Method


	Method ApproachTarget:Int()
		If targetPlanetID
			Local p:TPlanet = space.GetPlanet(targetPlanetID)
			If p Then p.OnShipApproaching(Self.ID, Self.ownerID, Self)
		EndIf
	End Method


	Method ArriveTarget:Int() 'override
		EventManager.triggerEvent( TEventSimple.Create( "Ship.ArriveTarget", New TData.AddNumber("sourcePlanetID", sourcePlanetID).AddNumber("targetPlanetID", targetPlanetID).AddNumber("ownerID", Self.ownerID), Self ) )
		Super.ArriveTarget()
	End Method


	Method OnTargetedByMissile:Int(missileOwnerID:Int, sourcePlanetID:Int)
		targetedByPlanetID = sourcePlanetID
		targetedByPlayerID = missileOwnerID

		Return True
	End Method


	Method OnMissileApproaching:Int(missileID:Int, missileOwnerID:Int, sender:Object)
		'todo: defense?
	End Method


	Method OnMissileArrives(missileID:Int, missileOwnerID:Int, sender:Object)
'		print "ship " + ID +"  got hit by missile: " + missileID
		'todo: inform player / diplomacy adjustments
	End Method
End Type




Type TSpacecraft
	Field ID:Int
	Field ownerID:Int
	Field sourcePlanetID:Int = -1
	Field targetPlanetID:Int = -1
	Field alive:int = True

	'to avoid flickering on windows
	Field lastPosition:TVec2D
	Field position:TVec2D
	Field speed:Float = 10
	Field sourcePosition:TVec2D
	Field targetPosition:TVec2D

	Global lastID:Int = 0
	Global approachDistanceFlyBy:Int = 15
	Global approachDistanceTarget:Int = 30


	Method New()
		lastID :+ 1
		ID = lastID
	End Method


	Method ArriveTarget:Int()
		targetPosition = Null
		targetPlanetID = 0
		sourcePlanetID = 0
	End Method


	Method ApproachTarget:Int() Abstract


	Method Update:Int()
		If targetPosition
			Local shipRadius:Int = 1
			Local distanceToTarget:Int = position.DistanceTo(targetPosition)

			If distanceToTarget >= 1
				'how strong the target "attracts" the ship
				Local pull:TVec2D = targetPosition.Copy().SubtractVec(position).MultiplyFactor(1.0/distanceToTarget)
				Local totalPush:TVec2D = New TVec2D '0,0

				'iterate over all planets/obstacles to check how much they attract us
				Local contenders:Int = 0
				For Local planet:TPlanet = EachIn space.planets
					'ignore target!
					If planet.position.IsSame(targetPosition) Then Continue

					'force vector of obstacle pushing away the ship
                    Local push:TVec2D = position.Copy().SubtractVec(planet.position)

                    'calculate how much we are pushed away from this obstacle, the closer, the more push
                    Local distance:Float = position.DistanceTo(planet.position) - planet.size ' - shipRadius

					'inform planet about flyby enemy objects
                    If distance < approachDistanceFlyBy And planet.ownerID <> Self.ownerID
						planet.OnShipFlyBy(Self.ID, Self.ownerID, Self)
					EndIf

                    'only use push force if this object is close enough such that an effect is needed
                    If distance < shipRadius * 3
						contenders :+ 1
                        If distance < 0.0001 Then distance = 0.0001

                        Local weight:Float = 0.00004 * 1.0/distance
                        totalPush.AddVec( push.MultiplyFactor(weight) )
                    EndIf
				Next

                '4 * contenders gives the pull enough force to pull stuff trough (tweak this setting for your game!)
                pull.MultiplyFactor( Max(1, 4 * contenders) )
                pull.AddVec(totalPush)

                'Normalize the vector so that we get a vector that points in a certain direction, which we van multiply by our desired speed
                pull.Normalize()
                'Set the ships new position:

				position.AddVec( pull.MultiplyFactor(speed * GetGameTimeDelta()) )
			EndIf

			Local resultingDistanceToTarget:Int = position.DistanceTo(targetPosition)


			'inform target about approaching ship
			If resultingDistanceToTarget < approachDistanceTarget Then ApproachTarget()
			If resultingDistanceToTarget < 1 Then ArriveTarget()
		EndIf
	End Method


	Method Render:Int(offsetX:Int=0, offsetY:Int=0)
		If AVOID_FLICKERING
'Rem
		'avoid flickering
		If lastPosition
			GameColorCollection.basePalette[11].SetRGB()
			DrawRect(offsetX + lastPosition.GetIntX(), offsetY + lastPosition.GetIntY(), 1, 1)
		EndIf
'EndRem
Rem
		If lastPosition
			GameColorCollection.basePalette[10].SetRGB()
			DrawRect(offsetX + lastPosition.GetIntX(), offsetY + lastPosition.GetIntY(), 1, 1)
		EndIf
EndRem
		EndIf

		Local ownerColor:TGameColor = game.playerColors[ownerID] 'ownerID is 1-based
		If ownerColor Then ownerColor.SetRGB()

		DrawRect(offsetX + position.GetIntX(), offsetY + position.GetIntY(), 1, 1)
'If Not lastPosition Or lastPosition.DistanceTo(position) >= 1 Then lastPosition = position.Copy()

lastPosition = position.Copy()
		SetColor(255,255,255)
	End Method
End Type




Type TBackgroundStar
	Field position:TVec3D = New TVec3D
	'for flickering
	Field animPos:Int
	Field animTime:Float
	Field animDuration:Float = 0.50
	'defines color
	Field variant:Int
	Field colors:TGameColor[]
	Field twinkleInterval:Int = 10
	Field twinkleTimer:Float = 0
	'time left of the twinkleAnim
	Field twinkleAnimTimer:Float = 0
	'how long a twinkle takes
	Const twinkleAnimTime:Float = 0.8

	Method New()
		animDuration = RandRange(40,60)*0.01
		variant = BiasedRandRange(0, 3, 0.2)
'		variant = RandRange(0,3)
		twinkleInterval = RandRange(20,40)
		twinkleTimer = twinkleInterval + RandRange(0,40)
	End Method


	Method InitColors()
		colors = New TGameColor[5]
		For Local i:Int = 0 Until colors.length
			colors[i] = GameColorCollection.FindSimilarRGB(i*30 + (variant=2)*50, i*30 + (variant=1)*50, i*30 + (variant=3)*50)
		Next
	End Method



	Method Update:Int()
		animTime :+ GetDeltaTimer().GetDelta()
		If animTime > animDuration
			animTime = 0
			animPos :+ 1
			If animPos > colors.length*2 Then animPos = 0
		EndIf

		twinkleTimer :- GetDeltaTimer().GetDelta()
		If twinkleTimer <= 0
			twinkleTimer = twinkleInterval
			'start twinkle anim
			twinkleAnimTimer = twinkleAnimTime
		EndIf

		If twinkleAnimTimer >= 0 Then twinkleAnimTimer :- GetDeltaTimer().GetDelta()
	End Method


	Method Render:Int(offsetX:Int=0, offsetY:Int=0)
		'modify offset according to "z" (depth) for a parallax effect
		If position.GetZ() < 0
			offsetX = offsetX * 0.8 - 0.2 / position.GetZ()
			offsetY = offsetY * 0.8 - 0.2 / position.GetZ()
		EndIf


		If Not colors Or colors.length = 0 Then InitColors()
		Local colorIndex:Int = animPos
		'0,1,2,3...3,2,1,0
		If colorIndex >= colors.length Then colorIndex = Max(0, colors.length*2-colorIndex -1)


		'draw twinkle
		If twinkleAnimTimer > 0
			'1,2,1
			Local twinkleAnimPos:Int = Abs(2 - Int(3 * (twinkleAnimTimer/twinkleAnimTime)))
			If twinkleAnimPos > 0
				If twinkleAnimPos = 1 Then GameColorCollection.extendedPalette[11].SetRGB()
				If twinkleAnimPos = 2 Then GameColorCollection.extendedPalette[12].SetRGB()
				DrawRect(offsetX + position.GetIntX() - 1, offsetY + position.GetIntY(), 3, 1)
				If twinkleAnimPos = 2 Then GameColorCollection.extendedPalette[11].SetRGB()
				If twinkleAnimPos = 1 Then GameColorCollection.extendedPalette[12].SetRGB()
				DrawRect(offsetX + position.GetIntX(), offsetY + position.GetIntY() - 1, 1, 3)
			EndIf
		EndIf

		colors[colorIndex].SetRGB()
		DrawRect(offsetX + position.GetIntX(), offsetY + position.GetIntY(), 1, 1)
		SetColor(255, 255, 255)
	End Method
End Type



Type TPlanet
	Field ID:Int
	Field name:String
	Field ownerID:Int = 0
	Field position:TVec2D = New TVec2D
	Field area:TRectangle
	Field size:Int = 9
	Field hovered:Int = 0
	Field selected:Int = 0

	'stored points on this planet
	Field researchPoints:Float = 0
	Field lastResearchPoints:Float = 0
	Field nextResearchTimer:Double = 1.0 '1 second

	Field spawnShipsQueue:TSpawnShipsCommand[]
	'how many harbors exist to spawn ships simultaneously
	'or at least to run multiple queues at once
	Field shipHarborCount:Int = 1

	'how many ships are currently flying to this planet
	'0 = total, 1-X = players
	Field incomingShips:Int[]
	Field incomingMissiles:Int[]
	Field missiles:Int = 0
	Field missilesLimit:Int = 0
	Field nextMissileRefillTimer:Double = 4 'in seconds

	Field population:Int
	Field populationGrowthRate:Float = 1.1
	Field nextPopulationGrowthTimer:Double = 1.0 '1 second


	Method New()
		incomingShips = New Int[6 + 1]
		incomingMissiles = New Int[6 + 1]

		nextPopulationGrowthTimer = TGame.defaultPopulationGrowthTime
		nextMissileRefillTimer = TGame.defaultMissileRefillTime
		nextResearchTimer = TGame.defaultResearchTime
	End Method


	Method GetArea:TRectangle()
		If Not area And Not position Then Return New TRectangle
		If Not area Then area = New TRectangle.Init(position.GetIntX()- size/2, position.GetIntY()-size/2, size, size)
		'area.SetXY(position.GetIntX()-4, position.GetIntY()-4)
		Return area
	End Method


	Method SetPosition(x:Int, y:Int)
		If Not position Then position = New TVec2D
		position.SetXY(x, y)
	End Method


	Method GetPopulationGrowthRate:Float()
		'no growth for unowned planets
		If ownerID = 0 Then Return 0

		Select population
			Case 0
				Return 0
			Case 1
				Return 1 * game.GetPlayer(ownerID).GetPopulationGrowthRateMod()
			Default
				Return 1.2 * game.GetPlayer(ownerID).GetPopulationGrowthRateMod()
		End Select
	End Method


	Method GetPopulation:Int()
		Return population
	End Method


	Method GetMissileCount:Int()
		Return missiles
	End Method


	Method GetMissileLimit:Int()
		Return missilesLimit
	End Method


	Method IsMissileMaxReached:Int()
		Return missilesLimit >= game.missilesPerPlanetLimit
	End Method


	Method GetResearchPoints:Float()
		Return researchPoints
	End Method

	Method GetResearchRate:Float()
		Return 1.0 * game.GetPlayer(ownerID).GetResearchRateMod()
	End Method


	Method GetMissileRefillRate:Float()
		Return 1.0 * game.GetPlayer(ownerID).GetMissileRefillRateMod()
	End Method

?bmxng
	Method GetIncomingMissilesCount:Int(playerID:Int)
		Return incomingMissiles[playerID]
	End Method
?

	Method GetIncomingMissilesCount:Int(ignorePlayerIDs:Int[])
		If Not ignorePlayerIDs Or ignorePlayerIDs.length = 0
			Return incomingMissiles[0]
		EndIf

		Local result:Int
		For Local i:Int = 1 Until incomingMissiles.length-1
			If MathHelper.InIntArray(i, ignorePlayerIDs) Then Continue

			result :+ incomingMissiles[i]
		Next
		Return result
	End Method


	Method GetIncomingShipCountByPlayer:Int(playerID:Int)
		Return incomingShips[playerID]
	End Method


	Method GetIncomingShipCount:Int(ignorePlayerIDs:Int[])
		If Not ignorePlayerIDs Or ignorePlayerIDs.length = 0
			Return incomingShips[0]
		EndIf

		Local result:Int
		For Local i:Int = 1 Until incomingShips.length-1
			If MathHelper.InIntArray(i, ignorePlayerIDs) Then Continue

			result :+ incomingShips[i]
		Next
		Return result
	End Method


	Method GetShipCount:Int(usePopulation:Int = -1)
		If usePopulation = -1 Or usePopulation > population Then usePopulation = population
		Return usePopulation/2
	End Method


	Method GetShipSpeed:Int()
		Return game.GetPlayer(ownerID).GetShipSpeed()
	End Method


	Method SetHovered(bool:Int)
		hovered = bool
	End Method


	Method SetSelected(bool:Int)
		selected = bool
	End Method


	Method SetOwner:Int(ownerID:Int)
		If Self.ownerID = ownerID Then Return True

		Local oldOwnerID:Int = Self.ownerID

		nextPopulationGrowthTimer = 1.0
		Self.ownerID = ownerID

		'loose all ship spawns and also the population of it!
		Self.spawnShipsQueue = New TSpawnShipsCommand[0]

		EventManager.triggerEvent( TEventSimple.Create( "Planet.SetOwner", New TData.AddNumber("planetID", Self.ID).AddNumber("oldOwnerID", oldOwnerID).AddNumber("ownerID", Self.ownerID), Self ) )
	End Method


	Method SpawnShips:Int(amount:Int, targetPlanetID:Int, spawnDelay:Float = 5)
		If population <= 1 Then Return False
		'keep at least 1 on this planet
		amount = Min(amount, population-1)

		Local command:TSpawnShipsCommand = New TSpawnShipsCommand.Init(amount, Self.ID, targetPlanetID, spawnDelay)
		spawnShipsQueue :+ [command]

		population :- amount

		Return True
	End Method


	Method SpawnShip:Int(targetPlanetID:Int)
		'inform target planet
		'TODO: do this as event?
		Local targetPlanet:TPlanet = space.GetPlanet(targetPlanetID)
		If targetPlanet Then targetPlanet.OnTargetedByShip(ownerID, ID)

		'also store the owner in this moment
		EventManager.triggerEvent( TEventSimple.Create( "Planet.SpawnShip", New TData.AddNumber("sourcePlanetID", Self.ID).AddNumber("targetPlanetID", targetPlanetID).AddNumber("ownerID", Self.ownerID), Self ) )
	End Method


	Method SpawnMissile:Int(targetShipID:Int=-1, targetPlanetID:Int=-1)
		If missiles = 0 Then Return False
		missiles :- 1

		'inform target planet
		'TODO: do this as event?
		If targetShipID >= 0
			Local targetShip:TShip = space.GetShip(targetShipID)
			If targetShip Then targetShip.OnTargetedByMissile(ownerID, ID)
		ElseIf targetPlanetID >= 0
			Local targetPlanet:TPlanet = space.GetPlanet(targetPlanetID)
			If targetPlanet Then targetPlanet.OnTargetedByShip(ownerID, ID)
		EndIf

		'also store the owner in this moment
		EventManager.triggerEvent( TEventSimple.Create( "Planet.SpawnMissile", New TData.AddNumber("sourcePlanetID", Self.ID).AddNumber("targetPlanetID", targetPlanetID).AddNumber("targetShipID", targetShipID).AddNumber("ownerID", Self.ownerID), Self ) )
	End Method


	Method GetEarnResearchPointsRate:Float()
		Return TGame.defaultResearchTime / GetResearchRate()
	End Method


	Method GetResearchPointsProductionRate:Float()
		'not correct but easier to calculate than using logistical influence
		'calculations
		Return lastResearchPoints * GetEarnResearchPointsRate()
	End Method


	Method EarnResearchPoints:Int()
		'linear ... boring !
		'Local addResearchPoints:Float = GetPopulation() * 0.001

		'using a logistic function means "grow fast and later slower"
		'with 500 or more you reach maximum of "researchers"
		'leading to 0.1 points
		Local addResearchPoints:Float = 0.1 * Helper.LogisticalInfluence_Euler(GetPopulation()/500.0, 5)

		researchPoints :+ addResearchPoints

		EventManager.triggerEvent( TEventSimple.Create( "Planet.EarnResearchPoints", New TData.AddNumber("planetID", Self.ID).AddNumber("researchPoints", addResearchPoints).AddNumber("ownerID", Self.ownerID), Self ) )
	End Method


	Method RefillMissiles:Int(amount:Int = 1)
		If missiles = missilesLimit Then Return False
		missiles = MathHelper.Clamp(missiles + amount, 0, missilesLimit)
		Return True
	End Method


	Method OnCollectResearchPoints:Int()
		lastResearchPoints = researchPoints
		researchPoints = 0.0
	End Method


	Method OnTargetedByShip:Int(shipOwnerID:Int, sourcePlanetID:Int)
		'for all
		incomingShips[0] = Max(0, incomingShips[0] + 1)
		'for player
		incomingShips[shipOwnerID] = Max(0, incomingShips[shipOwnerID] + 1)

		Return True
	End Method


	Method OnTargetedByMissile:Int(missileOwnerID:Int, sourcePlanetID:Int)
		'for all
		incomingMissiles[0] = Max(0, incomingMissiles[0] + 1)
		'for player
		incomingMissiles[missileOwnerID] = Max(0, incomingMissiles[missileOwnerID] + 1)

		Return True
	End Method


	Method OnMissileApproaching:Int(missileID:Int, missileOwnerID:Int, sender:Object)
		'can we hit them?
	End Method


	Method OnShipFlyBy:Int(shipID:Int, shipOwnerID:Int, sender:Object)
		'TODO: in war with them?
		Local inWar:Int = True

		If inWar
			Return OnShipApproaching(shipID, shipOwnerID, sender)
		Else
			Return False
		EndIf
	End Method


	Method OnShipApproaching:Int(shipID:Int, shipOwnerID:Int, sender:Object)
		'check if we have missiles left...
		If missiles = 0 Then Return False

		'our ships?
		If shipOwnerID = ownerID Then Return False

		'check if we target this ship already?
		Local s:TShip = TShip(sender)
		If Not s Then s = space.GetShip(shipID)
		If s.targetedByPlanetID = Self.ID Then Return False

		'send out a missile
		SpawnMissile(shipID)
	End Method


	'either add population or decrease and maybe change owner of the
	'planet
	Method OnShipArrives(shipOwnerID:Int)
		'for all
		incomingShips[0] = Max(0, incomingShips[0] - 1)
		'for player
		incomingShips[shipOwnerID] = Max(0, incomingShips[shipOwnerID] - 1)

		If shipOwnerID = ownerID
			population :+ 1
		Else
			population :- 1
			If population = 0
				SetOwner(0)
			ElseIf population < 0
				population :* -1
				SetOwner(shipOwnerID)
			EndIf
		EndIf
	End Method


	Method OnMissileArrives(missileID:Int, missileOwnerID:Int, sender:Object)
		'for all
		incomingMissiles[0] = Max(0, incomingMissiles[0] - 1)
		'for player
		incomingShips[missileOwnerID] = Max(0, incomingMissiles[missileOwnerID] - 1)

		population = Max(0, population - 1)
		If population = 0
			SetOwner(0)
		EndIf
	End Method


	Method Update:Int()
		If ownerID > 0
			nextPopulationGrowthTimer :- GetGameTimeDelta() * GetPopulationGrowthRate()
			If nextPopulationGrowthTimer <= 0
				population :+ 1
				nextPopulationGrowthTimer = TGame.defaultPopulationGrowthTime
			EndIf

			nextResearchTimer :- GetGameTimeDelta() * GetResearchRate()
			If nextResearchTimer <= 0
				EarnResearchPoints()
				nextResearchTimer = TGame.defaultResearchTime
			EndIf

			nextMissileRefillTimer :- GetGameTimeDelta() * GetMissileRefillRate()
			If nextMissileRefillTimer <= 0
				RefillMissiles()
				'the more missiles we have, the faster we refill them
				'0.98 -> 20 missiles lead to 66% of the time
				nextMissileRefillTimer = TGame.defaultMissileRefillTime * 0.98^missilesLimit
			EndIf
		EndIf


		'update ship spawn queues
		Local finishedCommands:Int = 0
		For Local i:Int = 0 Until Min(spawnShipsQueue.length, shipHarborCount)
			Local cmd:TSpawnShipsCommand = spawnShipsQueue[i]
			If Not cmd
				finishedCommands :+ 1
				Continue
			EndIf

			If Not cmd.IsStarted() Then cmd.Start()
			cmd.Update()

			If cmd.IsFinished() Then finishedCommands :+ 1
		Next
		If finishedCommands > 0
			If finishedCommands = spawnShipsQueue.length
				spawnShipsQueue = New TSpawnShipsCommand[0]
			Else
				Local newQueue:TSpawnShipsCommand[] = New TSpawnShipsCommand[spawnShipsQueue.length - finishedCommands]
				Local added:Int = 0
				For Local i:Int = 0 Until spawnShipsQueue.length
					If Not spawnShipsQueue[i] Or spawnShipsQueue[i].IsFinished() Then Continue
					newQueue[added] = spawnShipsQueue[i]
				Next
				spawnShipsQueue = newQueue
			EndIf
		EndIf
	End Method


	Method Render:Int(offsetX:Int=0, offsetY:Int=0)
		Local area:TRectangle = GetArea()

Rem
		if ownerID > 0
			Local ownerColor:TGameColor = game.playerColors[ownerID] 'ownerID is 1-based
			If ownerColor Then ownerColor.SetRGB()
		endif

		DrawOval(offsetX + area.GetIntX(), offsetY + area.GetIntY(), area.GetIntW(), area.GetIntH())

		if ownerID > 0
			SetColor(255,255,255)
		endif
EndRem
		Local raceID:Int = 0
		If ownerID > 0 Then raceID = game.GetPlayer(ownerID).raceID
		If raceID = 7 Then raceID = 0 'rebels use gray too
		GetSpriteFromRegistry("planet."+ raceID ).Draw(offsetX + position.GetIntX(), offsetY + position.GetIntY(), -1, ALIGN_CENTER_CENTER)
	End Method


	Method RenderOverlays:Int(offsetX:Int, offsetY:Int)
		Local area:TRectangle = GetArea()
		If hovered
			DrawMarkerRectXYWH(offsetX + area.GetIntX()-2, offsetY + area.GetIntY()-2, area.GetIntW()+4, area.GetIntH()+4, 0)
		ElseIf selected
			DrawMarkerRectXYWH(offsetX + area.GetIntX()-2, offsetY + area.GetIntY()-2, area.GetIntW()+4, area.GetIntH()+4, 1)
		EndIf


'		if ownerID > 0
			SetColor(255,255,255)
			GetBitmapFont("small").DrawBlock(population, offsetX + position.GetIntX() - 10 +2, offsetY + position.GetIntY() - 14, 20, 10, ALIGN_CENTER_CENTER)
			'DrawText("0123456789 ABC", offsetX + position.GetIntX() - 5, offsetY + position.GetIntY() - 12 - 10)
'		endif
	End Method
End Type




Type TSpawnShipsCommand
	'amount of ships spawned
	Field amount:Int
	'when was this command created?
	Field createdTime:Long
	'at which gametime we spawn next?
	Field nextSpawnTime:Long
	'at which interval do we spawn?
	Field spawnInterval:Float

	Field sourcePlanetID:Int
	Field targetPlanetID:Int


	Method Init:TSpawnShipsCommand(amount:Int, sourcePlanetID:Int, targetPlanetID:Int, spawnInterval:Float = 5, startImmediately:Int = False)
		Self.amount = amount
		Self.createdTime = GameTime.GetTimeGone()
		If startImmediately 'ignore others in a potential queue?
			Self.nextSpawnTime = Self.createdTime
		Else
			Self.nextSpawnTime = -1
		EndIf
		Self.spawnInterval = spawnInterval

		Self.sourcePlanetID = sourcePlanetID
		Self.targetPlanetID = targetPlanetID
		Return Self
	End Method


	Method IsStarted:Int()
		Return nextSpawnTime <> -1
	End Method


	Method IsFinished:Int()
		Return amount <= 0
	End Method


	Method Start:Int()
		'done already
		If nextSpawnTime <> -1 Then Return True

		nextSpawnTime = GameTime.GetTimeGone()
		Return True
	End Method


	Method Update:Int()
		'not active yet
		If nextSpawnTime = -1 Then Return False

		While amount > 0 And GameTime.GetTimeGone() > nextSpawnTime
			SpawnShip()
		Wend
		Return True
	End Method


	Method SpawnShip:Int()
		Local planet:TPlanet = space.GetPlanet(sourcePlanetID)
		If planet Then planet.SpawnShip(targetPlanetID)

		amount :- 1

		'plan next ship
		If nextSpawnTime <> -1 Then nextSpawnTime :+ spawnInterval
	End Method


	'send back "still to spawn ships" to the planet population
	Method Abort:Int()
		Local planet:TPlanet = space.GetPlanet(sourcePlanetID)
		If Not planet Then Return False

		For Local i:Int = 0 Until amount
			planet.onShipArrives( planet.ownerID )
		Next

		'Schiffe unterwegs extra zurueckschicken?!
	End Method
End Type



Type TPlayer
	Field playerID:Int
	Field difficulty:Int = 100 '100%
	Field raceID:Int = 0
	Field raceResearchRateMod:Float = 1.0
	Field raceCollectResearchPointsRateMod:Float = 1.0
	Field raceShipSpeedMod:Float = 1.0
	Field racePopulationGrowthRateMod:Float = 1.0
	Field raceMissileRefillRateMod:Float = 1.0

	Field state:Int = 0
	Field isObserving:Int = False

	Field name:String
	Field AI:TAI
	Field techTree:TTechTree = New TTechTree
	Field researchPoints:Float = 0
	Field nextCollectResearchPointsTimer:Double = 5.0 '5 seconds

	Const COLLECT_RESEARCH_POINTS_TIME:Int = 5
	Const TECH_POINTS_MAX:Int = 20
	Const RESEARCH_POINTS_MAX:Int = 20

	Const PLAYERSTATE_ALIVE:Int = 0
	Const PLAYERSTATE_LOST:Int = 1
	Const PLAYERSTATE_WON:Int = 2

?bmxng
	Method New(playerID:Int)
		Self.playerID = playerID
	End Method
?

	Method IsAlive:Int()
		Return state = PLAYERSTATE_ALIVE
	End Method


	Method SetRace(raceID:Int)
		Self.raceID = raceID
		name = game.racesNames[raceID-1]

		Select raceID
			Case 1 'red / octopus
				raceResearchRateMod = 1.05
				raceCollectResearchPointsRateMod = 1.0
				raceShipSpeedMod = 1.0
				racePopulationGrowthRateMod = 1.0
			Case 2 'green / aqua
				raceResearchRateMod = 0.95
				raceCollectResearchPointsRateMod = 1.05
				raceShipSpeedMod = 1.05
				racePopulationGrowthRateMod = 1.0
			Case 3 'blue / blyshyn
				raceResearchRateMod = 1.05
				raceCollectResearchPointsRateMod = 1.0
				raceShipSpeedMod = 1.0
				racePopulationGrowthRateMod = 0.95
			Case 4 'pink
				raceResearchRateMod = 1.075
				raceCollectResearchPointsRateMod = 0.9
				raceShipSpeedMod = 0.95
				racePopulationGrowthRateMod = 1.05

				raceMissileRefillRateMod = 1.02
			Case 5
			Case 6
			Case 7
			Case 8, 9 'unknown
		End Select

		'predefine techtree levels ?!
	End Method


	'100 = normal difficulty ("100%" of something)
	Method SetDifficulty:Int(difficulty:Int)
		difficulty = MathHelper.Clamp(difficulty, 1, 300) '1 - 300%
		Self.difficulty = difficulty
		If AI Then AI.SetDifficulty(difficulty)
	End Method


	Method GetShipSpeed:Float()
		Return 7 * GetTechTree().GetShipSpeedMod() * raceShipSpeedMod
	End Method


	Method GetResearchRateMod:Float()
		Return raceResearchRateMod
	End Method


	Method GetMissileRefillRateMod:Float()
		Return GetTechTree().GetMissileRefillRateMod() * raceMissileRefillRateMod
	End Method


	Method GetCollectResearchPointsRateMod:Float()
		Return GetTechTree().GetCollectResearchPointsRateMod() * raceCollectResearchPointsRateMod
	End Method


	Method GetPopulationGrowthRateMod:Float()
		Return GetTechTree().GetPopulationGrowthRateMod() * racePopulationGrowthRateMod
	End Method


	Method GetResearchPointsProductionRate:Int()
		Local inProduction:Float
		For Local p:TPlanet = EachIn space.GetPlanets( playerID )
			inProduction :+ p.GetResearchPointsProductionRate()
		Next
		inProduction = MathHelper.Clamp(inProduction, 0, RESEARCH_POINTS_MAX)
		Return inProduction
	End Method


	Method CollectResearchPoints:Int()
		Local collected:Float
		For Local p:TPlanet = EachIn space.GetPlanets( playerID )
			collected :+ p.researchPoints
			p.OnCollectResearchPoints()
		Next
		researchPoints = MathHelper.Clamp(researchPoints + collected, 0, RESEARCH_POINTS_MAX)

		Return collected
	End Method


	Method SpawnShipsFromPlanets:Int(planets:TPlanet[], targetPlanetID:Int)
		If Not planets Or planets.length = 0 Then Return -1

		Local sent:Int

		For Local p:TPlanet = EachIn planets
			sent :+ SpawnShipsFromPlanet(p, targetPlanetID)
		Next
		Return sent
	End Method


	Method SpawnShipsFromPlanet:Int(planet:TPlanet, targetPlanetID:Int)
		'only send from our own
		If planet.ownerID <> Self.playerID Then Return -1

		Local spawnDelay:Int = 100.0/(planet.population/2) 'maximum of 100ms in total
		Local sent:Int = planet.population/2
		planet.SpawnShips(planet.population/2, targetPlanetID, spawnDelay)
		Return sent
	End Method


	Method GetTechTree:TTechTree()
		Return techTree
	End Method


	Method GetSpaceDominationPercentage:Float()
		Return space.GetDomination(playerID)
	End Method


	Method GetTotalPopulation:Int()
		Local res:Int
		For Local p:TPlanet = EachIn space.GetPlanets( playerID )
			res :+ p.GetPopulation()
		Next
		Return res
	End Method


	Method GetResearchPoints:Int()
		'Techpoint-Bruchteil geben wenn Planet fuer X Sekunden ohne Schiff auszuschicken ("ohne angefangenen Krieg")
		Return Int(researchPoints)
	End Method


	Method GetResearchPointsPercentage:Float()
		'use getter to correctly return "blocks" (integers)
		Return GetResearchPoints() / Float(TECH_POINTS_MAX)
	End Method


	Method Update:Int()
		'collect research points of owned planets
		nextCollectResearchPointsTimer :- GetGameTimeDelta() * GetCollectResearchPointsRateMod()
		If nextCollectResearchPointsTimer <= 0
			CollectResearchPoints()
			nextCollectResearchPointsTimer = COLLECT_RESEARCH_POINTS_TIME
		EndIf


		If AI
			AI.Update()
			Return True
		EndIf

		'human player
	End Method

End Type




Type TAI
	Field playerID:Int
	Field difficulty:Int
	Field homePlanetID:Int = -1
	'defines how many ships to "leave on a planet" to avoid sending out
	'and getting owned by another one
	Field riskyness:Int
	Field expansiveness:Int
	Field distanceAttractionMod:Float = 2.0
	Field populationAttractionMod:Float = 1.2
	Field nemesisPlayerID:Int = -1
	Field inWarWithPlayerIDs:Int[]
	Field lastResearchPointUsageType:Int = 0
	'time of next "thought"
	Field nextTickTime:Long
	'cache
	Field _planets:TPlanet[]
	Field _averagePlanetPopulation:Int


	Method RandomizeCharacter()
		riskyness = RandRange(1, 5)
		expansiveness = RandRange(1, 5)
		populationAttractionMod = 0.9 + RandRange(0,6)/10.0
		distanceAttractionMod = 1.2 + RandRange(0,8)/10.0
	End Method


	Method SetDifficulty:Int(difficulty:Int)
		Self.difficulty = MathHelper.Clamp(difficulty, 1, 300) '1 - 300%
	End Method


	Method GetTickInterval:Int()
		Return 600 * 0.92^(3 * difficulty/100.0)
	End Method


	Method GetPlanetPopulationMinimum:Int(planetID:Int=-1)
		'generic
		Return Max(1, Min(25, Max(4, 0.2*_averagePlanetPopulation)) * 0.9^riskyness) * (1 + 0.5*(planetID = homePlanetID))
	End Method


	Method GetEnemyMod:Float(enemyPlayerID:Int)
		Local result:Float = 1.0
		If IsInWarWithPlayer(enemyPlayerID) Then result :+ 0.5

		Return result
	End Method


	Method IsInWarWithPlayer:Int(playerID:Int)
		Return MathHelper.InIntArray(playerID, inWarWithPlayerIDs)
	End Method


	Method SendShipsToAPlanet:Int()
		Local player:TPlayer = game.GetPlayer(playerID)
		If Not player Then Return False

		'find planets to send stuff
		Local planetsWithShips:TPlanet[]
		Local totalPopulation:Int
		Local totalShips:Int

		For Local p:TPlanet = EachIn _planets
			Local possibleShips:Int = p.GetShipCount( p.GetPopulation() - GetPlanetPopulationMinimum(p.ID) )
			If possibleShips > 0
				planetsWithShips :+ [p]
				totalPopulation :+ p.GetPopulation()
				totalShips :+ possibleShips
			EndIf
		Next
		If totalShips = 0 Then Return False



		Local avgPlanetPosition:TVec2D = New TVec2D
		For Local p:TPlanet = EachIn planetsWithShips
			avgPlanetPosition.AddX( p.position.GetIntX() * p.GetPopulation()/Float(totalPopulation))
			avgPlanetPosition.AddY( p.position.GetIntY() * p.GetPopulation()/Float(totalPopulation))
		Next

		'find nearest planet (average for each planet who would send)
		Local bestPlanet:TPlanet
		Local bestAttraction:Float
'Ronny
Local s:String
		For Local i:Int = 0 Until space.GetPlanetCount()
			Local p:TPlanet = space.GetPlanet(i+1)
			If p.ownerID = player.playerID Then Continue

			'attraction "less population" per distance
			'distance is more important than population
			Local attraction:Float
			Local effectivePopulation:Int = p.GetPopulation()
			'modify population by incoming ships - subtract enemies and add our own
			'add support by owner
			If p.ownerID > 0 Then effectivePopulation :+ 0.9 * p.GetIncomingShipCountByPlayer( p.ownerID )
			'subtract enemies
			For Local i:Int = 1 Until game.players.length
				effectivePopulation :- 0.75 * p.GetIncomingShipCountByPlayer(i)
				'new owner ?
				If effectivePopulation < 0 Then effectivePopulation = Abs( p.GetIncomingShipCountByPlayer(i) )
			Next

			Local populationAttraction:Float = 1000 * populationAttractionMod
			If effectivePopulation >0 Then populationAttraction = populationAttractionMod * 1.0/effectivePopulation
			Local distanceAttraction:Float = distanceAttractionMod * 1.0/p.position.DistanceTo(avgPlanetPosition)
			Local planetOwnerAttraction:Float = 15.0 * (p.ownerID <= 0) + 1.0 * GetEnemyMod(p.ownerID)

			attraction = populationAttraction * distanceAttraction * planetOwnerAttraction

			If Not bestPlanet Or bestAttraction < attraction
				bestPlanet = p
				bestAttraction = attraction
'Ronny
s = "P #"+player.playerID+" - new bestPlanet :" + bestPlanet.ID+" ["+ Int(bestPlanet.ownerID) +"]  attraction="+attraction+"  population"+p.GetPopulation()+"  distance="+p.position.DistanceTo(avgPlanetPosition) +"  populationAttraction="+populationAttraction+"  distanceAttraction="+distanceAttraction+"  planetOwnerAttraction="+planetOwnerAttraction
			EndIf
		Next
		If Not bestPlanet Then Return False


		'attack!
		'tackles: while ships fly the population increases a bit ...
		'         so we need to send out even some more
		Local safetyShips:Int = 3.0/riskyness '+ average or so?
		Local toSend:Int = 0
		If bestPlanet Then toSend = bestPlanet.GetPopulation() + safetyShips

		If toSend < totalShips
			'each "wave" contains only half the population of each planet
			'-> so send until it is enough
			'it might send MORE as needed (because it sends half the pop.)
			Local i:Int = 0
			Local planetsSentInTurn:Int = 0
			Repeat
				If i = 0 Then planetsSentInTurn = 0

				'twice the minimum as it sends half of the population!
				If planetsWithShips[i].GetPopulation() >= 2 * GetPlanetPopulationMinimum(planetsWithShips[i].ID)
					Local planetSent:Int = player.SpawnShipsFromPlanet(planetsWithShips[i], bestPlanet.ID)
					toSend :- planetSent
					planetsSentInTurn :+ planetSent
				EndIf
				i = (i + 1) Mod planetsWithShips.length
			Until toSend < 0 Or planetsSentInTurn = 0
'Ronny
'if s then print s

		EndIf
		Return True
	End Method


	Method HandleTechtree:Int()
		Local p:TPlayer = game.GetPlayer(playerID)
		If p.GetResearchPoints() = 0 Then Return False

'schauen ob sie wirklich punkte bekommen
'print p.GetResearchPoints()
		Local tt:TTechTree = p.GetTechTree()

		If tt.GetTotalProgress() = 1.0
			Return True
		EndIf

		'for now: simply "update each after another", no "savings for the best"
		Local availableRP:Int = p.GetResearchPoints()
		Local updatedSomething:Int = False

		If Not tt.IsPopulationGrowthRateLevelMaxReached() And availableRP >= tt.GetPopulationGrowthRateLevelCost()
'print "#"+playerID+": update TT - Population growth to level " + (tt.GetPopulationGrowthRateLevel() + 1)
			availableRP :- tt.GetPopulationGrowthRateLevelCost()
			p.researchPoints :- tt.GetPopulationGrowthRateLevelCost()
			tt.SetPopulationGrowthRateLevel(+1, True)
			updatedSomething = True
		EndIf

		If Not tt.IsShipSpeedLevelMaxReached() And availableRP >= tt.GetShipSpeedLevelCost()
'print "#"+playerID+": update TT - Ship speed to level " + (tt.GetShipSpeedLevel() + 1)
			availableRP :- tt.GetShipSpeedLevelCost()
			p.researchPoints :- tt.GetShipSpeedLevelCost()
			tt.SetShipSpeedLevel(+1, True)
			updatedSomething = True
		EndIf

		If Not tt.IsCollectResearchPointsRateLevelMaxReached() And availableRP >= tt.GetCollectResearchPointsRateLevelCost()
'print "#"+playerID+": update TT - Collect RP rate to level " + (tt.GetCollectResearchPointsRateLevel() + 1)
			availableRP :- tt.GetCollectResearchPointsRateLevelCost()
			p.researchPoints :- tt.GetCollectResearchPointsRateLevelCost()
			tt.SetCollectResearchPointsRateLevel(+1, True)
			updatedSomething = True
		EndIf

		If Not tt.IsMissileRefillRateLevelMaxReached() And availableRP >= tt.GetMissileRefillRateLevelCost()
'print "#"+playerID+": update TT - Collect RP rate to level " + (tt.GetCollectResearchPointsRateLevel() + 1)
			availableRP :- tt.GetMissileRefillRateLevelCost()
			p.researchPoints :- tt.GetMissileRefillRateLevelCost()
			tt.SetMissileRefillRateLevel(+1, True)
			updatedSomething = True
		EndIf

		Return updatedSomething
	End Method


	Method HandlePlanetaryUpgrades:Int()
		Local updatedSomething:Int = False
		Local rp:Int = game.GetPlayer(playerID).GetResearchPoints()
		Local rpRate:Float = game.GetPlayer(playerID).GetResearchPointsProductionRate()
		Local missilesToBuy:Int
		If rpRate < 2
			missilestoBuy = game.GetPlayer(playerID).GetResearchPoints()
		Else
			missilestoBuy = game.GetPlayer(playerID).GetResearchPoints() / 2
		EndIf

		Local planetsToChoose:TPlanet[]
		For Local p:TPlanet = EachIn _planets
			If p.IsMissileMaxReached() Then Continue
			planetsToChoose :+ [p]
		Next

		'does not necessary buy all (if one planet reaches limit meanwhile)
		If planetsToChoose.length > 0 And missilesToBuy > 0
			For Local i:Int = 0 Until missilesToBuy
				Local pid:Int = RandRange(0, planetsToChoose.length-1)
				Local p:Tplanet = planetsToChoose[ pid ]

				game.BuyMissileForPlanet(playerID, p.ID)
				updatedSomething = True
			Next
		Else
			'nothing to update
			Return True
		EndIf

		Return updatedSomething
	End Method


	Method Update:Int()
		'wait a bit
		If nextTickTime > GameTime.GetTimeGone() Then Return False
		'update tick time
		nextTickTime = GameTime.GetTimeGone() + GetTickInterval()

		'update cache
		_planets = space.GetPlanets( playerID )
		_averagePlanetPopulation = space.GetAveragePlanetPopulation()

		'assign home planet
		If homePlanetID = -1 And _planets.length > 0 Then homePlanetID = _planets[0].ID


		'do something
		If lastResearchPointUsageType = 0
			If HandleTechtree()
				lastResearchPointUsageType = 1
			EndIf
		Else
			If HandlePlanetaryUpgrades()
				lastResearchPointUsageType = 0
			EndIf
		EndIf

		SendShipsToAPlanet()

	End Method
End Type



Type TTechTree
	Field shipSpeedLevel:Int = 0
	Field populationGrowthLevel:Int = 0
	Field collectResearchPointsRateLevel:Int = 0
	Field missileRefillRateLevel:Int = 0

	Const SHIP_SPEED_LEVEL_MAX:Int = 10
	Const POPULATION_GROWTH_LEVEL_MAX:Int = 10
	Const COLLECT_RESEARCH_POINTS_RATE_LEVEL_MAX:Int = 10
	Const MISSILE_REFILL_RATE_LEVEL_MAX:Int = 10


	Method IsShipSpeedLevelMaxReached:Int()
		Return shipSpeedLevel >= POPULATION_GROWTH_LEVEL_MAX
	End Method


	Method GetShipSpeedLevelCost:Int(level:Int = -1)
		If level = -1 Then level = shipSpeedLevel + 1
		If level > SHIP_SPEED_LEVEL_MAX Then Return -1

		Select level
			Case 1	Return 1
			Case 2	Return 1
			Case 3	Return 2
			Case 4	Return 3
			Case 5	Return 5
			Case 6	Return 7
			Case 7	Return 10
			Case 8	Return 13
			Case 9	Return 16
			Case 10	Return 20
		End Select
	End Method


	Method GetShipSpeedMod:Float(level:Int = - 1)
		If level = -1 Then level = shipSpeedLevel

		'+10%  +19%  +27.1%    1.4  1.6
		'Return 1.0 + (1.0 - 0.9^level)

		'better round them in steps of 2.5 (inaccurate but better readable)
		Return 1.0 + Int(0.5 + 100*(1.0 - 0.9^level) / 2.5)*2.5 * 0.01
	End Method


	Method GetShipSpeedLevel:Int()
		Return shipSpeedLevel
	End Method


	Method SetShipSpeedLevel:Int(level:Int, relative:Int = False)
		If relative
			shipSpeedLevel :+ level
		Else
			shipSpeedLevel = level
		EndIf
		Return True
	End Method


	Method IsPopulationGrowthRateLevelMaxReached:Int()
		Return populationGrowthLevel >= POPULATION_GROWTH_LEVEL_MAX
	End Method


	Method GetPopulationGrowthRateLevelCost:Int(level:Int = -1)
		If level = -1 Then level = populationGrowthLevel + 1
		If level > POPULATION_GROWTH_LEVEL_MAX Then Return -1

		Select level
			Case 1	Return 1
			Case 2	Return 2
			Case 3	Return 4
			Case 4	Return 7
			Case 5	Return 10
			Case 6	Return 15
			Case 7	Return 20
			Case 8	Return 20
			Case 9	Return 20
			Case 10	Return 20
		End Select
	End Method


	Method GetPopulationGrowthRateMod:Float(level:Int = -1)
		If level = -1 Then level = populationGrowthLevel
		Return 1.01 ^ level
	End Method


	Method GetPopulationGrowthRateLevel:Int()
		Return populationGrowthLevel
	End Method


	Method SetPopulationGrowthRateLevel:Int(level:Int, relative:Int = False)
		If relative
			populationGrowthLevel :+ level
		Else
			populationGrowthLevel = level
		EndIf
		Return True
	End Method



	Method IsCollectResearchPointsRateLevelMaxReached:Int()
		Return collectResearchPointsRateLevel >= POPULATION_GROWTH_LEVEL_MAX
	End Method


	Method GetCollectResearchPointsRateLevelCost:Int(level:Int = -1)
		If level = -1 Then level = collectResearchPointsRateLevel + 1
		If level > POPULATION_GROWTH_LEVEL_MAX Then Return -1

		Select level
			Case 1	Return 1
			Case 2	Return 2
			Case 3	Return 4
			Case 4	Return 7
			Case 5	Return 10
			Case 6	Return 15
			Case 7	Return 20
			Case 8	Return 20
			Case 9	Return 20
			Case 10	Return 20
		End Select
	End Method


	Method GetCollectResearchPointsRateMod:Float(level:Int = -1)
		If level = -1 Then level = collectResearchPointsRateLevel
		Return 1.01 ^ level
	End Method


	Method GetCollectResearchPointsRateLevel:Int()
		Return collectResearchPointsRateLevel
	End Method


	Method SetCollectResearchPointsRateLevel:Int(level:Int, relative:Int = False)
		If relative
			collectResearchPointsRateLevel :+ level
		Else
			collectResearchPointsRateLevel = level
		EndIf
		Return True
	End Method



	Method IsMissileRefillRateLevelMaxReached:Int()
		Return missileRefillRateLevel >= MISSILE_REFILL_RATE_LEVEL_MAX
	End Method


	Method GetMissileRefillRateLevelCost:Int(level:Int = -1)
		If level = -1 Then level = missileRefillRateLevel + 1
		If level > MISSILE_REFILL_RATE_LEVEL_MAX Then Return -1

		Select level
			Case 1	Return 1
			Case 2	Return 2
			Case 3	Return 4
			Case 4	Return 7
			Case 5	Return 10
			Case 6	Return 15
			Case 7	Return 20
			Case 8	Return 20
			Case 9	Return 20
			Case 10	Return 20
		End Select
	End Method


	Method GetMissileRefillRateMod:Float(level:Int = -1)
		If level = -1 Then level = missileRefillRateLevel
		Return 1.072 ^ level
	End Method


	Method GetMissileRefillRateLevel:Int()
		Return missileRefillRateLevel
	End Method


	Method SetMissileRefillRateLevel:Int(level:Int, relative:Int = False)
		If relative
			missileRefillRateLevel :+ level
		Else
			missileRefillRateLevel = level
		EndIf
		Return True
	End Method


	Method GetTotalProgress:Float()
		Local done:Int = shipSpeedLevel + populationGrowthLevel + collectResearchPointsRateLevel
		Local maxPoints:Int = SHIP_SPEED_LEVEL_MAX ..
		                      + POPULATION_GROWTH_LEVEL_MAX ..
		                      + COLLECT_RESEARCH_POINTS_RATE_LEVEL_MAX ..
		                      + MISSILE_REFILL_RATE_LEVEL_MAX
		Return done / Float(maxPoints)
	End Method
End Type



Type TMessageWindow
	Field area:TRectangle = New TRectangle
	Field animOffset:TVec2D = New TVec2D
	Field caption:String
	Field screenLimit:String
	Field _destroyed:Int
	Field _eventListeners:TLink[]


	Method Destroy:Int()
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = New TLink[0]

		_destroyed = True
	End Method


	Method Open:Int()
	End Method


	Method Close:Int()
	End Method


	Method Update:Int()
		If KeyManager.IsHit(KEY_ESCAPE)
			Close()
			Destroy()
			KeyManager.ResetKey(KEY_ESCAPE)
			KeyManager.BlockKey(KEY_ESCAPE, 200)
		EndIf
		Return True
	End Method


	Method Render:Int(offsetX:Int=0, offsetY:Int=0)
		If caption
			GetSpriteFromRegistry("messagewindow.big.bg").DrawArea(area.GetIntX() + animOffset.GetIntX() + offsetX, area.GetIntY() + animOffset.GetIntY() + offsetY, area.GetIntW(), area.GetIntH())
			GetBitmapFont("small",, BOLDFONT).DrawBlock(caption, area.GetIntX(), area.GetIntY() + 4+1, area.GetIntW()-2, 20, ALIGN_CENTER_TOP, GameColorCollection.basePalette[0])
			GetBitmapFont("small",, BOLDFONT).DrawBlock(caption, area.GetIntX(), area.GetIntY() + 4, area.GetIntW()-2, 20, ALIGN_CENTER_TOP, GameColorCollection.basePalette[1])
		Else
			GetSpriteFromRegistry("messagewindow.bg").DrawArea(area.GetIntX() + animOffset.GetIntX() + offsetX, area.GetIntY() + animOffset.GetIntY() + offsetY, area.GetIntW(), area.GetIntH())
		EndIf
	End Method
End Type





Type TMessageWindow_SimpleMessage Extends TMessageWindow
	Field sprite:TSprite
	Field text:String
	Field wasPaused:Int = False
	Field guiButtonDone:TGUIButton


	Method Open:Int() 'override
		If Not guiButtonDone
			guiButtonDone = New TGameGUIButton.Create(New TVec2D.Init(85, area.getIntY() + area.GetIntH() - 25), New TVec2D.Init(80,17), "OK", "MessageWindowSimpleMessage")
			GuiManager.Remove(guiButtonDone)
		EndIf

		For Local i:Int = 0 Until 16
			text = text.Replace("|color="+i+"|", "|color="+GameColorCollection.basePalette[i].ToRGBString(",")+"|")
		Next

		wasPaused = game.IsPaused()
		game.SetPaused(True)
	End Method


	Method Close:Int() 'override
		If Not wasPaused Then game.SetPaused(False)
	End Method


	Method Update:Int() 'override
		If guiButtonDone
			guiButtonDone.Update()

			If guiButtonDone.IsClicked() Or MouseManager.IsHit(2)
				guiButtonDone.mouseIsClicked = Null
				MouseManager.ResetKey(1)
				MouseManager.ResetKey(2)
				Close()
				Destroy()
				Return False
			EndIf
		EndIf
	End Method


	Method Render:Int(offsetX:Int=0, offsetY:Int=0) 'override
		If caption
			GetSpriteFromRegistry("messagewindow.big.bg").DrawArea(area.GetIntX() + animOffset.GetIntX() + offsetX, area.GetIntY() + animOffset.GetIntY() + offsetY, area.GetIntW(), area.GetIntH())
			GetBitmapFont("small",, BOLDFONT).DrawBlock(caption, area.GetIntX(), area.GetIntY() + 4+1, area.GetIntW()-2, 20, ALIGN_CENTER_TOP, GameColorCollection.basePalette[0])
			GetBitmapFont("small",, BOLDFONT).DrawBlock(caption, area.GetIntX(), area.GetIntY() + 4, area.GetIntW()-2, 20, ALIGN_CENTER_TOP, GameColorCollection.basePalette[1])
		Else
			GetSpriteFromRegistry("messagewindow.bg").DrawArea(area.GetIntX() + animOffset.GetIntX() + offsetX, area.GetIntY() + animOffset.GetIntY() + offsetY, area.GetIntW(), area.GetIntH())
		EndIf

		Local textY:Int = area.GetIntY() + 20
		If sprite
			sprite.Draw(area.GetIntX() + area.GetIntW()/2, textY, ,ALIGN_CENTER_TOP)
			textY :+ sprite.GetHeight()
		EndIf

		GetBitmapFont("small").DrawBlock(text, area.GetIntX() + 10, textY, area.GetIntW()-20, area.GetIntH() - textY - 10, ALIGN_LEFT_TOP, Null, 0, 1, 1.0, True, False, 7)

		If guiButtonDone
			guiButtonDone.Draw()
		EndIf
	End Method
End Type






Type TChartsCurvePoints
	Field x:Int[]
	Field y:Int[]
End Type




Type TMessageWindow_GameStats Extends TMessageWindow
	Field playerID:Int = 1
	Field playerIDAuto:Int = False
	Field buttonDone:TGameGUIButton
	Field curvePoints:TChartsCurvePoints[]
	Field curvePointsYMax:Int
	Field curveDataID:Int = 0
	Field curveDataIDBefore:Int = -1
	Field exitOnclose:Int = False

	Field startY:Int
	Field col1:Int
	Field col2:Int
	Field col3:Int
	Field col4:Int
	Field row1:Int
	Field row2:Int
	Field row3:Int
	Field row4:Int


	Method New()
		Local startY:Int = 40
		caption = "Game Progress - Statistics"
		buttonDone = New TGameGUIButton.Create(New TVec2D.Init(85,startY+4*25 + 10 -1), New TVec2D.Init(80,17), "DONE", "MessageWindowUpgrade")
	End Method


	Method Open:Int() 'override
		Super.Open()

		'reset
		curveDataIDBefore = -1
		curveDataID = 0


		startY = area.GetIntY() +10
		col1 = area.GetIntX() + 12
		col2 = col1 + 50
		col3 = col2 + 58
		col4 = col3 + 54
		row1 = area.GetIntY() + 90
		row2 = row1 + 8
		row3 = row2 + 8
		row4 = row3 + 8
	End Method


	Method Close:Int() 'override
		Super.Close()

		If exitOnClose
			GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("mainmenu"), 0.2 )
		EndIf
	End Method


	Method Update:Int()
'		EnableOrDisableButtons()

		If playerIDAuto
			playerID = (Time.GetTimeGone() / 5000) Mod game.players.length +1
		EndIf


		'player select
		If MouseManager.IsHit(1)
			Local n:Int = 0
			Local buttonArea:TRectangle = New TRectangle.Init(area.GetIntX() + 159, area.GetIntY() + 20, 21, 13)
			For Local playerNumber:Int = 1 To game.players.length
				If buttonArea.Contains(MouseManager.currentPos)
					If playerID = playerNumber And Not playerIDAuto
						playerIDAuto = True
					Else
						playerID = playerNumber
						playerIDAuto = False
					EndIf
					MouseManager.ResetKey(1)
					Exit
				EndIf
				buttonArea.MoveXY(0, 15)

				If n = 2 Then buttonArea.MoveXY(+24, -45)
				n :+ 1
			Next
		EndIf

		'type select
		If MouseManager.IsHit(1)
			Local newID:Int = -1
			Local p:TVec2D = MouseManager.currentPos
			Local typeRect:TRectangle = New TRectangle.Init(col1, row1, col2-col1 + 40, row2-row1)
			If newID=-1 And typeRect.Contains(p) Then newID = 0

			typeRect.position.SetXY(col1, row2)
			If newID=-1 And typeRect.Contains(p) Then newID = 1

			typeRect.position.SetXY(col1, row3)
			If newID=-1 And typeRect.Contains(p) Then newID = 10

			typeRect.position.SetXY(col1, row4)
			If newID=-1 And typeRect.Contains(p) Then newID = 5

			typeRect.position.SetXY(col3, row1)
			If newID=-1 And typeRect.Contains(p) Then newID = 2

			typeRect.dimension.SetX(30)
			typeRect.position.SetXY(col3, row2)
			If newID=-1 And typeRect.Contains(p) Then newID = 3

			typeRect.position.SetXY(col3 + 30, row2)
			If newID=-1 And typeRect.Contains(p) Then newID = 4

			typeRect.dimension.SetX(col2-col1 + 40)
			typeRect.position.SetXY(col3, row3)
			If newID=-1 And typeRect.Contains(p) Then newID = 6


			typeRect.position.SetXY(col3, row4)
			If newID=-1 And typeRect.Contains(p) Then newID = 7

			If newID >= 0 Then curveDataID = newID
		EndIf

		UpdateCurve()



		If buttonDone Then buttonDone.Update()

		If buttonDone.IsClicked() Or MouseManager.IsHit(2)
			buttonDone.mouseIsClicked = Null
			MouseManager.ResetKey(1)
			MouseManager.ResetKey(2)
			Close()
			Destroy()
			Return False
		EndIf

		Return Super.Update()
	End Method


	Method Render:Int(offsetX:Int=0, offsetY:Int=0)
		Super.Render(offsetX, offsetY)

		Local col:String="114,177,75"
		Local color1:TColor = GameColorCollection.basePalette[1]
		Local color2:TColor = GameColorCollection.basePalette[7]
		Local techtree:TTechTree = Game.GetPlayer().GetTechTree()

		Local gs:TGameStats = game.GetPlayerGameStats(playerID)

		'TODO: 4 Rects fuer PLayer - beim hovern, pID wechsel
		'oder automatisch durchloopen wenn kein hover
		Local f:TBitmapFont = GetBitmapFont("small")
		If curveDataID = 0
			f.Draw("Population:", col1, row1, color2); f.DrawBlock(gs.population, col2, row1, 30, 6, ALIGN_RIGHT_CENTER)
		Else
			f.Draw("Population:", col1, row1, color1); f.DrawBlock(gs.population, col2, row1, 30, 6, ALIGN_RIGHT_CENTER)
		EndIf
		If curveDataID = 1
			f.Draw("Domination:", col1, row2, color2); f.DrawBlock(Int(100*gs.domination) +" %", col2, row2, 30, 6, ALIGN_RIGHT_CENTER)
		Else
			f.Draw("Domination:", col1, row2, color1); f.DrawBlock(Int(100*gs.domination) +" %", col2, row2, 30, 6, ALIGN_RIGHT_CENTER)
		EndIf
		If curveDataID = 10
			f.Draw("TechTree:", col1, row3, color2); f.DrawBlock(Int(100*gs.techtreeProgress) +" %", col2, row3, 30, 6, ALIGN_RIGHT_CENTER)
		Else
			f.Draw("TechTree:", col1, row3, color1); f.DrawBlock(Int(100*gs.techtreeProgress) +" %", col2, row3, 30, 6, ALIGN_RIGHT_CENTER)
		EndIf
		If curveDataID = 5
			f.Draw("Ships sent:", col1, row4, color2); f.DrawBlock(gs.shipsStarted, col2, row4, 30, 6, ALIGN_RIGHT_CENTER)
		Else
			f.Draw("Ships sent:", col1, row4, color1); f.DrawBlock(gs.shipsStarted, col2, row4, 30, 6, ALIGN_RIGHT_CENTER)
		EndIf

		If curveDataID = 2
			f.Draw("Planets owned:", col3, row1, color2); f.DrawBlock(Int(100*gs.planetsOwned), col4, row1, 30, 6, ALIGN_RIGHT_CENTER)
		Else
			f.Draw("Planets owned:", col3, row1, color1); f.DrawBlock(Int(100*gs.planetsOwned), col4, row1, 30, 6, ALIGN_RIGHT_CENTER)
		EndIf
		If curveDataID = 3
			f.Draw("  ~q  |color="+color2.ToRGBString(",")+"|won|/color|/lost:", col3, row2); f.DrawBlock(gs.planetsWon+"/"+gs.planetsLost, col4, row2, 30, 6, ALIGN_RIGHT_CENTER)
		ElseIf curveDataID = 4
			f.Draw("  ~q  won/|color="+color2.ToRGBString(",")+"|lost|/color|:", col3, row2); f.DrawBlock(gs.planetsWon+"/"+gs.planetsLost, col4, row2, 30, 6, ALIGN_RIGHT_CENTER)
		Else
			f.Draw("  ~q  won|/color|/lost:", col3, row2); f.DrawBlock(gs.planetsWon+"/"+gs.planetsLost, col4, row2, 30, 6, ALIGN_RIGHT_CENTER)
		EndIf

		If curveDataID = 6
			f.Draw("Missile slots:", col3, row3, color2); f.DrawBlock(gs.missilesBought, col4, row3, 30, 6, ALIGN_RIGHT_CENTER)
		Else
			f.Draw("Missile slots:", col3, row3, color1); f.DrawBlock(gs.missilesBought, col4, row3, 30, 6, ALIGN_RIGHT_CENTER)
		EndIf
		If curveDataID = 7
			f.Draw("Missiles fired:", col3, row4, color2); f.DrawBlock(gs.missilesStarted, col4, row4, 30, 6, ALIGN_RIGHT_CENTER)
		Else
			f.Draw("Missiles fired:", col3, row4, color1); f.DrawBlock(gs.missilesStarted, col4, row4, 30, 6, ALIGN_RIGHT_CENTER)
		EndIf

		Local n:Int = 0
		Local buttonArea:TRectangle = New TRectangle.Init(area.GetIntX() + 159, area.GetIntY() + 20, 21, 13)
		For Local playerNumber:Int = 1 To 6
			If playerNumber <= game.players.length
				game.playerColors[ playerNumber ].SetRGB
				DrawRect(buttonArea.GetIntX()+1, buttonArea.GetIntY()+1, 21-2, 13-2)
				SetColor 255,255,255
			EndIf

			If playerNumber = playerID And Not playerIDAuto
				GetSpriteFromRegistry("charts.button.active").Draw(buttonArea.GetIntX(), buttonArea.GetIntY())
			ElseIf playerNumber <= game.players.length
				If buttonArea.Contains(MouseManager.currentPos) Or (playerNumber = playerID And playerIDAuto)
					GetSpriteFromRegistry("charts.button.hover").Draw(buttonArea.GetIntX(), buttonArea.GetIntY())
				Else
					GetSpriteFromRegistry("charts.button.normal").Draw(buttonArea.GetIntX(), buttonArea.GetIntY())
				EndIf
			Else
				GetSpriteFromRegistry("charts.button.disabled").Draw(buttonArea.GetIntX(), buttonArea.GetIntY())
			EndIf
			buttonArea.MoveXY(0, 15)

			If n = 2 Then buttonArea.MoveXY(+24, -45)
			n :+ 1
		Next
		SetColor 255,255,255

		RenderCurve(area.GetIntX() + 10, area.GetIntY() + 20, 135, 65)

		If buttonDone Then buttonDone.Draw()
	End Method


	Method UpdateCurve()
		'initial fill
		If curveDataID <> curveDataIDBefore
			curvePointsYMax = 0
			If Not curvePoints Or curvePoints.length = 0
				curvePoints = New TChartsCurvePoints[game.players.length]
			EndIf

			For Local p:TPlayer = EachIn game.players
				Local archive:TGameStatsArchive = game.GetPlayerGameStatsArchive(p.playerID)
				Local c:TChartsCurvePoints = New TChartsCurvePoints
				curvePoints[p.playerID-1] = c
				c.x = New Int[archive.stats.length]
				c.y = New Int[archive.stats.length]

				For Local num:Int = 0 Until archive.stats.length
					Local v:Int = archive.stats[num].GetAtIndex(curveDataID)
					If curvePointsYMax = 0 Or curvePointsYMax < v
						curvePointsYMax = v
					EndIf

					c.x[num] = num
					c.y[num] = v
				Next
			Next
			curveDataIDBefore = curveDataID
		EndIf
	End Method


	Method RenderCurve(areaX:Int, areaY:Int, width:Int, height:Int)
		If curveDataID <> curveDataIDBefore Then Return

		Local curveOffsetX:Int = 3
		Local curveOffsetY:Int = -3
		Local curveWidth:Int = width - Abs(curveOffsetX)
		Local curveHeight:Int = height - Abs(curveOffsetX)
		Local curveX:Int = areaX + curveOffsetX
		Local curveY:Int = areaY + curveOffsetY
		Local lastX:Float = 0
		Local lastY:Int = 0
		Local xPerValue:Float = Float(curveWidth) / curvePoints[0].x.length
		Local yPerValue:Float = 0
		If curvePointsYMax > 0 Then yPerValue = Float(curveHeight) / curvePointsYMax

		'bg
'		GetSpriteFromRegistry("charts.bg").DrawArea(areaX + 2, areaY, width - 2, height - 2)
		GetSpriteFromRegistry("charts.bg").TileDraw(areaX + 2, areaY+1, width - 3, height - 3)

		'shadows
		SetColor 0,0,0
		For Local i:Int = 0 Until curvePoints.length
			Local c:TChartsCurvePoints = curvePoints[i]
			Local x:Float = 0
			For Local num:Int = 0 Until c.x.length
				Local valY:Int = height - Int(c.y[num] * yPerValue)
				If num > 0
					DrawRectLine(Int(curveX + lastX)+1, Int(curveY + lastY)+1, Int(curveX + x), Int(curveY + valY))
				EndIf
	'print "lastX->x: " + lastX + " -> " + int(x) +"   lastY->y: " + lastY + " -> " + valY
				lastX = x
				lastY = valY
				x :+ xPerValue
			Next
		Next

		'curves
		For Local i:Int = 0 Until curvePoints.length
			Local c:TChartsCurvePoints = curvePoints[i]
			Local x:Float = 0
			For Local num:Int = 0 Until c.x.length
				Local valY:Int = height - Int(c.y[num] * yPerValue)
				If num > 0
					game.playerColors[i+1].SetRGB()
					DrawRectLine(Int(curveX + lastX), Int(curveY + lastY), Int(curveX + x), Int(curveY + valY))
				EndIf
	'print "lastX->x: " + lastX + " -> " + int(x) +"   lastY->y: " + lastY + " -> " + valY
				lastX = x
				lastY = valY
				x :+ xPerValue
			Next
		Next
		SetColor 255,255,255

		SetColor 255,255,255

		'overlay / axis
		GetSpriteFromRegistry("charts.overlay").DrawArea(areaX, areaY, width, height)

	End Method

End Type




Type TMessageWindow_Settings Extends TMessageWindow
	Field checkboxFullscreen:TGameGUICheckBox
	Field sliderSFXVolume:TGameGUISlider
	Field sliderMusicVolume:TGameGUISlider
	Field dropdownSoundEngine:TGameGUIDropDown
	Field inputResolutionX:TGameGUIInput
	Field inputResolutionY:TGameGUIInput
	Field buttonPreset1:TGameGUIButton
	Field buttonPreset2:TGameGUIButton
	Field buttonPreset3:TGameGUIButton
	Field buttonPreset4:TGameGUIButton
	Field buttonDone:TGameGUIButton
	Field container:TGUIPanel
	Field lsGUIkey:TLowerString = New TLowerString.Create("MessageWindowSettings")
	Field startY:Int = 50
	Field startX:Int = 60
	Field firstRender:Int = True


	Method New()
		startX = area.GetX() + 15
		startY = area.GetY() + 10

		caption = "Settings"

		container = New TGUIPanel.Create(New TVec2D.Init(startX, startY+0*5), New TVec2D.Init(300, 300), lsGUIkey.ToString())

		sliderSFXVolume = New TGameGUISlider.Create(New TVec2D.Init(55, startY+0*5), New TVec2D.Init(50,10), "10") ', lsGUIkey.ToString())
		sliderSFXVolume.SetValueRange(0, 100)
		container.AddChild(sliderSFXVolume)

		sliderMusicVolume = New TGameGUISlider.Create(New TVec2D.Init(55, startY+3*5), New TVec2D.Init(50,10), "10") ', lsGUIkey.ToString())
		sliderMusicVolume.SetValueRange(0, 100)
		container.AddChild(sliderMusicVolume)

		dropdownSoundEngine = New TGameGUIDropDown.Create(New TVec2D.Init(55, startY+6*5), New TVec2D.Init(70,15), "", 100) ', lsGUIkey.ToString())
		dropdownSoundEngine.SetListContentHeight(5 * 10)
		Local soundEngineValues:String[] = ["AUTOMATIC", "NONE"]
		Local soundEngineTexts:String[] = ["Auto", "- None -"]
		?Win32
			soundEngineValues :+ ["WINDOWS_ASIO","WINDOWS_DS"]
			soundEngineTexts :+ ["ASIO", "Direct Sound"]
		?Linux
			soundEngineValues :+ ["LINUX_ALSA","LINUX_PULSE","LINUX_OSS"]
			soundEngineTexts :+ ["ALSA", "PulseAudio", "OSS"]
		?MacOS
			soundEngineValues :+ ["MACOSX_CORE"]
			soundEngineTexts :+ ["CoreAudio"]
		?

		Local itemHeight:Int = 0
		For Local i:Int = 0 Until soundEngineValues.Length
			Local item:TGUIDropDownItem = New TGameGUIDropDownItem.Create(Null, Null, soundEngineTexts[i]).SetExtra(soundEngineValues[i])
			'item.SetValueColor(TColor.CreateGrey(50))
			item.data.Add("value", soundEngineValues[i])
			dropdownSoundEngine.AddItem(item)
		Next
		dropdownSoundEngine.SetListContentHeight(10 * Len(soundEngineValues))
		dropdownSoundEngine.SetSelectedEntryByPos( 0 )
		container.AddChild(dropdownSoundEngine)


		inputResolutionX = New TGameGUIInput.Create(New TVec2D.Init(55,startY+10*5), New TVec2D.Init(35,14), "640", 4) ', lsGUIkey.ToString())
		inputResolutionY = New TGameGUIInput.Create(New TVec2D.Init(55 + 47,startY+10*5), New TVec2D.Init(35,14), "400", 4) ', lsGUIkey.ToString())
		container.AddChild(inputResolutionX)
		container.AddChild(inputResolutionY)

		buttonPreset1 = New TGameGUIButton.Create(New TVec2D.Init(55, startY+14*5 -4 ), New TVec2D.Init(19,14), "x1") ', lsGUIkey.ToString())
		buttonPreset2 = New TGameGUIButton.Create(New TVec2D.Init(55 + 21 , startY+14*5 -4), New TVec2D.Init(19,14), "x2") ', lsGUIkey.ToString())
		buttonPreset3 = New TGameGUIButton.Create(New TVec2D.Init(55 + 42, startY+14*5 -4), New TVec2D.Init(19,14), "x3") ', lsGUIkey.ToString())
		buttonPreset4 = New TGameGUIButton.Create(New TVec2D.Init(55 + 63, startY+14*5 -4), New TVec2D.Init(19,14), "x4") ', lsGUIkey.ToString())
		container.AddChild(buttonPreset1)
		container.AddChild(buttonPreset2)
		container.AddChild(buttonPreset3)
		container.AddChild(buttonPreset4)

		checkboxFullscreen = New TGameGUICheckBox.Create(New TVec2D.Init(55, startY+8*10 + 2), New TVec2D.Init(120,12), "Fullscreen") ', lsGUIkey.ToString())
		container.AddChild(checkboxFullscreen)

		buttonDone = New TGameGUIButton.Create(New TVec2D.Init(28, startY+10*10 + 2), New TVec2D.Init(80,17), "DONE") ', lsGUIkey.ToString())
		container.AddChild(buttonDone)
	End Method


	Method Destroy:Int() 'override
		GuiManager.Remove(container)
		GuiManager.Remove(checkboxFullscreen)
		GuiManager.Remove(sliderSFXVolume)
		GuiManager.Remove(sliderMusicVolume)
		GuiManager.Remove(inputResolutionX)
		GuiManager.Remove(inputResolutionY)
		GuiManager.Remove(buttonPreset1)
		GuiManager.Remove(buttonPreset2)
		GuiManager.Remove(buttonPreset3)
		GuiManager.Remove(buttonPreset4)
		GuiManager.Remove(buttonDone)
		GuiManager.Remove(dropdownSoundEngine)

		Return Super.Destroy()
	End Method


	Method Open:Int()
		checkboxFullscreen.SetChecked( GameConfig.fullscreen )
		If GameConfig.screenWidth > 0
			inputResolutionX.SetValue( GameConfig.screenWidth )
		Else
			inputResolutionX.SetValue( app.windowW )
		EndIf
		If GameConfig.screenHeight > 0
			inputResolutionY.SetValue( GameConfig.screenHeight )
		Else
			inputResolutionY.SetValue( app.windowH )
		EndIf

		sliderMusicVolume.SetValue(GameConfig.volumeMusic)
		sliderSFXVolume.SetValue(GameConfig.volumeSFX)

		local i:int = 0
		For local entry:TGameGUIDropDownItem = EachIn dropdownSoundEngine.GetEntries()
			if string(entry.extra).ToLower() = GameConfig.soundEngine.ToLower()
				dropdownSoundEngine.SetSelectedEntryByPos(i)
				exit
			endif
			i :+ 1
		Next

		Return Super.Open()
	End Method


	Method Close:Int()
		'apply config
		Local newResolutionX:Int = Int(inputResolutionX.GetValue())
		Local newResolutionY:Int = Int(inputResolutionY.GetValue())
		Local initG:Int = False
		If newResolutionX <> 0 And newResolutionY <> 0
			If newResolutionX <> app.resolutionX Or newResolutionY <> app.resolutionY
				app.resolutionX = newResolutionX
				app.resolutionY = newResolutionY

				If newResolutionX <> app.windowW Or GameConfig.screenWidth <> 0 Then GameConfig.screenWidth = newResolutionX
				If newResolutionY <> app.windowH Or GameConfig.screenHeight <> 0 Then GameConfig.screenHeight = newResolutionY

				GetGraphicsManager().SetResolution(app.resolutionX, app.resolutionY)
				initG = True
			EndIf
		EndIf

		Local newFullscreen:Int = checkboxFullscreen.IsChecked()
		If newFullscreen <> GameConfig.fullscreen
			GameConfig.fullscreen = newFullscreen
			initG = True
		EndIf

		If initG Then GetGraphicsManager().InitGraphics()
	End Method


	Method Update:Int()
		container.rect.position.SetXY(area.GetIntX() + 20, area.GetIntY() + 10)
		checkboxFullscreen.Resize(-1,-1)

		GuiManager.Update(lsGUIkey)

		GameConfig.volumeMusic = sliderMusicVolume.GetValue().ToInt()
		GameConfig.volumeSFX = sliderSFXVolume.GetValue().ToInt()

		if GameConfig.soundEngine.ToLower() <> string(TGameGUIDropDownItem(dropdownSoundEngine.GetSelectedEntry()).extra).ToLower()
			GameConfig.soundEngine = string(TGameGUIDropDownItem(dropdownSoundEngine.GetSelectedEntry()).extra)
			app.ApplySoundSettings()
		endif

		'TODO: an SoundManager weitergeben

		If buttonPreset1.IsClicked()
			buttonPreset1.mouseIsClicked = Null
			inputResolutionX.SetValue(320)
			inputResolutionY.SetValue(200)
		EndIf

		If buttonPreset2.IsClicked()
			buttonPreset2.mouseIsClicked = Null
			inputResolutionX.SetValue(320 * 2)
			inputResolutionY.SetValue(200 * 2)
			'normally this is not a supported fullscreen resolution
			checkboxFullscreen.SetChecked(False)
		EndIf
		If buttonPreset3.IsClicked()
			buttonPreset3.mouseIsClicked = Null
			inputResolutionX.SetValue(320 * 3)
			inputResolutionY.SetValue(200 * 3)
			'normally this is not a supported fullscreen resolution
			checkboxFullscreen.SetChecked(False)
		EndIf
		If buttonPreset4.IsClicked()
			buttonPreset4.mouseIsClicked = Null
			inputResolutionX.SetValue(320 * 4)
			inputResolutionY.SetValue(200 * 4)
			'normally this is not a supported fullscreen resolution
			checkboxFullscreen.SetChecked(False)
		EndIf

		If buttonDone.IsClicked() Or MouseManager.IsHit(2) Or KeyManager.IsHit(KEY_ESCAPE)
			KeyManager.ResetKey(KEY_ESCAPE)
			KeyManager.BlockKey(KEY_ESCAPE, 200)

			Close()
			Destroy()
			MouseManager.ResetKey(1)
			MouseManager.ResetKey(2)
			Return False
		EndIf

		Return Super.Update()
	End Method


	Method Render:Int(offsetX:Int=0, offsetY:Int=0)
		'somehow gui widgets "snap" into place
		If firstRender
			checkboxFullscreen.Resize(-1,-1)
			firstRender = False
		EndIf

		container.rect.position.SetXY(area.GetIntX() + 20, area.GetIntY() + 10)
		startY = area.GetIntY() + 20
		startX = area.GetIntX() + 12

		Super.Render(offsetX, offsetY)

		GetBitmapFont("small").Draw("SFX Volume:", startX, startY + 0*5 +1)
		If Int(sliderSFXVolume.GetValue()) = 0
			GetBitmapFont("small").Draw("muted", startX + 116, startY + 0*5 +1)
		Else
			GetBitmapFont("small").Draw(Int(sliderSFXVolume.GetValue())+" %", startX + 116, startY + 0*5 +1)
		EndIf

		GetBitmapFont("small").Draw("Music Volume:", startX, startY + 3*5 +1)
		If Int(sliderMusicVolume.GetValue()) = 0
			GetBitmapFont("small").Draw("muted", startX + 116, startY + 3*5 +1)
		Else
			GetBitmapFont("small").Draw(Int(sliderMusicVolume.GetValue())+" %", startX + 116, startY + 3*5 +1)
		EndIf

		GetBitmapFont("small").Draw("Sound Engine:", startX, startY + 6*5 +1)

		GetBitmapFont("small").Draw("Resolution:", startX, startY + 10*5 +3)
		GetBitmapFont("small").Draw("x", startX + 101, startY + 10*5 +3)

		GuiManager.Draw(lsGUIkey)
	End Method
End Type




Type TMessageWindow_LoadOrSaveGameMenu Extends TMessageWindow
	Field savegameList:TGUISelectList
	Field buttonOK:TGameGUIButton
	Field buttonCancel:TGameGUIButton
	Field container:TGUIPanel
	Field slotSelected:Int = -1
	Field slotSummaries:TData[]
	Field loadMode:Int = True
	Field lsGUIKey:TLowerString = New TLowerString.Create("MessageWindowLoadOrSaveGame")


	Method New()
		Local startX:Int = 30
		Local startY:Int = 30

		slotSummaries = New TData[3]

		container = New TGUIPanel.Create(New TVec2D.Init(0, 0), New TVec2D.Init(300, 300), lsGUIkey.ToString())
		buttonOK = New TGameGUIButton.Create(New TVec2D.Init(0, 105), New TVec2D.Init(60,17), "Load")
		buttonCancel = New TGameGUIButton.Create(New TVec2D.Init(70, 105), New TVec2D.Init(60,17), "Cancel")

		container.AddChild(buttonOK)
		container.AddChild(buttonCancel)

	End Method


	Method SetLoadMode:Int(bool:Int=True)
		If loadMode = bool Then Return False

		loadMode = bool

		If loadMode
			buttonOK.SetValue("Load")
		Else
			buttonOK.SetValue("Save")
		EndIf
	End Method


	Method Destroy:Int() 'override
		GuiManager.Remove(container)
		GuiManager.Remove(buttonOK)
		GuiManager.Remove(buttonCancel)
		GuiManager.Remove(savegameList)

		Return Super.Destroy()
	End Method


	Method Open:Int() 'override
		'speicherstaende lesen

		For Local i:Int = 1 To 3
			Local uri:String = "savegames/slot"+i+".xml"
			If FileType(uri) = 1
				slotSummaries[i-1] = TSaveGame.GetGameSummary(uri)
			EndIf
		Next
	End Method


	Method Update:Int() 'override
		container.rect.position.SetXY(area.GetIntX() + 20, area.GetIntY() + 10)

		GuiManager.Update(lsGUIKey)

		If buttonOK.IsClicked()
			buttonOK.mouseIsClicked = Null
			MouseManager.ResetKey(1)

			If slotSelected >= 0
				Local uri:String = "savegames/slot"+(slotSelected+1)+".xml"
				If loadMode
					If FileType(uri) = 1 Then TGame.LoadGame(uri)
					Return True
				Else
					TGame.SaveGame(uri)

					Close()
					Destroy()
					Return True
				EndIf
			EndIf
		EndIf


		If MouseManager.IsHit(1)
			For Local i:Int = 0 Until 3
				If New TRectangle.Init(area.GetIntX() + 15, area.GetIntY() + 20 + i*30, 130, 25).Contains(MouseManager.currentPos)
					slotSelected = i
					Exit
				EndIf
			Next
		EndIf


		If buttonCancel.IsClicked() Or MouseManager.IsHit(2) Or KeyManager.IsHit(KEY_ESCAPE)
			KeyManager.ResetKey(KEY_ESCAPE)
			KeyManager.BlockKey(KEY_ESCAPE, 200)

			buttonCancel.mouseIsClicked = Null

			Close()
			Destroy()
			MouseManager.ResetKey(1)
			MouseManager.ResetKey(2)
			Return False
		EndIf

		Return Super.Update()
	End Method


	Method RenderSlot(num:Int, x:Int, y:Int, w:Int, h:Int)
		If slotSelected = num
			DrawRect(x-5,y +3, 3, h -7)
			DrawRect(x+w+2,y +3, 3, h -7)
		EndIf
		GetSpriteFromRegistry("button").DrawArea(x, y, w, h)

		If slotSummaries[num]
			GetBitmapFont("small").Draw(slotSummaries[num].GetString("map_name", "Unknown map name"), x + 5, y + 3)
			GetBitmapFont("small").Draw("Playing " + slotSummaries[num].GetString("player_name")+".", x + 5, y + 3 + 7*1, GameColorCollection.basePalette[15])
			GetBitmapFont("small").Draw("Created at " + slotSummaries[num].GetString("savegame_time"), x + 5, y + 3 + 7*2, GameColorCollection.basePalette[15])
'			GetBitmapFont("small").Draw("Playing a SKIRMISH GAME as XYZ.", x + 8, y + 3)
			'
		Else
			GetBitmapFont("small").Draw("SLOT " + (num+1) +": UNUSED", x + 5, y + 10)
		EndIf
	End Method


	Method Render:Int(offsetX:Int=0, offsetY:Int=0) 'override
		If loadMode
			caption = "Load game"
		Else
			caption = "Save game"
		EndIf
		Super.Render(offsetX, offsetY)

		For Local i:Int = 0 Until 3
			RenderSlot(i, area.GetIntX() + 15, area.GetIntY() + 20 + i*30, 140, 28)
		Next

		container.rect.position.SetXY(area.GetIntX() + 20, area.GetIntY() + 10)
		GuiManager.Draw(lsGUIKey)
	End Method
End Type



Type TMessageWindow_InGameMenu Extends TMessageWindow
	Field buttonContinue:TGameGUIButton
	Field buttonSettings:TGameGUIButton
	Field buttonStatistics:TGameGUIButton
	Field buttonBackToMainMenu:TGameGUIButton
	Field buttonQuit:TGameGUIButton
	Field buttonLoad:TGameGUIButton
	Field buttonSave:TGameGUIButton
	Field wasPaused:Int = False


	Method New()
		Local startY:Int = 20
		Local startX:Int = 89
		buttonContinue = New TGameGUIButton.Create(New TVec2D.Init(startX, startY+0*10 -1), New TVec2D.Init(80,17), "Continue", "MessageWindowInGameMenu")
		buttonStatistics = New TGameGUIButton.Create(New TVec2D.Init(startX, startY+2*10 -1), New TVec2D.Init(80,17), "Game Statistics", "MessageWindowInGameMenu")
		buttonLoad = New TGameGUIButton.Create(New TVec2D.Init(startX, startY+5*10 -1), New TVec2D.Init(80,17), "Load Game", "MessageWindowInGameMenu")
		buttonSave = New TGameGUIButton.Create(New TVec2D.Init(startX, startY+7*10 -1), New TVec2D.Init(80,17), "Save Game", "MessageWindowInGameMenu")
		buttonSettings = New TGameGUIButton.Create(New TVec2D.Init(startX, startY+9*10 -1), New TVec2D.Init(80,17), "Settings", "MessageWindowInGameMenu")
		buttonBackToMainMenu = New TGameGUIButton.Create(New TVec2D.Init(startX, startY+12*10 -1), New TVec2D.Init(80,17), "Back to Main Menu", "MessageWindowInGameMenu")
		buttonQuit = New TGameGUIButton.Create(New TVec2D.Init(startX, startY+14*10 -1), New TVec2D.Init(80,17), "Quit", "MessageWindowInGameMenu")

		EnableOrDisableButtons()
	End Method


	Method Open:Int() 'override
		wasPaused = game.IsPaused()
		game.SetPaused(True)
	End Method


	Method Close:Int() 'override
		If Not wasPaused Then game.SetPaused(False)
	End Method



	Method EnableOrDisableButtons()
		'
	End Method


	Method Update:Int()
		EnableOrDisableButtons()

		If MessageWindowCollection.IsActiveWindow(Self)
			If buttonContinue Then buttonContinue.Update()
			If buttonStatistics Then buttonStatistics.Update()
			If buttonLoad Then buttonLoad.Update()
			If buttonSave Then buttonSave.Update()
			If buttonSettings Then buttonSettings.Update()
			If buttonBackToMainMenu Then buttonBackToMainMenu.Update()
			If buttonQuit Then buttonQuit.Update()
		EndIf

		If buttonContinue.IsClicked()
			buttonContinue.mouseIsClicked = Null
			Close()
			Destroy()
			MouseManager.ResetKey(1)
			Return False
		EndIf

		If buttonQuit.IsClicked()
			buttonQuit.mouseIsClicked = Null
			app.exitApp = True
			MouseManager.ResetKey(1)
			Return False
		EndIf

		If buttonBackToMainMenu.IsClicked()
			buttonBackToMainMenu.mouseIsClicked = Null
			GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("mainmenu"), 0.2)
			MouseManager.ResetKey(1)
			Return False
		EndIf

		If buttonSettings.IsClicked()
			buttonSettings.mouseIsClicked = Null
			MessageWindowCollection.OpenSettings()
			MouseManager.ResetKey(1)
			Return False
		EndIf

		If buttonStatistics.IsClicked()
			buttonStatistics.mouseIsClicked = Null
			MessageWindowCollection.OpenGameStatsWindow()
			MouseManager.ResetKey(1)
			Return False
		EndIf

		If buttonLoad.IsClicked()
			buttonLoad.mouseIsClicked = Null
			MessageWindowCollection.OpenLoadMenu()
			MouseManager.ResetKey(1)
			Return False
		EndIf

		If buttonSave.IsClicked()
			buttonSave.mouseIsClicked = Null
			MessageWindowCollection.OpenSaveMenu()
			MouseManager.ResetKey(1)
			Return False
		EndIf

		If MouseManager.IsHit(2) Or KeyManager.IsHit(KEY_ESCAPE)
			KeyManager.ResetKey(KEY_ESCAPE)
			KeyManager.BlockKey(KEY_ESCAPE, 200)

			Close()
			Destroy()
			MouseManager.ResetKey(2)
			Return False
		EndIf


		Return Super.Update()
	End Method


	Method Render:Int(offsetX:Int=0, offsetY:Int=0)
		Super.Render(offsetX, offsetY)

		If buttonContinue Then buttonContinue.Draw()
		If buttonStatistics Then buttonStatistics.Draw()
		If buttonLoad Then buttonLoad.Draw()
		If buttonSave Then buttonSave.Draw()
		If buttonSettings Then buttonSettings.Draw()
		If buttonBackToMainMenu Then buttonBackToMainMenu.Draw()
		If buttonQuit Then buttonQuit.Draw()
	End Method
End Type




Type TMessageWindow_Upgrade Extends TMessageWindow
	Field buttonFertility:TGameGUIButton
	Field buttonShipspeed:TGameGUIButton
	Field buttonResearchPoints:TGameGUIButton
	Field buttonMissileRefillRate:TGameGUIButton
	Field buttonDone:TGameGUIButton
	Field planetID:Int
	Field wasPaused:Int = False


	Method New()
		caption = "Knowledge Hub"

		Local startY:Int = 40
		buttonFertility = New TGameGUIButton.Create(New TVec2D.Init(164, startY+0*25 -1), New TVec2D.Init(62,17), "", "MessageWindowUpgrade")
		buttonFertility.SetIcon("icon.heart", 12)

		buttonShipspeed = New TGameGUIButton.Create(New TVec2D.Init(164, startY+1*25 -1), New TVec2D.Init(62,17), "", "MessageWindowUpgrade")
		buttonShipspeed.SetIcon("icon.rocket", 12)

		buttonResearchPoints = New TGameGUIButton.Create(New TVec2D.Init(164, startY+2*25 -1), New TVec2D.Init(62,17), "", "MessageWindowUpgrade")
		buttonResearchPoints.SetIcon("icon.researchpoints", 12)

		buttonMissileRefillRate = New TGameGUIButton.Create(New TVec2D.Init(164, startY+3*25 -1), New TVec2D.Init(62,17), "", "MessageWindowUpgrade")
		buttonMissileRefillRate.SetIcon("icon.refill", 12)

		buttonDone = New TGameGUIButton.Create(New TVec2D.Init(85,startY+4*25 + 10 -1), New TVec2D.Init(80,17), "DONE", "MessageWindowUpgrade")

		EnableOrDisableButtons()
	End Method


	Method Open:Int() 'override
		wasPaused = game.IsPaused()
		game.SetPaused(True)
	End Method


	Method Close:Int() 'override
		If Not wasPaused Then game.SetPaused(False)
	End Method


	Method EnableOrDisableButtons()
		Local techtree:TTechTree = Game.GetPlayer().GetTechTree()
		Local availableRP:Int = Game.GetPlayer().GetResearchPoints()
		If availableRP < techtree.GetPopulationGrowthRateLevelCost() Or techtree.IsPopulationGrowthRateLevelMaxReached()
			buttonFertility.Disable()
		Else
			buttonFertility.Enable()
		EndIf
		If availableRP < techtree.GetShipSpeedLevelCost() Or techtree.IsShipSpeedLevelMaxReached()
			buttonShipspeed.Disable()
		Else
			buttonShipspeed.Enable()
		EndIf
		If availableRP < techtree.GetCollectResearchPointsRateLevelCost() Or techtree.IsCollectResearchPointsRateLevelMaxReached()
			buttonResearchPoints.Disable()
		Else
			buttonResearchPoints.Enable()
		EndIf
		If availableRP < techtree.GetMissileRefillRateLevelCost() Or techtree.IsMissileRefillRateLevelMaxReached()
			buttonMissileRefillRate.Disable()
		Else
			buttonMissileRefillRate.Enable()
		EndIf
	End Method


	Method Update:Int()
		Local techtree:TTechTree = Game.GetPlayer().GetTechTree()

		EnableOrDisableButtons()


		If buttonDone Then buttonDone.Update()
		If buttonFertility Then buttonFertility.Update()
		If buttonShipspeed Then buttonShipspeed.Update()
		If buttonResearchPoints Then buttonResearchPoints.Update()
		If buttonMissileRefillRate Then buttonMissileRefillRate.Update()

		If techtree.IsCollectResearchPointsRateLevelMaxReached()
			buttonResearchPoints.SetCaption("Reached~n upgrade max")
		Else
			buttonResearchPoints.SetCaption("Upgrade for ~n" + techtree.GetCollectResearchPointsRateLevelCost() +" RP")
		EndIf
		If techtree.IsPopulationGrowthRateLevelMaxReached()
			buttonFertility.SetCaption("Reached~nupgrade max")
		Else
			buttonFertility.SetCaption("Upgrade for ~n" + techtree.GetPopulationGrowthRateLevelCost() +" RP")
		EndIf
		If techtree.IsShipSpeedLevelMaxReached()
			buttonShipspeed.SetCaption("Reached~nupgrade max")
		Else
			buttonShipspeed.SetCaption("Upgrade for ~n" + techtree.GetShipSpeedLevelCost() +" RP")
		EndIf
		If techtree.IsMissileRefillRateLevelMaxReached()
			buttonMissileRefillRate.SetCaption("Reached~nupgrade max")
		Else
			buttonMissileRefillRate.SetCaption("Upgrade for ~n" + techtree.GetMissileRefillRateLevelCost() +" RP")
		EndIf

		If buttonResearchPoints.IsClicked()
			Game.GetPlayer().researchPoints :- techtree.GetCollectResearchPointsRateLevelCost()
			techtree.SetCollectResearchPointsRateLevel(+1, True)
			MouseManager.ResetKey(1)
		EndIf
		If buttonFertility.IsClicked()
			Game.GetPlayer().researchPoints :- techtree.GetPopulationGrowthRateLevelCost()
			techtree.SetPopulationGrowthRateLevel(+1, True)
			MouseManager.ResetKey(1)
		EndIf
		If buttonShipspeed.IsClicked()
			Game.GetPlayer().researchPoints :- techtree.GetShipSpeedLevelCost()
			techtree.SetShipSpeedLevel(+1, True)
			MouseManager.ResetKey(1)
		EndIf
		If buttonMissileRefillRate.IsClicked()
			Game.GetPlayer().researchPoints :- techtree.GetMissileRefillRateLevelCost()
			techtree.SetMissileRefillRateLevel(+1, True)
			MouseManager.ResetKey(1)
		EndIf


		If buttonDone.IsClicked() Or MouseManager.IsHit(2)
			Close()
			Destroy()
			Return False
		EndIf

		Return Super.Update()
	End Method


	Method Render:Int(offsetX:Int=0, offsetY:Int=0)
		Super.Render(offsetX, offsetY)

'		Local planet:TPlanet = space.GetPlanet(planetID)
'		If planet
'			GetBitmapFont("default").DrawBlock("Upgrade |b|"+planet.name+"|/b|", area.GetIntX() + 10, area.GetIntY()+10, area.GetIntW()-20, area.GetIntH()-20, ALIGN_LEFT_TOP, GameColorCollection.basePalette[1])
'		Else
'			GetBitmapFont("default").DrawBlock("Upgrade", area.GetIntX() + 10, area.GetIntY()+10, area.GetIntW()-20, area.GetIntH()-20, ALIGN_LEFT_TOP, GameColorCollection.basePalette[1])
'		EndIf
		'only global for now
'		GetBitmapFont("default").DrawBlock("knowledge hub", area.GetIntX() + 10, area.GetIntY()+10, area.GetIntW()-20, area.GetIntH()-20, ALIGN_LEFT_TOP, GameColorCollection.basePalette[1])

		Local s:String
		Local col:String="114,177,75"
		Local techtree:TTechTree = Game.GetPlayer().GetTechTree()
		Local startY:Int = area.GetIntY()+20

		If techtree.IsPopulationGrowthRateLevelMaxReached()
			s = "Fertility reached maximum level. Population growth rate is increased by |color=" + col + "|"+MathHelper.NumberToString(100*(techtree.GetPopulationGrowthRateMod() - 1.0), 1)+" %|/color|."
		Else
'print "pop: "+techtree.GetPopulationGrowthRateMod(1)
			s = "Upgrading fertility to |color=" + col + "|level" + (techtree.GetPopulationGrowthRateLevel() + 1) + "|/color| will increase population growth rate by |color=" + col + "|"+MathHelper.NumberToString(100*(techtree.GetPopulationGrowthRateMod(techtree.GetPopulationGrowthRateLevel() + 1) - 1.0), 1)+" %|/color|."
		EndIf
		GetBitmapFont("small").DrawBlock(s, area.GetIntX() + 10, startY + 0*25, area.GetIntW()-20 - 55, area.GetIntH()-30, ALIGN_LEFT_TOP, GameColorCollection.basePalette[15])

		If techtree.IsPopulationGrowthRateLevelMaxReached()
			s = "Ship speed reached maximum level. Your space ships travel faster by |color=" + col + "|"+MathHelper.NumberToString(100*(techtree.GetShipSpeedMod() - 1.0), 1)+" %|/color|."
		Else
'print "spd: "+techtree.GetShipSpeedMod(1)
			s = "Upgrading ship speed to |color=" + col + "|level" + (techtree.GetShipSpeedLevel() + 1) + "|/color| allows your space ships to travel faster by |color=" + col + "|"+MathHelper.NumberToString(100*(techtree.GetShipSpeedMod(techtree.GetShipSpeedLevel() + 1) - 1.0), 1)+" %|/color|."
		EndIf
		GetBitmapFont("small").DrawBlock(s, area.GetIntX() + 10, startY + 1*25, area.GetIntW()-20 - 55, area.GetIntH()-30, ALIGN_LEFT_TOP, GameColorCollection.basePalette[15])

		If techtree.IsPopulationGrowthRateLevelMaxReached()
			s = "Research efficiency reached maximum level. Your production of research points is increased by  |color=" + col + "|"+MathHelper.NumberToString(100*(techtree.GetCollectResearchPointsRateMod() - 1.0), 1)+" %|/color|."
		Else
'print "eff: "+techtree.GetCollectResearchPointsRateMod(1)
			s = "Upgrading research efficiency to |color=" + col + "|level" + (techtree.GetCollectResearchPointsRateLevel() + 1) + "|/color| increases production of research points by |color=" + col + "|"+MathHelper.NumberToString(100*(techtree.GetCollectResearchPointsRateMod(techtree.GetCollectResearchPointsRateLevel() + 1) - 1.0), 1)+" %|/color|."
		EndIf
		GetBitmapFont("small").DrawBlock(s, area.GetIntX() + 10, startY + 2*25, area.GetIntW()-20 - 55, area.GetIntH()-30, ALIGN_LEFT_TOP, GameColorCollection.basePalette[15])

		If techtree.IsMissileRefillRateLevelMaxReached()
			s = "Missile refill rate reached maximum level. Your refill rate is increased by  |color=" + col + "|"+MathHelper.NumberToString(100*(techtree.GetMissileRefillRateMod() - 1.0), 1)+" %|/color|."
		Else
			s = "Upgrading missile refill rate to |color=" + col + "|level" + (techtree.GetMissileRefillRateLevel() + 1) + "|/color| decreases time needed to refill a missile of the planetary defense by |color=" + col + "|"+MathHelper.NumberToString(100*(techtree.GetMissileRefillRateMod(techtree.GetMissileRefillRateLevel() + 1) - 1.0), 1)+" %|/color|."
		EndIf
		GetBitmapFont("small").DrawBlock(s, area.GetIntX() + 10, startY + 3*25, area.GetIntW()-20 - 55, area.GetIntH()-30, ALIGN_LEFT_TOP, GameColorCollection.basePalette[15])


		If buttonDone Then buttonDone.Draw()
		If buttonFertility Then buttonFertility.Draw()
		If buttonShipspeed Then buttonShipspeed.Draw()
		If buttonResearchPoints Then buttonResearchPoints.Draw()
		If buttonMissileRefillRate Then buttonMissileRefillRate.Draw()
	End Method

End Type




Type TMessageWindow_LevelStart Extends TMessageWindow
	Field buttonDone:TGameGUIButton
	Field shuffleAnimTimer:Double = 3
	Field shuffleAnimTime:Double = 2.99
	Field shuffleAnimStepTime:Double = 0.01
	Field shuffleAnimPos:Int
	Field wasPaused:Int = False

	Method New()
		buttonDone = New TGameGUIButton.Create(New TVec2D.Init(85,158), New TVec2D.Init(80,17), "Start now", "MessageWindowUpgrade")
		buttonDone.Disable()
	End Method


	Method Open:Int() 'override
		wasPaused = game.IsPaused()
		game.SetPaused(True)

		Return Super.Open()
	End Method


	Method Close:Int() 'override
		If Not wasPaused Then game.SetPaused(False)

		Return Super.Close()
	End Method



	Method Update:Int()
		If shuffleAnimTimer > 0
			shuffleAnimTimer :- GetDeltaTimer().GetDelta()
			If shuffleanimTimer < shuffleAnimTime
				shuffleAnimPos :+ 1
				shuffleAnimStepTime :+ 0.01
				shuffleAnimTime :- shuffleAnimStepTime
			EndIf
		Else
			If Not buttonDone.IsEnabled() Then buttonDone.Enable()
		EndIf

		If buttonDone
			buttonDone.rect.SetXY(area.GetX() + 0.5*(area.GetW() - buttonDone.GetWidth()), area.GetY2() - 8 - buttonDone.GetHeight())
			buttonDone.Update()
		EndIf

		If buttonDone.IsClicked() Or MouseManager.IsHit(2) Or KeyManager.IsHit(KEY_ESCAPE)
			KeyManager.ResetKey(KEY_ESCAPE)
			KeyManager.BlockKey(KEY_ESCAPE, 200)

			MouseManager.ResetKey(1)
			MouseManager.ResetKey(2)

			game.SetPaused(False)
			Close()
			Destroy()
			Return False
		EndIf

		Return Super.Update()
	End Method


	Method Render:Int(offsetX:Int=0, offsetY:Int=0)
		Super.Render(offsetX, offsetY)


		Local centerX:Int = Int(area.GetIntX() + area.GetIntW()/2)
		Local startY:Int = area.GetIntY() + 35
		Local framesPerRowMax:Int = Min(3, game.players.length)

		For Local pIndex:Int = 0 Until game.players.length
			Local row:Int = pIndex / 3
			Local col:Int = pIndex Mod 3
			Local colsInRow:Int = Max(0, Min(3, game.players.length - (row * 3)))
			Local frameX:Int = centerX - Int(colsInRow/2.0 * 55) + col*55

			Local frameY:Int = startY + row*55

			If shuffleAnimTime > 0
				GetSpriteFromRegistry("characterframe."+(1 + (shuffleAnimPos + pIndex) Mod 6)).Draw(frameX, frameY)
			Else
				Local p:TPlayer = game.GetPlayer(pIndex+1)
				GetSpriteFromRegistry("characterframe."+(p.raceID)).Draw(frameX, frameY)
			EndIf
			GetSpriteFromRegistry("characterframe.overlay").Draw(frameX, frameY)
		Next
		GetBitmapFont("default").DrawBlock("Fight for the |color="+GameColorCollection.basePalette[7].ToRGBString(",")+"|"+game.galaxyName+"|/color|", area.GetIntX() + 10, area.GetIntY() + 10, area.GetIntW()-20, area.GetIntH()-30, ALIGN_LEFT_TOP, GameColorCollection.basePalette[1])
		GetBitmapFont("small").DrawBlock("The following races try to dominate this sector of the galaxy:", area.GetIntX() + 10, area.GetIntY() + 20, area.GetIntW()-20, area.GetIntH()-30, ALIGN_LEFT_TOP, GameColorCollection.basePalette[15])


		If buttonDone Then buttonDone.Draw()
	End Method

End Type




Type TMessageWindow_GameWon Extends TMessageWindow
	Field buttonDone:TGameGUIButton
	Field buttonNextCampaignMap:TGameGUIButton
	Field buttonStatistics:TGameGUIButton


	Method New()
		buttonDone = New TGameGUIButton.Create(New TVec2D.Init(85,158), New TVec2D.Init(80,17), "Back to Main Menu", "MessageWindowGameWon")
		buttonStatistics = New TGameGUIButton.Create(New TVec2D.Init(85,138), New TVec2D.Init(80,17), "Show Statistics", "MessageWindowGameWon")
		buttonNextCampaignMap = New TGameGUIButton.Create(New TVec2D.Init(85,118), New TVec2D.Init(80,17), "Continue Campaign", "MessageWindowGameWon")
		buttonNextCampaignMap.Hide()
	End Method


	Method Open:Int()
		If buttonDone
			buttonDone.rect.SetXY(area.GetX() + 0.5*(area.GetW() - buttonDone.GetWidth()), area.GetY2() - 8 - buttonDone.GetHeight())
		EndIf
		If buttonStatistics
			buttonStatistics.rect.SetXY(area.GetX() + 0.5*(area.GetW() - buttonDone.GetWidth()), area.GetY2() - 8 - buttonDone.GetHeight() - 2 - buttonStatistics.GetHeight())
		EndIf
		If buttonNextCampaignMap
			buttonNextCampaignMap.rect.SetXY(area.GetX() + 0.5*(area.GetW() - buttonDone.GetWidth()), area.GetY2() - 8 - buttonDone.GetHeight() -  2 - buttonStatistics.GetHeight() - 2 - buttonNextCampaignMap.GetHeight())
		EndIf
		If game.gameType = TGame.GAMETYPE_CAMPAIGN
			buttonNextCampaignMap.Show()
		EndIf

		Return Super.Open()
	End Method


	Method Close:Int()
	End Method


	Method Update:Int()
		If buttonDone Then buttonDone.Update()
		If buttonNextCampaignMap Then buttonNextCampaignMap.Update()
		If buttonStatistics Then buttonStatistics.Update()


		If buttonNextCampaignMap.IsClicked()
			buttonNextCampaignMap.mouseIsClicked = Null
			MouseManager.ResetKey(1)

			GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("campaignmenu"), 0.2 )

			Close()
			Destroy()
			Return True
		EndIf

		If buttonStatistics.IsClicked()
			buttonStatistics.mouseIsClicked = Null
			MouseManager.ResetKey(1)

			MessageWindowCollection.OpenGameStatsWindow()
			Return True
		EndIf

		If buttonDone.IsClicked() Or MouseManager.IsHit(2) Or KeyManager.IsHit(KEY_ESCAPE)
			buttonDone.mouseIsClicked = Null
			KeyManager.ResetKey(KEY_ESCAPE)
			KeyManager.BlockKey(KEY_ESCAPE, 200)
			MouseManager.ResetKey(1)
			MouseManager.ResetKey(2)

			GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("mainmenu"), 0.2 )

			game.SetPaused(False)
			Close()
			Destroy()
			Return False
		EndIf

		Return Super.Update()
	End Method


	Method Render:Int(offsetX:Int=0, offsetY:Int=0)
		Super.Render(offsetX, offsetY)

		GetBitmapFont("default").DrawBlock("Seems you won this fight.", area.GetIntX() + 10, area.GetIntY() + 10, area.GetIntW()-20, area.GetIntH()-30, ALIGN_LEFT_TOP, GameColorCollection.basePalette[1])
		GetBitmapFont("small").DrawBlock("Will luck follow you into the next combat?", area.GetIntX() + 10, area.GetIntY() + 20, area.GetIntW()-20, area.GetIntH()-30, ALIGN_LEFT_TOP, GameColorCollection.basePalette[15])

		If buttonStatistics Then buttonStatistics.Draw()
		If buttonNextCampaignMap Then buttonNextCampaignMap.Draw()
		If buttonDone Then buttonDone.Draw()
	End Method
End Type




Type TMessageWindow_GameLost Extends TMessageWindow
	Field buttonDone:TGameGUIButton
	Field buttonRetry:TGameGUIButton
	Field buttonContinueWatching:TGameGUIButton
	Field buttonStatistics:TGameGUIButton


	Method New()
		buttonDone = New TGameGUIButton.Create(New TVec2D.Init(85,158), New TVec2D.Init(80,17), "Back to Main Menu", "MessageWindowGameLost")
		buttonRetry = New TGameGUIButton.Create(New TVec2D.Init(85,138), New TVec2D.Init(80,17), "Try again", "MessageWindowGameLost")
		buttonStatistics = New TGameGUIButton.Create(New TVec2D.Init(85,118), New TVec2D.Init(80,17), "Show Statistics", "MessageWindowGameLost")
		buttonContinueWatching = New TGameGUIButton.Create(New TVec2D.Init(85,138), New TVec2D.Init(80,17), "Continue Watching", "MessageWindowGameLost")
	End Method


	Method Open:Int()
		buttonDone.rect.SetXY(area.GetX() + 0.5*(area.GetW() - buttonDone.GetWidth()), area.GetY2() - 8 - buttonDone.GetHeight())
		buttonStatistics.rect.SetXY(area.GetX() + 0.5*(area.GetW() - buttonDone.GetWidth()), area.GetY2() - 8 - buttonDone.GetHeight() - 2 - buttonStatistics.GetHeight())
		buttonContinueWatching.rect.SetXY(area.GetX() + 0.5*(area.GetW() - buttonDone.GetWidth()), area.GetY2() - 8 - buttonDone.GetHeight() - 2 - buttonStatistics.GetHeight() - 2 - buttonContinueWatching.GetHeight())

		If buttonRetry
			If Not game.mapGUID Then buttonRetry.Hide()
			buttonRetry.rect.SetXY(area.GetX() + 0.5*(area.GetW() - buttonDone.GetWidth()), area.GetY2() - 8 - buttonDone.GetHeight() - 2 - buttonStatistics.GetHeight() - 2 - buttonContinueWatching.GetHeight() - 2 - buttonRetry.GetHeight())
		EndIf

		Return Super.Open()
	End Method


'	Method Close:Int()
'	End Method


	Method Update:Int()
		If buttonDone Then buttonDone.Update()
		If buttonRetry Then buttonRetry.Update()
		If buttonContinueWatching Then buttonContinueWatching.Update()
		If buttonStatistics Then buttonStatistics.Update()

		If buttonContinueWatching.IsClicked()
			buttonContinueWatching.mouseIsClicked = Null
			MouseManager.ResetKey(1)

			game.GetPlayer().isObserving = True

			Close()
			Destroy()
			Return True
		EndIf

		If buttonStatistics.IsClicked()
			buttonStatistics.mouseIsClicked = Null
			MouseManager.ResetKey(1)

			MessageWindowCollection.OpenGameStatsWindow()
			Return True
		EndIf


		If buttonRetry.IsClicked()
			buttonRetry.mouseIsClicked = Null
			MouseManager.ResetKey(1)

			game.RestartGame()

			Close()
			Destroy()
			Return True
		EndIf


		If buttonDone.IsClicked() Or MouseManager.IsHit(2) Or KeyManager.IsHit(KEY_ESCAPE)
			buttonDone.mouseIsClicked = Null
			KeyManager.ResetKey(KEY_ESCAPE)
			KeyManager.BlockKey(KEY_ESCAPE, 200)
			MouseManager.ResetKey(1)
			MouseManager.ResetKey(2)

			GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("mainmenu"), 0.2 )

			game.SetPaused(False)
			Close()
			Destroy()
			Return False
		EndIf

		Return Super.Update()
	End Method


	Method Render:Int(offsetX:Int=0, offsetY:Int=0)
		Super.Render(offsetX, offsetY)

		GetBitmapFont("default").DrawBlock("Better Luck next time...", area.GetIntX() + 10, area.GetIntY() + 10, area.GetIntW()-20, area.GetIntH()-30, ALIGN_LEFT_TOP, GameColorCollection.basePalette[1])
		GetBitmapFont("small").DrawBlock("You might not be ready for intergalactic operations.", area.GetIntX() + 10, area.GetIntY() + 20, area.GetIntW()-20, area.GetIntH()-30, ALIGN_LEFT_TOP, GameColorCollection.basePalette[15])

		If buttonDone Then buttonDone.Draw()
		If buttonRetry Then buttonRetry.Draw()
		If buttonContinueWatching Then buttonContinueWatching.Draw()
		If buttonStatistics Then buttonStatistics.Draw()
	End Method
End Type




Type TGameGUIDropDown_Race Extends TGameGUIDropDown
	Method DrawContent()
		Local i:TGUIListItem = TGUIListItem(GetSelectedEntry())
		If i And Int(String(i.extra))
			valueDisplacement = New TVec2D.Init(8, 4)
		Else
			valueDisplacement = New TVec2D.Init(2, 4)
		EndIf

		Super.DrawContent()

		If i And Int(String(i.extra))
			valueDisplacement = New TVec2D.Init(8, 4)
			Local raceID:Int = Int(String(i.extra))
			If raceID
				GameColorCollection.basePalette[0].SetRGB()
				DrawRect(GetScreenX()+4, GetScreenY()+6, 4,4)
				game.racesColors[raceID].SetRGB()
				DrawRect(GetScreenX()+4, GetScreenY()+5, 4,4)
				SetColor 255,255,255
			EndIf
		EndIf
	End Method
End Type


Type TGameGUIDropDownItem_Race Extends TGameGUIDropDownItem


	Method DrawValue()
		Local raceID:Int = Int(String(extra))
		If raceID
			GameColorCollection.basePalette[0].SetRGB()
			DrawRect(GetScreenX()+2, GetScreenY()+4, 4,4)
			game.racesColors[raceID].SetRGB()
			DrawRect(GetScreenX()+2, GetScreenY()+3, 4,4)
			SetColor 255,255,255
			GetBitmapFont("small").DrawBlock(value, getScreenX()+2 + 6, GetScreenY(), GetScreenWidth()-4, GetScreenHeight(), ALIGN_LEFT_CENTER, valueColor)
		Else
			GetBitmapFont("small").DrawBlock(value, getScreenX()+2, GetScreenY(), GetScreenWidth()-4, GetScreenHeight(), ALIGN_LEFT_CENTER, valueColor)
		EndIf
	End Method
End Type



Type TGameGUIDropDownItem Extends TGUIDropDownItem
    Method Create:TGameGUIDropDownItem(position:TVec2D = Null, dimension:TVec2D = Null, value:String="")
		SetFont(GetBitmapFont("small"))
		valueColor = TColor.clBlack

		Super.Create(position, dimension, value)

		rect.SetWH(80, 10)

		Return Self
	End Method


	Method SetExtra:TGameGUIDropDownItem(extra:Object) 'override
		Super.SetExtra(extra)
		Return Self
	End Method


	Method GetScreenWidth:Float()
		Return 60
	End Method

	Method GetScreenHeight:Float()
		Return 10
	End Method

'	Method DrawValue()
'		GetBitmapFont("small").DrawBlock(value, getScreenX()+2, GetScreenY(), GetScreenWidth()-4, GetScreenHeight(), ALIGN_LEFT_CENTER, valueColor)
'	End Method


'SetListContentHeight

	Method DrawBackground()
		If Not isHovered() And Not isSelected() Then Return

		Local upperParent:TGUIObject = GetParent("TGUIListBase")
		upperParent.RestrictContentViewPort()

		If isHovered()
			GameColorCollection.basePalette[1].SetRGB()
			DrawRect(getScreenX(), getScreenY(), GetScreenWidth(), GetScreenHeight())
			SetColor 255,255,255
		ElseIf isSelected()
			GameColorCollection.basePalette[11].SetRGB()
			DrawRect(getScreenX(), getScreenY(), GetScreenWidth(), GetScreenHeight())
			SetColor 255,255,255
		EndIf

		upperParent.ResetViewPort()
	End Method
End Type




Type TGameGUIDropDown Extends TGUIDropDown

	Method New()
		defaultSpriteName = "gui.input"
		defaultOverlaySpriteName = "gui.icon.arrowDown"

		minDimension = New TVec2D.Init(18,12)
		valueDisplacement = New TVec2D.Init(2, 4)
	End Method


    Method Create:TGameGUIDropDown(position:TVec2D = Null, dimension:TVec2D = Null, value:String="", maxLength:Int=128, limitState:String = "")
		SetFont(GetBitmapFont("small"))
		color = TColor.clWhite
		editColor = TColor.clBlack
		textEffectAmount = 0.0 'no drop
		textEffectType = 0

		listOffsetY = -3
		listHeight = 30
		spriteName = "gui.input"

		Super.Create(position, dimension, value, maxLength, limitState)

		Return Self
	End Method
End Type




Type TGameGUIInput Extends TGUIInput
	Method New()
		minDimension = New TVec2D.Init(18,12)
	End Method

	Method Create:TGameGUIInput(pos:TVec2D, dimension:TVec2D, value:String, maxLength:Int=128, limitState:String="")
		Super.Create(pos, dimension, value, maxLength, limitState)
		SetTypeFont(GetBitmapFont("small"))
		color = TColor.clBlack
		editColor = TColor.clBlack
		textEffectAmount = 0.0 'no drop
		textEffectType = 0

		spriteName = "gui.input"

		Return Self
	End Method


	Method DrawCaret(x:Int, y:Int) 'override
		Local oldAlpha:Float = GetAlpha()
		SetAlpha Float(Ceil(Sin(Time.GetTimeGone() / 4)) * oldAlpha)
		DrawRect(x, y+1, 1, GetFont().GetMaxCharHeight()+1 )
		SetAlpha oldAlpha
	End Method

End Type



Type TGameGUICheckbox Extends TGUICheckBox
	Method New()
		_checkboxMinDimension.SetXY(12,12)
		tintEnabled = False
	End Method



	Method Create:TGameGUICheckbox(pos:TVec2D, dimension:TVec2D, value:String, limitState:String="")
		Super.Create(pos, dimension, value, state)
		caption.valueEffectType = 0 'disable shadow
		caption.SetFont(GetBitmapFont("small"))
		caption.color = TColor.clWhite

		spriteName = "gui.button.small"
		checkedSpriteName = "gui.checkbox.sign"

		Return Self
	End Method
End Type




Type TGameGUISlider Extends TGUISlider
	Method Create:TGameGUISlider(pos:TVec2D, dimension:TVec2D, value:String, State:String = "")
		Super.Create(pos, dimension, value, state)

		handleSpriteName = "gui.slider.handle"
		gaugeSpriteName = "gui.slider.gauge"
		gaugeFilledSpriteName = "gui.slider.gauge.filled"
		_gaugeOffset.SetXY(0,1)
		Return Self
	End Method
End Type



Type TGameGUIButton Extends TGUIButton
	Field _onClickHandler:Int()
	Field iconSprite:TSprite

	Method Create:TGameGUIButton(pos:TVec2D, dimension:TVec2D, value:String, State:String = "")
		Local button:TGameGUIButton = TGameGUIButton(Super.Create(pos, dimension, value, state))
		'button.SetCaptionOffset(15, -1)
		button.caption.valueEffectType = 0 'disable shadow
		button.caption.SetFont(GetBitmapFont("pixelfont", 4))

		button.spriteName = "button"

		Return button
	End Method


	Method SetIcon(spriteName:String, width:Int = -1, height:Int = -1)
		iconSprite = GetSpriteFromRegistry(spriteName)
		If width = -1 Then width = iconSprite.GetWidth()
		If height = -1 Then height = iconSprite.GetHeight()

		SetCaptionOffset( width + 2, -1)
		RepositionCaption()
	End Method


	Method onClick:Int(triggerEvent:TEventBase)
		If _onClickHandler Then _onClickHandler()

		Return Super.onClick(triggerEvent)
	End Method


	Method DrawBackground() 'override
		SetAlpha 1.0
		Super.DrawBackground()
	End Method


	Method DrawButtonContent:Int(position:TVec2D)
		If iconSprite
			If state = ".active"
				iconSprite.Draw(GetScreenX() + 7 +1, GetScreenY() + 0.5 * GetScreenHeight()-1 +1, 0, ALIGN_CENTER_CENTER)
			Else
				iconSprite.Draw(GetScreenX() + 7, GetScreenY() + 0.5 * GetScreenHeight()-1, 0, ALIGN_CENTER_CENTER)
			EndIf
		EndIf

		If Not IsEnabled()
			caption.color = TColor.clWhite
			caption.SetFont(GetBitmapFont("pixelfont.gray", 4))
		ElseIf state = ".hover" Or state = ".active"
			caption.color = TColor.clWhite
			caption.SetFont(GetBitmapFont("pixelfont", 4))
'			caption.color = GameColorCollection.basePalette[7] ' oTColor.clWhite
		Else
			caption.SetFont(GetBitmapFont("pixelfont.yellow", 4))
			caption.color = TColor.clWhite
'			caption.color = GameColorCollection.basePalette[1]
		EndIf
		Return Super.DrawButtonContent(position)
	End Method
End Type



'a bitmapfont based on a sprite / image
Type TSpritePackBitmapFont Extends TBitmapFont
	Field imgGlyphCount:Int
	Field spriteKey:String
	Field glyphString:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:.,!?"


	Function Create:TSpritePackBitmapFont(name:String, url:String, size:Int, style:Int, fixedCharWidth:Int = -1, charWidthModifier:Float = 1.0)
		Local obj:TSpritePackBitmapFont = New TSpritePackBitmapFont
		obj.FName = name
		obj.FFile = url
		obj.spriteKey = url
		obj.FSize = size
		obj.FStyle = style
		obj.uniqueID = name+"_"+url+"_"+size+"_"+style
		obj.gfx = tmax2dgraphics.Current()
		obj.fixedCharWidth = fixedCharWidth
		obj.charWidthModifier = charWidthModifier

		obj.FImageFont = GetImageFont()

		'generate a charmap containing packed rectangles where to store images
		obj.InitFont()

		Return obj
	End Function



	Method LoadCharsFromSource(source:Object=Null) 'override
		Local sprite:TSprite = GetSpriteFromRegistry(spriteKey)

		AnalyzeImage()

		charsSprites = New TSprite[ chars.length ]
		For Local i:Int = 0 Until glyphString.length
			Local charKey:Int = glyphString[i]
			Local char:TBitmapFontChar = chars[charKey]

			Local rect:TRectangle = New TRectangle.Init(sprite.area.GetIntX() + char.area.GetIntX(), sprite.area.GetIntY(), char.area.GetIntW(), 4)
			char.area.SetX(0) 'remove information
'			resizeCharsSprites(charKey)
			charsSprites[charKey] = New TSprite.Init(sprite.parent, charKey, rect, Null, 0)
		Next
	End Method


	Method AnalyzeImage()
		imgGlyphCount = 30

		'1. bild extrahieren
		'2. y-achse kontrollieren: alles leer, dann naechster Buchstabe

		Local img:TImage = GetSpriteFromRegistry(spriteKey).GetImage()
		Local pix:TPixmap = LockImage(img)
		Local glyphFound:Int = 0
		Local glyphStart:Int = 0
		For Local x:Int = 0 Until pix.width
			Local colEmpty:Int = True
			For Local y:Int = 0 Until pix.height
				If ARGB_Alpha( pix.ReadPixel(x,y) ) > 0
					colEmpty = False
					Exit
				EndIf
			Next

			If colEmpty Or x = pix.width -1
				Local charCode:Int = 0
				If glyphFound <= glyphString.length Then charCode = glyphString[glyphFound]
				Local charWidth:Int = x - glyphStart
				If Not colEmpty And x = pix.width - 1 Then charWidth :+ 1
				chars[ charCode ] = New TBitmapFontChar.Init(Null, glyphStart, 0, charWidth, 4, charWidth+1)

				glyphFound :+ 1
				glyphStart = x + 1
			EndIf
		Next

		'space
		chars[ 32 ] = New TBitmapFontChar.Init(Null, 0, 0, 2, 4, 4)

		displaceY = 0
	End Method


	Method __draw:TVec2D(text:String,x:Float,y:Float, color:TColor=Null, doDraw:Int=True, FontStyle:TBitmapFontStyle)
		'this font only has uppercase
		text = text.ToUpper()

		Return Super.__draw(text,x,y,color,doDraw,FontStyle)
	End Method
'endrem
End Type



Function GenerateGalaxyName:String()
	Local result:String
	Local appendix:String[] = ["Galaxy", "System", "Boreas", "Aquarii", "Cloud", "Star System"]
	Local prependix:String[] = ["Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Comae", "Crux"]
	result = GeneratePlanetName()
	If RandRange(0, 100) < 5
		result = prependix[ RandRange(0, prependix.length - 1) ] + " " + result
	Else
		result = result + " " + appendix[ RandRange(0, appendix.length - 1) ]
	EndIf
	Return result
End Function



Function GeneratePlanetName:String()
	Global syllables:String[] = ["..lexegezacebisousesarmaindirea.eratenberalavetiedorquanteisrion", ..
	                             "ius'ru'ta'af'te'to'tu'he'ha'ho'hu" ..
	                            ]
	Global syllableLength:Int[] = [2, 3]
	Local doLongName:Int = 0 'RandRange(0, 100) < 20

	Local result:String
	Local syllableIndex:Int
	Local syllableVariant:Int = 0
	Local parts:Int = 2 + doLongName
	For Local i:Int = 0 To parts
		If i = parts
			syllableVariant = RandRange(0, 100) > 80
		Else
			syllableVariant = 0
		EndIf
		'0, 2, 4 ...
		syllableIndex = RandRange(0, syllables[syllableVariant].length / syllableLength[syllableVariant]) * syllableLength[syllableVariant]

		result :+ Mid(syllables[syllableVariant], syllableIndex + 1, syllableLength[syllableVariant])
		result = result.Replace(".","")
	Next
	result = StringHelper.UCFirst(result, 1)
	Return result
End Function


Rem
Function GeneratePlanetNameElite:string()
	global syllables:string = "..lexegezacebisousesarmaindirea.eratenberalavetiedorquanteisrion"
	global seed:int[2]
	seed[0] = RandRange(0, 65535) '$ffff
	seed[1] = RandRange(0, 65535)
	seed[2] = RandRange(0, 65535)

	return CreateName()

	Function ShuffleSeed()
		Local temp:int = (seed[0] +seed[1] +seed[2]) Mod 65536 '$10000
		seed[0] = seed[1]
		seed[1] = seed[2]
		seed[2] = temp
	End Function

	function CreateName:string()
		Local longnameflag:int = seed[0] & 64 '$40
		Local planetname:string = ""
		Local d:int

		For local n:int = 0 To 3
			d = ((seed[2] Shr 8) & $1f) Shl 1
			ShuffleSeed()

			If n < 3 Or longnameflag
				planetname = planetname + Mid(syllables,1+d,2)
				planetname = Replace(planetname,".","")
			EndIf
	    Next

		planetname = StringHelper.UCFirstSimple(planetname, 1)
		'planetname = Upper(Mid(planetname,1,1))+Mid(planetname,2,Len(planetname)-1)

		Return planetname
	End Function
End Function
endrem




Function GetGameTimeDelta:Float()
	Return (Not GameTime.paused) * GameTime.speedFactor * GetDeltaTimer().GetDelta()
End Function



Function DrawMarkerRect(rect:TRectangle, mode:Int = 0)
	Local minX:Int = Int( Min(rect.GetIntX(), rect.GetIntX2()) )
	Local maxX:Int = Int( Max(rect.GetIntX(), rect.GetIntX2()) )
	Local minY:Int = Int( Min(rect.GetIntY(), rect.GetIntY2()) )
	Local maxY:Int = Int( Max(rect.GetIntY(), rect.GetIntY2()) )
	DrawMarkerRectXYWH(minX, minY, maxX-minX, maxY-minY, mode)
End Function


Function DrawMarkerRectXYWH(x:Int, y:Int, w:Int, h:Int, mode:Int = 0)
	Local col1:TGameColor
	Local col2:TGamecolor
	Select mode
		Case 0
			col1 = game.hoverRectCol1
			col2 = game.hoverRectCol2
		Default
			col1 = game.selectionRectCol1
			col2 = game.selectionRectCol2
	End Select


	Local even:Int = (MilliSecs() / 200) Mod 3
	For Local i:Int = 0 To 3
		If i Mod 3 = even
			col1.SetRGB()
		Else
			col2.SetRGB()
		EndIf
		'drawrect takes scale into consideration ("320x200 -> 640x400")
		DrawRect(x + i, y, 1, 1)
		DrawRect(x + w -3 + i, y, 1, 1)
		DrawRect(x + 3 - i, y + h, 1, 1)
		DrawRect(x + w - i, y + h, 1, 1)

		DrawRect(x, y + 3 - i, 1, 1)
		DrawRect(x + w, y + i, 1, 1)
		DrawRect(x, y + h - i, 1, 1)
		DrawRect(x + w, y + h -3 + i, 1, 1)
	Next
	SetColor 255,255,255
End Function




Type Helper


	'the logistic function is a fast-to-slow-growing function
	'higher values are more likely returning nearly the maximum value
	'http://de.wikipedia.org/wiki/Logistische_Funktion
	'returns a value between 0-maximumValue subtracted by "fZero"
	Function logisticFunction:Float(value:Float, maximumValue:Float, proportionalityFactor:Float = 1.0, fZero:Float=0.5)
		Rem
			formula:
			f(t) =                 1
					G * ------------------------------
						1 + e^(-k*G*t) * (  G        )
										 (----   - 1 )
										 (f(0)       )

			e = euler value ("exp" in coding langugaes)
			G = maximumValue
			k = proportionalityFactor
			t = value
			f(0) = fZero
		End Rem

		Return maximumValue * 1.0/(1.0 + Exp(-proportionalityFactor*maximumValue*value) * (maximumValue/fZero - 1))
	End Function


	'returns a value between 0-1.0 for a given percentage value (0-1.0)
	Function LogisticalInfluence:Float(percentage:Float, proportionalityFactor:Float= 0.11)
		Return 1.0 - logisticFunction(percentage*100, 1.0, proportionalityFactor, 0.001)
	End Function


	Function LogisticalInfluence_Tangens:Float(percentage:Float, strength:Float=1.0, addRandom:Int=True)
		'sinus is there for some "randomness"
		'2.5 = "base strength" so 100% will reach "1.0"
		Return Min(1.0, Max(0.0, Tanh(percentage*(2.5*strength)) + addRandom * Abs(0.03*Sin(95*percentage))))
	End Function


	'higher strength values have a stronger decrease per percentage
	'higher strength can lead to Value(0.5) > Value(0.7)
	'higher percentages return a higher influence (in 100% = out ~100%)
	'value growth changes at 1/strength!!
	'-> we cut "used" percentage" so 100% = 1/strength
	Function LogisticalInfluence_Euler:Float(percentage:Float, strength:Float=1.0, addRandom:Int=True)
		'sinus is there for some "randomness"
		Return 1 - ( Exp(-strength * percentage) + addRandom * Abs(0.01 * Sin(155*percentage)) )
	End Function
End Type




'Plot/DrawLine ignore "SetVirtualResolution"
Function DrawRectLine(X1:Int,Y1:Int,X2:Int,Y2:Int)
        'Draws a line of individual pixels from X1,Y1 to X2,Y2 at any angle
        Local Steep:Int = Abs(Y2-Y1) > Abs(X2-X1)                 'Boolean
        If Steep
                Local Temp:Int=X1; X1=Y1; Y1=Temp               'Swap X1,Y1
                Temp=X2; X2=Y2; Y2=Temp         'Swap X2,Y2
        EndIf
        Local DeltaX:Int=Abs(X2-X1)             'X Difference
        Local DeltaY:Int=Abs(Y2-Y1)             'Y Difference
        Local Error:Int=0               'Overflow counter
        Local DeltaError:Int=DeltaY             'Counter adder
        Local X:Int=X1          'Start at X1,Y1
        Local Y:Int=Y1
        Local XStep:Int
        Local YStep:Int
        If X1<X2 Then XStep=1 Else XStep=-1     'Direction
        If Y1<Y2 Then YStep=1 Else YStep=-1     'Direction
        If Steep Then DrawRect(Y,X,1,1) Else DrawRect(X,Y,1,1)          'Draw
        While X<>X2
                X:+XStep                'Move in X
                Error:+DeltaError               'Add to counter
                If (Error Shl 1)>DeltaX         'Would it overflow?
                        Y:+YStep                'Move in Y
                        Error=Error-DeltaX              'Overflow/wrap the counter
                EndIf
                If Steep Then DrawRect(Y,X,1,1) Else DrawRect(X,Y,1,1)          'Draw
        Wend
End Function




Type TSimpleSoundSource Extends TSoundSourceElement
	Field SfxChannels:TMap = CreateMap()

	Function Create:TSimpleSoundSource()
		Return New TSimpleSoundSource
	End Function

	Method GetSfxChannelByName:TSfxChannel(name:String)
		Return TSfxChannel(MapValueForKey(SfxChannels, name))
	End Method

	'override default behaviour
	Method PlaySfxOrPlaylist(name:String, sfxSettings:TSfxSettings=Null, playlistMode:Int=False)
		TSoundManager.GetInstance().RegisterSoundSource(Self)

		'add channel if not done yet
		If Not TSfxChannel(SfxChannels.ValueForKey(name))
			SfxChannels.insert(name, TSfxChannel.Create())
		EndIf

		Local channel:TSfxChannel = GetChannelForSfx(name)
		'if channel getter fails, just return silently
		If Not channel Then Return

		Local settings:TSfxSettings = sfxSettings
		If settings = Null Then settings = GetSfxSettings(name)

		If playlistMode
			channel.PlayRandomSfx(name, settings)
		Else
			channel.PlaySfx(name, settings)
		EndIf

		'print GetClassIdentifier() + " # End PlaySfx: " + name
	End Method


	Method Stop(sfx:String)
		Local channel:TSfxChannel = GetChannelForSfx(sfx)
		If channel Then channel.Stop()
	End Method


	Method GetSfxSettings:TSfxSettings(sfx:String)
		Local settings:TSfxSettings = TSfxSettings.Create()
		settings.defaultVolume = 1.50
		Return settings
	End Method


	Method GetIsHearable:Int()
		Return True
	End Method

	Method GetChannelForSfx:TSfxChannel(sfx:String)
		Return GetSfxChannelByName(sfx)
	End Method

	Method GetClassIdentifier:String()
		Return "SimpleSfx"
	End Method

	Method GetCenter:TVec3D()
		'print "DoorCenter: " + Room.Pos.x + "/" + Room.Pos.y + " => " + (Room.Pos.x + Room.doorwidth/2) + "/" + (Building.GetFloorY2(Room.Pos.y) - Room.doorheight/2) + "    GetFloorY: " + TBuilding.GetFloorY2(Room.Pos.y) + " ... GetFloor: " + Building.GetFloor(Room.Pos.y)
		Return New TVec3D.Init(GetGraphicsManager().GetWidth()/2, GetGraphicsManager().GetHeight()/2)
	End Method

	Method IsMovable:Int()
		Return False
	End Method

	Method OnPlaySfx:Int(sfx:String)
		Return True
	End Method

End Type