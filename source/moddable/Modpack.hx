package moddable;

import openfl.display.BitmapData;
import haxe.io.Bytes;
import cpp.cppia.Module;
import sys.io.File;

/**
 * The modpack.
 */
@:publicFields
class Modpack
{
	/**
	 * The current modpack.
	 */
	static var current:Modpack = new Modpack();

	/**
	/**
	 * The modpack's CPPIA module.
	 /
	var module:Module;
	 */

	/**
	 * The modpack's asset embed linked to the class.
	 */
	static var embed:Embed = new Embed();

	private function new() {}

	// What the fuck
	static function fromFile(file:String)
	{
		var source:String = File.getContent(file);
		var module:Module = Module.fromString(source);
		/*var cls = module.resolveClass("moddable.Embed");
		embed.img = Reflect.field(cls, "img");
		embed.snd = Reflect.field(cls, "snd");
		embed.txt = Reflect.field(cls, "txt");
		embed.bin = Reflect.field(cls, "bin");*/
	}
}

/**
 * The private class of the asset embed instance from the modpack.
 */
@:publicFields
private class Embed
{
	/**
	 * Put your images here.
	 */
	var img:Map<String, BitmapData>;

	/**
	 * Put your sounds here.
	 */
	var snd:Map<String, BitmapData>;

	/**
	 * Put your text strings here.
	 * This is useful for embedding json files, xml files, etc. inside the embed list.
	 */
	var txt:Map<String, String>;

	/**
	 * Put your binary code here.
	 * This is useful for embedding chart files (dk what extension I would name them) inside the embed list.
	 */
	var bin:Map<String, Bytes>;

	/**
	 * Create an asset embed instance.
	 */
	function new() {}
}
