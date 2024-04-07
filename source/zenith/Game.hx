package zenith;

import openfl.display.Sprite;
import lime.app.Application;

import sys.thread.Mutex;

@:allow(flixel.FlxG.elapsed) // Please don't remve this
class Game extends FlxGame
{
	private final initState:Class<FlxState> = Gameplay;

	public static var frameRate(default, null):Int;

	public var inputEnabled:Bool = true;

	var __mutex:Mutex;
	public function new():Void
	{
		var fps:Int = inline Std.int(setFramerate(SaveData.contents.preferences.fps));
		super(0, 0, initState, fps, fps, true);
		FlxG.fixedTimestep = false; // Get rid of flixel's mouse as the transition goes over it
		FlxSprite.defaultAntialiasing = SaveData.contents.preferences.antialiasing;
		Application.current.window.onClose.add(SaveData.saveContent);

		__mutex = new Mutex();

		trace('Game initialized.');
	}

	override public function onEnterFrame(_:openfl.events.Event):Void
	{
		__mutex.acquire();
		super.onEnterFrame((_ : openfl.events.Event));
		Main.updateMain(FlxG.elapsed);
		__mutex.release();
	}

	var delta:Float = 0;
	override function updateElapsed():Void
	{
		var timestamp:Float = untyped __global__.__time_stamp() * 1000.0;
		_elapsedMS = timestamp - delta;
		super.updateElapsed();
		delta = timestamp;
	}

	inline public function setFramerate(fps:Int):Float
		return frameRate = fps;
}