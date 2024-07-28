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
	var _in:Void->Void;
	var _out:Void->Void;
}

@:access(lime.app.Application)
@:access(lime._internal.backend.native.NativeApplication)
@:access(lime._internal.backend.native.NativeCFFI)
@:access(zenith.Gameplay)
@:access(flixel.FlxGame)
class Main extends Sprite
{
	static public var conductor:Conductor;

	#if (SCRIPTING_ALLOWED && hscript)
	static public var hscript:HScriptSystem;
	#end

	static private final transitioning:Transitioning = {_in: function() {}, _out: function() {}};

	static public var game:Game;
	static public var transition:Sprite;

	static public var fpsTxt:TextField;
	static public var volumeTxt:TextField;

	static public var skipTransIn:Bool = false;
	static public var skipTransOut:Bool = false;

	public function new()
	{
		super();

		SaveData.read();

		conductor = new Conductor();

		#if (SCRIPTING_ALLOWED && hscript)
		hscript = new HScriptSystem();
		hscript.callFromAllScripts('onGameBoot');
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

		addChild(game = new Game());
		addChild(transition);
		FlxG.signals.postStateSwitch.add(openfl.system.System.gc);

		if (SaveData.contents.graphics.showFPS)
		{
			fpsTxt = new TextField();
			fpsTxt.defaultTextFormat = new TextFormat(AssetManager.font('vcr'), 18, 0xFFFFFFFF, true);
			fpsTxt.selectable = false;
			fpsTxt.width = 400;
			fpsTxt.text = 'FPS: 0 (MAX: 0)\nRAM: 0Bytes (MEM: 0Bytes)';
			addChild(fpsTxt);
		}

		volumeTxt = new TextField();
		volumeTxt.defaultTextFormat = new TextFormat(AssetManager.font('vcr'), 18, 0xFFFF0000, true);
		volumeTxt.selectable = false;
		volumeTxt.width = 72;
		volumeTxt.alpha = 0;
		addChild(volumeTxt);

		openfl.Lib.current.stage.quality = stage.quality = LOW;

		___initInternalModifications();
	}

	static public function startTransition(_transIn:Bool = false, _callback:Void->Void)
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

			transitioning._in = _callback;
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

			transitioning._out = _callback;
		}
	}

	static private var transitionY:Float = 0;

	static private var fps:Int = 60;
	static private var fpsMax:Int = 60;
	static private var fpsTextTimer:Float = 0;

	static public function updateMain(elapsed:Float)
	{
		if (game._lostFocus && FlxG.autoPause)
		{
			return;
		}

		// Framerate rework
		fps += fps > Std.int(1 / elapsed) ? -1 : 1;

		if (volumeTxt != null)
		{
			volumeTxt.y = (FlxG.height * FlxG.scaleMode.scale.y) - 20;
			volumeTxt.text = (FlxG.sound.muted ? 0 : Std.int(FlxG.sound.volume * 100)) + '%';
			volumeTxt.alpha -= elapsed * 2;
		}

		fpsTextTimer += elapsed;

		if (SaveData.contents.graphics.showFPS && fpsTextTimer > 1)
		{
			if (fpsMax < fps)
				fpsMax = fps;

			fpsTxt.text = 'FPS: '
				+ fps
				+ ' (MAX: '
				+ fpsMax
				+ ')\nRAM: '
				+ flixel.util.FlxStringUtil.formatBytes(#if hl hl.Gc.stats().currentMemory #elseif cpp cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_RESERVED) #end)
				+ ' (MEM: '
				+ flixel.util.FlxStringUtil.formatBytes(openfl.Lib.current.stage.context3D.totalGPUMemory)
				+ ')';
			fpsTextTimer = elapsed;
		}

		transition.scaleX = FlxG.scaleMode.scale.x;
		transition.scaleY = FlxG.scaleMode.scale.y;

		transition.y = transitionY;

		if (transitionY < 720 * transition.scaleY)
		{
			transitionY += (1585 * transition.scaleY) * elapsed;
		}

		if (transitioning._in != (function() {}) && transitionY > -transition.height * 0.6)
		{
			transitioning._in();
			transitioning._in = function() {}
		}

		if (transitioning._out != (function() {}) && transitionY > 720 * transition.scaleY)
		{
			transitioning._out();
			transitioning._out = function() {}
		}
	}

	static function ___initInternalModifications()
	{
		var backend = lime.app.Application.current.__backend;

		var window:Window;
		NativeCFFI.lime_key_event_manager_register(function()
		{
			if (backend.keyEventInfo.type == KEY_UP)
			{
				if (Gameplay.instance == FlxG.state && !Gameplay.instance?.paused)
				{
					Gameplay.instance.onKeyUp(Std.int(backend.keyEventInfo.keyCode), backend.keyEventInfo.modifier);
				}
				else
				{
					game.onKeyUp.dispatch(Std.int(backend.keyEventInfo.keyCode), backend.keyEventInfo.modifier);
				}
			}

			if (backend.keyEventInfo.type == KEY_DOWN)
			{
				if (Gameplay.instance == FlxG.state && !Gameplay.instance?.paused)
				{
					Gameplay.instance.onKeyDown(Std.int(backend.keyEventInfo.keyCode), backend.keyEventInfo.modifier);
				}
				else
				{
					game.onKeyDown.dispatch(Std.int(backend.keyEventInfo.keyCode), backend.keyEventInfo.modifier);
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
						FlxG.sound.volume = Math.min(FlxG.sound.volume + 0.1, 1);
						Main.volumeTxt.alpha = 1;
					}

					if (backend.keyEventInfo.keyCode == KeyCode.MINUS)
					{
						FlxG.sound.muted = false;
						FlxG.sound.volume = Math.max(FlxG.sound.volume - 0.1, 0);
						Main.volumeTxt.alpha = 1;
					}

					if (backend.keyEventInfo.keyCode == KeyCode.NUMBER_0)
					{
						FlxG.sound.muted = !FlxG.sound.muted;
						Main.volumeTxt.alpha = 1;
					}
				}
			}
		}, backend.keyEventInfo);

		NativeCFFI.lime_mouse_event_manager_register(function()
		{
			if (backend.mouseEventInfo.type == cast 0)
			{
				game.onMouseDown.dispatch(backend.mouseEventInfo.x, backend.mouseEventInfo.y, backend.mouseEventInfo.button);
			}

			if (backend.mouseEventInfo.type == cast 1)
			{
				game.onMouseUp.dispatch(backend.mouseEventInfo.x, backend.mouseEventInfo.y, backend.mouseEventInfo.button);
			}
		}, backend.mouseEventInfo);

		NativeCFFI.lime_application_event_manager_register(function()
		{
			if (backend.applicationEventInfo.type == UPDATE)
			{
				backend.updateTimer();
				backend.parent.onUpdate.dispatch(backend.applicationEventInfo.deltaTime);
			}
		}, backend.applicationEventInfo);

		// You don't really need those as they're either very hard to press keys or they're flat out unneeded
		NativeCFFI.lime_sensor_event_manager_register(function() {}, backend.sensorEventInfo);
		NativeCFFI.lime_touch_event_manager_register(function() {},
			backend.touchEventInfo); // Might do android support for fnf zenith but idk about that since it's not in my priority list lmao
		NativeCFFI.lime_gamepad_event_manager_register(function() {}, backend.gamepadEventInfo);
		NativeCFFI.lime_joystick_event_manager_register(function() {}, backend.joystickEventInfo);
	}
}
