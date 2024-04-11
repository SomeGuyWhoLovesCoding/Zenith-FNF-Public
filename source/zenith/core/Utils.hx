package zenith.core;

import openfl.Lib;
import lime.graphics.opengl.GL;
import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.display3D.textures.TextureBase;

class Utils
{
	inline static public var SLASH:String = #if linux '/' #else '\\' #end ;

	// If you want to reduce RAM usage, this is for you

	inline static public function toTexture(source:BitmapData):BitmapData
	{
		if (SaveData.contents.preferences.gpuCaching && source.readable && !GL.isContextLost())
		{
			var context:Context3D = Lib.current.stage.context3D;
			var texture:TextureBase = source.getTexture(context);
			return BitmapData.fromTexture(texture);
		}

		return source;
	}
}