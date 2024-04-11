package lime._internal.backend.native;

import haxe.Int64;
import haxe.Timer;
import lime._internal.backend.native.NativeCFFI;
import lime.app.Application;
import lime.graphics.opengl.GL;
import lime.graphics.OpenGLRenderContext;
import lime.graphics.RenderContext;
import lime.math.Rectangle;
import lime.media.AudioManager;
import lime.system.Clipboard;
import lime.system.Display;
import lime.system.DisplayMode;
import lime.system.JNI;
import lime.system.Sensor;
import lime.system.SensorType;
import lime.system.System;
import lime.ui.Gamepad;
import lime.ui.Joystick;
import lime.ui.JoystickHatPosition;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Touch;
import lime.ui.Window;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(haxe.Timer)
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime._internal.backend.native.NativeOpenGLRenderContext)
@:access(lime._internal.backend.native.NativeWindow)
@:access(lime.app.Application)
@:access(lime.graphics.opengl.GL)
@:access(lime.graphics.OpenGLRenderContext)
@:access(lime.graphics.Renderer)
@:access(lime.system.Clipboard)
@:access(lime.system.Sensor)
@:access(lime.ui.Gamepad)
@:access(lime.ui.Joystick)
@:access(lime.ui.Window)
class NativeApplication
{
	private var applicationEventInfo:ApplicationEventInfo = new ApplicationEventInfo(UPDATE);
	private var clipboardEventInfo:ClipboardEventInfo = new ClipboardEventInfo();
	private var currentTouches:Map<Int, Touch> = new Map<Int, Touch>();
	private var dropEventInfo:DropEventInfo = new DropEventInfo();
	private var gamepadEventInfo:GamepadEventInfo = new GamepadEventInfo();
	private var joystickEventInfo:JoystickEventInfo = new JoystickEventInfo();
	private var keyEventInfo:KeyEventInfo = new KeyEventInfo();
	private var mouseEventInfo:MouseEventInfo = new MouseEventInfo();
	private var renderEventInfo:RenderEventInfo = new RenderEventInfo(RENDER);
	private var sensorEventInfo:SensorEventInfo = new SensorEventInfo();
	private var textEventInfo:TextEventInfo = new TextEventInfo();
	private var touchEventInfo:TouchEventInfo = new TouchEventInfo();
	private var unusedTouchesPool:List<Touch> = new List<Touch>();
	private var windowEventInfo:WindowEventInfo = new WindowEventInfo();

	public var handle:Dynamic;

	private var pauseTimer:Int;
	private var parent:Application;

	private static function __init__()
	{
		#if (lime_cffi && !macro)
		var init = NativeCFFI;
		#end
	}

	public function new(parent:Application):Void
	{
		this.parent = parent;
		pauseTimer = -1;

		AudioManager.init();

		#if (ios || android || tvos)
		Sensor.registerSensor(SensorType.ACCELEROMETER, 0);
		#end

		#if (!macro && lime_cffi)
		handle = NativeCFFI.lime_application_create();
		#end
	}

	private function advanceTimer():Void
	{
		#if lime_cffi
		if (pauseTimer > -1)
		{
			var offset = System.getTimer() - pauseTimer;
			for (i in 0...Timer.sRunningTimers.length)
			{
				if (Timer.sRunningTimers[i] != null) Timer.sRunningTimers[i].mFireAt += offset;
			}
			pauseTimer = -1;
		}
		#end
	}

	public function exec():Int
	{
		#if !macro
		#if lime_cffi
		NativeCFFI.lime_application_event_manager_register(handleApplicationEvent, applicationEventInfo);
		NativeCFFI.lime_clipboard_event_manager_register(handleClipboardEvent, clipboardEventInfo);
		NativeCFFI.lime_drop_event_manager_register(handleDropEvent, dropEventInfo);
		NativeCFFI.lime_gamepad_event_manager_register(handleGamepadEvent, gamepadEventInfo);
		NativeCFFI.lime_joystick_event_manager_register(handleJoystickEvent, joystickEventInfo);
		NativeCFFI.lime_key_event_manager_register(handleKeyEvent, keyEventInfo);
		NativeCFFI.lime_mouse_event_manager_register(handleMouseEvent, mouseEventInfo);
		NativeCFFI.lime_render_event_manager_register(handleRenderEvent, renderEventInfo);
		NativeCFFI.lime_text_event_manager_register(handleTextEvent, textEventInfo);
		NativeCFFI.lime_touch_event_manager_register(handleTouchEvent, touchEventInfo);
		NativeCFFI.lime_window_event_manager_register(handleWindowEvent, windowEventInfo);
		#if (ios || android || tvos)
		NativeCFFI.lime_sensor_event_manager_register(handleSensorEvent, sensorEventInfo);
		#end
		#end

		#if (nodejs && lime_cffi)
		NativeCFFI.lime_application_init(handle);

		var eventLoop = function()
		{
			var active = NativeCFFI.lime_application_update(handle);

			if (!active)
			{
				untyped process.exitCode = NativeCFFI.lime_application_quit(handle);
				parent.onExit.dispatch(untyped process.exitCode);
			}
			else
			{
				untyped setImmediate(eventLoop);
			}
		}

		untyped setImmediate(eventLoop);
		return 0;
		#elseif lime_cffi
		var result = NativeCFFI.lime_application_exec(handle);

		#if (!emscripten && !ios && !nodejs)
		parent.onExit.dispatch(result);
		#end

		return result;
		#end
		#end

		return 0;
	}

