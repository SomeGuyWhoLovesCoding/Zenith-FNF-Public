package zenith.system;

class MusicBeatState extends State
{
	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0.0;
	private var curDecBeat:Float = 0.0;

	static public var instance:MusicBeatState;

	override function create():Void
	{
		instance = this;

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
		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCallInt('stepHit', curStep);
		#end
		// trace('Step: ' + curStep);
	}

	public function beatHit():Void
	{
		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCallInt('beatHit', curBeat);
		#end
		// trace('Beat: ' + curBeat);
	}
}
