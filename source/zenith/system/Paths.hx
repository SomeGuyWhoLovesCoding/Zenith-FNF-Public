package zenith.system;

import flixel.animation.FlxAnimationController;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;

import openfl.display.BitmapData;
import openfl.media.Sound;

using StringTools;

class Paths
{
	inline public static var ASSET_PATH:String = "assets";
	inline public static var SOUND_EXT:String = "ogg";

	private static var noteAnimationHolder:FlxSprite;
	private static var holdNoteAnimationHolder:FlxSprite;

	//public static var soundChannel:SoundChannel;

	public static function initNoteShit()
	{
		// Do this to be able to just copy over the note animations and not reallocate it

		noteAnimationHolder = new FlxSprite();
		noteAnimationHolder.frames = getSparrowAtlas('noteskins/Regular');
		noteAnimationHolder.animation.addByPrefix('scroll', 'purple0');

		holdNoteAnimationHolder = new FlxSprite();
		holdNoteAnimationHolder.frames = noteAnimationHolder.frames;
		holdNoteAnimationHolder.animation.addByPrefix('piece', 'hold piece0');
		holdNoteAnimationHolder.animation.addByPrefix('tail', 'hold end0');
	}

	public static var bitmapDataCache:Map<String, BitmapData> = new Map<String, BitmapData>();
	public static function image(key:String):BitmapData
	{
		var imagePath:String = '$ASSET_PATH/images/$key.png';

		if (sys.FileSystem.exists(imagePath))
		{
			if (!bitmapDataCache.exists(imagePath)) // Create a new FlxGraphic and add its bitmap data to the cache
				bitmapDataCache.set(imagePath, Utils.toTexture(FlxG.bitmap.add(BitmapData.fromFile(imagePath), true, imagePath).bitmap));

			return bitmapDataCache.get(imagePath);
		}

		trace('Image file "$imagePath" doesn\'t exist.');
		return null;
	}

	public static var soundCache:Map<String, Sound> = new Map<String, Sound>();
	public static function __soundHelper(key:String):Sound
	{
		var soundPath:String = '$ASSET_PATH${Utils.SLASH}$key.$SOUND_EXT';

		if (sys.FileSystem.exists(soundPath))
		{
			if (soundCache.exists(soundPath))
				return soundCache.get(soundPath);
			else
			{
				soundCache.set(soundPath, Sound.fromFile(soundPath));
				return soundCache.get(soundPath);
			}
		}

		trace('Sound file "$soundPath" doesn\'t exist.');

		return null;
	}

	public static function sound(key:String):Sound
	{
		return __soundHelper('sounds/$key');
	}

	public static function soundRandom(key:String, min:Int = 0, max:Int = flixel.math.FlxMath.MAX_VALUE_INT):Sound
	{
		return sound(key + FlxG.random.int(min, max));
	}

	public static function music(key:String):Sound
	{
		return __soundHelper('music/$key');
	}

	public static function voices(song:String):Sound
	{
		return __soundHelper('songs${Utils.SLASH}${formatToSongPath(song)}${Utils.SLASH}Voices');
	}

	public static function inst(song:String):Sound
	{
		return __soundHelper('songs${Utils.SLASH}${formatToSongPath(song)}${Utils.SLASH}Inst');
	}

	public static function font(key:String, ext:String = 'ttf')
	{
		return '$ASSET_PATH${Utils.SLASH}fonts${Utils.SLASH}$key.$ext';
	}

	public static function getSparrowAtlas(key:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(image(key), '$ASSET_PATH${Utils.SLASH}images${Utils.SLASH}$key.xml');
	}

	public static function formatToSongPath(path:String) {
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var path = invalidChars.split(path.replace(' ', '-')).join('-');
		return hideChars.split(path).join('').toLowerCase();
	}
}
