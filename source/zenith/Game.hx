package zenith;

/**
 * A FlxGame with flxsignals that work outside the gameplay state.
 * If you still want input signals, there's already hscript.
 */
@:publicFields
class Game extends FlxGame
{
	private var UPDATE_PRE = 'updatePre';

	private final initState:Class<FlxState> = Gameplay;

	var blockSoundKeys:Bool = false;

	// Input events
	var onKeyDown:FlxTypedSignal<(Int, Int) -> Void> = new FlxTypedSignal<(Int, Int) -> Void>();
	var onKeyUp:FlxTypedSignal<(Int, Int) -> Void> = new FlxTypedSignal<(Int, Int) -> Void>();
	var onMouseDown:FlxTypedSignal<(Float, Float, Int) -> Void> = new FlxTypedSignal<(Float, Float, Int) -> Void>();
	var onMouseUp:FlxTypedSignal<(Float, Float, Int) -> Void> = new FlxTypedSignal<(Float, Float, Int) -> Void>();

	static var frameRate(default, null):Int;

	function new():Void
	{
		trace('Game initialized.');
		FlxSprite.defaultAntialiasing = SaveData.contents.graphics.antialiasing;
		var fps = Std.int(setFramerate(SaveData.contents.graphics.fps));
		super(0, 0, initState, fps, fps, true);
		lime.app.Application.current.window.onClose.add(SaveData.write);
	}

	override function onEnterFrame(_:openfl.events.Event):Void
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts(UPDATE_PRE, FlxG.elapsed);
		#end
		FlxG.fixedTimestep = false;
		super.onEnterFrame((_ : openfl.events.Event));
		Main.updateMain(FlxG.elapsed);
	}

	inline function setFramerate(fps:Int):Int
	{
		return frameRate = fps;
	}
}
