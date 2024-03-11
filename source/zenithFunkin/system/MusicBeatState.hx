package zenithFunkin.system;

class MusicBeatState extends FlxState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

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

	// State stuff

	public static function switchState(nextState:MusicBeatState)
	{
		Main.startTransition(true, function()
		{
			FlxG.switchState(cast nextState);
		});
	}

	public static function resetState()
	{
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
		if (Gameplay.SONG != null && Gameplay.SONG.notes[curSection] != null)
			val = Gameplay.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}