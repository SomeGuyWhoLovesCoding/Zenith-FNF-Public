package zenith.core;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.utils.Assets;

using StringTools;

/**
 * The asset manager.
 */
@:final
@:publicFields
class AssetManager
{
	inline static var ASSET_PATH = "assets";
	inline static var SOUND_EXT = "ogg";

	static function image(key:String) // Classic Paths.hx vibes
	{
		if (!Assets.exists(key))
			Assets.cache.setBitmapData(key, BitmapData.fromFile('$ASSET_PATH/images/$key.png'));
		return Tools.toTexture(Assets.getBitmapData(key), key);
	}

	inline static function xml(key:String)
	{
		return '$ASSET_PATH/$key.xml';
	}

	inline static function audio(key:String)
	{
		return '$ASSET_PATH/$key.$SOUND_EXT';
	}

	inline static function sound(key:String)
	{
		return audio('sounds/$key');
	}

	inline static function music(key:String)
	{
		return audio('music/$key');
	}

	inline static function font(key:String, ext:String = "ttf")
	{
		return '$ASSET_PATH/fonts/$key.$ext';
	}

	inline static function inst(song:String)
	{
		return audio('data/${formatToSongPath(song)}/audio/inst');
	}

	inline static function voices(song:String)
	{
		return audio('data/${formatToSongPath(song)}/audio/vocals');
	}

	inline static function getSparrowAtlas(key:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(image(key), sys.io.File.getContent(xml("images/" + key)));
	}

	static function formatToSongPath(path:String)
	{
		// From psych lmao
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}
}