	public function exit():Void
	{
		AudioManager.shutdown();

		#if (!macro && lime_cffi)
		NativeCFFI.lime_application_quit(handle);
		#end
	}

	private function handleApplicationEvent():Void
	{
		if (applicationEventInfo.type == UPDATE)
		{
			updateTimer();
			parent.onUpdate.dispatch(applicationEventInfo.deltaTime);
		}
	}

	private function handleClipboardEvent():Void
	{
		Clipboard.__update();
	}

	private function handleDropEvent():Void
	{
		for (window in parent.windows)
		{
			window.onDropFile.dispatch(#if hl @:privateAccess String.fromUTF8(dropEventInfo.file) #else dropEventInfo.file #end);
		}
	}

	private function handleGamepadEvent():Void
	{
		if (gamepadEventInfo.type == AXIS_MOVE)
			Game.onGamepadAxisMove.emit(SignalEvent.GAMEPAD_AXIS_MOVE, gamepadEventInfo.axis, gamepadEventInfo.axisValue);

		if (gamepadEventInfo.type == BUTTON_DOWN)
			Game.onGamepadButtonDown.emit(SignalEvent.GAMEPAD_BUTTON_DOWN, gamepadEventInfo.button);

		if (gamepadEventInfo.type == BUTTON_UP)
			Game.onGamepadButtonUp.emit(SignalEvent.GAMEPAD_BUTTON_UP, gamepadEventInfo.button);

		if (gamepadEventInfo.type == CONNECT)
		{
			Gamepad.__connect(gamepadEventInfo.id);
			Game.onGamepadConnect.emit(SignalEvent.GAMEPAD_CONNECT, gamepadEventInfo.id);
		}

		if (gamepadEventInfo.type == DISCONNECT)
		{
			Gamepad.__disconnect(gamepadEventInfo.id);
			Game.onGamepadConnect.emit(SignalEvent.GAMEPAD_DISCONNECT, gamepadEventInfo.id);
		}
	}

	private function handleJoystickEvent():Void
	{
		var joystick:Joystick = Joystick.devices.get(joystickEventInfo.id);
		if (joystick == null) return;

		if (joystickEventInfo.type == AXIS_MOVE)
			joystick.onAxisMove.dispatch(joystickEventInfo.index, joystickEventInfo.x);

		if (joystickEventInfo.type == HAT_MOVE)
			joystick.onHatMove.dispatch(joystickEventInfo.index, joystickEventInfo.eventValue);

		if (joystickEventInfo.type == TRACKBALL_MOVE)
			joystick.onTrackballMove.dispatch(joystickEventInfo.index, joystickEventInfo.x, joystickEventInfo.y);

		if (joystickEventInfo.type == BUTTON_DOWN)
			joystick.onButtonDown.dispatch(joystickEventInfo.index);

		if (joystickEventInfo.type == BUTTON_UP)
			joystick.onButtonUp.dispatch(joystickEventInfo.index);

		if (joystickEventInfo.type == CONNECT)
			Joystick.__connect(joystickEventInfo.id);

		if (joystickEventInfo.type == DISCONNECT)
			Joystick.__disconnect(joystickEventInfo.id);
	}

	private function handleKeyEvent():Void
	{
		var window:Window = parent.__windowByID.get(keyEventInfo.windowID);
		if (window == null) return;
		
		var type:KeyEventType = keyEventInfo.type;
		var keyCode:KeyCode = keyEventInfo.keyCode;
		var modifier:KeyModifier = keyEventInfo.modifier;

		if (type == KEY_UP)
			Game.onKeyUp.emit(SignalEvent.KEY_UP, keyCode, modifier);

		if (type == KEY_DOWN)
		{
			Game.onKeyDown.emit(SignalEvent.KEY_DOWN, keyCode, modifier);

			if (keyCode == F11)
				window.fullscreen = !window.fullscreen;

			if (null != FlxG.sound && !Game.blockSoundKeys)
			{
				if (keyCode == EQUALS)
				{
					FlxG.sound.volume = inline Math.min(FlxG.sound.volume + 0.1, 1.0);
					Main.volumeTxt.alpha = 1.0;
				}

				if (keyCode == MINUS)
				{
					FlxG.sound.volume = inline Math.max(FlxG.sound.volume - 0.1, 0.0);
					Main.volumeTxt.alpha = 1.0;
				}

				if (keyCode == NUMBER_0)
				{
					FlxG.sound.muted = !FlxG.sound.muted;
					Main.volumeTxt.alpha = 1.0;
				}
			}
		}
	}

	private function handleMouseEvent():Void
	{
		var window:Window = parent.__windowByID.get(keyEventInfo.windowID);
		if (window == null) return;

		if (mouseEventInfo.type == MOUSE_DOWN)
			window.onMouseDown.dispatch(mouseEventInfo.x, mouseEventInfo.y, mouseEventInfo.button);

		if (mouseEventInfo.type == MOUSE_UP)
			window.onMouseUp.dispatch(mouseEventInfo.x, mouseEventInfo.y, mouseEventInfo.button);

		if (mouseEventInfo.type == MOUSE_MOVE)
			window.onMouseMove.dispatch(mouseEventInfo.x, mouseEventInfo.y);

		if (mouseEventInfo.type == MOUSE_WHEEL)
			window.onMouseWheel.dispatch(mouseEventInfo.x, mouseEventInfo.y, UNKNOWN);
	}

	private function handleRenderEvent():Void
	{
		// TODO: Allow windows to render independently

		for (window in parent.__windows)
		{
			if (window == null) continue;

			// parent.renderer = renderer;

			switch (renderEventInfo.type)
			{
				case RENDER:
					if (window.context != null)
					{
						window.__backend.render();
						window.onRender.dispatch(window.context);

						if (!window.onRender.canceled)
						{
							window.__backend.contextFlip();
						}
					}

				case RENDER_CONTEXT_LOST:
					if (window.__backend.useHardware && window.context != null)
					{
						switch (window.context.type)
						{
							case OPENGL, OPENGLES, WEBGL:
								#if (lime_cffi && (lime_opengl || lime_opengles) && !display)
								var gl = window.context.gl;
								(gl : NativeOpenGLRenderContext).__contextLost();
								if (GL.context == gl) GL.context = null;
								#end

							default:
						}

						window.context = null;
						window.onRenderContextLost.dispatch();
					}

				case RENDER_CONTEXT_RESTORED:
					if (window.__backend.useHardware)
					{
						// GL.context = new OpenGLRenderContext ();
						// window.context.gl = GL.context;

						window.onRenderContextRestored.dispatch(window.context);
					}
			}
		}
	}

	private function handleSensorEvent():Void
	{
		var sensor = Sensor.sensorByID.get(sensorEventInfo.id);

		if (sensor != null)
		{
			sensor.onUpdate.dispatch(sensorEventInfo.x, sensorEventInfo.y, sensorEventInfo.z);
		}
	}

	private function handleTextEvent():Void
	{
		var window:Window = parent.__windowByID.get(textEventInfo.windowID);

		if (window != null)
		{
			switch (textEventInfo.type)
			{
				case TEXT_INPUT:
					window.onTextInput.dispatch(#if hl @:privateAccess String.fromUTF8(textEventInfo.text) #else textEventInfo.text #end);

				case TEXT_EDIT:
					window.onTextEdit.dispatch(#if hl @:privateAccess String.fromUTF8(textEventInfo.text) #else textEventInfo.text #end, textEventInfo.start,
						textEventInfo.length);

				default:
			}
		}
	}

	private function handleTouchEvent():Void
	{
		switch (touchEventInfo.type)
		{
			case TOUCH_START:
				var touch = unusedTouchesPool.pop();

				if (touch == null)
				{
					touch = new Touch(touchEventInfo.x, touchEventInfo.y, touchEventInfo.id, touchEventInfo.dx, touchEventInfo.dy, touchEventInfo.pressure,
						touchEventInfo.device);
				}
				else
				{
					touch.x = touchEventInfo.x;
					touch.y = touchEventInfo.y;
					touch.id = touchEventInfo.id;
					touch.dx = touchEventInfo.dx;
					touch.dy = touchEventInfo.dy;
					touch.pressure = touchEventInfo.pressure;
					touch.device = touchEventInfo.device;
				}

				currentTouches.set(touch.id, touch);

				Touch.onStart.dispatch(touch);

			case TOUCH_END:
				var touch = currentTouches.get(touchEventInfo.id);

				if (touch != null)
				{
					touch.x = touchEventInfo.x;
					touch.y = touchEventInfo.y;
					touch.dx = touchEventInfo.dx;
					touch.dy = touchEventInfo.dy;
					touch.pressure = touchEventInfo.pressure;

					Touch.onEnd.dispatch(touch);

					currentTouches.remove(touchEventInfo.id);
					unusedTouchesPool.add(touch);
				}

			case TOUCH_MOVE:
				var touch = currentTouches.get(touchEventInfo.id);

				if (touch != null)
				{
					touch.x = touchEventInfo.x;
					touch.y = touchEventInfo.y;
					touch.dx = touchEventInfo.dx;
					touch.dy = touchEventInfo.dy;
					touch.pressure = touchEventInfo.pressure;

					Touch.onMove.dispatch(touch);
				}

			default:
		}
	}

	private function handleWindowEvent():Void
	{
		var window:Window = parent.__windowByID.get(windowEventInfo.windowID);

		if (window != null)
		{
			switch (windowEventInfo.type)
			{
				case WINDOW_ACTIVATE:
					advanceTimer();
					window.onActivate.dispatch();
					AudioManager.resume();

				case WINDOW_CLOSE:
					window.close();

				case WINDOW_DEACTIVATE:
					window.onDeactivate.dispatch();
					AudioManager.suspend();
					pauseTimer = System.getTimer();

				case WINDOW_ENTER:
					window.onEnter.dispatch();

				case WINDOW_EXPOSE:
					window.onExpose.dispatch();

				case WINDOW_FOCUS_IN:
					window.onFocusIn.dispatch();

				case WINDOW_FOCUS_OUT:
					window.onFocusOut.dispatch();

				case WINDOW_LEAVE:
					window.onLeave.dispatch();

				case WINDOW_MAXIMIZE:
					window.__maximized = true;
					window.__fullscreen = false;
					window.__minimized = false;
					window.onMaximize.dispatch();

				case WINDOW_MINIMIZE:
					window.__minimized = true;
					window.__maximized = false;
					window.__fullscreen = false;
					window.onMinimize.dispatch();

				case WINDOW_MOVE:
					window.__x = windowEventInfo.x;
					window.__y = windowEventInfo.y;
					window.onMove.dispatch(windowEventInfo.x, windowEventInfo.y);

				case WINDOW_RESIZE:
					window.__width = windowEventInfo.width;
					window.__height = windowEventInfo.height;
					window.onResize.dispatch(windowEventInfo.width, windowEventInfo.height);

				case WINDOW_RESTORE:
					window.__fullscreen = false;
					window.__minimized = false;
					window.onRestore.dispatch();

				case WINDOW_SHOW:
					window.onShow.dispatch();

				case WINDOW_HIDE:
					window.onHide.dispatch();
			}
		}
	}

	private function updateTimer():Void
	{
		#if lime_cffi
		if (Timer.sRunningTimers.length > 0)
		{
			var currentTime = System.getTimer();
			var foundNull = false;
			var timer;

			for (i in 0...Timer.sRunningTimers.length)
			{
				timer = Timer.sRunningTimers[i];

				if (timer != null)
				{
					if (timer.mRunning && currentTime >= timer.mFireAt)
					{
						timer.mFireAt += timer.mTime;
						timer.run();
					}
				}
				else
				{
					foundNull = true;
				}
			}

			if (foundNull)
			{
				Timer.sRunningTimers = Timer.sRunningTimers.filter(function(val)
				{
					return val != null;
				});
			}
		}

		#if (haxe_ver >= 4.2)
		#if target.threaded
		sys.thread.Thread.current().events.progress();
		#else
		// Duplicate code required because Haxe 3 can't handle
		// #if (haxe_ver >= 4.2 && target.threaded)
		@:privateAccess haxe.EntryPoint.processEvents();
		#end
		#else
		@:privateAccess haxe.EntryPoint.processEvents();
		#end
		#end
	}
}

@:generic class ApplicationEventInfo
{
	public var deltaTime:Int;
	public var type:ApplicationEventType;

	public function new(type:ApplicationEventType = null, deltaTime:Int = 0)
	{
		this.type = type;
		this.deltaTime = deltaTime;
	}

	public function clone():ApplicationEventInfo
	{
		return new ApplicationEventInfo(type, deltaTime);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract ApplicationEventType(Int)
{
	var UPDATE = 0;
	var EXIT = 1;
}

@:generic class ClipboardEventInfo
{
	public var type:ClipboardEventType;

	public function new(type:ClipboardEventType = null)
	{
		this.type = type;
	}

	public function clone():ClipboardEventInfo
	{
		return new ClipboardEventInfo(type);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract ClipboardEventType(Int)
{
	var UPDATE = 0;
}

@:generic class DropEventInfo
{
	public var file:#if hl hl.Bytes #else String #end;
	public var type:DropEventType;

	public function new(type:DropEventType = null, file = null)
	{
		this.type = type;
		this.file = file;
	}

	public function clone():DropEventInfo
	{
		return new DropEventInfo(type, file);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract DropEventType(Int)
{
	var DROP_FILE = 0;
}

@:generic class GamepadEventInfo
{
	public var axis:Int;
	public var button:Int;
	public var id:Int;
	public var type:GamepadEventType;
	public var axisValue:Float;

	/**
	 * The timestamp, in milliseconds, of when the event occurred.
	 * Relative to `lime_sdl_get_ticks()`
	 * May be `0` if timestamp could not be determined.
	 * TODO: Replace with `Int64` when I figure out how to return one from HashLink
	 */
	public var timestamp:Int;

	public function new(type:GamepadEventType = null, id:Int = 0, button:Int = 0, axis:Int = 0, value:Float = 0, ?timestamp:Int = 0)
	{
		this.type = type;
		this.id = id;
		this.button = button;
		this.axis = axis;
		this.axisValue = value;
		this.timestamp = timestamp;
	}

	public function clone():GamepadEventInfo
	{
		return new GamepadEventInfo(type, id, button, axis, axisValue);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract GamepadEventType(Int)
{
	var AXIS_MOVE = 0;
	var BUTTON_DOWN = 1;
	var BUTTON_UP = 2;
	var CONNECT = 3;
	var DISCONNECT = 4;
}

@:generic class JoystickEventInfo
{
	public var id:Int;
	public var index:Int;
	public var type:JoystickEventType;
	public var eventValue:Int;
	public var x:Float;
	public var y:Float;

	public function new(type:JoystickEventType = null, id:Int = 0, index:Int = 0, value:Int = 0, x:Float = 0, y:Float = 0)
	{
		this.type = type;
		this.id = id;
		this.index = index;
		this.eventValue = value;
		this.x = x;
		this.y = y;
	}

	public function clone():JoystickEventInfo
	{
		return new JoystickEventInfo(type, id, index, eventValue, x, y);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract JoystickEventType(Int)
{
	var AXIS_MOVE = 0;
	var HAT_MOVE = 1;
	var TRACKBALL_MOVE = 2;
	var BUTTON_DOWN = 3;
	var BUTTON_UP = 4;
	var CONNECT = 5;
	var DISCONNECT = 6;
}

@:generic class KeyEventInfo
{
	public var keyCode:Int;
	public var modifier:Int;
	public var type:KeyEventType;
	public var windowID:Int;
	/**
	 * The timestamp, in milliseconds, of when the event occurred.
	 * Relative to `lime_sdl_get_ticks()`
	 * May be `0` if timestamp could not be determined.
	 * TODO: Replace with `Int64` when I figure out how to return one from HashLink
	 */
	public var timestamp:Int;

	public function new(type:KeyEventType = null, windowID:Int = 0, keyCode:Int = 0, modifier:Int = 0, ?timestamp:Int)
	{
		this.type = type;
		this.windowID = windowID;
		this.keyCode = keyCode;
		this.modifier = modifier;
		this.timestamp = timestamp;
	}

	public function clone():KeyEventInfo
	{
		return new KeyEventInfo(type, windowID, keyCode, modifier);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract KeyEventType(Int)
{
	var KEY_DOWN = 0;
	var KEY_UP = 1;
}

@:generic class MouseEventInfo
{
	public var button:Int;
	public var movementX:Float;
	public var movementY:Float;
	public var type:MouseEventType;
	public var windowID:Int;
	public var x:Float;
	public var y:Float;

	public function new(type:MouseEventType = null, windowID:Int = 0, x:Float = 0, y:Float = 0, button:Int = 0, movementX:Float = 0, movementY:Float = 0)
	{
		this.type = type;
		this.windowID = 0;
		this.x = x;
		this.y = y;
		this.button = button;
		this.movementX = movementX;
		this.movementY = movementY;
	}

	public function clone():MouseEventInfo
	{
		return new MouseEventInfo(type, windowID, x, y, button, movementX, movementY);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract MouseEventType(Int)
{
	var MOUSE_DOWN = 0;
	var MOUSE_UP = 1;
	var MOUSE_MOVE = 2;
	var MOUSE_WHEEL = 3;
}

@:generic class RenderEventInfo
{
	public var type:RenderEventType;

	public function new(type:RenderEventType = null)
	{
		this.type = type;
	}

	public function clone():RenderEventInfo
	{
		return new RenderEventInfo(type);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract RenderEventType(Int)
{
	var RENDER = 0;
	var RENDER_CONTEXT_LOST = 1;
	var RENDER_CONTEXT_RESTORED = 2;
}

@:generic class SensorEventInfo
{
	public var id:Int;
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var type:SensorEventType;

	public function new(type:SensorEventType = null, id:Int = 0, x:Float = 0, y:Float = 0, z:Float = 0)
	{
		this.type = type;
		this.id = id;
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public function clone():SensorEventInfo
	{
		return new SensorEventInfo(type, id, x, y, z);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract SensorEventType(Int)
{
	var ACCELEROMETER = 0;
}

@:generic class TextEventInfo
{
	public var id:Int;
	public var length:Int;
	public var start:Int;
	public var text:#if hl hl.Bytes #else String #end;
	public var type:TextEventType;
	public var windowID:Int;

	public function new(type:TextEventType = null, windowID:Int = 0, text = null, start:Int = 0, length:Int = 0)
	{
		this.type = type;
		this.windowID = windowID;
		this.text = text;
		this.start = start;
		this.length = length;
	}

	public function clone():TextEventInfo
	{
		return new TextEventInfo(type, windowID, text, start, length);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract TextEventType(Int)
{
	var TEXT_INPUT = 0;
	var TEXT_EDIT = 1;
}

@:generic class TouchEventInfo
{
	public var device:Int;
	public var dx:Float;
	public var dy:Float;
	public var id:Int;
	public var pressure:Float;
	public var type:TouchEventType;
	public var x:Float;
	public var y:Float;

	public function new(type:TouchEventType = null, x:Float = 0, y:Float = 0, id:Int = 0, dx:Float = 0, dy:Float = 0, pressure:Float = 0, device:Int = 0)
	{
		this.type = type;
		this.x = x;
		this.y = y;
		this.id = id;
		this.dx = dx;
		this.dy = dy;
		this.pressure = pressure;
		this.device = device;
	}

	public function clone():TouchEventInfo
	{
		return new TouchEventInfo(type, x, y, id, dx, dy, pressure, device);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract TouchEventType(Int)
{
	var TOUCH_START = 0;
	var TOUCH_END = 1;
	var TOUCH_MOVE = 2;
}

@:generic class WindowEventInfo
{
	public var height:Int;
	public var type:WindowEventType;
	public var width:Int;
	public var windowID:Int;
	public var x:Int;
	public var y:Int;

	public function new(type:WindowEventType = null, windowID:Int = 0, width:Int = 0, height:Int = 0, x:Int = 0, y:Int = 0)
	{
		this.type = type;
		this.windowID = windowID;
		this.width = width;
		this.height = height;
		this.x = x;
		this.y = y;
	}

	public function clone():WindowEventInfo
	{
		return new WindowEventInfo(type, windowID, width, height, x, y);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract WindowEventType(Int)
{
	var WINDOW_ACTIVATE = 0;
	var WINDOW_CLOSE = 1;
	var WINDOW_DEACTIVATE = 2;
	var WINDOW_ENTER = 3;
	var WINDOW_EXPOSE = 4;
	var WINDOW_FOCUS_IN = 5;
	var WINDOW_FOCUS_OUT = 6;
	var WINDOW_LEAVE = 7;
	var WINDOW_MAXIMIZE = 8;
	var WINDOW_MINIMIZE = 9;
	var WINDOW_MOVE = 10;
	var WINDOW_RESIZE = 11;
	var WINDOW_RESTORE = 12;
	var WINDOW_SHOW = 13;
	var WINDOW_HIDE = 14;
}
