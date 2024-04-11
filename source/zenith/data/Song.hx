package zenith.data;

import zenith.data.Section;

using StringTools;

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

class Song
{
	inline static public function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);

		var songJson:SwagSong = parseJSONshit(sys.io.File.getContent(Paths.ASSET_PATH + Utils.SLASH + 'data' + Utils.SLASH + formattedFolder + Utils.SLASH + formattedSong + '.json'));
		if(jsonInput != 'events') StageData.loadDirectory(songJson);
		return songJson;
	}

	inline static public function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = inline haxe.Json.parse(rawJson);
		return swagShit;
	}
}
