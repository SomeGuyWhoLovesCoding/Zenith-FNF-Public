package zenith.data;

import haxe.Json;
import zenith.data.Song;

using StringTools;

typedef StageFile =
{
	var directory:String;
	var defaultZoom:Float;
	var isPixelStage:Bool;

	var boyfriend:Array<Dynamic>;
	var girlfriend:Array<Dynamic>;
	var opponent:Array<Dynamic>;
	var hide_girlfriend:Bool;

	var camera_boyfriend:Array<Float>;
	var camera_opponent:Array<Float>;
	var camera_girlfriend:Array<Float>;
	var camera_speed:Null<Float>;
}

class StageData
{
	public static var forceNextDirectory:String = null;
	public static function loadDirectory(SONG:SwagSong):Void
	{
		var stage:String = '';
		if(null != SONG.info.stage)
			stage = SONG.info.stage;
		else if(null != SONG.song)
		{
			switch (Paths.formatToSongPath(inline SONG.song.toLowerCase()))
			{
				case 'spookeez' | 'south' | 'monster':
					stage = 'spooky';
				default:
					stage = 'stage';
			}
		} else
			stage = 'stage';
	}

	public static function getStageFile(stage:String):StageFile
	{
		var rawJson:String = null;
		var path:String = Paths.ASSET_PATH + '/stages/' + stage + '.json';

		if(sys.FileSystem.exists(path))
			return cast Json.parse(sys.io.File.getContent(path));
		else
			return null;
	}
}