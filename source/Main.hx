package;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.geom.Matrix;
import lime._internal.backend.native.NativeCFFI;
import lime.ui.Window;
import lime.ui.KeyCode;

using StringTools;

typedef Transitioning =
{
	var _in:TransitioningInfo;
	var _out:TransitioningInfo;
}

typedef TransitioningInfo =
{
	var callback:()->Void;
}

@:access(lime.app.Application)
@:access(lime._internal.backend.native.NativeApplication)
@:access(lime._internal.backend.native.NativeCFFI)
@:access(zenith.Gameplay)
@:access(flixel.FlxGame)

class Main extends Sprite
{
	static public var conductor:Conductor;

	#if SCRIPTING_ALLOWED
	static public var hscript:HScriptSystem;
	#end

	static private final transitioning:Transitioning = {_in: null, _out: null};

	static public var game:Game;
	static public var transition:Sprite;

	static public var fpsTxt:TextField;
	static public var volumeTxt:TextField;

	static public var skipTransIn:Bool = false;
	static public var skipTransOut:Bool = false;

	static public var ENABLE_MULTITHREADING:Bool = false;

	public function new()
	{
		super();

		SaveData.read();

		// Some benchmark I did
		/*trace("Optimized List");

		var list:linkedlist.LinkedList<linkedlist.LinkedListItem> = new linkedlist.LinkedList<linkedlist.LinkedListItem>();

		trace("Add");
		haxe.Timer.measure(function():Void
		{
			for (i in 0...1000000)
			{
				list.push(i);
			}
		});

		trace("Pop");
		haxe.Timer.measure(function():Void
		{
			for (i in 0...1000000)
			{
				list.pop();
			}
		});*/

		conductor = new Conductor();
	
		#if SCRIPTING_ALLOWED
		hscript = new HScriptSystem();
		hscript.callFromAllScripts(HScriptFunctions.GAME_BOOT);
		#end

		// Before adding ``game``, create the transition

		var transitionMatrix:Matrix = new Matrix();
		transitionMatrix.createGradientBox(2560, 2880, Math.PI * 0.5);

		transition = new Sprite();
		transition.graphics.beginGradientFill(LINEAR, [0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000], [0, 1, 1, 0], [127, 157, 225, 255], transitionMatrix);
		transition.graphics.drawRect(0, 0, 2560, 2880);
		transition.graphics.endFill();
		transition.x = -transition.width * 0.5;

		flixel.graphics.FlxGraphic.defaultPersist = SaveData.contents.graphics.persistentGraphics;
		ENABLE_MULTITHREADING = SaveData.contents.experimental.multithreading;

		addChild(game = new Game());
		addChild(transition);

		fpsTxt = new TextField();
		fpsTxt.defaultTextFormat = new TextFormat(Paths.font('vcr'), 18, 0xFFFFFFFF, true);
		addChild(fpsTxt);

		volumeTxt = new TextField();
		volumeTxt.defaultTextFormat = new TextFormat(Paths.font('vcr'), 18, 0xFFFF0000, true);
		addChild(volumeTxt);

		volumeTxt.selectable = fpsTxt.selectable = false;
		volumeTxt.width = fpsTxt.width = FlxG.width;
		volumeTxt.alpha = 0.0;

		openfl.Lib.current.stage.quality = stage.quality = LOW;

		var backend = lime.app.Application.current.__backend;

		var window:Window;
		NativeCFFI.lime_key_event_manager_register(function():Void
		{
			if (FlxG.game._lostFocus && FlxG.autoPause) // How come none other fnf engines do this? I wonder why lol
			{
				return;
			}

			if (Gameplay.instance != null && FlxG.state == Gameplay.instance)
			{
				if (backend.keyEventInfo.type == cast 1)
				{
					if (!Gameplay.instance.paused)
					{
						Gameplay.instance.onKeyUp(Std.int(backend.keyEventInfo.keyCode), backend.keyEventInfo.modifier);
					}
					else
					{
						game.onKeyUp.emit(SignalEvent.KEY_UP, Std.int(backend.keyEventInfo.keyCode), backend.keyEventInfo.modifier);
					}
				}
			}

			if (backend.keyEventInfo.type == cast 0)
			{
				if (Gameplay.instance != null && FlxG.state == Gameplay.instance && !Gameplay.instance.paused)
				{
					Gameplay.instance.onKeyDown(Std.int(backend.keyEventInfo.keyCode), backend.keyEventInfo.modifier);
				}
				else
				{
					game.onKeyDown.emit(SignalEvent.KEY_DOWN, Std.int(backend.keyEventInfo.keyCode), backend.keyEventInfo.modifier);
				}

				if (backend.keyEventInfo.keyCode == KeyCode.F11)
				{
					window = backend.parent.__windowByID.get(backend.keyEventInfo.windowID);
					window.fullscreen = !window.fullscreen;
				}

				if (null != FlxG.sound && !game.blockSoundKeys)
				{
					if (backend.keyEventInfo.keyCode == KeyCode.EQUALS)
					{
						FlxG.sound.muted = false;
						FlxG.sound.volume = Math.min(FlxG.sound.volume + 0.1, 1.0);
						Main.volumeTxt.alpha = 1.0;
					}

					if (backend.keyEventInfo.keyCode == KeyCode.MINUS)
					{
						FlxG.sound.muted = false;
						FlxG.sound.volume = Math.max(FlxG.sound.volume - 0.1, 0.0);
						Main.volumeTxt.alpha = 1.0;
					}

					if (backend.keyEventInfo.keyCode == KeyCode.NUMBER_0)
					{
						FlxG.sound.muted = !FlxG.sound.muted;
						Main.volumeTxt.alpha = 1.0;
					}
				}
			}
		}, backend.keyEventInfo);

		NativeCFFI.lime_application_event_manager_register(function():Void
		{
			if (FlxG.game._lostFocus && FlxG.autoPause) // How come none other fnf engines do this? I wonder why lol
			{
				return;
			}

			if (backend.applicationEventInfo.type == UPDATE)
			{
				backend.updateTimer();
				backend.parent.onUpdate.dispatch(backend.applicationEventInfo.deltaTime);
			}
		}, backend.applicationEventInfo);
		NativeCFFI.lime_sensor_event_manager_register(function():Void {}, backend.sensorEventInfo);
		NativeCFFI.lime_touch_event_manager_register(function():Void {}, backend.touchEventInfo);
		NativeCFFI.lime_gamepad_event_manager_register(function():Void {}, backend.gamepadEventInfo);
		NativeCFFI.lime_joystick_event_manager_register(function():Void {}, backend.joystickEventInfo);
	}

