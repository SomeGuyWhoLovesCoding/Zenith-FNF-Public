package zenith.objects;

class Note extends NoteBase
{
	public var child:SustainNote;
	public var hasChild:Bool = false;
	public var sustainLength:Int = 0;
	public var state:NoteState = IDLE;
}
