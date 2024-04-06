package zenith.core;

class SignalEvent
{
	// Gameplay events
	inline static public var NOTE_FOLLOW:SignalType.SignalType2<(Note, StrumNote)->Void, Note, StrumNote> = "note_follow";
	inline static public var NOTE_HIT:SignalType.SignalType1<(Note)->Void, Note> = "note_hit";
	inline static public var NOTE_MISS:SignalType.SignalType1<(Note)->Void, Note> = "note_miss";
	inline static public var GAMEPLAY_UPDATE:SignalType.SignalType1<(Float)->Void, Float> = "gameplay_update";

	// Keyboard events
	inline static public var KEY_DOWN:SignalType.SignalType1<(Int)->Void, Int> = "key_down";
	inline static public var KEY_UP:SignalType.SignalType1<(Int)->Void, Int> = "key_up";
}