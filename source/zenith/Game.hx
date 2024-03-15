package zenith;

import openfl.display.Sprite;
import lime.app.Application; // Wow

class Game extends FlxGame
{
	var initState(default, null):Class<FlxState> = Gameplay;

	public function new():Void
	{
		SaveData.reloadSave();
		FlxG.mouse.visible = false; // Get rid of flixel's mouse as the transition goes over it

		super(0, 0, initState, Std.int(Application.current.window.frameRate), Std.int(Application.current.window.frameRate), true);

		trace('Game initialized.');
	}
}