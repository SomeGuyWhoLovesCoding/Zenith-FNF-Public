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

	private static var noteFrames:FlxFramesCollection; // Don't reuse the same note spritesheet data, leave it there
	private static var noteAnimation:FlxAnimationController;

	public static var LowMemoryMode(default, null):Bool = true;

	//public static var soundChannel:SoundChannel;

	public static function initNoteShit(keys:Int = 4)
	{
		noteFrames = getSparrowAtlas('noteskins/NOTE_assets');

		// Do this to be able to just copy over the note animations and not reallocate it

		var spr:FlxSprite = new FlxSprite();
		spr.frames = noteFrames;
		noteAnimation = new FlxAnimationController(spr);

		// Use a for loop for adding all of the animations in the note spritesheet, otherwise it won't find the animations for the next recycle
		for (d in 0...keys)
		{
			noteAnimation.addByPrefix(Note.animArray[d] + 'holdend', Note.animArray[d] + ' hold end0');
			noteAnimation.addByPrefix(Note.animArray[d] + 'hold', Note.animArray[d] + ' hold piece0');
			noteAnimation.addByPrefix(Note.animArray[d] + 'Scroll', Note.animArray[d] + '0');
		}
	}

	public static var bitmapDataCache:Map<String, BitmapData> = new Map<String, BitmapData>();
	public static function image(key:String):BitmapData
	{
		var imagePath:String = '$ASSET_PATH/images/$key.png';

		if (sys.FileSystem.exists(imagePath))
		{
			if (bitmapDataCache.exists(imagePath))
			{
				return (LowMemoryMode ? Utils.toTexture(bitmapDataCache.get(imagePath)) : bitmapDataCache.get(imagePath));
			}
			else
			{
				// Create a new FlxGraphic and add its bitmap data to the cache
				bitmapDataCache.set(imagePath, FlxG.bitmap.add(BitmapData.fromFile(imagePath), true, imagePath).bitmap);
				return (LowMemoryMode ? Utils.toTexture(bitmapDataCache.get(imagePath)) : bitmapDataCache.get(imagePath));
			}
		}

		trace('Image file "$imagePath" doesn\'t exist.');

		return null;
	}

	public static var soundCache:Map<String, Sound> = new Map<String, Sound>();
	public static function __soundHelper(key:String):Sound
	{
		var soundPath:String = '$ASSET_PATH/$key.$SOUND_EXT';

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
		return __soundHelper('songs/${formatToSongPath(song)}/Voices');
	}

	public static function inst(song:String):Sound
	{
		return __soundHelper('songs/${formatToSongPath(song)}/Inst');
	}

	public static function font(key:String, ext:String = 'ttf')
	{
		return '$ASSET_PATH/fonts/$key.$ext';
	}

	public static function getSparrowAtlas(key:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(image(key), '$ASSET_PATH/images/$key.xml');
	}

	public static function formatToSongPath(path:String) {
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var path = invalidChars.split(path.replace(' ', '-')).join('-');
		return hideChars.split(path).join('').toLowerCase();
	}
}
