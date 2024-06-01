package zenith;

class Game extends FlxGame
{
	final initState:Class<FlxState> = Gameplay;

	public var volume:Float = 1.0;
	public var muted:Bool = false;
	public var blockSoundKeys:Bool = false;

	// Keyboard events
	public var onKeyDown:Emitter = new Emitter();
	public var onKeyUp:Emitter = new Emitter();

	public static var frameRate(default, null):Int;

	public function new():Void
	{
		FlxSprite.defaultAntialiasing = SaveData.contents.graphics.antialiasing;
		var fps = Std.int(setFramerate(SaveData.contents.graphics.fps));
		super(0, 0, initState, fps, fps, true);
		lime.app.Application.current.window.onClose.add(SaveData.writr);
		trace('Game initialized.');
	}

	override public function onEnterFrame(_:openfl.events.Event):Void
	{
		FlxG.fixedTimestep = false;
		super.onEnterFrame((_ : openfl.events.Event));
		Main.updateMain(FlxG.elapsed);
	}

	inline public function setFramerate(fps:Int):Int
	{
		return frameRate = fps;
	}
}
