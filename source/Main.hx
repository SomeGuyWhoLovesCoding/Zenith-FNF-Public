package;

import openfl.display.Sprite;
import openfl.display.DisplayObject;
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

/**
 * The main class.
 * **WARNING**: The end of it is terrible. Watch out.
 */
@:access(lime.app.Application)
@:access(lime._internal.backend.native.NativeApplication)
@:access(lime._internal.backend.native.NativeCFFI)
@:access(zenith.Gameplay)
@:access(flixel.FlxGame)
@:publicFields
class Main extends Sprite
{
	static var conductor:Conductor;

	#if (SCRIPTING_ALLOWED && hscript)
	static var hscript:HScriptFrontend;
	#end

	static private final transitioning:Transitioning = {_in: function() {}, _out: function() {}};

	static var game:Game;
	static var transition:Sprite;

	static var fpsTxt:TextField;
	static var volumeTxt:TextField;

	static var skipTransIn:Bool = false;
	static var skipTransOut:Bool = false;

	function new()
	{
		super();

		SaveData.read();

		conductor = new Conductor();

		#if (SCRIPTING_ALLOWED && hscript)
		hscript = new HScriptFrontend();
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

	static function startTransition(_transIn:Bool = false, _callback:Void->Void)
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

	static function updateMain(elapsed:Float)
	{
		if (game._lostFocus && FlxG.autoPause)
		{
			return;
		}

		// Framerate rework
		fps += fps > Math.floor(1 / elapsed) ? -1 : 1;

		if (volumeTxt != null)
		{
			volumeTxt.y = (FlxG.height * FlxG.scaleMode.scale.y) - 20;
			volumeTxt.text = (FlxG.sound.muted ? 0 : Math.floor(FlxG.sound.volume * 100)) + '%';
			volumeTxt.alpha -= elapsed * 2;
		}

		fpsTextTimer += elapsed;

		if (SaveData.contents.graphics.showFPS && fpsTextTimer > 0.115)
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
				+ flixel.util.FlxStringUtil.formatBytes(FlxG.stage.context3D.totalGPUMemory)
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

	// Get rid of hit test function because mouse memory ramp up during first move (-Bolo)
    @:noCompletion override function __hitTest(x:Float, y:Float, shapeFlag:Bool, stack:Array<DisplayObject>, interactiveOnly:Bool, hitObject:DisplayObject):Bool return false;
    @:noCompletion override function __hitTestHitArea(x:Float, y:Float, shapeFlag:Bool, stack:Array<DisplayObject>, interactiveOnly:Bool, hitObject:DisplayObject):Bool return false;
    @:noCompletion override function __hitTestMask(x:Float, y:Float):Bool return false;

	@:noCompletion static private function ___initInternalModifications()
	{
		var backend = lime.app.Application.current.__backend;

		var window:Window;
		NativeCFFI.lime_key_event_manager_register(function()
		{
			var gameinst = Gameplay.instance;

			var kei = backend.keyEventInfo;
			var kc = kei.keyCode;
			var km = kei.modifier;

			if (kei.type == KEY_UP)
			{
				if (gameinst != null && gameinst == FlxG.state && !gameinst.paused)
				{
					gameinst.onKeyUp(Math.floor(kc), km);
				}
				else
				{
					game.onKeyUp.dispatch(Math.floor(kc), km);
				}
			}

			if (kei.type == KEY_DOWN)
			{
				if (gameinst != null && gameinst == FlxG.state && !gameinst.paused)
				{
					gameinst.onKeyDown(Math.floor(kc), km);
				}
				else
				{
					game.onKeyDown.dispatch(Math.floor(kc), km);
				}

				if (kc == KeyCode.F11)
				{
					window = backend.parent.__windowByID.get(kei.windowID);
					window.fullscreen = !window.fullscreen;
				}

				if (null != FlxG.sound && !game.blockSoundKeys)
				{
					if (kc == KeyCode.EQUALS)
					{
						FlxG.sound.muted = false;
						FlxG.sound.volume = Math.min(FlxG.sound.volume + 0.1, 1);
						Main.volumeTxt.alpha = 1;
					}

					if (kc == KeyCode.MINUS)
					{
						FlxG.sound.muted = false;
						FlxG.sound.volume = Math.max(FlxG.sound.volume - 0.1, 0);
						Main.volumeTxt.alpha = 1;
					}

					if (kc == KeyCode.NUMBER_0)
					{
						FlxG.sound.muted = !FlxG.sound.muted;
						Main.volumeTxt.alpha = 1;
					}
				}
			}
		}, backend.keyEventInfo);

		NativeCFFI.lime_mouse_event_manager_register(function()
		{
			var mei = backend.mouseEventInfo;

			if (mei.type == cast 0)
			{
				game.onMouseDown.dispatch(mei.x, mei.y, mei.button);
			}

			if (mei.type == cast 1)
			{
				game.onMouseUp.dispatch(mei.x, mei.y, mei.button);
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
		// Side note: m ight do android support for fnf zenith but idk about that since it's not in my priority list lmao
		NativeCFFI.lime_sensor_event_manager_register(function() {}, backend.sensorEventInfo);
		NativeCFFI.lime_touch_event_manager_register(function() {}, backend.touchEventInfo);
		NativeCFFI.lime_gamepad_event_manager_register(function() {}, backend.gamepadEventInfo);
		NativeCFFI.lime_joystick_event_manager_register(function() {}, backend.joystickEventInfo);
	}
}
