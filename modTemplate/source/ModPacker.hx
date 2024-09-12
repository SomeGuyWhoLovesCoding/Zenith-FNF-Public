package;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.system.System;

import lime.math.Rectangle;
import lime.graphics.Image;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;

import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;
import sys.io.FileInput;

import external.FileExtra;

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
 * Fuck you. This took forever to maintain.
 */
class ModPacker extends Sprite
{
	/**
	 * Construct a `ModPacker`.
	 */
	function new()
	{
		super();

		#if testOutput

		/**
		 * OUTPUT TEST.
		 */

		//Sys.println("\n\n-------- OUTPUT TEST --------\n\n");

		var trueStr = "true";

		/**
		 * The local function for getting an embedded asset's raw data.
		 * @param path 
		 * @param type 
		 * @return Bytes
		 */
		function getFileRaw(path:String, type:String):Bytes
		{
			var bytes:Bytes = null;

			switch (type)
			{
				case "bitmap":
					/**
					 * Just a quick note: We're not using BitmapData because it abstracts `Image`.
					 */
					var bitmap:BitmapData = BitmapData.fromFile(path);

					var lh:Int = bitmap.height;
					var lw:Int = bitmap.width;

					var bytesBuffer:BytesBuffer = new BytesBuffer();
					bytesBuffer.addInt32(lw);
					bytesBuffer.addInt32(lh);

					var rect:Rectangle = new Rectangle(0, 0, lw, lh);
					var rgba:Bytes = bitmap.image.getPixels(rect, BGRA32);

					bitmap.image.buffer.data.buffer = null;
					bitmap.image.buffer.data = null;
					bitmap.image.buffer = null;
					bitmap.disposeImage();
					bitmap.dispose();

					bytesBuffer.addBytes(rgba, 0, rgba.length);

					bytes = bytesBuffer.getBytes();

				default:
					var stamp:Float = haxe.Timer.stamp();

					var fileInput:FileInput = File.read(path);

					/**
					 * This section here checks if the file encoding has BOM.
					 * After that, the file input starts to process the text input while also flipping all of its bits.
					 */

					var isBOM:Bool = (fileInput.readByte() == 0xEF && fileInput.readByte() == 0xBB && fileInput.readByte() == 0xBF);

					if (!isBOM)
					{
						fileInput.seek(0, SeekBegin);
					}

					var bomValue:Int = (isBOM ? 3 : 0);
					var textBytes:Bytes = Bytes.alloc(FileSystem.stat(path).size - bomValue);
					for (i in bomValue...textBytes.length)
					{
						textBytes.set(i - bomValue, -fileInput.readByte());
					}

					bytes = textBytes;
			}

			return bytes;
		}

		/**
		 * The local function for getting an asset embed element's attributes.
		 * @param element 
		 * @return AssetEmbedAttributes
		 */
		function getAssetEmbedAttributes(element:Xml):AssetEmbedAttributes
		{
			var key:String = element.get('name'); // Named this thing "key" because if you have something with the key then you will get actual raw bytes of a bitmap, sound, or text.
			var path:String = element.get('path');

			var type:String = "";
			try { type = element.get('type').toLowerCase(); } catch (e) {}

			var compress:Bool = false;
			try { compress = element.get('compress') == trueStr; } catch (e) {}

			return new AssetEmbedAttributes(key, path, type, compress);
		}

		/**
		 * The modpack file output.
		 */
		var output:FileOutput = File.write('output.zfmp');

		/**
		 * The asset embed xml.
		 * The reason why it's an xml because it's meant to be robust and flexible.
		 */
		var xml:Xml = Xml.parse(sys.io.File.getContent('embed.xml'));

		for (element in xml.firstElement().elements())
		{
			/**
			 * Element attributes.
			 */
			var att:AssetEmbedAttributes = getAssetEmbedAttributes(element);

			if (!FileSystem.exists(att.path))
			{
				Sys.println("File doesn't exist. Let's move on.");
				continue;
			}

			output.writeInt32(att.key.length);
			output.writeString(att.key);

			/**
			 * Asset type.
			 */
			var type:AssetEmbedType = att.type;

			/**
			 * A helper variable.
			 */
			var addedBytes:Int = (type == AssetEmbedType.BITMAP ? 8 : 0);

			output.writeInt32(output.tell() + 9 + addedBytes);

			Sys.println('Embedding ${att.name} from ${att.path}...');

			/**
			 * File bytes from the original location, with added data at the
			 */
			var bytes:Bytes = getFileRaw(att.path, att.type);

			output.writeByte(type.toInt());

			output.writeInt32(bytes.length - addedBytes);
			output.write(bytes);

			Sys.println('Asset ${att.name} embedded!');
		}

		output.close();

		Sys.exit(0);

		#else

		/**
		 * INPUT TEST.
		 */

		//Sys.println("-------- INPUT TEST --------\n\n");

		/**
		 * The modpack file input.
		 */
		var input:FileInput = File.read('output.zfmp');

		// Stylized as a unit test to make sure that everything works fine.

		while (true)
		{
			try
			{
				/**
				 * KEY.
				 */
				var keyLen:Int = input.readInt32();
				var key:String = input.readString(keyLen);

				/**
				 * POSITION.
				 */
				var position:Int = input.readInt32();

				/**
				 * TYPE.
				 */
				var type:AssetEmbedType = input.readByte();

				/**
				 * SIZE.
				 */
				var size:Int = input.readInt32();

				/**
				 * BITMAP.
				 * THE PARSER IS MEANT TO BE AS FAST AS POSSIBLE.
				 */
				if (type == AssetEmbedType.BITMAP)
				{
					var stamp:Float = Sys.time();

					var lw:Int = input.readInt32();
					//trace('$key width: $lw');
					var lh:Int = input.readInt32();
					//trace('$key height: $lh');

					/**
					 * THIS IS A CONCEPT!
					 * The real method is going to be `File.getBytes` but with 2 optional parameters being
					 * the starting position and ending position, allowing you to basically get parts of
					 * a file's bytes in the most efficient way possible.
					 * Also, the original byte position's summed by 9 because additional bytes were in the way.
					 * And, you can fill an empty `BitmapData` with raw uncompressed bytes of image data in
					 * the fastest ever way possible.
					 */

					var bitmapData:BitmapData = new BitmapData(lw, lh, true, 0);
					var b:Bytes = (bitmapData.image.buffer.data.buffer:Bytes);
					input.readBytes(b, 0, size);

					Sys.println(Sys.time() - stamp);

					var bitmap:Bitmap = new Bitmap(bitmapData);
					//bitmap.scaleX = bitmap.scaleY = 0.45;

					addChild(bitmap);
				}

				/**
				 * TEXT.
				 */
				if (type == AssetEmbedType.TEXT)
				{
					var textBytes:Bytes = Bytes.alloc(size);

					for (i in 0...size)
					{
						textBytes.set(i, -input.readByte());
					}

					var text:String = textBytes.getString(0, size, RawNative);
				}
			}
			catch (e)
			{
				break;
			}
		}

		//Sys.exit(0);

		#end
	}
}
