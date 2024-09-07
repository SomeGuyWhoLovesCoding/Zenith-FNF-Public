package moddable;

import openfl.display.BitmapData;
import haxe.io.Bytes;
import cpp.cppia.Module;

/**
 * The asset embed in the scripted modpack.
 * This class is a beta and is untested.
 */
@:publicFields
class Embed
{
	/**
	 * Put your images here.
	 */
	static var img:Map<String, BitmapData> = [];

	/**
	 * Put your sounds here.
	 */
	static var snd:Map<String, BitmapData> = [];

	/**
	 * Put your text strings here.
	 * This is useful for embedding json files, xml files, etc. inside the embed list.
	 */
	static var txt:Map<String, String> = [];

	/**
	 * Put your binary code here.
	 * This is useful for embedding chart files (dk what extension I would name them) inside the embed list.
	 */
	static var bin:Map<String, Bytes> = [];

	/**
	 * Construct an embed class from a modpack.
	 * @param modpack 
	 */
	static function generateFromModpack(modpack:Modpack)
	{
		// Generate embeds out of modpack data
		var inst = modpack.embed;

		img = inst.img;
		snd = inst.snd;
		txt = inst.txt;
		bin = inst.bin;

		trace(txt);
	}
}
