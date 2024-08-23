package zenith.system;

/**
 * The conductor class. The definitive conductor class similar to legacy base game's but cooler.
 */
@:publicFields
class Conductor
{
	private var _rawStep(get, default):Float = 0;

	inline private function get__rawStep():Float
	{
		return ((songPosition - offsetTime) / stepCrochet) + offsetStep;
	}

	private var _stepPos(default, null):Float = 0;
	private var _beatPos(default, null):Float = 0;
	private var _measurePos(default, null):Float = 0;

	private var _stepTracker(default, null):Float = 0;
	private var _beatTracker(default, null):Float = 0;
	private var _measureTracker(default, null):Float = 0;

	private var offsetTime(default, null):Float = 0;
	private var offsetStep(default, null):Float = 0;

	var steps(default, set):Int = 4;

	inline function set_steps(value:Int):Int
	{
		return steps = value;
	}

	var beats(default, set):Int = 4;

	inline function set_beats(value:Int):Int
	{
		return beats = value;
	}

	function new(initialBpm:Float = 100):Void
	{
		bpm = initialBpm;
	}

	inline function reset():Void
	{
		offsetStep = offsetTime = songPosition = 0.0;
		changeTimeSignature(4, 4);
	}

	inline function changeTimeSignature(newSteps:Int = 4, newBeats:Int = 4):Void
	{
		crochet = stepCrochet * newSteps;
		steps = newSteps;
		beats = newBeats;
	}

	var lastBpm(default, null):Float = 100;
	var bpm(default, set):Float = 100;

	// Ensure that the bpm change executes at the right spot

	inline function executeBpmChange(newBpm:Float, position:Float):Void
	{
		offsetStep += (position - offsetTime) / stepCrochet;
		offsetTime = position;
		bpm = newBpm;
	}

	inline function set_bpm(value:Float):Float
	{
		lastBpm = bpm;
		bpm = value;

		stepCrochet = 15000.0 / bpm;
		crochet = stepCrochet * steps;

		return value;
	}

	var songPosition(default, set):Float = 0;

	function set_songPosition(value:Float):Float
	{
		songPosition = value;

		_stepTracker = Math.ffloor(_rawStep);
		_beatTracker = Math.ffloor(_stepTracker / steps);
		_measureTracker = Math.ffloor(_beatTracker / beats);

		if (_stepPos != _stepTracker)
		{
			_stepPos = _stepTracker;

			#if SCRIPTING_ALLOWED
			callHScript('onStepHit', _stepPos);
			#end

			if (onStepHit != null)
			{
				onStepHit(_stepPos);
			}
		}

		if (_beatPos != _beatTracker)
		{
			_beatPos = _beatTracker;

			#if SCRIPTING_ALLOWED
			callHScript('onBeatHit', _beatPos);
			#end

			if (onBeatHit != null)
			{
				onBeatHit(_beatPos);
			}
		}

		if (_measurePos != _measureTracker)
		{
			_measurePos = _measureTracker;

			#if SCRIPTING_ALLOWED
			callHScript('onMeasureHit', _measurePos);
			#end

			if (onMeasureHit != null)
			{
				onMeasureHit(_measurePos);
			}
		}

		return value;
	}

	var crochet(default, null):Float;

	var stepCrochet(default, null):Float;

	var onStepHit:Float->Void;
	var onBeatHit:Float->Void;
	var onMeasureHit:Float->Void;
}
