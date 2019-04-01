SuperStrict
Import Brl.Map
Import "Dig/base.util.color.bmx"


Type TGameColorCollection
	Field basePalette:TGameColor[]
	Field extendedPalette:TGameColor[]
	'alternate this on each render
	global evenFrame:int = 0
	global alternatePalettes:int = True
	global _similarityAlgorithm:int = 0
	global _rgbLookupCache:TMap = CreateMap()
	global _rgbLookupCacheCount:int = 0
	Const SIMILAR_MODE_CIELAB:int = 0
	Const SIMILAR_MODE_EUCLIDEAN:int = 1


	Method New()
		'RGB
		rem
		basePalette :+ [New TGameColor.Create(  0,  0,  0)] '0
		basePalette :+ [New TGameColor.Create(255,255,255)] '1
		basePalette :+ [New TGameColor.Create(136,  0,  0)] '2
		basePalette :+ [New TGameColor.Create(170,255,238)]	'3
		basePalette :+ [New TGameColor.Create(204, 68,204)] '4  on some websites: (112,100,214)
		basePalette :+ [New TGameColor.Create(  0,204, 85)] '5  on some websites: ( 92,160, 53)
		basePalette :+ [New TGameColor.Create(  0,  0,170)] '6
		basePalette :+ [New TGameColor.Create(238,238,119)] '7
		basePalette :+ [New TGameColor.Create(221,136, 85)] '8
		basePalette :+ [New TGameColor.Create(102, 68,  0)] '9
		basePalette :+ [New TGameColor.Create(255,119,119)] '10
		basePalette :+ [New TGameColor.Create( 51, 51, 51)]
		basePalette :+ [New TGameColor.Create(119,119,119)]
		basePalette :+ [New TGameColor.Create(170,255,102)]
		basePalette :+ [New TGameColor.Create(  0,136,255)]
		basePalette :+ [New TGameColor.Create(187,187,187)]
		endrem

		'YUV base
		basePalette :+ [New TGameColor.Create(  0,  0,  0)] '0
		basePalette :+ [New TGameColor.Create(255,255,255)] '1
		basePalette :+ [New TGameColor.Create(146, 74, 64)] '2	<- 136,  0,  0
		basePalette :+ [New TGameColor.Create(132,197,204)]	'3  <- 170,255,238
		basePalette :+ [New TGameColor.Create(147, 87,182)] '4  <- 204, 68,204  on some websites: (112,100,214)
		basePalette :+ [New TGameColor.Create(114,177, 75)] '5  <-   0,204, 85  on some websites: ( 92,160, 53)
		basePalette :+ [New TGameColor.Create( 72, 58,170)] '6  <-   0,  0,170
		basePalette :+ [New TGameColor.Create(213,223,124)] '7  <- 238,238,119
		basePalette :+ [New TGameColor.Create(153,105, 45)] '8  <- 221,136, 85
		basePalette :+ [New TGameColor.Create(103, 82,  0)] '9  <- 102, 68,  0
		basePalette :+ [New TGameColor.Create(193,129,120)] '10 <- 255,119,119
		basePalette :+ [New TGameColor.Create( 96, 96, 96)] '   <-  51, 51, 51
		basePalette :+ [New TGameColor.Create(138,138,138)] '   <- 119,119,119
		basePalette :+ [New TGameColor.Create(179,236,145)] '   <- 170,255,102
		basePalette :+ [New TGameColor.Create(134,122,222)] '   <-   0,136,255
		basePalette :+ [New TGameColor.Create(179,179,179)] '   <- 187,187,187


		For local colorIndex1:int = 0 until basePalette.length
			For local colorIndex2:int = colorIndex1 until basePalette.length
				local gColor:TGameColor = new TGameColor
					gColor.baseColor1 = basePalette[colorIndex1]
				if colorIndex1 <> colorIndex2
					gColor.baseColor2 = basePalette[colorIndex2]
				endif
				gColor.ActivateColor(1)
				extendedPalette :+ [gColor]
				'print (extendedPalette.length-1)+":  "  + colorIndex1+","+colorIndex2 + "   " + gColor.GetBaseColor(1).ToRGBString(",") + " / " + gColor.GetBaseColor(2).ToRGBString(",") + " = " + gColor.GetEffectiveColor().ToRGBStrinG(",")
			Next
		Next

