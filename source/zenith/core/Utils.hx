package zenith.core;

import openfl.Lib;
import lime.graphics.opengl.GL;
import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.display3D.textures.TextureBase;

class Utils
{
	inline static public var SLASH:String = #if linux '\\' #else '/' #end ;

	// If you want to reduce RAM usage, this is for you

	static public function toTexture(source:BitmapData):BitmapData
	{
		#if !hl
		if (SaveData.contents.preferences.gpuCaching && source.readable && !GL.isContextLost())
		{
			var context:Context3D = Lib.current.stage.context3D;
			var texture:TextureBase = source.getTexture(context);
			return BitmapData.fromTexture(texture);
		}
		#end

		return source;
	}

	/**
	* Format seconds as minutes with a colon, an optionally with milliseconds too.
	*
	* @param	ms		The number of seconds (for example, time remaining, time spent, etc).
	* @param	EnglishStyle		Whether to show a ":" instead of a ";".
	* @param	showMS		Whether to show a "." after seconds aswell.
	* @return	A nicely formatted String, like "1:03.45".
	*/
	inline public static function formatTime(ms:Float, englishStyle:Bool, showMS:Bool):String
	{
		// Rewritten code??? Moment when I use ChatGPT:
		var milliseconds:Int = Std.int(ms * 0.1) % 100;
		var seconds:Int = Std.int(ms * 0.001);
		var hours:Int = Std.int(seconds / 3600);
		seconds %= 3600;
		var minutes:Int = Std.int(seconds / 60);
		seconds %= 60;

		var t:String = ';';

		if (englishStyle)
			t = ':';

		var c:String = ',';

		if (englishStyle)
			c = '.';

		var time:String = '';
		if (!Math.isNaN(ms)) {
			if (hours > 0) time += '$hours$t';
			time += '${minutes < 10 && hours > 0 ? '0' : ''}$minutes$t';
			if (seconds < 10) time += '0';
			time += seconds;
		} else
			time = 'NaN';

		if (showMS) {
			if (milliseconds < 10) 
				time += '${c}0$milliseconds';
			else
				time += '${c}$milliseconds';
		}

		return time;
	}
}