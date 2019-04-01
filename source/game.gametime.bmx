SuperStrict
import "Dig/base.util.time.bmx"



Type GameTime Extends Time
	Global lastGameMillisecsUpdate:Long = -1
	Global gameMillisecs:Long
	Global speedFactor:Float = 1.0
	Global paused:int


	Function Reset:int()
		lastGameMillisecsUpdate = -1
		gameMillisecs = 0
		speedFactor = 1.0
		paused = False
	End Function


	Function Update:Int()
		If lastGameMillisecsUpdate = -1 Then lastGameMillisecsUpdate = GameTime.MilliSecs()

		Local timeGone:Long = Max(0, (MilliSecsLong() - lastGameMillisecsUpdate)) * speedFactor*(not paused)

		gameMillisecs :+ timeGone

		lastGameMillisecsUpdate = MilliSecsLong()
	End Function


	'returns the time gone since the first call to "GetTimeGone()"
	Function GetTimeGone:Long()
		return gameMillisecs
	End Function


	Function MilliSecs:Long()
		If lastGameMillisecsUpdate = -1 Then lastGameMillisecsUpdate = MilliSecsLong()

		Local timeGone:Long = Max(0,(Super.MilliSecsLong() - lastGameMillisecsUpdate)) * speedFactor*(not paused)

		Return lastGameMillisecsUpdate + timeGone
	End Function
End Type




Type TGameTimeIntervalTimer Extends TIntervalTimer
	Method Init:TGameTimeIntervalTimer(interval:Int, actionTime:Int = 0, randomnessMin:Int = 0, randomnessMax:Int = 0)
		Super.Init(interval, actionTime, randomnessMin, randomnessMax)
		Return Self
	End Method

	'override
	'use game timer instead (for slowdown, pause, ...
	Function _GetTimeGone:Long()
		Return GameTime.MilliSecs()
	End Function
End Type