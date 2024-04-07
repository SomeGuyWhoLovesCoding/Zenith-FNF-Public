package zenith;

import openfl.display.Sprite;
import lime.app.Application;

import sys.thread.Mutex;

class Game extends FlxGame
{
	private final initState:Class<FlxState> = Gameplay;

	public static var frameRate(default, null):Int;

	public var inputEnabled:Bool = true;

	public function new():Void
	{
		var fps:Int = inline Std.int(setFramerate(SaveData.contents.preferences.fps));
		super(0, 0, initState, fps, fps, true);
		FlxG.fixedTimestep = false; // Get rid of flixel's mouse as the transition goes over it
		FlxSprite.defaultAntialiasing = SaveData.contents.preferences.antialiasing;
		Application.current.window.onClose.add(SaveData.saveContent);

		mutex = new Mutex();

		trace('Game initialized.');
	}

	var mutex:Mutex;
	override public function onEnterFrame(_:openfl.events.Event):Void
	{
		mutex.acquire();
		super.onEnterFrame((_ : openfl.events.Event));
		Main.updateMain(FlxG.elapsed);
		mutex.release();
	}

	inline public function setFramerate(fps:Int):Float
		return frameRate = fps;
}