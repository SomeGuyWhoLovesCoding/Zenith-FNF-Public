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

	static public function image(key:String):BitmapData
	{
		var imagePath:String = '$ASSET_PATH/images/$key.png';

		if (sys.FileSystem.exists(imagePath))
		{
			var bitmap:BitmapData = BitmapData.fromFile(imagePath);
			var bitmapData:BitmapData = FlxG.bitmap.add(bitmap, true, imagePath).bitmap;
			return Utils.toTexture(bitmapData);
		}

		trace("Image file \"" + imagePath + "\" doesn't exist.");

		return null;
	}

	static private var soundCache:Map<String, Sound> = new Map<String, Sound>();
	static public function sound(key:String):Sound
	{
		var soundPath:String = '$ASSET_PATH/$key.$SOUND_EXT';

		if (sys.FileSystem.exists(soundPath))
		{
			if (!soundCache.exists(soundPath))
			{
				var sound:Sound = Sound.fromFile(soundPath);
				soundCache.set(soundPath, sound);
			}

			return soundCache.get(soundPath);
		}

		trace('Sound file "$soundPath" doesn\'t exist.');

		return null;
	}

	static public function font(key:String, ext:String = "ttf"):String
	{
		return '$ASSET_PATH/fonts/$key.$ext';
	}

	static public function inst(song:String):Sound
	{
		return sound('data/${formatToSongPath(song)}/audio/inst');
	}

	static public function voices(song:String):Sound
	{
		return sound('data/${formatToSongPath(song)}/audio/vocals');
	}

	static public function getSparrowAtlas(key:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(image(key), '$ASSET_PATH/images/$key.xml');
	}

	static public function formatToSongPath(path:String):String
	{
		return path.replace(' ', '-').toLowerCase();
	}

	// Weird stuff that belongs to the end. Used for making stuff hacky while allowing you to have your custom noteskin btw

	static public var strumNoteAnimationHolder:FlxSprite = new FlxSprite();
	static public var noteAnimationHolder:FlxSprite = new FlxSprite();
	static public var sustainAnimationHolder:FlxSprite = new FlxSprite();
	static public var regularNoteFrame:FlxFrame;
	static public var sustainNoteFrame:FlxFrame;

	static public var idleNote:Note = new Note();
	static public var idleSustain:SustainNote = new SustainNote();
	static public var idleStrumNote:StrumNote = new StrumNote(0, 0);

	static public function initNoteShit():Void
	{
		strumNoteAnimationHolder.frames = getSparrowAtlas('noteskins/Regular/Strums');
		strumNoteAnimationHolder.animation.addByPrefix('static', 'static', 0, false);
		strumNoteAnimationHolder.animation.addByPrefix('pressed', 'press', 12, false);
		strumNoteAnimationHolder.animation.addByPrefix('confirm', 'confirm', 24, false);

		noteAnimationHolder.loadGraphic(image('noteskins/Regular/Note'));
		sustainAnimationHolder.loadGraphic(image('noteskins/Regular/Sustain'));

		regularNoteFrame = noteAnimationHolder._frame;
		sustainNoteFrame = sustainAnimationHolder._frame;

		idleNote.state = idleSustain.state = MISS;
		idleNote.strum = idleSustain.strum = idleStrumNote;
		idleNote.active = idleSustain.active = idleStrumNote.active = idleNote.visible = idleSustain.visible = idleStrumNote.visible = false;
	}
}
