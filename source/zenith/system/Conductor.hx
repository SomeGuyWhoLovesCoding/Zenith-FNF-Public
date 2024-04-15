package zenith.system;

import zenith.data.Song;

/**
 * ...
 * @author
 */

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	@:optional var stepCrochet:Float;
}

// WIP rework

class Conductor
{
	static public var bpm:Float = 100.0;
	static public var crochet:Float = (60.0 / bpm) * 1000.0; // beats in milliseconds
	static public var stepCrochet:Float = crochet * 0.25; // steps in milliseconds
	static public var songPosition:Float = 0.0;

	static public var bpmChangeMap:Array<BPMChangeEvent> = [];

	public function new()
	{
	}

	static public function mapBPMChanges(song:SwagSong):Void
	{
		bpmChangeMap = [];

		var curBPM:Float = song.info.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;

		for (i in 0...song.bpmChanges.length)
		{
			var newBpm:Float = song.bpmChanges[i][0]; // Avoid redundant array access
			if(newBpm != curBPM)
			{
				curBPM = newBpm;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					stepCrochet: calculateCrochet(curBPM) * 0.25
				};
				bpmChangeMap.push(event);
			}

			totalSteps += 4; // What am I supposed to do?
			totalPos += (60 / curBPM) * 250.0;
		}
		trace("new BPM map BUDDY " + bpmChangeMap);
	}

	static public function getBPMFromSeconds(time:Float):BPMChangeEvent
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}

		for (i in 0...Conductor.bpmChangeMap.length)
			if (time >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];

		return lastChange;
	}

	inline static public function calculateCrochet(bpm:Float)
		return (60 / bpm) * 1000.0; // Don't worry if colorization breaks with no brackets, it's just vsc

	inline static public function changeBPM(newBpm:Float)
	{
		crochet = calculateCrochet(bpm = newBpm);
		stepCrochet = crochet * 0.25;
	}
}