package zenith.data;

using StringTools;

typedef SongInfo =
{
	var stage:String;
	var player1:String;
	var player2:String;
	var spectator:String;
	var speed:Float;
	var bpm:Float;
	var time_signature:Array<Int>;
	var offset:Null<Int>;
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

@:keep class Song
{
	static public function loadFromJson(jsonInput:String = "", folder:String = ""):SwagSong
	{
		var path:String = Paths.ASSET_PATH + '/data/' + folder.toLowerCase().replace(' ', '-') + '/' + jsonInput.toLowerCase().replace(' ', '-') + '.json';
		var content:String = sys.io.File.getContent(path);
		var songJson:SwagSong = haxe.Json.parse(content);
		StageData.loadDirectory(songJson);
		return songJson;
	}
}
