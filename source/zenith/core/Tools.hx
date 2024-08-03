package zenith.core;

import openfl.display.BitmapData;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class Tools
{
	// GPU Texture system
	private static var textures:Map<String, openfl.display3D.textures.RectangleTexture> = [];

	static public function toTexture(source:BitmapData, key:String):BitmapData
	{
		#if !hl
		if (SaveData.contents.graphics.gpuCaching && source.readable && !lime.graphics.opengl.GL.isContextLost())
		{
			if (textures.exists(key))
			{
				return BitmapData.fromTexture(@:bypassAccessor textures[key]);
			}

			var texture = openfl.Lib.current.stage.context3D.createRectangleTexture(source.width, source.height, BGRA, false);
			texture.uploadFromBitmapData(source);
			source.disposeImage();
			source.dispose();
			source = null;
			@:bypassAccessor textures[key] = texture;

			openfl.system.System.gc();

			return BitmapData.fromTexture(texture);
		}
		#end

		return source;
	}

	static public function strumlineSwap(left:Int, right:Int):Void
	{
		try
		{
			var diff1 = (Gameplay.instance.strumlines[left].x - Gameplay.instance.strumlines[right].x);
			var diff2 = (Gameplay.instance.strumlines[right].x - Gameplay.instance.strumlines[left].x);
			Gameplay.instance.strumlines[left].x -= diff1;
			Gameplay.instance.strumlines[right].x -= diff2;
		}
		catch (e:haxe.Exception)
		{
			#if (SCRIPTING_ALLOWED && hscript)
			HScriptFrontend.error(e);
			#end
		}
	}

	private static var strumYTweens(default, null):Map<StrumNote, FlxTween> = new Map<StrumNote, FlxTween>();
	private static var strumScrollMultTweens(default, null):Map<StrumNote, FlxTween> = new Map<StrumNote, FlxTween>();

	static public function strumlineChangeDownScroll(whichStrum:Int = -1, tween:Bool = false, tweenLength:Float = 1.0):Void
	{
		// Strumline
		var strumlines = Gameplay.instance.strumlines;

		for (strumline in strumlines)
		{
			for (strum in strumline.members)
			{
				if (strum.player == whichStrum || whichStrum == -1)
				{
					if (tween && tweenLength != 0.0)
					{
						var actualScrollMult = strum.scrollMult;
						actualScrollMult = -actualScrollMult;

						var scrollMultTween = strumScrollMultTweens[strum];
						var yTween = strumYTweens[strum];

						if (null != scrollMultTween)
							scrollMultTween.cancel();

						strumScrollMultTweens.set(strum,
							FlxTween.tween(strum, {scrollMult: strum.scrollMult > 0.0 ? -1.0 : 1.0}, (tweenLength < 0.0 ? -tweenLength : tweenLength),
								{ease: FlxEase.quintOut}));

						if (null != yTween)
							yTween.cancel();

						strumYTweens.set(strum,
							FlxTween.tween(strum, {y: actualScrollMult < 0.0 ? FlxG.height - 160 : 60}, (tweenLength < 0.0 ? -tweenLength : tweenLength),
								{ease: FlxEase.quintOut}));
					}
					else
					{
						strum.scrollMult = -strum.scrollMult;
					}
				}

				if (strum.noteData == strumline.keys - 1)
				{
					strumline.downScroll = strum.scrollMult < 0.0;
				}
			}
			strumline.y = strumline.downScroll ? FlxG.height - 160 : 60;
		}
	}

	/**
	 * Format seconds as minutes with a colon, an optionally with milliseconds too.
	 *
	 * @param	ms		The number of seconds (for example, time remaining, time spent, etc).
	 * @param	EnglishStyle		Whether to show a ":" instead of a ";".
	 * @param	showMS		Whether to show a "." after seconds aswell.
	 * @return	A nicely formatted String, like "1:03.45".
	 */
	static public function formatTime(ms:Float, englishStyle:Bool, showMS:Bool):String
	{
		// Rewritten code??? Moment when I use ChatGPT:
		var milliseconds:Float = Math.ffloor(ms * 0.1) % 100.0;
		var seconds:Float = Math.ffloor(ms * 0.001);
		var hours:Float = Math.ffloor(seconds / 3600.0);
		seconds %= 3600.0;
		var minutes:Float = Math.ffloor(seconds / 60.0);
		seconds %= 60.0;

		var t:String = englishStyle ? ':' : ';';

		var c:String = englishStyle ? '.' : ',';

		var time:String = '';
		if (!Math.isNaN(ms))
		{
			if (hours > 0)
				time += '$hours$t';
			time += '${minutes < 10.0 && hours > 0.0 ? '0' : ''}$minutes$t';
			if (seconds < 10.0)
				time += '0';
			time += seconds;
		}
		else
			time = 'NaN';

		if (showMS)
		{
			if (milliseconds < 10.0)
				time += '${c}0$milliseconds';
			else
				time += '${c}$milliseconds';
		}

		return time;
	}
}
