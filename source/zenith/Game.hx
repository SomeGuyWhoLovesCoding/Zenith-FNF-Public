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
		FlxG.fixedTimestep = FlxG.mouse.visible = false; // Get rid of flixel's mouse as the transition goes over it

		trace('Game initialized.');
	}

	private var prevTime:Float = 0;
	public static var musicDeltaTarget:FlxSound;

	override public function updateElapsed():Void
	{
		if (musicDeltaTarget != null)
			FlxG.elapsed = (musicDeltaTarget.time - (prevTime = musicDeltaTarget.time)) * (FlxG.timeScale * 0.001);\
		else
			super.updateElapsed();
	}
}