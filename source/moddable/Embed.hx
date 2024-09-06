package moddable;

import openfl.display.BitmapData;
import haxe.io.Bytes;

/**
 * The embedded in the scripted modpack.
 * This class is a beta.
 */
@:final
@:publicFields
extern class Embed
{
    /**
     * Put your images here.
     */
    static var img:Map<String, BitmapData>;

    /**
     * Put your sounds here.
     */
    static var snd:Map<String, BitmapData>;

    /**
     * Put your text strings here.
     * This is useful for embedding json files, xml files, etc. inside the embed list.
     */
    static var txt:Map<String, String>;

    /**
     * Put your binary code here.
     * This is useful for embedding chart files (dk what extension I would name them) inside the embed list.
     */
    static var bin:Map<String, Bytes>;
}