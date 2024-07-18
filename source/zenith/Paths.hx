package zenith;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;

using StringTools;

@:final
class Paths
{
	inline static public var ASSET_PATH:String = "assets";
	inline static public var SOUND_EXT:String = "ogg";

	inline static public function image(key:String)
	{
		return '$ASSET_PATH/images/$key.png';
	}

	inline static public function sound(key:String)
	{
		return '$ASSET_PATH/$key.$SOUND_EXT';
	}

	inline static public function font(key:String, ext:String = "ttf"):String
	{
		return '$ASSET_PATH/fonts/$key.$ext';
	}

	inline static public function inst(song:String)
	{
		return sound('data/${formatToSongPath(song)}/audio/inst');
	}

	inline static public function voices(song:String)
	{
		return sound('data/${formatToSongPath(song)}/audio/vocals');
	}

	static public function getSparrowAtlas(key:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(image(key), '$ASSET_PATH/images/$key.xml');
	}

	static public function formatToSongPath(path:String):String
	{
		// From psych lmao
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}
}
