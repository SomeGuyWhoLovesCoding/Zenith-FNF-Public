package;

// Use ``haxe --main ChartConverter %path2import% %path2save% --interp`` to compile this in order for it for work.

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
}

class ChartConverter
{
	static function main():Void
	{
		try
		{
			Sys.println('Psych/Vanilla chart converter\nUsage: Argument 4 - Path to psych engine chart, Argument 5 - Path to save the converted chart');
			trace(Sys.args()[1]);
			var song:PsychSwagSong = haxe.Json.parse(sys.io.File.getContent(Sys.args()[1]));
			trace(Sys.args());
		}
		catch (e)
		{
			Sys.println('Error: Uncaught exception - $e');
		}
	}
}