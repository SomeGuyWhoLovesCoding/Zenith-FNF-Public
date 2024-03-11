package zenithFunkin.system;

import flixel.animation.FlxAnimationController;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.media.Sound;
import openfl.utils.Assets;

using StringTools;

class Paths
{
	inline public static var ASSET_PATH = "assets";
	inline public static var SOUND_EXT = "ogg";

	private static var noteFrames:FlxFramesCollection; // Don't reuse the same note spritesheet data, leave it there
	private static var noteAnimation:FlxAnimationController;

	public static function initNoteShit(keys:Int = 4)
	{
		noteFrames = Paths.getSparrowAtlas('noteskins/NOTE_assets');

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

	inline static public function sound(key:String):Sound
	{
		return Assets.getSound('$ASSET_PATH/sounds/$key.ogg', true);
	}

	inline static public function soundRandom(key:String, min:Int = 0, max:Int = flixel.math.FlxMath.MAX_VALUE_INT):Sound
	{
		return sound(key + FlxG.random.int(min, max));
	}

	inline static public function music(key:String):Sound
	{
		return Assets.getSound('$ASSET_PATH/music/$key.ogg', true);
	}

	inline static public function voices(song:String):Sound
	{
		return Assets.getSound('$ASSET_PATH/songs/${formatToSongPath(song)}/Voices.ogg', true);
	}

	inline static public function inst(song:String):Sound
	{
		return Sound.fromFile('$ASSET_PATH/songs/${formatToSongPath(song)}/Inst.ogg');
	}

	inline static public function font(key:String, ext:String = 'ttf')
	{
		return '$ASSET_PATH/fonts/$key.$ext';
	}

	inline static public function getSparrowAtlas(key:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow('$ASSET_PATH/images/$key.png', '$ASSET_PATH/images/$key.xml');
	}

	inline static public function formatToSongPath(path:String) {
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}
}
