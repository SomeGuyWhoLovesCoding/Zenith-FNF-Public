package zenith.core;

import lime.ui.*;

class SignalEvent
{
	// Keyboard

	inline static public var KEY_DOWN:SignalType.SignalType2<(KeyCode, KeyModifier)->Void, KeyCode, KeyModifier> = "key_down";
	inline static public var KEY_UP:SignalType.SignalType2<(KeyCode, KeyModifier)->Void, KeyCode, KeyModifier> = "key_up";

	// Gamepad

	inline static public var GAMEPAD_AXIS_MOVE:SignalType.SignalType2<(GamepadAxis, Float)->Void, GamepadAxis, Float> = "gamepad_axis_move";
	inline static public var GAMEPAD_BUTTON_DOWN:SignalType.SignalType1<(GamepadButton)->Void, GamepadButton> = "gamepad_button_down";
	inline static public var GAMEPAD_BUTTON_UP:SignalType.SignalType1<(GamepadButton)->Void, GamepadButton> = "gamepad_button_up";
	inline static public var GAMEPAD_CONNECT:SignalType.SignalType1<(Int)->Void, Int> = "gamepad_connect";
	inline static public var GAMEPAD_DISCONNECT:SignalType.SignalType1<(Int)->Void, Int> = "gamepad_disconnect";

	// Gameplay

	inline static public var NOTE_HIT:SignalType.SignalType1<(Note)->Void, Note> = "note_hit";
	inline static public var NOTE_MISS:SignalType.SignalType1<(Note)->Void, Note> = "note_miss";
	inline static public var GAMEPLAY_UPDATE:SignalType.SignalType1<(Float)->Void, Float> = "gameplay_update";
}