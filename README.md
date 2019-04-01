# GenusPrime

![title screen](https://user-images.githubusercontent.com/2625226/55310802-a9de7480-5461-11e9-9e81-5654aa3c895a.png)

Game for the syntaxbomb.com 8bit retro competition 2019.

Conquer space within the provided campaigns or play a skirmish or random game against some opponents. Upgrade your techtree to improve fertility on your planets, improve speed of your ships etc.

![map start screen](https://user-images.githubusercontent.com/2625226/55310809-acd96500-5461-11e9-8294-82c59c738c7a.png)

![ingame screen](https://user-images.githubusercontent.com/2625226/55310812-ae0a9200-5461-11e9-8ac1-a0284745606b.png)


# Technics
While the competition at syntaxbomb.com was called "8-BIT WARS" and the allowed systems were C64 and the likes there was no strict rule for resolution - just the palette was fixed.
So this game uses the C64 palette and a 320x20 resolution and no serious restrictions on the "8x8 blocks" colorwise (kind of IFLI, NUFLI or AFLI mode).
Also there is no sound emulation done - just a bunch of "retro sounds".

Compared to classic C64 games this game does not offer a gamepad/joystick control but a mouse one (there existed a more or less rarely used C64 mouse!). So this game was able to be easily done in a GUI centric way.

![skirmish mode](https://user-images.githubusercontent.com/2625226/55310804-aba83800-5461-11e9-8d0c-4c7295734739.png)


# Coding Style
Compared to my other projects this code in its current base is a bit of a "tightly coupled monster". Compared to other projects I tried to do a "prototype approach" so that means I wrote stuff into a big file just to make it work. No interfaces or "base classes" for the game specific parts.


# Campaigns and missions
They are written in XML files so it should be able to write your own (despite the game for now is not prepared to "scroll" through a multitude of campaigns as it was not needed yet for the competition itself). A scrolling list isn't that hard to implement (Dig framework ;-)) but without interest of others this is skipped for now. 
