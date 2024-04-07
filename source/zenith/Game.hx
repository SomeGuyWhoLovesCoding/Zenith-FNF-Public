package zenith;

import openfl.display.Sprite;
import lime.app.Application;

class Game extends FlxGame
{
	private final initState:Class<FlxState> = Gameplay;

	public static var frameRate(default, null):Int;

	public var inputEnabled:Bool = true;

	public function new():Void
	{
		var fps:Int = inline Std.int(setFramerate(SaveData.contents.preferences.fps));
		super(0, 0, initState, fps, fps, true);
		FlxG.fixedTimestep = FlxG.mouse.visible = false; // Get rid of flixel's mouse as the transition goes over it
		FlxSprite.defaultAntialiasing = SaveData.contents.preferences.antialiasing;
		Application.current.window.onClose.add(SaveData.saveContent);

		trace('Game initialized.');
	}

	override public function onEnterFrame(_:openfl.events.Event):Void
	{
		super.onEnterFrame((_ : openfl.events.Event));
		Main.updateMain(FlxG.elapsed);
	}

	inline public function setFramerate(fps:Int):Float
		return frameRate = fps;
}