package zenith.core;

import openfl.Lib;
import openfl.display.BitmapData;
import lime.graphics.opengl.GL;
import openfl.display3D.Context3D;
import openfl.display3D.textures.TextureBase;

class BitmapDataUtils
{
	public static function toTexture(source:BitmapData):BitmapData
	{
		if (source.readable && !GL.isContextLost())
		{
			var context:Context3D = Lib.current.stage.context3D;
			var texture:TextureBase = source.getTexture(context);
			@:privateAccess texture.__optimizeForRenderToTexture = true;
			return BitmapData.fromTexture(texture);
		}

		return source;
	}
}