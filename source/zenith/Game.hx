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

		super(0, 0, initState, Std.int(Application.current.window.frameRate), Std.int(Application.current.window.frameRate), true);
		FlxG.mouse.visible = false; // Get rid of flixel's mouse as the transition goes over it

		trace('Game initialized.');
	}

	override public function onEnterFrame(_:openfl.events.Event):Void
	{
		Main.updateMain(FlxG.elapsed);
		super.onEnterFrame(_);
	}
}