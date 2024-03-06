package;

import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();

		var game = new FlxGame(0, 0, PlayState);
		@:privateAccess game._skipSplash = true;
		addChild(game);
	}
}
