package zenith.core;

import flixel.graphics.frames.FlxAtlasFrames;
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
	/**
	 * The asset path.
	 */
	inline static var ASSET_PATH = "assets";

	/**
	 * The sound extension.
	 */
	inline static var SOUND_EXT = "ogg";

	/**
	 * The image bitmap grabber.
	 * @param key 
	 */
	static function image(key:String)
	{
		var bmp:BitmapData = null;

		if (!Assets.exists(key))
		{
			var img = Modpack.embed.img;

			if (img.exists(key))
			{
				bmp = img[key];
			}

			Assets.cache.setBitmapData(key, bmp);
		}

		return Tools.toTexture(Assets.getBitmapData(key), key);
	}

	/**
	 * The xml path.
	 * @param key 
	 */
	inline static function xml(key:String)
	{
		return '$ASSET_PATH/$key.xml';
	}

	/**
	 * The audio path.
	 * @param key 
	 */
	inline static function audio(key:String)
	{
		return '$ASSET_PATH/$key.$SOUND_EXT';
	}

	/**
	 * The sound path.
	 * @param key 
	 */
	inline static function sound(key:String)
	{
		return audio('sounds/$key');
	}

	/**
	 * The music path.
	 * @param key 
	 */
	inline static function music(key:String)
	{
		return audio('music/$key');
	}

	/**
	 * The font path.
	 * @param key 
	 */
	inline static function font(key:String, ext:String = "ttf")
	{
		return '$ASSET_PATH/fonts/$key.$ext';
	}

	/**
	 * The instrumental path.
	 * @param key 
	 */
	inline static function inst(song:String)
	{
		return audio('data/${formatToSongPath(song)}/audio/inst');
	}

	/**
	 * The voices path.
	 * @param key 
	 */
	inline static function voices(song:String)
	{
		return audio('data/${formatToSongPath(song)}/audio/vocals');
	}

	/**
	 * The sparrow atlas frames grabber.
	 * @param key 
	 * @return FlxAtlasFrames
	 */
	static function getSparrowAtlas(key:String):FlxAtlasFrames
	{
		var xmlCode:String = "";
		var xmlPath:String = xml("images/" + key);

		try
		{
			xmlCode = sys.io.File.getContent(xmlPath);
		}
		catch (e)
		{
			var txt = Modpack.embed.txt;
			if (txt.exists(key))
			{
				xmlCode = txt[key];
			}
			else
				throw('$e\n\n(There is no text file named "$xmlPath".)');
		}

		return FlxAtlasFrames.fromSparrow(image(key), xmlCode);
	}

	/**
	 * Format the song path.
	 * @param path 
	 */
	static function formatToSongPath(path:String)
	{
		// From psych lmao
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}
}
