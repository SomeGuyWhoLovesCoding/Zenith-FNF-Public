package zenith;

@:access(flixel.FlxG.elapsed)
class Game extends FlxGame
{
	final initState:Class<FlxState> = Gameplay;

	public var volume:Float = 1.0;
	public var muted:Bool = false;
	public var blockSoundKeys:Bool = false;

	// Keyboard events
	public var onKeyDown:Emitter = new Emitter();
	public var onKeyUp:Emitter = new Emitter();

	// Gamepad events
	public var onGamepadAxisMove:Emitter = new Emitter();
	public var onGamepadButtonDown:Emitter = new Emitter();
	public var onGamepadButtonUp:Emitter = new Emitter();
	public var onGamepadConnect:Emitter = new Emitter();
	public var onGamepadDisconnect:Emitter = new Emitter();

	public static var frameRate(default, null):Int;

	// The updateElapsed calls in the constructor are for extra frame accuracy btw
	public function new():Void
	{
		var fps = Std.int(setFramerate(SaveData.contents.graphics.fps));

		FlxSprite.defaultAntialiasing = SaveData.contents.graphics.antialiasing;

		super(0, 0, initState, fps, fps, true);

		lime.app.Application.current.window.onClose.add(SaveData.saveContent);

		trace('Game initialized.');
	}

	override function updateElapsed():Void
	{
		FlxG.elapsed = FlxG.timeScale * (_elapsedMS * 0.001); // variable timestep

		/*if (Main.VSYNC.ENABLED)
		{
			lime.app.Application.current.window.setVsync(FlxG.elapsed > 1.0 / frameRate || Main.VSYNC.ADAPTIVE);
		}*/

		Main.updateMain(FlxG.elapsed);
	}

	inline public function setFramerate(fps:Int):Int
		return frameRate = fps;
}
