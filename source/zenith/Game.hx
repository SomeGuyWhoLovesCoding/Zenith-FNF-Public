package zenith;

class Game extends FlxGame
{
	private final initState:Class<FlxState> = Gameplay;

	public static var volume:Float = 1.0;
	public static var muted:Bool = false;
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

	public function new():Void
	{
		var fps:Int = Std.int(setFramerate(SaveData.contents.preferences.fps));

		FlxSprite.defaultAntialiasing = SaveData.contents.preferences.antialiasing;

		super(0, 0, initState, fps, fps, true);

		lime.app.Application.current.window.frameRate = fps / 1.041666666666667;
		lime.app.Application.current.window.onClose.add(SaveData.saveContent);

		trace('Game initialized.');
	}

	override public function create(_:openfl.events.Event):Void
	{
		super.create((_ : openfl.events.Event));
	}

	override public function onEnterFrame(_:openfl.events.Event):Void
	{
		FlxG.fixedTimestep = false;
		super.onEnterFrame((_ : openfl.events.Event));
		Main.updateMain(FlxG.elapsed);
	}

	inline public function setFramerate(fps:Int):Float
		return frameRate = fps;
}
