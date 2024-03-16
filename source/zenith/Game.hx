package zenith;

import openfl.display.Sprite;
import lime.app.Application; // Wow
import openfl.display3D.textures.Texture;

class Game extends FlxGame
{
	var initState(default, null):Class<FlxState> = TitleScreen;

	public function new():Void
	{
		SaveData.reloadSave();

		//@:privateAccess Texture.__lowMemoryMode = Paths.LowMemoryMode;

		super(0, 0, initState, Std.int(Application.current.window.frameRate), Std.int(Application.current.window.frameRate), true);
		FlxG.mouse.visible = false; // Get rid of flixel's mouse as the transition goes over it

		trace('Game initialized.');
	}
}