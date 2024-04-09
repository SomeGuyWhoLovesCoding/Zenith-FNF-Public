package zenith;

import sys.thread.Mutex;

@:allow(flixel.FlxG.elapsed) // Please don't remove this
class Game extends FlxGame
{
	private final initState:Class<flixel.FlxState> = Gameplay;

	public static var blockSoundKeys:Bool = false;

	// Keyboard events
	public static var onKeyDown:Emitter = new Emitter();
	public static var onKeyUp:Emitter = new Emitter();

	// Mouse events
	public static var onMouseDown:Emitter = new Emitter();
	public static var onMouseUp:Emitter = new Emitter();
	public static var onMouseMove:Emitter = new Emitter();
	public static var onMouseWheel:Emitter = new Emitter();

	// Gamepad events
	public static var onGamepadAxisMove:Emitter = new Emitter();
	public static var onGamepadButtonDown:Emitter = new Emitter();
	public static var onGamepadButtonUp:Emitter = new Emitter();
	public static var onGamepadConnect:Emitter = new Emitter();
	public static var onGamepadDisconnect:Emitter = new Emitter();

	public static var frameRate(default, null):Int;

	public var inputEnabled:Bool = true;

	private var __mutex:Mutex;
	public function new():Void
	{
		var fps:Int = inline Std.int(setFramerate(SaveData.contents.preferences.fps));
		super(0, 0, initState, fps, fps, true);
		FlxG.fixedTimestep = false; // Get rid of flixel's mouse as the transition goes over it
		FlxSprite.defaultAntialiasing = SaveData.contents.preferences.antialiasing;

		lime.app.Application.current.window.onClose.add(SaveData.saveContent);

		__mutex = new Mutex();

		delta = untyped __global__.__time_stamp() * 1000.0;

		trace('Game initialized.');
	}

	override public function create(_:openfl.events.Event):Void
	{
		super.create((_ : openfl.events.Event));
	}

	override public function onEnterFrame(_:openfl.events.Event):Void
	{
		__mutex.acquire();
		super.onEnterFrame((_ : openfl.events.Event));
		Main.updateMain(FlxG.elapsed);
		__mutex.release();
	}

	private var delta:Float;
	override function updateElapsed():Void
	{
		var timestamp:Float = untyped __global__.__time_stamp() * 1000.0;
		_elapsedMS = timestamp - delta;
		super.updateElapsed();
		delta = timestamp;
	}

	inline public function setFramerate(fps:Int):Float
		return frameRate = fps;
}