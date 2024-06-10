package zenith.system;

import flixel.animation.FlxAnimationController;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;
import openfl.media.Sound;

using StringTools;

@:access(flixel.FlxSprite)

@:final
class Paths
{
	inline static public var ASSET_PATH:String = "assets";
	inline static public var SOUND_EXT:String = "ogg";

	// Notes

	static public var strumNoteAnimationHolder:FlxSprite = null;
	static public var noteAnimationHolder:FlxSprite = null;
	static public var sustainAnimationHolder:FlxSprite = null;
	static public var regularNoteFrame:FlxFrame = null;
	static public var sustainNoteFrame:FlxFrame = null;

	static public var idleNote:Note = new Note();
	static public var idleSustain:SustainNote = new SustainNote();
	static public var idleStrumNote:StrumNote = new StrumNote(0, 0);

	// Do this to be able to just copy over the note animations and not reallocate it
	static public function initNoteShit():Void
	{
		strumNoteAnimationHolder = new FlxSprite();
		strumNoteAnimationHolder.frames = getSparrowAtlas('noteskins/Regular/Strums');
		strumNoteAnimationHolder.animation.addByPrefix('static', 'static', 0, false);
		strumNoteAnimationHolder.animation.addByPrefix('pressed', 'press', 12, false);
		strumNoteAnimationHolder.animation.addByPrefix('confirm', 'confirm', 24, false);

		noteAnimationHolder = new FlxSprite().loadGraphic(image('noteskins/Regular/Note'));
		sustainAnimationHolder = new FlxSprite().loadGraphic(image('noteskins/Regular/Sustain'));

		regularNoteFrame = noteAnimationHolder._frame;
		sustainNoteFrame = sustainAnimationHolder._frame;

		idleNote.state = idleSustain.state = MISS;
		idleNote.strum = idleSustain.strum = idleStrumNote;
		idleNote.active = idleSustain.active = idleStrumNote.active = idleNote.visible = idleSustain.visible = idleStrumNote.visible = false;
	}

	static public function font(key:String, ext:String = "ttf"):String
	{
		return '$ASSET_PATH/fonts/$key.$ext';
	}

	static public function image(key:String):BitmapData
	{
		var imagePath:String = '$ASSET_PATH/images/$key.png';

		if (sys.FileSystem.exists(imagePath))
		{
			return Utils.toTexture(FlxG.bitmap.add(BitmapData.fromFile(imagePath), true, imagePath).bitmap); // Fuck it. Let's just leave it there until I find out a way to remake the bitmap caching system.
		}

		trace("Image file \"" + imagePath + "\" doesn't exist.");
		return null;
	}

	static private var soundCache:Map<String, Sound> = new Map<String, Sound>();
	static private function __soundHelper(key:String):Sound
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

	static public function sound(key:String):Sound
	{
		return __soundHelper('sounds/$key');
	}

	static public function soundRandom(key:String, min:Int = 0, max:Int = flixel.math.FlxMath.MAX_VALUE_INT):Sound
	{
		return sound(key + FlxG.random.int(min, max));
	}

	static public function music(key:String):Sound
	{
		return __soundHelper('music/$key');
	}

	static public function voices(song:String):Sound
	{
		return __soundHelper('data/${formatToSongPath(song)}/audio/vocals');
	}

	static public function inst(song:String):Sound
	{
		return __soundHelper('data/${formatToSongPath(song)}/audio/inst');
	}

	static public function getSparrowAtlas(key:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(image(key), '$ASSET_PATH/images/$key.xml');
	}

	static public function formatToSongPath(path:String):String
	{
		return path.replace(' ', '-').toLowerCase();
	}
}
