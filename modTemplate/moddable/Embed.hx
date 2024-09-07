package moddable;

import openfl.display.BitmapData;
import haxe.io.Bytes;

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
    var img:Map<String, BitmapData> = ["img"=>BitmapData.fromFile("assets/images/img.png")];

    /**
     * Put your sounds here.
     */
    var snd:Map<String, BitmapData> = [];

    /**
     * Put your text strings here.
     * This is useful for embedding json files, xml files, etc. inside the embed list.
     */
    var txt:Map<String, String> = ["readme.md"=>"Hey there. This is a test."];

    /**
     * Put your binary code here.
     * This is useful for embedding chart files (dk what extension I would name them) inside the embed list.
     */
    var bin:Map<String, Bytes> = [];
}