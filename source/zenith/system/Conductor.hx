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

class Conductor
{
	public static var bpm:Float = 100.0;
	public static var crochet:Float = (60 / bpm) * 1000.0; // beats in milliseconds
	public static var stepCrochet:Float = crochet * 0.25; // steps in milliseconds
	public static var songPosition:Float = 0.0;

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public function new()
	{
	}

	public static function getCrotchetAtTime(time:Float):Float{
		final lastChange:BPMChangeEvent = getBPMFromSeconds(time);
		return lastChange.stepCrochet * 4.0;
	}

	public static function getBPMFromSeconds(time:Float):BPMChangeEvent{
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

	public static function getBPMFromStep(step:Float):BPMChangeEvent{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}

		for (i in 0...Conductor.bpmChangeMap.length)
			if (Conductor.bpmChangeMap[i].stepTime<=step)
				lastChange = Conductor.bpmChangeMap[i];

		return lastChange;
	}

	public static function beatToSeconds(beat:Float):Float{
		var step = beat * 4;
		var lastChange = getBPMFromStep(step);
		return lastChange.songTime + ((step - lastChange.stepTime) / (lastChange.bpm * 0.0166666666666667) * 0.25) * 1000; // TODO: make less shit and take BPM into account PROPERLY
	}

	public static function getStep(time:Float):Float{
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepTime + (time - lastChange.songTime) / lastChange.stepCrochet;
	}

	public static function getStepRounded(time:Float):Float{
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepTime + inline Math.floor(time - lastChange.songTime) / lastChange.stepCrochet;
	}

	public static function getBeat(time:Float):Float{
		return getStep(time) * 0.25;
	}

	public static function getBeatRounded(time:Float):Int{
		return inline Math.floor(inline getStepRounded(time) * 0.25);
	}

	public static function mapBPMChanges(song:SwagSong)
	{
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length)
		{
			if(song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					stepCrochet: calculateCrochet(curBPM) * 0.25
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = Math.round(getSectionBeats(song, i) * 4);
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
		trace("new BPM map BUDDY " + bpmChangeMap);
	}

	inline static function getSectionBeats(song:SwagSong, section:Int)
	{
		var val:Null<Float> = null;
		if(null != song.notes[section]) val = song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}

	inline public static function calculateCrochet(bpm:Float){
		return (60 / bpm) * 1000.0;
	}

	inline static public function changeBPM(newBpm:Float)
	{
		crochet = calculateCrochet(bpm = newBpm);
		stepCrochet = crochet * 0.25;
	}
}