'		local test:TColor = new TColor.InitRGBA(102,130,133)
'		local similar:TGameColor = FindSimilar(test)
'		print similar.GetBaseColor(1).ToRGBString(",") + " / " + similar.GetBaseColor(2).ToRGBString(",") + " = " + similar.GetEffectiveColor().ToRGBStrinG(",")
	End Method


	Method _ClearRGBLookupCache()
		_rgbLookupCache.Clear()
		_rgbLookupCacheCount = 0
	End Method


	Method SetSimilarityAlgorithm:int(newMode:int)
		_similarityAlgorithm = newMode
		_ClearRGBLookupCache()
	End Method


	Method FindSimilar:TGameColor(rgbColor:TColor)
		return FindSimilarRGB(rgbColor.r, rgbColor.g, rgbColor.b, rgbColor)
	End Method

	'returns the most similar paletted color for a given rgb one
	Method FindSimilarRGB:TGameColor(r:int, g:int, b:int, rgbColor:TColor = null)
		local cacheKey:string = r+","+g+","+b 'rgbColor.ToRGBString(",")
		local result:TGameColor
		'check CACHE to avoid long calculations
		result = TGameColor(_rgbLookupCache.ValueForKey(cacheKey))

		if not result
			'find most similar color in the palettes

			'avoid calculating it over and over
			local rgbColorL:float, rgbColorA:float, rgbColorB:float
			if not rgbColor then rgbColor = new TColor.Create(r, g, b)
			rgbColor.ToLAB(rgbColorL, rgbColorA, rgbColorB)

			local lowestDelta:Float = -1

			'loop over all palette colors
			if _similarityAlgorithm = SIMILAR_MODE_CIELAB
				'prefer base palette
				for local gColor:TGameColor = EachIn basePalette
					local delta:Float = gColor.GetEffectiveColor().GetCIELABDelta_ByLAB(rgbColorL, rgbColorA, rgbColorB)
					if lowestDelta < 0 or delta < lowestDelta
						lowestDelta = delta
						result = gColor
						if lowestDelta = 0 then exit
					endif
				next

				if lowestDelta > 0
					for local gColor:TGameColor = EachIn extendedPalette
						local delta:Float = gColor.GetEffectiveColor().GetCIELABDelta_ByLAB(rgbColorL, rgbColorA, rgbColorB)
						if lowestDelta < 0 or delta < lowestDelta
							lowestDelta = delta
							result = gColor
							if lowestDelta = 0 then exit
						endif
					next
				endif
			elseif _similarityAlgorithm = SIMILAR_MODE_EUCLIDEAN
				for local gColor:TGameColor = EachIn basePalette
					local delta:Float = gColor.GetEffectiveColor().GetEuclideanDistance(rgbColor)

					if lowestDelta < 0 or delta < lowestDelta
						lowestDelta = delta
						result = gColor
						if lowestDelta = 0 then exit
					endif
				next
				if lowestDelta > 0
					for local gColor:TGameColor = EachIn extendedPalette
						local delta:Float = gColor.GetEffectiveColor().GetEuclideanDistance(rgbColor)

						if lowestDelta < 0 or delta < lowestDelta
							lowestDelta = delta
							result = gColor
							if lowestDelta = 0 then exit
						endif
					next
				endif
			endif

			if _rgbLookupCacheCount > 500 then _ClearRGBLookupCache()

			_rgbLookupCache.Insert(cacheKey, result)
			_rgbLookupCacheCount :+ 1
			'print "UNCACHED " + rgbColor.ToRGBString(",") + "  -   " + result.baseColor1.ToRGBString(",") +"/"+result.baseColor2.ToRGBString(",")  + " => " + result.GetEffectiveColor().ToRGBString(",") +" = " + lowestDelta
		'else
			'print "CACHED " + rgbColor.ToRGBString(",") + "  -   " + result.baseColor1.ToRGBString(",") +"/"+result.baseColor2.ToRGBString(",")  + " => " + result.GetEffectiveColor().ToRGBString(",")
		endif


		return result
	End Method


	'assigns new values to the given game color based on the given rgb color
	'-> "gameColor-reference" stays intact (no new variable created)
	Method MakeSimilar:int(gameColor:TGameColor, rgbColor:TColor)
		if not rgbColor then return False
		if not gameColor then gameColor = new TGameColor

		gameColor.CopyFrom( FindSimilar(rgbColor) )

		return True
	End Method


	'returns a paletted color for the given rgb color
	'-> new variable created
	Method CreateSimilar:TGameColor(rgbColor:TColor)
		if not rgbColor then return null

		local gColor:TGameColor = new TGameColor
		MakeSimilar(gColor, rgbColor)

		return gColor
	End Method


	Method Update:int()
		evenFrame = 1 - evenFrame

		'inform our colors which base color they should use
		'for this render period
		local colorIndex:int = evenFrame + 1
		if not GameColorCollection.alternatePalettes then colorIndex = 0
		For local gColor:TGameColor = EachIn extendedPalette
			gColor.ActivateColor(colorIndex)
		Next
	End Method
