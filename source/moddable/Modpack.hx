package moddable;

import openfl.display.BitmapData;
import openfl.system.System;
import lime.math.Rectangle;
import haxe.io.Bytes;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;
import sys.io.FileInput;

/**
 * Asset embed attributes class.
 * This is here for greater readability.
 */
@:publicFields
private class AssetEmbedAttributes
{
	var name:String;
	var path:String;
	var type:String;
	var comp:Bool;

	function new(n:String, p:String, t:String, c:Bool)
	{
		name = n;
		path = p;
		type = t;
		comp = c;
	}
}

/**
 * Asset embed type class.
 * This is here for greater readability.
 */
@:publicFields
private abstract AssetEmbedType(Int) from Int
{
	/**
	 * The `BITMAP` asset embed type constant.
	 */
	inline static var BITMAP:AssetEmbedType = 1;

	/**
	 * The `SOUND` asset embed type constant.
	 */
	inline static var SOUND:AssetEmbedType = 2;

	/**
	 * The `TEXT` asset embed type constant.
	 */
	inline static var TEXT:AssetEmbedType = 0;

	/**
	 * Convert an asset embed type to a string.
	 * @returns String
	 */
	function toString():String
	{
		if (this == AssetEmbedType.BITMAP)
			return "BITMAP";

		if (this == AssetEmbedType.SOUND)
			return "SOUND";

		return "TEXT";
	}

	/**
	 * Construct an asset embed type from a string.
	 * @returns AssetEmbedType
	 */
	@:from static function fromString(value:String):AssetEmbedType
	{
		if (value.toUpperCase() == "BITMAP")
			return AssetEmbedType.BITMAP;

		if (value.toUpperCase() == "SOUND")
			return AssetEmbedType.SOUND;

		return AssetEmbedType.TEXT;
	}

	/**
	 * Get the asset embed type's underlying type.
	 * @returns Int
	 */
	@:to inline function toInt():Int
	{
		return this;
	}
}

/**
 * The modpack block.
 * This is here because it helps with storing header info of raw data from key.
 * And, it abstracts over an array of integers for additional optimization.
 */
@:publicFields
abstract ModpackBlock(Array<Int>) from Array<Int>
{
	/**
	 * The type.
	 */
	var position(get, never):Int;

	/**
	 * The getter for the position.
	 * @return Int
	 */
	inline function get_position():Int
	{
		return this[0];
	}

	/**
	 * The type.
	 */
	var type(get, never):AssetEmbedType;

	/**
	 * The getter for the type.
	 * @return AssetEmbedType
	 */
	inline function get_type():AssetEmbedType
	{
		return this[1];
	}

	/**
	 * The size.
	 */
	var size(get, never):Int;

	/**
	 * The getter for the size.
	 * @return Int
	 */
	inline function get_size():Int
	{
		return this[2];
	}

	/**
	 * The block width.
	 */
	var width(get, never):Int;

	/**
	 * The getter for the block width.
	 * @return Int
	 */
	inline function get_width():Int
	{
		return this[3];
	}

	/**
	 * The block height.
	 */
	var height(get, never):Int;

	/**
	 * The getter for the block width.
	 * @return Int
	 */
	inline function get_height():Int
	{
		return this[4];
	}
}

/**
 * The modpack.
 */
@:publicFields
class Modpack
{
	/**
	 * The modpack's file input.
	 */
	static var input:FileInput;

	/**
	 * The byte position map.
	 */
	static var blockMap:Map<String, ModpackBlock> = [];

	/**
	 * The bitmap list.
	 * This is a cache that ensures that you don't have to allocate the same bitmap data again.
	 */
	static var bitmapList:Map<String, BitmapData> = [];

	/**
	 * The text list.
	 * This is a cache that ensures that you don't have to allocate the same text string again.
	 */
	static var textList:Map<String, String> = [];

	/**
	 * Construct a `ModPacker`.
	 */
	static function fromFile(path:String)
	{
		if (!FileSystem.exists(path))
		{
			return;
		}

		input = File.read(path);

		// Stylized as a unit test to make sure that everything works fine.

		while (true)
		{
			try
			{
				var keyLen:Int = input.readInt32();
				var key:String = input.readString(keyLen);

				var position:Int = input.readInt32();

				var type:AssetEmbedType = input.readByte();

				var size:Int = input.readInt32();

				var arr = [position, type.toInt(), size];

				// SPECIAL CONDITIONS
				if (type == AssetEmbedType.BITMAP)
				{
					var lw:Int = input.readInt32();
					arr.push(lw);

					var lh:Int = input.readInt32();
					arr.push(lh);
				}

				blockMap[key] = arr;

				input.seek(position + size, SeekBegin);
			}
			catch (e)
			{
				break;
			}
		}
	}

	static function readBitmapDataFromEmbed(key:String):BitmapData
	{
		if (bitmapList.exists(key))
		{
			return bitmapList[key];
		}

		if (blockMap.exists(key))
		{
			var block:ModpackBlock = blockMap[key];

			input.seek(block.position, SeekBegin);

			var size:Int = block.size;
			var lw:Int = block.width;
			var lh:Int = block.height;

			var bitmapData:BitmapData = new BitmapData(lw, lh, true, 0);
			var b:Bytes = (bitmapData.image.buffer.data.buffer:Bytes);
			input.readBytes(b, 0, size);

			if (!bitmapList.exists(key))
			{
				bitmapList[key] = bitmapData;
			}

			return bitmapData;
		}

		return null;
	}

	static function readTextFromEmbed(key:String):Null<String>
	{
		if (textList.exists(key))
		{
			return textList[key];
		}

		if (blockMap.exists(key))
		{
			var block:ModpackBlock = blockMap[key];

			input.seek(block.position, SeekBegin);

			var size:Int = block.size;

			var textBytes:Bytes = Bytes.alloc(size);

			for (i in 0...size)
			{
				textBytes.set(i, -input.readByte());
			}

			var text:String = textBytes.getString(0, size, RawNative);

			if (!textList.exists(key))
			{
				textList[key] = text;
			}

			return text;
		}

		return null;
	}
}
