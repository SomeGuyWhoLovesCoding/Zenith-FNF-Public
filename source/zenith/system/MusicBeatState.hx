package zenith.system;

import openfl.Lib;
import lime.ui.KeyCode;
import lime.app.Application;
import flixel.input.keyboard.FlxKey;

class MusicBeatState extends FlxState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

	public var keyEmitter:Emitter;
	override function create():Void
	{
		Main.startTransition(false);

		keyEmitter = new Emitter();

		Application.current.window.onKeyDown.add((keyCode:UInt, keyMod:UInt) -> {keyEmitter.emit(SignalEvent.KEY_DOWN, keyCode);});
		Application.current.window.onKeyUp.add((keyCode:UInt, keyMod:UInt) -> {keyEmitter.emit(SignalEvent.KEY_UP, keyCode);});

		super.create();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		final oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if (curStep > 0)
				stepHit();

			if (null != Gameplay.SONG)
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
		Application.current.window.onKeyDown.remove((keyCode:UInt, keyMod:UInt) -> {keyEmitter.emit(SignalEvent.KEY_DOWN, keyCode);});
		Application.current.window.onKeyUp.remove((keyCode:UInt, keyMod:UInt) -> {keyEmitter.emit(SignalEvent.KEY_UP, keyCode);});
		super.destroy();
	}

	// State stuff

	public function switchState(nextState:FlxState)
	{
		Application.current.window.onKeyDown.remove((keyCode:UInt, keyMod:UInt) -> {keyEmitter.emit(SignalEvent.KEY_DOWN, keyCode);});
		Application.current.window.onKeyUp.remove((keyCode:UInt, keyMod:UInt) -> {keyEmitter.emit(SignalEvent.KEY_UP, keyCode);});

		Main.startTransition(true, function()
		{
			FlxG.switchState(nextState);
		});
	}

	public function resetState()
	{
		Application.current.window.onKeyDown.remove((keyCode:UInt, keyMod:UInt) -> {keyEmitter.emit(SignalEvent.KEY_DOWN, keyCode);});
		Application.current.window.onKeyUp.remove((keyCode:UInt, keyMod:UInt) -> {keyEmitter.emit(SignalEvent.KEY_UP, keyCode);});

		Main.startTransition(true, FlxG.resetState);
	}

	// Beat stuff

	private function updateSection():Void
	{
		if (stepsToDo < 1)
			stepsToDo = inline Math.round(inline getBeatsOnSection() * 4);

		while (curStep >= stepsToDo)
		{
			stepsToDo += inline Math.round(inline getBeatsOnSection() * 4);
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
			if (null != Gameplay.SONG.notes[i])
			{
				stepsToDo += inline Math.round(inline getBeatsOnSection() * 4);
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
		curBeat = inline Std.int(curStep * 0.25);
		curDecBeat = curDecStep * 0.25;
	}

	private function updateCurStep():Void
	{
		var lastChange:Conductor.BPMChangeEvent = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = (Conductor.songPosition - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + inline Std.int(shit);
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

	inline function getBeatsOnSection()
	{
		var val:Null<Float> = 4;

		if (null != Gameplay.SONG && null != Gameplay.SONG.notes[curSection])
			val = Gameplay.SONG.notes[curSection].sectionBeats;

		return null == val ? 4 : val;
	}
}