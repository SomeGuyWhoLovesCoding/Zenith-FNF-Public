package zenith;

class Game extends FlxGame
{
	private final initState:Class<flixel.FlxState> = Gameplay;

	public static var volume:Float = 1.0;
	public static var muted:Bool = false;
	public static var blockSoundKeys:Bool = false;

	public static var onKeyDown:Emitter = new Emitter();
	public static var onKeyUp:Emitter = new Emitter();

	public static var onGamepadAxisMove:Emitter = new Emitter();
	public static var onGamepadButtonDown:Emitter = new Emitter();
	public static var onGamepadButtonUp:Emitter = new Emitter();
	public static var onGamepadConnect:Emitter = new Emitter();
	public static var onGamepadDisconnect:Emitter = new Emitter();

	public static var frameRate(default, null):Int;

	public var inputEnabled:Bool = true;

	public function new():Void
	{
		var fps:Int = Std.int(setFramerate(SaveData.contents.preferences.fps));
		FlxSprite.defaultAntialiasing = SaveData.contents.preferences.antialiasing;

		super(0, 0, initState, fps, fps, true);
		FlxG.fixedTimestep = false; // Get rid of flixel's mouse as the transition goes over it

		lime.app.Application.current.window.onClose.add(SaveData.saveContent);

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

	inline public function setFramerate(fps:Int):Float
		return frameRate = fps;
}
