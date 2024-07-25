package zenith.core;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.utils.Assets;

using StringTools;

class AssetManager
{
	inline static public var ASSET_PATH = "assets";
	inline static public var SOUND_EXT = "ogg";

	public static function image(key:String) // Classic Paths.hx vibes
	{
		if (!Assets.exists(key)) Assets.cache.setBitmapData(key, BitmapData.fromFile('$ASSET_PATH/images/$key.png'));
		return !SaveData.contents.graphics.gpuCaching ? Assets.getBitmapData(key) : Tools.toTexture(Assets.getBitmapData(key));
	}

	inline static public function xml(key:String)
	{
		return '$ASSET_PATH/$key.xml';
	}

	inline static public function audio(key:String)
	{
		return '$ASSET_PATH/$key.$SOUND_EXT';
	}

	inline static public function sound(key:String)
	{
		return audio('sounds/$key');
	}

	inline static public function font(key:String, ext:String = "ttf")
	{
		return '$ASSET_PATH/fonts/$key.$ext';
	}

	inline static public function inst(song:String)
	{
		return audio('data/${formatToSongPath(song)}/audio/inst');
	}

	inline static public function voices(song:String)
	{
		return audio('data/${formatToSongPath(song)}/audio/vocals');
	}

	inline static public function getSparrowAtlas(key:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(image(key), sys.io.File.getContent(xml("images/" + key)));
	}

	static public function formatToSongPath(path:String)
	{
		// From psych lmao
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}
}
