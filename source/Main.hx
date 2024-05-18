package;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.geom.Matrix;

import lime._internal.backend.native.NativeCFFI;
import haxe.CallStack;
import openfl.events.UncaughtErrorEvent;

import lime.ui.*;

using StringTools;

typedef Transitioning =
{
	var _in:TransitioningInfo;
	var _out:TransitioningInfo;
}

typedef TransitioningInfo =
{
	var callback:Void->Void;
}

// Keep these
@:access(lime.app.Application)
@:access(lime.ui.Gamepad)
@:access(lime.ui.Joystick)
@:access(lime._internal.backend.native.NativeApplication)
@:access(lime._internal.backend.native.NativeCFFI)

// Crash handler from psych btw
class Main extends Sprite
{
	static private final transitioning:Transitioning = {_in: null, _out: null};

	static public var game:Game;
	static public var transition:Sprite;

	static public var fpsTxt:TextField;
	static public var volumeTxt:TextField;

	static public var skipTransIn:Bool = false;
	static public var skipTransOut:Bool = false;

	private var keyboard:()->(Void);
	private var gamepad:()->(Void);

	static public var ENABLE_MULTITHREADING:Bool = false;
	static public var VSYNC = {ADAPTIVE: false, ENABLED: false};

	public function new()
	{
		super();

		HScriptSystem.init();

		openfl.Lib.current.stage.quality = stage.quality = LOW;

		var backend = lime.app.Application.current.__backend;

		NativeCFFI.lime_key_event_manager_register(keyboard = () ->
		{
			var keyEventInfo = backend.keyEventInfo;

			if (keyEventInfo.type == cast 1)
				Game.instance.onKeyUp.emit(SignalEvent.KEY_UP, Std.int(keyEventInfo.keyCode), keyEventInfo.modifier);

			if (keyEventInfo.type == cast 0)
			{
				Game.instance.onKeyDown.emit(SignalEvent.KEY_DOWN, Std.int(keyEventInfo.keyCode), keyEventInfo.modifier);

				if (keyEventInfo.keyCode == KeyCode.F11)
				{
					var window:Window = backend.parent.__windowByID.get(keyEventInfo.windowID);
					window.fullscreen = !window.fullscreen;
				}

				if (null != FlxG.sound && !Game.instance.blockSoundKeys)
				{
					if (keyEventInfo.keyCode == KeyCode.EQUALS)
					{
						FlxG.sound.volume = Math.min(FlxG.sound.volume + 0.1, 1.0);
						Main.volumeTxt.alpha = 1.0;
					}

					if (keyEventInfo.keyCode == KeyCode.MINUS)
					{
						FlxG.sound.volume = Math.max(FlxG.sound.volume - 0.1, 0.0);
						Main.volumeTxt.alpha = 1.0;
					}

					if (keyEventInfo.keyCode == KeyCode.NUMBER_0)
					{
						FlxG.sound.muted = !FlxG.sound.muted;
						Main.volumeTxt.alpha = 1.0;
					}
				}
			}
		}, backend.keyEventInfo);

		NativeCFFI.lime_gamepad_event_manager_register(gamepad = () ->
		{
			var gamepadEventInfo = backend.gamepadEventInfo;

			if (gamepadEventInfo.type == cast 0)
				Game.instance.onGamepadAxisMove.emit(SignalEvent.GAMEPAD_AXIS_MOVE, gamepadEventInfo.axis, gamepadEventInfo.axisValue);

			if (gamepadEventInfo.type == cast 1)
				Game.instance.onGamepadButtonDown.emit(SignalEvent.GAMEPAD_BUTTON_DOWN, gamepadEventInfo.button);

			if (gamepadEventInfo.type == cast 2)
				Game.instance.onGamepadButtonUp.emit(SignalEvent.GAMEPAD_BUTTON_UP, gamepadEventInfo.button);

			if (gamepadEventInfo.type == cast 3)
			{
				Gamepad.__connect(gamepadEventInfo.id);
				Game.instance.onGamepadConnect.emit(SignalEvent.GAMEPAD_CONNECT, gamepadEventInfo.id);
			}

			if (gamepadEventInfo.type == cast 4)
			{
				Gamepad.__disconnect(gamepadEventInfo.id);
				Game.instance.onGamepadDisconnect.emit(SignalEvent.GAMEPAD_DISCONNECT, gamepadEventInfo.id);
			}
		}, backend.gamepadEventInfo);

		NativeCFFI.lime_joystick_event_manager_register(null, backend.joystickEventInfo);

		// Before adding ``game``, create the transition

		var transitionMatrix:Matrix = new Matrix();
		transitionMatrix.createGradientBox(2560, 2880, Math.PI * 0.5);

		transition = new Sprite();
		transition.graphics.beginGradientFill(LINEAR, [0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000], [0, 1, 1, 0], [127, 157, 225, 255], transitionMatrix);
		transition.graphics.drawRect(0, 0, 2560, 2880);
		transition.graphics.endFill();
		transition.x = -transition.width * 0.5;

		SaveData.reloadSave();
		flixel.graphics.FlxGraphic.defaultPersist = SaveData.contents.graphics.persistentGraphics;
		ENABLE_MULTITHREADING = SaveData.contents.graphics.multithreading;
		VSYNC.ADAPTIVE = SaveData.contents.graphics.vsync.adaptive;
		VSYNC.ENABLED = SaveData.contents.graphics.vsync.enabled;

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

		#if debug
		// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
		// very cool person for real they don't get enough credit for their work
		openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, (e:UncaughtErrorEvent) ->
		{
			var errMsg:String = "";
			var path:String;
			var callStack:Array<StackItem> = CallStack.exceptionStack(true);
			var dateNow:String = Date.now().toString();

			dateNow = dateNow.replace(" ", "_");
			dateNow = dateNow.replace(":", "'");

			for (stackItem in callStack)
			{
				switch (stackItem)
				{
					case FilePos(s, file, line, column):
						errMsg += file + " (line " + line + ")\n";
					default:
						Sys.println(stackItem);
				}
			}

			errMsg += "\nUncaught Error: " + e.error + "\nPlease report this error to the GitHub page: https://github.com/ShadowMario/FNF-PsychEngine\n\n> Crash Handler written by: sqirra-rng";

			Sys.println(errMsg);

			lime.app.Application.current.window.alert(errMsg, "Error!");
			Sys.exit(1);
		});
		#end
	}

	static public function startTransition(_transIn:Bool = false, _callback:Void->Void = null):Void
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