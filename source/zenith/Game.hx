package zenith;

class Game extends FlxGame
{
	final initState:Class<FlxState> = Gameplay;
	public var blockSoundKeys:Bool = false;

	// Input events
	public var onKeyDown:FlxTypedSignal<(Int, Int)->Void> = new FlxTypedSignal<(Int, Int)->Void>();
	public var onKeyUp:FlxTypedSignal<(Int, Int)->Void> = new FlxTypedSignal<(Int, Int)->Void>();
	public var onMouseDown:FlxTypedSignal<(Float, Float, Int)->Void> = new FlxTypedSignal<(Float, Float, Int)->Void>();
	public var onMouseUp:FlxTypedSignal<(Float, Float, Int)->Void> = new FlxTypedSignal<(Float, Float, Int)->Void>();

	public static var frameRate(default, null):Int;

	public function new():Void
	{
		trace('Game initialized.');
		FlxSprite.defaultAntialiasing = SaveData.contents.graphics.antialiasing;
		var fps = Std.int(setFramerate(SaveData.contents.graphics.fps));
		super(0, 0, initState, fps, fps, true);
		lime.app.Application.current.window.onClose.add(SaveData.write);
	}

	override public function onEnterFrame(_:openfl.events.Event):Void
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('updatePre', FlxG.elapsed);
		#end
		FlxG.fixedTimestep = false;
		super.onEnterFrame((_ : openfl.events.Event));
		Main.updateMain(FlxG.elapsed);
	}

	inline public function setFramerate(fps:Int):Int
	{
		return frameRate = fps;
	}
}
