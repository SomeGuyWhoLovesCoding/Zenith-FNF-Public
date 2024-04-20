package zenith.system;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;
import openfl.media.Sound;

using StringTools;

class Paths
{
	inline public static var ASSET_PATH:String = "assets";
	inline public static var SOUND_EXT:String = "ogg";

	// Notes

	public static var strumNoteAnimationHolder:FlxSprite = null;
	public static var noteAnimationHolder:FlxSprite = null;
	public static var noteFrame:FlxFrame = null;
	public static var holdPieceFrame:FlxFrame = null;
	public static var holdEndFrame:FlxFrame = null;

	// Do this to be able to just copy over the note animations and not reallocate it
	public static function initNoteShit():Void
	{
		strumNoteAnimationHolder = new FlxSprite();
		strumNoteAnimationHolder.frames = getSparrowAtlas('noteskins/Regular/Strums');
		strumNoteAnimationHolder.animation.addByPrefix('static', 'static', 0, false);
		strumNoteAnimationHolder.animation.addByPrefix('pressed', 'press', 12, false);
		strumNoteAnimationHolder.animation.addByPrefix('confirm', 'confirm', 24, false);

		noteAnimationHolder = new FlxSprite();
		noteAnimationHolder.frames = getSparrowAtlas('noteskins/Regular/Notes');

		noteFrame = noteAnimationHolder.frames.frames[2];
		holdPieceFrame = noteAnimationHolder.frames.frames[1];
		holdEndFrame = noteAnimationHolder.frames.frames[0];

		noteAnimationHolder.visible = strumNoteAnimationHolder.visible = noteAnimationHolder.active = strumNoteAnimationHolder.active = false;
	}

	inline public static function font(key:String, ext:String = "ttf"):String
		return '$ASSET_PATH/fonts/$key.$ext';

	private static var bitmapDataCache:Map<String, BitmapData> = new Map<String, BitmapData>();
	public static function image(key:String):BitmapData
	{
		var imagePath:String = '$ASSET_PATH/images/$key.png';

		if (sys.FileSystem.exists(imagePath))
		{
			if (!bitmapDataCache.exists(imagePath)) // Create a new FlxGraphic and add its bitmap data to the cache
				bitmapDataCache.set(imagePath, Utils.toTexture(FlxG.bitmap.add(BitmapData.fromFile(imagePath), true, imagePath).bitmap));

			return bitmapDataCache.get(imagePath);
		}

		trace("Image file \"" + imagePath + "\" doesn't exist.");
		return null;
	}

	private static var soundCache:Map<String, Sound> = new Map<String, Sound>();
	private static function __soundHelper(key:String):Sound
	{
		var soundPath:String = '$ASSET_PATH/$key.$SOUND_EXT';

		if (sys.FileSystem.exists(soundPath))
		{
			if (!soundCache.exists(soundPath))
				soundCache.set(soundPath, Sound.fromFile(soundPath));

			return soundCache.get(soundPath);
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

	public static function getSparrowAtlas(key:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(image(key), '$ASSET_PATH/images/$key.xml');
	}

	public static function formatToSongPath(path:String):String
		return path.replace(' ', '-').toLowerCase();
}
