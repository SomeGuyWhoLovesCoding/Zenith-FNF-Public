package zenith.system;

import openfl.Lib;
import lime.ui.KeyCode;
import flixel.input.keyboard.FlxKey;

class MusicBeatState extends FlxState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

	private static var limeToOfl:haxe.ds.IntMap<Int> = [
		KeyCode.A => FlxKey.A,
		KeyCode.B => FlxKey.B,
		KeyCode.C => FlxKey.C,
		KeyCode.D => FlxKey.D,
		KeyCode.E => FlxKey.E,
		KeyCode.F => FlxKey.F,
		KeyCode.G => FlxKey.G,
		KeyCode.H => FlxKey.H,
		KeyCode.I => FlxKey.I,
		KeyCode.J => FlxKey.J,
		KeyCode.K => FlxKey.K,
		KeyCode.L => FlxKey.L,
		KeyCode.M => FlxKey.M,
		KeyCode.N => FlxKey.N,
		KeyCode.O => FlxKey.O,
		KeyCode.P => FlxKey.P,
		KeyCode.Q => FlxKey.Q,
		KeyCode.R => FlxKey.R,
		KeyCode.S => FlxKey.S,
		KeyCode.T => FlxKey.T,
		KeyCode.U => FlxKey.U,
		KeyCode.V => FlxKey.V,
		KeyCode.W => FlxKey.W,
		KeyCode.X => FlxKey.X,
		KeyCode.Y => FlxKey.Y,
		KeyCode.Z => FlxKey.Z,
		KeyCode.BACKSLASH => FlxKey.BACKSLASH,
		KeyCode.BACKSPACE => FlxKey.BACKSPACE,
		KeyCode.PERIOD => FlxKey.PERIOD,
		KeyCode.COMMA => FlxKey.COMMA,
		KeyCode.PERIOD => FlxKey.PERIOD,
		KeyCode.ASTERISK => 189 /* Asterisk */,
		KeyCode.SLASH => FlxKey.SLASH,
		KeyCode.SPACE => FlxKey.SPACE,
		KeyCode.INSERT => FlxKey.INSERT,
		KeyCode.HOME => FlxKey.HOME,
		KeyCode.PRINT_SCREEN => FlxKey.PRINTSCREEN,
		KeyCode.LEFT_BRACKET => FlxKey.LBRACKET,
		KeyCode.RIGHT_BRACKET => FlxKey.RBRACKET,
		KeyCode.LEFT_CTRL => FlxKey.CONTROL,
		KeyCode.RIGHT_CTRL => FlxKey.CONTROL,
		KeyCode.LEFT_SHIFT => FlxKey.SHIFT,
		KeyCode.RIGHT_SHIFT => FlxKey.SHIFT,
		KeyCode.LEFT => FlxKey.LEFT,
		KeyCode.DOWN => FlxKey.DOWN,
		KeyCode.UP => FlxKey.UP,
		KeyCode.RIGHT => FlxKey.RIGHT,
		KeyCode.RETURN => FlxKey.ENTER
	];

	public var keyEmitter:Emitter;
	override function create():Void
	{
		Main.startTransition(false);

		keyEmitter = new Emitter();

		lime.app.Application.current.window.onKeyDown.add((keyCode:UInt, keyMod:UInt) -> {inline keyEmitter.emit(SignalEvent.KEY_DOWN, limeToOfl.get(keyCode));});
		lime.app.Application.current.window.onKeyUp.add((keyCode:UInt, keyMod:UInt) -> {inline keyEmitter.emit(SignalEvent.KEY_UP, limeToOfl.get(keyCode));});

		super.create();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if (curStep > 0)
				stepHit();

			if (Gameplay.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}
	}

	override function destroy():Void
	{
		lime.app.Application.current.window.onKeyDown.remove((keyCode:UInt, keyMod:UInt) -> {inline keyEmitter.emit(SignalEvent.KEY_DOWN, limeToOfl.get(keyCode));});
		lime.app.Application.current.window.onKeyUp.remove((keyCode:UInt, keyMod:UInt) -> {inline keyEmitter.emit(SignalEvent.KEY_UP, limeToOfl.get(keyCode));});
		super.destroy();
	}

	// State stuff

	public function switchState(nextState:FlxState)
	{
		lime.app.Application.current.window.onKeyDown.remove((keyCode:UInt, keyMod:UInt) -> {inline keyEmitter.emit(SignalEvent.KEY_DOWN, limeToOfl.get(keyCode));});
		lime.app.Application.current.window.onKeyUp.remove((keyCode:UInt, keyMod:UInt) -> {inline keyEmitter.emit(SignalEvent.KEY_UP, limeToOfl.get(keyCode));});

		Main.startTransition(true, function()
		{
			FlxG.switchState(nextState);
		});
	}

	public function resetState()
	{
		lime.app.Application.current.window.onKeyDown.remove((keyCode:UInt, keyMod:UInt) -> {inline keyEmitter.emit(SignalEvent.KEY_DOWN, limeToOfl.get(keyCode));});
		lime.app.Application.current.window.onKeyUp.remove((keyCode:UInt, keyMod:UInt) -> {inline keyEmitter.emit(SignalEvent.KEY_UP, limeToOfl.get(keyCode));});

		Main.startTransition(true, function()
		{
			FlxG.resetState();
		});
	}

	// Beat stuff

	private function updateSection():Void
	{
		if (stepsToDo < 1)
			stepsToDo = Math.round(getBeatsOnSection() * 4);

		while (curStep >= stepsToDo)
		{
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			curSection++;
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if (curStep < 0)
			return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...Gameplay.SONG.notes.length)
		{
			if (Gameplay.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep)
					break;

				curSection++;
			}
		}

		if (curSection > lastSection)
			sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Std.int(curStep * 0.25);
		curDecBeat = curDecStep * 0.25;
	}

	private function updateCurStep():Void
	{
		var lastChange:Conductor.BPMChangeEvent = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = (Conductor.songPosition - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Std.int(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// trace('Beat: ' + curBeat);
	}

	public function sectionHit():Void
	{
		// trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;

		if (null != Gameplay.SONG && null != Gameplay.SONG.notes[curSection])
			val = Gameplay.SONG.notes[curSection].sectionBeats;

		return val == null ? 4 : val;
	}
}