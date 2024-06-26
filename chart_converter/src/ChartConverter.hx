package;

// Use run.bat in order for it for work, or simply type out what's at the end of the code inside using the command prompt.

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

	@:optional var strumlines:Int;
}

typedef SongInfo =
{
	var stage:String;
	var player1:String;
	var player2:String;
	var spectator:String;
	var speed:Float;
	var bpm:Float;
	var time_signature:Array<Int>;
	var needsVoices:Bool;
	@:optional var strumlines:Int;
}

typedef SwagSong =
{
	song:Null<String>,
	info:SongInfo,
	noteData:Array<Array<Float>>,
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

			var contents:String = sys.io.File.getContent(Sys.args()[0]);
			var songImported:PsychSwagSong = haxe.Json.parse(contents).song;

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
					needsVoices: songImported.needsVoices,
					strumlines: 2
				},
				noteData: [],
				bpmChanges: []
			};

			if (result.info.strumlines == 0)
				result.info.strumlines = 2;

			for (i in 0...songImported.notes.length)
			{
				var section:SwagSection = songImported.notes[i];
				songPosition += (60000.0 / currentBPM) * (songImported.notes[i].sectionBeats ?? 4);

				if (section.changeBPM)
					result.bpmChanges.push([currentBPM, songPosition]);

				convertSectionNotes(section, result);
			}

			result.noteData.sort((a:Array<Float>, b:Array<Float>) -> Std.int(a[0] - b[0]));
			sys.io.File.saveContent(Sys.args()[1], haxe.Json.stringify(result));
		}
		catch (e)
		{
			Sys.println('Error: Uncaught exception - $e');
		}
	}

	static function convertSectionNotes(section:SwagSection, result:SwagSong):Void
	{
		for (songNotes in section.sectionNotes)
		result.noteData.push([
			songNotes[0],
			Std.int(songNotes[1] % 4),
			songNotes[2],
			songNotes[1] > 3 || !section.mustHitSection ? result.info.strumlines - 1 : 0,
			0
		]);
	}
}