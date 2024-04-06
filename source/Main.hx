package;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.geom.Matrix;

typedef Transitioning =
{
	var _in:TransitioningInfo;
	var _out:TransitioningInfo;
}

typedef TransitioningInfo =
{
	var callback:Void->Void;
}

class Main extends Sprite
{
	private static final transitioning:Transitioning = {_in: null, _out: null};

	public static var game:Game;
	public static var transition:Sprite;

	public static var fpsTxt:TextField;

	public static var skipTransIn:Bool = false;
	public static var skipTransOut:Bool = false;

	public function new()
	{
		super();

		#if windows //DPI AWARENESS BABY
		@:functionCode('
			#include <Windows.h>
			SetProcessDPIAware();
		')
		#end

		// Before adding ``game``, create the transition

		var transitionMatrix:Matrix = new Matrix();
		transitionMatrix.createGradientBox(2560, 2880, Math.PI * 0.5);

		transition = new Sprite();
		transition.graphics.beginGradientFill(LINEAR, [0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000], [0, 1, 1, 0], [127, 157, 225, 255], transitionMatrix);
		transition.graphics.drawRect(0, 0, 2560, 2880);
		transition.graphics.endFill();
		transition.x = -transition.width * 0.5;

		SaveData.reloadSave();

		addChild(game = new Game());
		addChild(transition);

		fpsTxt = new TextField();
		fpsTxt.defaultTextFormat = new TextFormat(Paths.font('vcr'), 18, 0xFFFFFFFF, true);
		fpsTxt.selectable = false;
		fpsTxt.width = FlxG.width;
		addChild(fpsTxt);
	}

	public static function startTransition(_transIn:Bool = false, _callback:Void->Void = null):Void
	{
		if (_transIn)
		{
			if (skipTransIn)
			{
				transitionY = 720;

				if (null != _callback)
					_callback();

				return;
			}

			transitionY = -transition.height;

			if (null == transitioning._in)
				transitioning._in = {callback: _callback};
		}
		else
		{
			if (skipTransOut)
			{
				transitionY = 720;

				return;
			}

			transitionY = -transition.height * 0.6;

			if (null == transitioning._out)
				transitioning._out = {callback: _callback};
		}
	}

	private static var transitionY:Float = 0;
	private static var fps:Float = 60;
	public static function updateMain(elapsed:Float):Void
	{
		if (@:privateAccess FlxG.game._lostFocus && FlxG.autoPause)
			return;


		if (null != fpsTxt)
		{
			fps = inline Math.min(inline flixel.math.FlxMath.lerp(fps, 1 / FlxG.elapsed, 0.08), 1000.0);
			fpsTxt.text = 'FPS: ' + inline Std.int(fps) + '\nMEM: ' + inline flixel.util.FlxStringUtil.formatBytes(openfl.system.System.totalMemory);
		}

		transition.y = transitionY;

		if (transitionY < 720 * transition.scaleY)
			transitionY += (1585 * transition.scaleY) * elapsed;

		if (null != transitioning._in)
		{
			if (transitionY > -transition.height * 0.6)
			{
				if (null != transitioning._in.callback)
					transitioning._in.callback();
				transitioning._in = null;
			}
		}

		if (null != transitioning._out)
		{
			if (transitionY > 720 * transition.scaleY)
			{
				if (null != transitioning._out.callback)
					transitioning._out.callback();
				transitioning._out = null;
			}
		}

		transition.scaleX = FlxG.scaleMode.scale.x;
		transition.scaleY = FlxG.scaleMode.scale.y;
	}
}
