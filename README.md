# GenusPrime

![title screen](https://user-images.githubusercontent.com/2625226/55310802-a9de7480-5461-11e9-9e81-5654aa3c895a.png)

Game for the syntaxbomb.com 8bit retro competition 2019.

Conquer space within the provided campaigns or play a skirmish or random game against some opponents. Upgrade your techtree to improve fertility on your planets, improve speed of your ships etc.

![map start screen](https://user-images.githubusercontent.com/2625226/55310809-acd96500-5461-11e9-8294-82c59c738c7a.png)

![ingame screen](https://user-images.githubusercontent.com/2625226/55310812-ae0a9200-5461-11e9-8ac1-a0284745606b.png)



# Technics
While the competition at syntaxbomb.com was called "8-BIT WARS" and the allowed systems were C64 and the likes there was no strict rule for resolution - just the palette was fixed.
So this game uses the C64 palette and a 320x200 resolution and no serious restrictions on the "8x8 blocks" colorwise (imagine kind of a mix between IFLI, NUFLI or AFLI mode).
Also there is no sound emulation done - just a bunch of "retro sounds" + nice music by Kevin McLeod and Eric Skiff.

Compared to classic C64 games this game does not offer a gamepad/joystick control but a mouse one (there existed a more or less rarely used C64 mouse!). So this game was able to be easily done in a GUI centric way.

![skirmish mode](https://user-images.githubusercontent.com/2625226/55310804-aba83800-5461-11e9-8d0c-4c7295734739.png)



# Coding Style
Compared to my other projects this code in its current base is a bit of a "tightly coupled monster". Compared to other projects I tried to do a "prototype approach" so that means I wrote stuff into a big file just to make it work. No interfaces or "base classes" for the game specific parts.



# Campaigns and missions
They are written in XML files so it should be able to write your own (despite the game for now is not prepared to "scroll" through a multitude of campaigns as it was not needed yet for the competition itself). A scrolling list isn't that hard to implement (Dig framework ;-)) but without interest of others this is skipped for now. 



# Build instructions
Either build with BlitzMax (legacy/vanilla) or with BlitzMax NG (https://blitzmax.org).
The game requires a module called "maxmod2.mod" which can be found:

Vanilla: sources/Dig/external/maxmod2_lite.mod.zip

NG: https://github.com/bmx-ng/maxmod2.mod



# Licence
================================================================

Copyright (c) 20019-now Ronny Otto

This software is provided 'as-is'. No warranty is given.
The authors cannot be held liable for any damages arising from
the use of this software.

Permission is granted to anyone to use this software for any
purpose, and to alter it and redistribute it freely, subject to
the following restrictions:

	1. Any commercial usage requires explicit permission from
	   the original authors.

	2. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product is required.

	3. Altered source or binary versions of this software must
	   be plainly marked as such, and must not be misrepresented
	   as being the original software.

	4. This notice may not be removed or altered from any source
	   distribution.

================================================================
