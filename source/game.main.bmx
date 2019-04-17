SuperStrict
Import "Dig/base.framework.graphicalapp.bmx"
Import "Dig/base.gfx.sprite.bmx"
Import "Dig/base.gfx.gui.bmx"
Import "Dig/base.sfx.soundmanager.bmx"
'Import "Dig/base.framework.toastmessage.bmx"
Import "game.assets.bmx"
Import "game.gameconfig.bmx"
Import "game.toastmessage.bmx"



Type TMyApp Extends TGraphicalApp
	Field designedW:Int = 320
	Field designedH:Int = 200
	Field windowW:Int = 640
	Field windowH:Int = 400
	Field _customPrepareFunction:Int()
	Field _customStartFunction:Int()
	Field _customUpdateFunction:Int()
	Field _customRenderFunction:Int()

	Method Prepare:Int()
		ApplyAppArguments()

		'load game configuration
		GameConfig.LoadFromFile("config/settings.xml")


		Local gm:TGraphicsManager = GetGraphicsManager()
		gm.SetDesignedResolution(designedW, designedH)
		ApplyConfig()
		ApplySoundSettings()


		Super.Prepare()

		'try to center the window, for now only Windows
'		GetGraphicsManager().CenterDisplay()
		'init loop
		GetDeltatimer().Init(30, -1, 60)

		'load assets
		GetAssets()

		'we use a full screen background - so no cls needed
		autoCls = False

		If _customPrepareFunction Then _customPrepareFunction()
	End Method


	Method ApplySoundSettings()
		if GameConfig.soundEngine.ToLower() = "none"
			TSoundManager.audioEngineEnabled = False
			GetSoundManager()
			TSoundManager.audioEngineEnabled = True
			GetSoundManager().MuteMusic(true)
			GetSoundManager().MuteSfx(true)
			TSoundManager.audioEngineEnabled = False
		Else
			GetSoundManager().ApplyConfig( GameConfig.soundEngine, 0.01*GameConfig.volumeMusic, 0.01*GameConfig.volumeSfx)
		EndIf
	End Method


	Method ApplyConfig()
		If GameConfig.fullscreen Then GetGraphicsManager().SetFullscreen(True)
		If GameConfig.screenWidth > 0
			resolutionX = GameConfig.screenWidth
		Else
			resolutionX = windowW
		EndIf

		If GameConfig.screenHeight > 0
			resolutionY = GameConfig.screenHeight
		Else
			resolutionY = windowH
		EndIf
	End Method


	Method ApplyAppArguments:Int()
		Local argNumber:Int = 0
		For Local arg:String = EachIn AppArgs
			'only interested in args starting with "-"
			If arg.Find("-") <> 0 Then Continue

			Select arg.ToLower()
				?Win32
				Case "-directx7", "-directx"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: DirectX 7", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_DIRECTX7)
					GameConfig.renderer = GetGraphicsManager().RENDERER_DIRECTX7
				Case "-directx9"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: DirectX 9", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_DIRECTX9)
					GameConfig.renderer = GetGraphicsManager().RENDERER_DIRECTX9
				Case "-directx11"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: DirectX 11", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_DIRECTX11)
					GameConfig.renderer = GetGraphicsManager().RENDERER_DIRECTX11
				?
				Case "-opengl"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: OpenGL", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_OPENGL)
					GameConfig.renderer = GetGraphicsManager().RENDERER_OPENGL
				Case "-bufferedopengl"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: Buffered OpenGL", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_BUFFEREDOPENGL)
					GameConfig.renderer = GetGraphicsManager().RENDERER_BUFFEREDOPENGL
			End Select
		Next
	End Method


	'override
	Function __UpdateInput:Int()
		'needs modified "brl.mod/polledinput.mod" (disabling autopoll)
		SetAutoPoll(False)
		KEYMANAGER.Update()
		MOUSEMANAGER.Update()
		SetAutoPoll(True)
	End Function



	Method Update:Int()
