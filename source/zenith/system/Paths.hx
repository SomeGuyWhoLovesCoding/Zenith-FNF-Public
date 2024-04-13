package zenith.system;

import flixel.animation.FlxAnimationController;
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

	private static var strumNoteAnimationHolder:FlxSprite;
	private static var noteAnimationHolder:FlxSprite;
	private static var holdNoteAnimationHolder:FlxSprite;
	private static var noteFrame:FlxFrame;
	private static var holdPieceFrame:FlxFrame;
	private static var holdEndFrame:FlxFrame;

	//public static var soundChannel:SoundChannel;

	public static function initNoteShit():Void
	{
		// Do this to be able to just copy over the note animations and not reallocate it

		try
		{
			strumNoteAnimationHolder = new FlxSprite();
	
			strumNoteAnimationHolder.frames = getSparrowAtlas('noteskins/Regular/Strums');
			strumNoteAnimationHolder.animation.addByPrefix('static', 'static', 0, false);
			strumNoteAnimationHolder.animation.addByPrefix('pressed', 'press', 12, false);
			strumNoteAnimationHolder.animation.addByPrefix('confirm', 'confirm', 24, false);
	
			noteAnimationHolder = new FlxSprite();
			holdNoteAnimationHolder = new FlxSprite();
	
			noteAnimationHolder.frames = getSparrowAtlas('noteskins/Regular/Notes');
			holdNoteAnimationHolder.frames = noteAnimationHolder.frames;
	
			noteFrame = noteAnimationHolder.frames.frames[2];
			holdPieceFrame = noteAnimationHolder.frames.frames[1];
			holdEndFrame = noteAnimationHolder.frames.frames[0];
		}
		catch (e:haxe.Exception)
		{
			trace(e.message);
			trace(e.stack);
		}
	}

	public static var bitmapDataCache:Map<String, BitmapData> = new Map<String, BitmapData>();
	inline static public function image(key:String):BitmapData
	{
		var imagePath:String = '$ASSET_PATH${Utils.SLASH}images${Utils.SLASH}$key.png';

		if (sys.FileSystem.exists(imagePath))
		{
			if (!bitmapDataCache.exists(imagePath)) // Create a new FlxGraphic and add its bitmap data to the cache
				bitmapDataCache.set(imagePath, Utils.toTexture(FlxG.bitmap.add(BitmapData.fromFile(imagePath), true, imagePath).bitmap));

			return bitmapDataCache.get(imagePath);
		}

		trace('Image file "$imagePath" doesn\'t exist.');
		return null;
	}

	inline static public function sound(key:String):String
		return '$ASSET_PATH${Utils.SLASH}sounds${Utils.SLASH}$key.$SOUND_EXT';

	inline static public function soundRandom(key:String, min:Int = 0, max:Int = flixel.math.FlxMath.MAX_VALUE_INT):String
		return sound(key + FlxG.random.int(min, max));

	inline static public function music(key:String):String
		return '$ASSET_PATH${Utils.SLASH}music${Utils.SLASH}$key.$SOUND_EXT';

	inline static public function voices(song:String):String
		return '$ASSET_PATH${Utils.SLASH}songs${Utils.SLASH}${formatToSongPath(song)}${Utils.SLASH}Voices.$SOUND_EXT';

	inline static public function inst(song:String):String
		return '$ASSET_PATH${Utils.SLASH}songs${Utils.SLASH}${formatToSongPath(song)}${Utils.SLASH}Inst.$SOUND_EXT';

	inline static public function font(key:String, ext:String = 'ttf'):String
		return '$ASSET_PATH${Utils.SLASH}fonts${Utils.SLASH}$key.$ext';

	public static function getSparrowAtlas(key:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(image(key), '$ASSET_PATH/images/$key.xml'); // Don't change the slashes to "Utils.SLASH".
	}

	inline static public function formatToSongPath(path:String):String
		return path.replace(' ', '-').toLowerCase();
}
