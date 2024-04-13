// Don't mind this

package zenith.system;

import lime.ui.KeyCode;
import lime.ui.KeyModifier;

typedef BaseNativeApplication = lime._internal.backend.native.NativeApplication;

@:access(lime.ui.Gamepad)
@:access(lime.ui.Joystick)
class NativeApp extends BaseNativeApplication
{
	public function new():Void
	{
		super(null); // Workaround
	}

	override function handleGamepadEvent():Void
	{
		if (gamepadEventInfo.type == cast 0)
			Game.onGamepadAxisMove.emit(SignalEvent.GAMEPAD_AXIS_MOVE, gamepadEventInfo.axis, gamepadEventInfo.axisValue);

		if (gamepadEventInfo.type == cast 1)
			Game.onGamepadButtonDown.emit(SignalEvent.GAMEPAD_BUTTON_DOWN, gamepadEventInfo.button);

		if (gamepadEventInfo.type == cast 2)
			Game.onGamepadButtonUp.emit(SignalEvent.GAMEPAD_BUTTON_UP, gamepadEventInfo.button);

		if (gamepadEventInfo.type == cast 3)
		{
			lime.ui.Gamepad.__connect(gamepadEventInfo.id);
			Game.onGamepadConnect.emit(SignalEvent.GAMEPAD_CONNECT, gamepadEventInfo.id);
		}

		if (gamepadEventInfo.type == cast 4)
		{
			lime.ui.Gamepad.__disconnect(gamepadEventInfo.id);
			Game.onGamepadConnect.emit(SignalEvent.GAMEPAD_DISCONNECT, gamepadEventInfo.id);
		}
	}

	override function handleJoystickEvent():Void
	{
		var joystick = lime.ui.Joystick.devices.get(joystickEventInfo.id);
		if (joystick == null) return;

		if (joystickEventInfo.type == cast 0)
			joystick.onAxisMove.dispatch(joystickEventInfo.index, joystickEventInfo.x);

		if (joystickEventInfo.type == cast 1)
			joystick.onHatMove.dispatch(joystickEventInfo.index, joystickEventInfo.eventValue);

		if (joystickEventInfo.type == cast 2)
			joystick.onTrackballMove.dispatch(joystickEventInfo.index, joystickEventInfo.x, joystickEventInfo.y);

		if (joystickEventInfo.type == cast 3)
			joystick.onButtonDown.dispatch(joystickEventInfo.index);

		if (joystickEventInfo.type == cast 4)
			joystick.onButtonUp.dispatch(joystickEventInfo.index);

		if (joystickEventInfo.type == cast 5)
			lime.ui.Joystick.__connect(joystickEventInfo.id);

		if (joystickEventInfo.type == cast 6)
			lime.ui.Joystick.__disconnect(joystickEventInfo.id);
	}

	override function handleKeyEvent():Void
	{
		trace('a');
		var window = @:privateAccess lime.app.Application.current.__windowByID.get(keyEventInfo.windowID);
		if (window == null) return;

		var type = keyEventInfo.type;
		var keyCode:KeyCode = Std.int(keyEventInfo.keyCode);
		var modifier:KeyModifier = keyEventInfo.modifier;

		if (type == cast 1)
			Game.onKeyUp.emit(SignalEvent.KEY_UP, keyCode, modifier);

		if (type == cast 0)
		{
			Game.onKeyDown.emit(SignalEvent.KEY_DOWN, keyCode, modifier);

			if (keyCode == KeyCode.F11)
				window.fullscreen = !window.fullscreen;

			if (!Game.blockSoundKeys)
			{
				if (keyCode == KeyCode.EQUALS)
				{
					Game.volume = Math.min(Game.volume + 0.1, 1.0);
					Main.volumeTxt.alpha = 1.0;
				}

				if (keyCode == KeyCode.MINUS)
				{
					Game.volume = Math.max(Game.volume - 0.1, 0.0);
					Main.volumeTxt.alpha = 1.0;
				}

				if (keyCode == KeyCode.NUMBER_0)
				{
					Game.muted = !Game.muted;
					Main.volumeTxt.alpha = 1.0;
				}
			}
		}
	}
}