package zenith.system;

import openfl.Lib;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.app.Application;
import flixel.input.keyboard.FlxKey;

class MusicBeatState extends State
{
	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0.0;
	private var curDecBeat:Float = 0.0;

	override function create():Void
	{
		Main.startTransition(false);

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
			stepHit();
			if (curStep % 4 == 0)
				beatHit();
		}
	}

	// State stuff

	public function switchState(nextState:FlxState)
	{
		Main.startTransition(true, function()
		{
			FlxG.switchState(nextState);
		});
	}

	public function resetState()
	{
		Main.startTransition(true, FlxG.resetState);
	}

	// Beat stuff

	inline private function updateBeat():Void
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
		HScriptSystem.callFromAllScripts('stepHit', []);
		// trace('Step: ' + curStep);
	}

	public function beatHit():Void
	{
		HScriptSystem.callFromAllScripts('beatHit', []);
		// trace('Beat: ' + curBeat);
	}
}