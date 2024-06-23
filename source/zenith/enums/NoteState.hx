package zenith.enums;

enum abstract NoteState(UInt8) to UInt8
{
	var IDLE;
	var HELD;
	var HIT;
	var MISS;
}
