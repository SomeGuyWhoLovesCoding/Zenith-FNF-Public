package zenith.enums;

/**
 * The note state.
 */
enum abstract NoteState(Int) to Int
{
	var IDLE;
	var HELD;
	var HIT;
	var MISS;
}
