package zenith;

import openfl.display.Sprite;
import lime.app.Application;

@:access(flixel.FlxG.elapsed) // Please don't remove this
class Game extends FlxGame
{
	var initState(default, null):Class<FlxState> = Gameplay;

	public var inputEnabled:Bool = true;

	public function new():Void
	{
		SaveData.reloadSave();

		super(0, 0, initState, inline Std.int(Application.current.window.frameRate), inline Std.int(Application.current.window.frameRate), true);
		FlxG.fixedTimestep = FlxG.mouse.visible = false; // Get rid of flixel's mouse as the transition goes over it

		trace('Game initialized.');
	}

	override public function onEnterFrame(_:openfl.events.Event):Void
	{
		super.onEnterFrame((_ : openfl.events.Event));

		FlxG.drawFramerate = FlxG.updateFramerate = inline Std.int(inline Math.min(SaveData.contents.preferences.fps, 1000.0));
		Main.updateMain(FlxG.elapsed);
	}
}