End Type

Global GameColorCollection:TGameColorCollection = new TGameColorCollection




Type TGameColor extends TColor
	'base colors do not need to be of type "TGamecolor" as a mix of
	'two already "flickering" colors would lead to 4 colors alternating
	'which results in visible flickering
	Field baseColor1:TColor
	Field baseColor2:TColor
	'mix of both bases
	Field effectiveColor:TColor

	'override
	Function Create:TGameColor(r:int, g:int, b:int, a:Float=1.0)
		local col:TGameColor = new TGameColor
		col.InitRGBA(r, g, b, a)
		return col
	End Function


	'override
	Function CreateGrey:TGameColor(grey:int=0,a:float=1.0)
		local col:TGameColor = new TGameColor
		col.InitRGBA(grey, grey, grey, a)
		return col
	End Function


	'override
	Method Copy:TGameColor()
		local copyColor:TGameColor = new TGameColor
		copyColor.CopyFrom(self)
		if baseColor1 then copyColor.baseColor1 = baseColor1.Copy()
		if baseColor2 then copyColor.baseColor2 = baseColor2.Copy()
		if effectiveColor then copyColor.effectiveColor = effectiveColor.Copy()
		return copyColor
	End Method


	'override
	Method CopyFrom:TGameColor(color:TColor)
		if color
			self.r = color.r
			self.g = color.g
			self.b = color.b
			self.a = color.a
			if TGameColor(color)
				local gColor:TGameColor = TGameColor(color)
				if gcolor.baseColor1
					self.baseColor1 = gcolor.baseColor1.Copy()
				else
					self.baseColor1 = null
				endif
				if gcolor.baseColor2
					self.baseColor2 = gcolor.baseColor2.Copy()
				else
					self.baseColor2 = null
				endif
				if gcolor.effectiveColor
					self.effectiveColor = gcolor.effectiveColor.Copy()
				else
					self.effectiveColor = null
				endif
			endif
		endif
		return self
	End Method


	Method GetBaseColor:TColor(number:int)
		if number=1
			if not baseColor1 then return self
			return baseColor1
		elseif number=2
			if not baseColor2 then return self
			return baseColor2
		endif

		return self
	End Method


	Method GetEffectiveColor:TColor()
		'only one color defined
		if not baseColor1 or not baseColor2 then return self

		'cache result if not done yet
		if not effectiveColor
			effectiveColor = new TColor.InitRGBA(int(0.5*(baseColor1.r+baseColor2.r)), int(0.5*(baseColor1.g+baseColor2.g)), int(0.5*(baseColor1.b+baseColor2.b)), 1.0)
		endif
		return effectiveColor
	End Method


	Method ActivateColor(colorNumber:int)
		if not baseColor1 then return

		if colorNumber = 1 or not baseColor2
			r = baseColor1.r
			g = baseColor1.g
			b = baseColor1.b
			a = baseColor1.a
		elseif colorNumber = 2
			r = baseColor2.r
			g = baseColor2.g
			b = baseColor2.b
			a = baseColor2.a
		elseif colorNumber = 0
			local eff:TColor = GetEffectiveColor()
			r = eff.r
			g = eff.g
			b = eff.b
			a = eff.a
		endif
	End Method
End Type