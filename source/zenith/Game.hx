package zenith;

class Game extends FlxGame
{
	private final initState:Class<flixel.FlxState> = Gameplay;

	public static var blockSoundKeys:Bool = false;

	// Keyboard events
	public static var onKeyDown:Emitter = new Emitter();
	public static var onKeyUp:Emitter = new Emitter();

	// Gamepad events
	public static var onGamepadAxisMove:Emitter = new Emitter();
	public static var onGamepadButtonDown:Emitter = new Emitter();
	public static var onGamepadButtonUp:Emitter = new Emitter();
	public static var onGamepadConnect:Emitter = new Emitter();
	public static var onGamepadDisconnect:Emitter = new Emitter();

	public static var frameRate(default, null):Int;

	public var inputEnabled:Bool = true;

	public function new():Void
	{
		var fps:Int = inline Std.int(setFramerate(SaveData.contents.preferences.fps));
		FlxSprite.defaultAntialiasing = SaveData.contents.preferences.antialiasing;

		super(0, 0, initState, fps, fps, true);
		FlxG.fixedTimestep = false; // Get rid of flixel's mouse as the transition goes over it

		lime.app.Application.current.window.onClose.add(SaveData.saveContent);

		delta = inline timeStamp();

		trace('Game initialized.');
	}

	override public function create(_:openfl.events.Event):Void
	{
		super.create((_ : openfl.events.Event));
	}

	override public function onEnterFrame(_:openfl.events.Event):Void
	{
		super.onEnterFrame((_ : openfl.events.Event));
		Main.updateMain(FlxG.elapsed);
	}

	private var delta:Float;
	override function updateElapsed():Void
	{
		var timestamp:Float = inline timeStamp();
		_elapsedMS = timestamp - delta;
		super.updateElapsed();
		delta = timestamp;
	}

	inline public function setFramerate(fps:Int):Float
		return frameRate = fps;

	function timeStamp():Float
	{
		#if cpp
		return untyped __global__.__time_stamp() * 1000.0;
		#elseif sys
		return Sys.time() * 1000.0;
		#else
		return FlxG.elapsed;
		#end
	}
}