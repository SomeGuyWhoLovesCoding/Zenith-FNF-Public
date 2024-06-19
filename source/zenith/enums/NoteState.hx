package zenith.enums;

enum abstract NoteState(Int)
{
	var IDLE = 0;
	var HELD = 1;
	var HIT = 2;
	var MISS = -1;
}
