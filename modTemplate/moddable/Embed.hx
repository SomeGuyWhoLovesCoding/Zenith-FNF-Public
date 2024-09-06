package moddable;

import openfl.display.BitmapData;
import haxe.ds.StringMap;

/**
 * The embedded in the scripted modpack.
 * This class is a beta.
 */
@:final
@:publicFields
class Embed
{
    static var img:StringMap<BitmapData> = [
    /**
     * Put your images here.
     */
    ];

    static var snd:StringMap<BitmapData> = [
    /**
     * Put your sounds here.
     */
    ];

    static var txt:StringMap<String> = [
    /**
     * Put your text strings here.
     * This is useful for embedding json files, xml files, etc. inside the embed list.
     */
    ];

    static var bin:StringMap<Bytes> = [
    /**
     * Put your binary code here.
     * This is useful for embedding chart files (dk what extension I would name them) inside the embed list.
     */
    ]
}