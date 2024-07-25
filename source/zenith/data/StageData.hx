package zenith.data;

import haxe.Json;
import zenith.data.Song;

using StringTools;

typedef StageFile =
{
	var directory:String;
	var defaultZoom:Float;
	var isPixelStage:Bool;

	var boyfriend:Array<Int>;
	var girlfriend:Array<Int>;
	var opponent:Array<Int>;
	var hide_girlfriend:Bool;

	var camera_boyfriend:Array<Int>;
	var camera_opponent:Array<Int>;
	var camera_girlfriend:Array<Int>;
	var camera_speed:Null<Float>;
}

class StageData
{
	public static var forceNextDirectory:String = null;

	public static function loadDirectory(SONG:SwagSong):Void
	{
		var stage:String = '';

		if (null != SONG.info.stage)
			stage = SONG.info.stage;

		switch (AssetManager.formatToSongPath(SONG.song.toLowerCase()))
		{
			case 'spookeez' | 'south' | 'monster':
				stage = 'spooky';
			default:
				stage = 'stage';
		}
	}

	public static function getStageFile(stage:String):StageFile
	{
		var rawJson:String = null;
		var path:String = AssetManager.ASSET_PATH + '/stages/' + stage + '.json';
		var contents:String = sys.io.File.getContent(path);

		return sys.FileSystem.exists(path) ? cast Json.parse(contents) : null;
	}
}