	static public function startTransition(_transIn:Bool = false, _callback:()->Void):Void
	{
		if (_transIn)
		{
			if (skipTransIn)
			{
				transitionY = 720.0;

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
				transitionY = 720.0;
				skipTransOut = false;
				return;
			}

			transitionY = -transition.height * 0.6;

			if (null == transitioning._out)
				transitioning._out = {callback: _callback};
		}
	}

	static private var transitionY:Float = 0.0;

	static private var fps:Int = 60;
	static private var fpsMax:Int = 60;
	static public function updateMain(elapsed:Float):Void
	{
		if (@:privateAccess FlxG.game._lostFocus && FlxG.autoPause)
			return;

		// Framerate rework
		fps += fps > Math.round(1 / elapsed) ? -1 : 1;

		if (null != volumeTxt)
		{
			volumeTxt.y = (FlxG.height * FlxG.scaleMode.scale.y) - 20.0;
			volumeTxt.text = (FlxG.sound.muted ? 0.0 : Std.int(FlxG.sound.volume * 100.0)) + '%';
			volumeTxt.alpha -= elapsed * 2.0;
		}

		if (null != fpsTxt)
		{
			if (fpsMax < fps)
				fpsMax = fps;

			fpsTxt.text = 'FPS: ' + fps + ' (MAX: ' + fpsMax + ')\nMEM: ' + flixel.util.FlxStringUtil.formatBytes(#if hl hl.Gc.stats().currentMemory #elseif cpp cpp.vm.Gc.memInfo(3) #end);
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
				transitioning._in;
			}
		}

		if (null != transitioning._out)
		{
			if (transitionY > 720 * transition.scaleY)
			{
				if (null != transitioning._out.callback)
					transitioning._out.callback();
				transitioning._out;
			}
		}

		transition.scaleX = FlxG.scaleMode.scale.x;
		transition.scaleY = FlxG.scaleMode.scale.y;
	}
}
