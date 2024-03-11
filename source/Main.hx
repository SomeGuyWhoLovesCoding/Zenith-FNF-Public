package;

import openfl.display.Sprite;
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

	public static var skipTransIn:Bool = false;
	public static var skipTransOut:Bool = false;

	public function new()
	{
		super();

		// Before adding ``game``, create the transition

		var transitionMatrix:Matrix = new Matrix();
		transitionMatrix.createGradientBox(2560, 2880, Math.PI * 0.5);

		transition = new Sprite();
		transition.graphics.beginGradientFill(LINEAR, [0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000], [0, 1, 1, 0], [127, 157, 225, 255], transitionMatrix);
		transition.graphics.drawRect(0, 0, 2560, 2880);
		transition.graphics.endFill();
		transition.x = -transition.width * 0.5;

		addChild(game = new Game());
		addChild(transition);

		addEventListener("enterFrame", onTransitionUpdate);
	}

	public static function startTransition(_transIn:Bool = false, _callback:Void->Void = null):Void
	{
		if (_transIn)
		{
			if (skipTransIn)
			{
				transitionY = 720;

				if (_callback != null)
					_callback();

				return;
			}

			transitionY = -transition.height;

			if (transitioning._in == null)
				transitioning._in = {callback: _callback};
		}
		else
		{
			if (skipTransOut)
			{
				transitionY = 720;

				return;
			}

			transitionY = -transition.height * 0.65;

			if (transitioning._out == null)
				transitioning._out = {callback: _callback};
		}
	}

	private static var transitionY:Float = 0;
	function onTransitionUpdate(_):Void
	{
		if (@:privateAccess FlxG.game._lostFocus)
			return;

		transition.y = transitionY;

		if (transitionY < 720 * transition.scaleY)
			transitionY += 30 * transition.scaleY;

		if (transitioning._in != null)
		{
			if (transitionY > -transition.height * 0.65)
			{
				if (transitioning._in.callback != null)
					transitioning._in.callback();
				transitioning._in = null;
			}
		}

		if (transitioning._out != null)
		{
			if (transitionY > 720 * transition.scaleY)
				transitioning._out = null;
		}

		transition.scaleX = FlxG.scaleMode.scale.x;
		transition.scaleY = FlxG.scaleMode.scale.y;
	}
}
