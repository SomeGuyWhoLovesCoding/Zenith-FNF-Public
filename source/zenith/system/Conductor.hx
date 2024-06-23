package zenith.system;

class Conductor
{
	var _rawStep(get, default):Single = 0.0;

	// Not sure if I want to inline this because I think inling can sometimes hurt the bpm change timing but idk
	function get__rawStep():Single
	{
		return ((songPosition - offsetTime) / stepCrochet) + offsetStep;
	}

	var _stepPos(default, null):Single = 0.0;
	var _beatPos(default, null):Single = 0.0;
	var _measurePos(default, null):Single = 0.0;

	var _stepTracker(default, null):Single = 0.0;
	var _beatTracker(default, null):Single = 0.0;
	var _measureTracker(default, null):Single = 0.0;

	var offsetTime(default, null):Single = 0.0;
	var offsetStep(default, null):Single = 0.0;

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

	public function new(initialBpm:Single = 100.0):Void
	{
		bpm = initialBpm;
	}

	inline public function reset():Void
	{
		offsetStep = offsetTime = songPosition = 0.0;
		changeTimeSignature(4, 4);
	}

	public function changeTimeSignature(newSteps:Int = 4, newBeats:Int = 4):Void
	{
		crochet = stepCrochet * newSteps;
		steps = newSteps;
		beats = newBeats;
	}

	public var lastBpm(default, null):Single = 100.0;
	public var bpm(default, set):Single = 100.0;

	// Ensure that the bpm change executes at the right spot

	public function executeBpmChange(newBpm:Single, position:Single):Void
	{
		offsetStep += (position - offsetTime) / stepCrochet;
		offsetTime = position;
		bpm = newBpm;

		trace(offsetStep, offsetTime);
	}

	inline function set_bpm(value:Single):Single
	{
		lastBpm = bpm;
		bpm = value;

		stepCrochet = 15000.0 / bpm;
		crochet = stepCrochet * steps;

		return value;
	}

	public var songPosition(default, set):Single = 0.0;

	function set_songPosition(value:Single):Single
	{
		songPosition = value;

		_stepTracker = Math.ffloor(_rawStep);
		_beatTracker = Math.ffloor(_stepTracker / steps);
		_measureTracker = Math.ffloor(_beatTracker / beats);

		if (_stepPos != _stepTracker)
		{
			_stepPos = _stepTracker;

			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('onStepHit', _stepPos);
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
			Main.hscript.callFromAllScripts('onBeatHit', _beatPos);
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
			Main.hscript.callFromAllScripts('onMeasureHit', _measurePos);
			#end

			if (onMeasureHit != null)
			{
				onMeasureHit(_measurePos);
			}
		}

		return value;
	}

	public var crochet(default, null):Single;

	public var stepCrochet(default, null):Single;

	public var onStepHit:Single->Void;
	public var onBeatHit:Single->Void;
	public var onMeasureHit:Single->Void;
}
