package;

// Use ``ChartConverter %path2import% %path2save% --interp`` to compile this in order for it for work.

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

typedef PsychSwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	@:optional var offset:Null<Float>; // For the "Sync notes to beat" option
	@:optional var strumlines:UInt;
}

typedef SongInfo =
{
	var stage:String;
	var player1:String;
	var player2:String;
	var spectator:String;
	var speed:Float;
	var bpm:Float;
	var time_signature:Array<UInt>;
	var offset:Null<Float>;
	var needsVoices:Bool;
	@:optional var strumlines:UInt;
}

typedef SwagSong =
{
	song:Null<String>,
	info:SongInfo,
	noteData:Array<Array<UInt>>,
	bpmChanges:Array<Array<Float>>
}

class ChartConverter
{
	static function main():Void
	{
		Sys.println('Psych/Vanilla chart converter\nUsage: Argument 1 - Path to psych engine chart, Argument 2 - Path to save the converted chart');
		trace(Sys.args());
		trace(Sys.args()[0]);

		// Prevent crash from missing file
		if(!sys.FileSystem.exists(Sys.args()[0]))
			return;

		try
		{
			var songPosition:Float = 0.0;
			var currentBPM:Float = 0.0;

			var songImported:PsychSwagSong = haxe.Json.parse(sys.io.File.getContent(Sys.args()[0])).song;

			var result:SwagSong = {
				song: songImported.song,
				info: {
					stage: songImported.stage,
					player1: songImported.player1,
					player2: songImported.player2,
					spectator: songImported.gfVersion,
					speed: songImported.speed,
					bpm: currentBPM = songImported.bpm,
					time_signature: [4, 4],
					offset: songImported.offset,
					needsVoices: songImported.needsVoices,
					strumlines: null == songImported.strumlines ? 2 : songImported.strumlines
				},
				noteData: [],
				bpmChanges: []
			};

			for (i in 0...songImported.notes.length)
			{
				var section:SwagSection = songImported.notes[i];
				songPosition += (60000.0 / currentBPM) * getBeatsOnSection(songImported, i);

				if (section.changeBPM)
					result.bpmChanges.push([currentBPM, songPosition]);

				for (songNotes in section.sectionNotes)
					result.noteData.push([songNotes[0], songNotes[1], songNotes[2], section.mustHitSection ? result.info.strumlines - 1 : 0, 0]);
			}

			result.noteData.sort((a:Array<Int>, b:Array<Int>) -> inline Std.int(a[0] - b[0]));
			sys.io.File.saveContent(Sys.args()[1], haxe.Json.stringify(result));
		}
		catch (e)
		{
			Sys.println('Error: Uncaught exception - $e');
		}
	}

	inline static function getBeatsOnSection(SONG:PsychSwagSong, curSection:Int):Float
	{
		var val:Null<Float> = 4;
		if (null != SONG && null != SONG.notes[curSection]) val = SONG.notes[curSection].sectionBeats;
		return null == val ? 4 : val;
	}
}