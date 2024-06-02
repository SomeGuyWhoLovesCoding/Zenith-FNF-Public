package zenith.objects;

enum NoteState
{
    IDLE;
    HIT;
    MISSED;
}

class Note extends NoteBase
{
	public var sustainLength:Int = 0;
	public var multiplier:Int = 0;
	public var state:NoteState = IDLE;
}
