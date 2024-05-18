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

	public static var instance:Game = null;

	public static var frameRate(default, null):Int;

	public function new():Void
	{
		var fps = Std.int(setFramerate(SaveData.contents.graphics.fps));

		FlxSprite.defaultAntialiasing = SaveData.contents.graphics.antialiasing;

		super(0, 0, initState, fps, fps, true);

		lime.app.Application.current.window.onClose.add(SaveData.saveContent);

		trace('Game initialized.');

		instance = this;
	}

	override public function onEnterFrame(_:openfl.events.Event):Void
	{
		super.onEnterFrame((_ : openfl.events.Event));
		Main.updateMain(FlxG.elapsed);
	}

	override function updateElapsed():Void
	{
		if (Main.VSYNC.ENABLED)
			FlxG.elapsed = 1.0 / frameRate;
		else
		{
			FlxG.elapsed = FlxG.timeScale * (_elapsedMS * 0.001); // variable timestep

			var max = FlxG.maxElapsed * FlxG.timeScale;
			if (FlxG.elapsed > max)
				FlxG.elapsed = max;
		}
	}

	inline public function setFramerate(fps:Int):Int
		return frameRate = fps;
}
