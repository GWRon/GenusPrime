Rem
	====================================================================
	Game specific implementation/configuration of the generic
	TToastMessage.
	====================================================================
End Rem

SuperStrict

Import "Dig/base.framework.toastmessage.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"



Type TGameToastMessage extends TToastMessage
	Field backgroundSprite:TSprite
	Field messageType:int = 0
	Field caption:string = ""
	Field text:string = ""
	Field clickText:string = ""
	Field textColor:TColor
	Field captionColor:TColor
	Field textFont:TBitmapFont
	Field captionFont:TBitmapFont

	'the higher the more important the message is
	Field priority:int = 0
	Field showBackgroundSprite:int = True
	'an array containing registered event listeners
	Field _registeredEventListener:TLink[]


	Method New()
		textColor = TColor.clWhite.Copy()
		captionColor = TColor.clWhite.Copy()
	End Method


	Method GetCaptionFont:TBitmapFont()
		if captionFont then return captionFont
		return GetBitmapFontManager().baseFontBold
	End Method

	Method GetTextFont:TBitmapFont()
		if textFont then return textFont
		return GetBitmapFontManager().baseFont
	End Method

	Method GetClickTextFont:TBitmapFont()
		return GetBitmapFontManager().baseFontItalic
	End Method


	Method Remove:Int()
		For Local link:TLink = EachIn _registeredEventListener
			link.Remove()
		Next
		return Super.Remove()
	End Method


	Method SetMessageType:Int(messageType:int)
		self.messageType = messageType

		Select messageType
			case 0
				self.backgroundSprite = GetSpriteFromRegistry("toastmessage.normal")
			case 1
				self.backgroundSprite = GetSpriteFromRegistry("toastmessage.attention")
		EndSelect

		RecalculateHeight()
	End Method


	Method AddCloseOnEvent(eventKey:String)
		local listenerLink:TLink = EventManager.registerListenerMethod(eventKey, self, "onReceiveCloseEvent", self)
		_registeredEventListener :+ [listenerLink]
	End Method


	Method onReceiveCloseEvent(triggerEvent:TEventSimple)
		Close()
	End Method


	Method SetCaption:Int(caption:String, skipRecalculation:int=False)
		if self.caption = caption then return False

		self.caption = caption
		if not skipRecalculation then RecalculateHeight()
		return True
	End Method


	Method SetText:Int(text:String, skipRecalculation:int=False)
		if self.text = text then return False

		self.text = text
		if not skipRecalculation then RecalculateHeight()
		return True
	End Method


	Method SetClickText:Int(clickText:String, skipRecalculation:int=False)
		if self.clickText = clickText then return False

		self.clickText = clickText
		if not skipRecalculation then RecalculateHeight()
		return True
	End Method


	'override to add height recalculation (as a bar is drawn then)
	Method SetLifeTime:Int(lifeTime:Float = -1)
		Super.SetLifeTime(lifeTime)

		if lifeTime > 0
			RecalculateHeight()
		endif
	End Method


	Method SetPriority:Int(priority:int=0)
		self.priority = priority
	End Method


	Method RecalculateHeight:Int()
		local height:int = 0
		'caption singleline
		height :+ GetCaptionFont().GetBlockDimension(caption, GetContentWidth(), -1).GetY()
		height :+ 2 'little offset
		'text
		'attention: subtract some pixels from width (to avoid texts fitting
		'because of rounding errors - but then when drawing they do not
		'fit)
		height :+ GetTextFont().GetBlockDimension(text, GetContentWidth(), -1).GetY()
		if clickText
			height :+ GetTextFont().GetBlockDimension(clickText, GetContentWidth(), -1).GetY()
		endif
		'gfx padding
		if showBackgroundSprite and backgroundSprite
			height :+ backgroundSprite.GetNinePatchContentBorder().GetTop()
			height :+ backgroundSprite.GetNinePatchContentBorder().GetBottom()
		endif
		'lifetime bar
		if _lifeTime > 0 then height :+ 5

		area.dimension.SetY(height)
	End Method


	Method GetContentWidth:int()
		if showBackgroundSprite and backgroundSprite
			return GetScreenWidth() - backgroundSprite.GetNinePatchContentBorder().GetLeft() - backgroundSprite.GetNinePatchContentBorder().GetRight()
		else
			return GetScreenWidth()
		endif
	End Method


	'override to draw our nice background
	Method RenderBackground:Int(xOffset:Float=0, yOffset:Float=0)
		if showBackgroundSprite
			'set type again to reload sprite
			if not backgroundSprite or backgroundSprite.name = "defaultsprite" then SetMessageType(messageType)
			if backgroundSprite then backgroundSprite.DrawArea(xOffset + GetScreenX(), yOffset + GetScreenY(), area.GetW(), area.GetH())
		endif
	End Method


	'override to draw our texts
	Method RenderForeground:Int(xOffset:Float=0, yOffset:Float=0)
		local contentX:int = xOffset + GetScreenX()
		local contentY:int = yOffset + GetScreenY()
		local contentX2:int = contentX + GetScreenWidth()
		local contentY2:int = contentY + GetScreenHeight()
		if showBackgroundSprite and backgroundSprite
			contentX :+ backgroundSprite.GetNinePatchContentBorder().GetLeft()
			contentY :+ backgroundSprite.GetNinePatchContentBorder().GetTop()
			contentX2 :- backgroundSprite.GetNinePatchContentBorder().GetRight()
			contentY2 :- backgroundSprite.GetNinePatchContentBorder().GetBottom()
		endif

		local captionH:int
		local textH:int
		'simple shadow
		captionH = GetCaptionFont().DrawBlock(caption, contentX+1, contentY +1, GetContentWidth(), -1, null, TColor.clBlack).GetY()
		captionH :+ 2
		GetCaptionFont().DrawBlock(caption, contentX+1, contentY, GetContentWidth(), -1, null, captionColor).GetY()

		'simple shadow
		GetTextFont().DrawBlock(text+clickText, contentX + 1, contentY + captionH +1, GetContentWidth() -2, -1, null, TColor.clBlack)
		GetTextFont().DrawBlock(text+clickText, contentX + 1, contentY + captionH, GetContentWidth() -2, -1, null, textColor)


		'lifetime bar
		if _lifeTime > 0
			local lifeTimeWidth:int = contentX2 - contentX
			local oldCol:TColor = new TColor.Get()
			lifeTimeWidth :* GetLifeTimeProgress()

			_lifeTimeBarColor.SetRGB()
			DrawRect(xOffset + GetScreenX() + _textOffset.GetIntX(), yOffset + GetScreenY() + area.GetH() - _lifeTimeBarBottomY, lifeTimeWidth, _lifeTimeBarHeight)
'			DrawRect(contentX, contentY2 - 5 + 2, lifeTimeWidth, 3)
			oldCol.SetRGBA()
		endif

	End Method
End Type
