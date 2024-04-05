package zenith.core;

class SignalEvent
{
	// Gameplay events
	public static inline var NOTE_FOLLOW:SignalType.SignalType2<(Note, StrumNote)->Void, Note, StrumNote> = "note_follow";
	public static inline var NOTE_HIT:SignalType.SignalType1<(Note)->Void, Note> = "note_hit";
	public static inline var NOTE_MISS:SignalType.SignalType1<(Note)->Void, Note> = "note_miss";

	// Keyboard events
	public static inline var KEY_DOWN:SignalType.SignalType1<(Int)->Void, Int> = "key_down";
	public static inline var KEY_UP:SignalType.SignalType1<(Int)->Void, Int> = "key_up";
}