'		Keymanager.Update()
'		Mousemanager.Update()
		'fetch and cache mouse and keyboard states for this cycle
		GUIManager.StartUpdates()

		GetToastMessageCollection().Update()

		GetSoundManager().Update()

		'GetSoundManager().Update()

		'run parental update (screen handling)
		Super.Update()


		If KeyManager.IsHit(KEY_TAB)
			debugLevel = 1 - debugLevel
		EndIf


		If KeyManager.IsHit(KEY_C)
			If GameColorCollection.alternatePalettes
				Print "disable paletted image alternation"
				GameColorCollection.alternatePalettes = False
			Else
				Print "enable paletted image alternation"
				GameColorCollection.alternatePalettes = True
			EndIf
		EndIf

		If _customUpdateFunction Then _customUpdateFunction()

		GUIManager.EndUpdates()
	End Method


	Method Render:Int()
		GameColorCollection.Update()

		Super.Render()

		If KeyHit(KEY_F12) Then SaveScreenshot()
	End Method


	Method RenderContent:Int()
		Super.RenderContent()
		'custom render content
		If _customRenderFunction Then _customRenderFunction()
	End Method


	Method RenderDebug:Int()
		SetColor 255,255,255
		DrawText("FPS: " + GetDeltaTimer().currentFps, 5, 16)
		DrawText("UPS: " + GetDeltaTimer().currentUps, 5, 22)
		DrawText("L: " + GetDeltaTimer().HasLimitedFPS(), 5, 28)
	End Method

	Method RenderHUD:Int()
		Super.RenderHUD()

		GetToastMessageCollection().Render(0,0)

		'=== DRAW MOUSE CURSOR ===
		'...
		GameColorCollection.extendedPalette[135].SetRGB()
		DrawRect(MouseManager.x, MouseManager.y - 4, 1, 2)
		DrawRect(MouseManager.x, MouseManager.y + 3, 1, 2)
		DrawRect(MouseManager.x - 4, MouseManager.y, 2, 1)
		DrawRect(MouseManager.x + 3, MouseManager.y, 2, 1)
		GameColorCollection.basePalette[1].SetRGB()
		DrawRect(MouseManager.x-1, MouseManager.y-1, 3, 3)
		GameColorCollection.extendedPalette[31].SetRGB()
		DrawRect(MouseManager.x, MouseManager.y, 1, 1)
	End Method

	'override
	Method ShutDown:Int()
		Print "Storing configuration"
		GameConfig.SaveToFile("config/settings.xml")
	End Method


	Method SaveScreenshot(overlay:TSprite = Null)
		Local filename:String, padded:String
		Local num:Int = 1

		filename = "screenshot_001.png"

		While FileType(filename) <> 0
			num:+1

			padded = num
			While padded.length < 3
				padded = "0"+padded
			Wend
			filename = "screenshot_"+padded+".png"
		Wend

		Local img:TPixmap = VirtualGrabPixmap(0, 0, VirtualWidth(), VirtualHeight())

		'remove alpha
		SavePixmapPNG(ConvertPixmap(img, PF_RGB888), filename)

		TLogger.Log("App.SaveScreenshot", "Screenshot saved as ~q"+filename+"~q", LOG_INFO)
	End Method
End Type





'growing/shrinking rectangles hiding an area
Type TScreenFaderRectGrid Extends TScreenFader
	Field gridOrder:Int[]

	Method GetGridOrder:Int[](length:Int)
		If Not gridOrder Or gridOrder.length < length
			gridOrder = New Int[length]
			For Local i:Int = 0 Until length
				gridOrder[i] = i
			Next

			Local shuffleIndex:Int
			Local shuffleTmp:Int
			For Local i:Int = gridOrder.length-1 To 0 Step -1
				'visual - so no mersenne PRNG!
				shuffleIndex = Rand(0, gridOrder.length-1)
				shuffleTmp = gridOrder[i]
				gridOrder[i] = gridOrder[shuffleIndex]
				gridOrder[shuffleIndex] = shuffleTmp
			Next
		EndIf

		Return gridOrder
	End Method


	Method Render:Int()
		Local relativeProgress:Float
		If fadeOut
			relativeProgress = GetProgress()
		Else
			relativeProgress = 1 - GetProgress()
		EndIf

		'we want to stay "black" a bit of time
		If fadeOut Then relativeProgress = MathHelper.Clamp(relativeProgress*1.25, 0, 1.0)
'		if not fadeOut then relativeProgress = MathHelper.Clamp(relativeProgress/1.25, 0, 1.0)


		Local cellSize:Int = 8

		Local col:TColor = New TColor.Get()
		SetColor 0,0,0

		Local cols:Int = Int(GetArea().GetW() / cellSize +0.5) '+0.5 = ceil
		Local rows:Int = Int(GetArea().GetH() / cellSize +0.5)
		Local rectCount:Int = relativeProgress * cols * rows + 0.5
		Local order:Int[] = GetGridOrder(cols*rows)
'print cols +" * " + rows + " = " + rectCount +"   progress="+relativeProgress +"  timeGone="+timeGone
		For Local i:Int = 0 Until rectCount
'			print order[i]
			Local c:Int = order[i] Mod cols
			Local r:Int = order[i] / cols
			DrawRect(c * cellSize, r * cellSize, cellSize, cellSize)
		Next
'end
		col.SetRGBA()
	End Method
End Type