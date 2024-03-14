package zenith;

import openfl.display.Sprite;
import lime.app.Application; // Wow
import flixel.tweens.FlxTween;

class Game extends FlxGame
{
	var initState(default, null):Class<FlxState> = TitleScreen;

	public function new():Void
	{
		super(0, 0, initState, Std.int(Application.current.window.frameRate), Std.int(Application.current.window.frameRate), true);

		trace('Game initialized.');
	}
}