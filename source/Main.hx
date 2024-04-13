package;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.geom.Matrix;

import lime.ui.*;

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
	public static var volumeTxt:TextField;

	public static var skipTransIn:Bool = false;
	public static var skipTransOut:Bool = false;

	public function new()
	{
		super();

		stage.quality = LOW;

		// Before adding ``game``, create the transition

		var transitionMatrix:Matrix = new Matrix();
		transitionMatrix.createGradientBox(2560, 2880, Math.PI * 0.5);

		transition = new Sprite();
		transition.graphics.beginGradientFill(LINEAR, [0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000], [0, 1, 1, 0], [127, 157, 225, 255], transitionMatrix);
		transition.graphics.drawRect(0, 0, 2560, 2880);
		transition.graphics.endFill();
		transition.x = -transition.width * 0.5;

		SaveData.reloadSave();
		flixel.graphics.FlxGraphic.defaultPersist = SaveData.contents.preferences.persistentGraphics;

		addChild(game = new Game());
		addChild(transition);

		fpsTxt = new TextField();
		fpsTxt.defaultTextFormat = new TextFormat(Paths.font('vcr'), 18, 0xFFFFFFFF, true);
		addChild(fpsTxt);

		volumeTxt = new TextField();
		volumeTxt.defaultTextFormat = new TextFormat(Paths.font('vcr'), 18, 0xFFFF0000, true);
		addChild(volumeTxt);

		var window:Window = stage.window;

		window.onKeyDown.add((keyCode:Int, keyModifier:Int) -> {
			Game.onKeyDown.emit(SignalEvent.KEY_DOWN, keyCode, keyModifier);

			if (keyCode == KeyCode.F11)
				window.fullscreen = !window.fullscreen;

			if (null != FlxG.sound && !Game.blockSoundKeys)
			{
				if (keyCode == KeyCode.EQUALS)
				{
					FlxG.sound.volume = Math.min(FlxG.sound.volume + 0.1, 1.0);
					Main.volumeTxt.alpha = 1.0;
				}

				if (keyCode == KeyCode.MINUS)
				{
					FlxG.sound.volume = Math.max(FlxG.sound.volume - 0.1, 0.0);
					Main.volumeTxt.alpha = 1.0;
				}

				if (keyCode == KeyCode.NUMBER_0)
				{
					FlxG.sound.muted = !FlxG.sound.muted;
					Main.volumeTxt.alpha = 1.0;
				}
			}
		});

		window.onKeyUp.add((keyCode:Int, keyModifier:Int) -> {
			Game.onKeyUp.emit(SignalEvent.KEY_UP, keyCode, keyModifier);
		});

		volumeTxt.selectable = fpsTxt.selectable = false;
		volumeTxt.width = fpsTxt.width = FlxG.width;
		volumeTxt.alpha = 0.0;
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

				skipTransIn = false;
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
				skipTransOut = false;
				return;
			}

			transitionY = -transition.height * 0.6;

			if (null == transitioning._out)
				transitioning._out = {callback: _callback};
		}
	}

	private static var transitionY:Float = 0.0;

	private static var fps:Float = 60.0;
	private static var fpsMax:Float = 60.0;
	public static function updateMain(elapsed:Float):Void
	{
		if (@:privateAccess FlxG.game._lostFocus && FlxG.autoPause)
			return;

		if (null != volumeTxt)
		{
			volumeTxt.y = (FlxG.height * FlxG.scaleMode.scale.y) - 20;
			volumeTxt.text = (FlxG.sound.muted ? 0.0 : Std.int(FlxG.sound.volume * 100.0)) + '%';
			volumeTxt.alpha -= elapsed * 2.0;
		}

		if (null != fpsTxt)
		{
			fps = inline Math.min(inline flixel.math.FlxMath.lerp(fps, 1.0 / elapsed, 0.01), 1000.0);

			if (fpsMax < fps)
				fpsMax = fps;

			fpsTxt.text = 'FPS: ' + Std.int(fps) + ' (MAX: ' + Std.int(fpsMax) + ')\nMEM: ' + flixel.util.FlxStringUtil.formatBytes(#if neko neko.vm.Gc.stats().heap #elseif hl hl.Gc.stats().currentMemory #elseif cpp cpp.vm.Gc.memInfo(3) #end);
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
