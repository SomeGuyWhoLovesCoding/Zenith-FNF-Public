package zenith.system;

class Conductor
{
	var _stepPos(default, null):Float = 0.0;
	var _beatPos(default, null):Float = 0.0;
	var _measurePos(default, null):Float = 0.0;

	var _stepTracker(default, null):Float = 0.0;
	var _beatTracker(default, null):Float = 0.0;
	var _measureTracker(default, null):Float = 0.0;

	var timeOffset(default, null):Float = 0.0;

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

	inline public function changeTimeSignature(newSteps:Int = 4, newBeats:Int = 4):Void
	{
		steps = newSteps;
		beats = newBeats;
	}

	public var lastBpm(default, null):Float = 100.0;
	public var bpm(default, set):Float = 100.0;

	function set_bpm(value:Float):Float
	{
		if (lastBpm != value)
		{
			lastBpm = bpm;
			//stepOffset = curStep * (lastBpm / value);
			bpm = value;

			crochet = 60000.0 / bpm;
			stepCrochet = crochet * 0.25;
		}

		return value;
	}

	public var songPosition(default, set):Float = 0.0;

	function set_songPosition(value:Float):Float
	{
		_stepTracker = Math.ffloor(rawMBTime(value) / stepCrochet);
		_beatTracker = Math.ffloor(rawMBTime(value) / crochet);
		_measureTracker = Math.ffloor(rawMBTime(value) / (crochet * beats));

		if (onStepHit != null && _stepPos != _stepTracker)
		{
			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCallFloat('onStepHit', _stepPos);
			#end
			onStepHit(_stepPos);
			_stepPos = _stepTracker;
		}

		if (onBeatHit != null && _beatPos != _beatTracker)
		{
			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCallFloat('onBeatHit', _beatPos);
			#end
			onBeatHit(_beatPos);
			_beatPos = _beatTracker;
		}

		if (onMeasureHit != null && _measurePos != _measureTracker)
		{
			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCallFloat('onMeasureHit', _measurePos);
			#end
			onMeasureHit(_measurePos);
			_measurePos = _measureTracker;
		}

		return songPosition = value;
	}

	// Just for organization
	inline function rawMBTime(pos:Float):Float
	{
		return pos + timeOffset;
	}

	public var crochet(default, null):Float;

	public var stepCrochet(default, null):Float;

	public var onStepHit:(Float)->(Void) = null;
	public var onBeatHit:(Float)->(Void) = null;
	public var onMeasureHit:(Float)->(Void) = null;
}