package zenith.system;

class Conductor
{
	var _stepPos(default, null):Float = 0.0;
	var _beatPos(default, null):Float = 0.0;
	var _measurePos(default, null):Float = 0.0;

	var _stepTracker(default, null):Float = 0.0;
	var _beatTracker(default, null):Float = 0.0;
	var _measureTracker(default, null):Float = 0.0;

	var stepsToLose(default, null):Float = 0.0;
	var stepsToAdd(default, null):Float = 0.0;

	public var steps(default, set):Int = 4;

	function set_steps(value:Int):Int
	{
		return steps = value;
	}

	public var beats(default, set):Int = 4;

	function set_beats(value:Int):Int
	{
		return beats = value;
	}

	public function new(initialBpm:Float = 100.0):Void
	{
		bpm = initialBpm;
	}

	inline public function reset():Void
	{
		stepsToLose = songPosition = 0.0;
		changeTimeSignature(4, 4);
	}

	inline public function changeTimeSignature(newSteps:Int = 4, newBeats:Int = 4):Void
	{
		crochet = stepCrochet * newSteps;
		steps = newSteps;
		beats = newBeats;
	}

	public var lastBpm(default, null):Float = 100.0;
	public var bpm(default, set):Float = 100.0;

	// Ensure that the bpm change executes at the right spot

	inline public function executeBpmChange(newBpm:Float, position:Float):Void
	{
		stepsToAdd += (position - stepsToLose) / stepCrochet;
		stepsToLose = position;
		bpm = newBpm;
		
		trace(stepsToLose);
	}

	inline function set_bpm(value:Float):Float
	{
		if (lastBpm != value)
		{
			lastBpm = bpm;
			bpm = value;

			stepCrochet = 15000.0 / bpm;
			crochet = stepCrochet * steps;
		}

		return value;
	}

	public var songPosition(default, set):Float = 0.0;

	function set_songPosition(value:Float):Float
	{
		_stepTracker = Math.ffloor((value - stepsToLose) / stepCrochet) + (stepsToAdd * (lastBpm / bpm));
		_beatTracker = Math.ffloor(_stepTracker / steps);
		_measureTracker = Math.ffloor(_beatTracker / beats);

		if (_stepPos != _stepTracker)
		{
			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('onStepHit', _stepPos);
			#end
			if (onStepHit != null)
			{
				onStepHit(_stepPos);
			}
			_stepPos = _stepTracker;
		}

		if (_beatPos != _beatTracker)
		{
			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('onBeatHit', _beatPos);
			#end
			if (onBeatHit != null)
			{
				onBeatHit(_beatPos);
			}
			_beatPos = _beatTracker;
		}

		if (_measurePos != _measureTracker)
		{
			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('onMeasureHit', _measurePos);
			#end
			if (onMeasureHit != null)
			{
				onMeasureHit(_measurePos);
			}
			_measurePos = _measureTracker;
		}

		return songPosition = value;
	}

	public var crochet(default, null):Float;

	public var stepCrochet(default, null):Float;

	public var onStepHit:Float->Void;
	public var onBeatHit:Float->Void;
	public var onMeasureHit:Float->Void;
}