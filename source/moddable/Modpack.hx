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
	var embed:EmbedInstance;

	private function new() {}

	static function fromFile(file:String)
	{
		var modpack = current;
		modpack.embed = Type.createInstance(Module.fromString(File.getContent(file)).resolveClass("moddable.Embed"), []);
	}
}

/**
 * The private class of the asset embed instance from the modpack.
 */
@:publicFields
private class EmbedInstance
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
